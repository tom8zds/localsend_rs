//! Multi-session transfer manager.
//!
//! A single actor owns every transfer session (both directions), keyed
//! by session id (a UUID v4). It replaces the old single-slot
//! pending/transfer pair:
//!
//! * receive sessions are capped at [`DEFAULT_MAX_RECV_SESSIONS`]
//!   concurrent pending/transferring sessions; `prepare-upload` past the
//!   limit is rejected with [`SessionError::Busy`] (HTTP 409),
//! * decisions are imperative: [`SessionHandle::accept`] /
//!   [`SessionHandle::decline`] write the outcome back into the pending
//!   `prepare-upload` request through a stored oneshot channel,
//! * observers use [`SessionHandle::session_index`] (low-frequency
//!   snapshots) and [`SessionHandle::session_events`] (per-session
//!   event stream).

use std::collections::HashMap;

use log::{debug, warn};
use tokio::sync::{mpsc, oneshot, watch};
use tokio_util::sync::CancellationToken;
use uuid::Uuid;

use crate::model::{
    FileInfo, FileState, MissionFileInfo, MissionState, NodeDevice, SessionDirection, SessionEvent,
    SessionSummary,
};

/// Maximum number of concurrent receive sessions (pending + active).
pub const DEFAULT_MAX_RECV_SESSIONS: usize = 8;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SessionError {
    /// Too many concurrent receive sessions.
    Busy,
    /// No session with this id.
    NotFound,
    /// The session is not in a state allowing this operation.
    InvalidState,
    /// No file with this token/id in the session.
    UnknownFile,
}

impl std::fmt::Display for SessionError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            SessionError::Busy => write!(f, "too many concurrent sessions"),
            SessionError::NotFound => write!(f, "session not found"),
            SessionError::InvalidState => write!(f, "invalid session state"),
            SessionError::UnknownFile => write!(f, "unknown file"),
        }
    }
}

impl std::error::Error for SessionError {}

/// Outcome of a pending receive session, delivered to the waiting
/// `prepare-upload` handler.
#[derive(Debug)]
pub enum Decision {
    /// Accepted; maps file id to the upload token the sender must use.
    Accepted { files: HashMap<String, String> },
    /// Rejected by the local user.
    Declined,
    /// Aborted (sender disconnected or cancelled while pending).
    Canceled,
}

/// Handle for one in-flight file upload on the receive side.
pub struct FileTask {
    pub file_id: String,
    pub info: FileInfo,
    /// Receiver-side progress sink: total bytes written so far.
    pub progress: watch::Sender<usize>,
    /// Cancelled when the session is cancelled; in-flight writers must
    /// abort.
    pub cancel: CancellationToken,
}

/// A freshly registered pending receive session.
pub struct RecvPending {
    pub session_id: String,
    pub decision: oneshot::Receiver<Decision>,
}

#[derive(Debug, Clone)]
struct FileEntry {
    token: Option<String>,
    info: FileInfo,
    state: FileState,
}

struct Session {
    id: String,
    direction: SessionDirection,
    peer: NodeDevice,
    state: MissionState,
    via_relay: bool,
    route: String,
    speed_bps: u64,
    last_progress_at: Option<std::time::Instant>,
    last_total_bytes: u64,
    files: HashMap<String, FileEntry>,
    token_index: HashMap<String, String>,
    decision: Option<oneshot::Sender<Decision>>,
    events_tx: watch::Sender<SessionEvent>,
    events_rx: watch::Receiver<SessionEvent>,
    cancel_token: CancellationToken,
}

impl Session {
    /// Per-file view, sorted by file name for a stable display order.
    fn file_infos(&self) -> Vec<MissionFileInfo> {
        let mut files: Vec<MissionFileInfo> = self
            .files
            .values()
            .map(|f| MissionFileInfo {
                info: f.info.clone(),
                state: f.state.clone(),
            })
            .collect();
        files.sort_by(|a, b| a.info.file_name.cmp(&b.info.file_name));
        files
    }

    fn summary(&self) -> SessionSummary {
        SessionSummary {
            id: self.id.clone(),
            direction: self.direction,
            peer: self.peer.clone(),
            file_count: self.files.len(),
            state: self.state,
            via_relay: self.via_relay,
            route: self.route.clone(),
            speed_bps: self.speed_bps,
            files: self.file_infos(),
        }
    }

    fn is_active(&self) -> bool {
        matches!(
            self.state,
            MissionState::Pending | MissionState::Transfering
        )
    }
}

enum Message {
    CreateRecvSession {
        sender: NodeDevice,
        files: HashMap<String, FileInfo>,
        respond_to: oneshot::Sender<Result<RecvPending, SessionError>>,
    },
    CreateSendSession {
        target: NodeDevice,
        files: Vec<(String, FileInfo)>,
        respond_to: oneshot::Sender<String>,
    },
    Accept {
        id: String,
        file_ids: Option<Vec<String>>,
        respond_to: oneshot::Sender<Result<(), SessionError>>,
    },
    Decline {
        id: String,
        respond_to: oneshot::Sender<Result<(), SessionError>>,
    },
    Cancel {
        id: String,
        respond_to: oneshot::Sender<()>,
    },
    MarkViaRelay {
        id: String,
    },
    MarkRoute {
        id: String,
        route: String,
    },
    StartFile {
        id: String,
        token: String,
        respond_to: oneshot::Sender<Result<FileTask, SessionError>>,
    },
    FinishFile {
        id: String,
        token: String,
        state: FileState,
        respond_to: oneshot::Sender<()>,
    },
    ReportProgress {
        id: String,
        file_id: String,
        bytes: usize,
    },
    ReportFileState {
        id: String,
        file_id: String,
        state: FileState,
        respond_to: oneshot::Sender<()>,
    },
    ReportState {
        id: String,
        state: MissionState,
        respond_to: oneshot::Sender<()>,
    },
    Fail {
        id: String,
        reason: String,
        respond_to: oneshot::Sender<()>,
    },
    SessionEvents {
        id: String,
        respond_to: oneshot::Sender<Option<watch::Receiver<SessionEvent>>>,
    },
    CancelToken {
        id: String,
        respond_to: oneshot::Sender<Option<CancellationToken>>,
    },
    GetSession {
        id: String,
        respond_to: oneshot::Sender<Option<SessionSummary>>,
    },
    ListenIndex {
        respond_to: oneshot::Sender<watch::Receiver<Vec<SessionSummary>>>,
    },
}

struct Actor {
    receiver: mpsc::Receiver<Message>,
    sender: mpsc::Sender<Message>,
    sessions: HashMap<String, Session>,
    max_recv_sessions: usize,
    index_tx: watch::Sender<Vec<SessionSummary>>,
    index_rx: watch::Receiver<Vec<SessionSummary>>,
}

impl Actor {
    fn new(
        receiver: mpsc::Receiver<Message>,
        sender: mpsc::Sender<Message>,
        max_recv_sessions: usize,
    ) -> Self {
        let (index_tx, index_rx) = watch::channel(Vec::new());
        Actor {
            receiver,
            sender,
            sessions: HashMap::new(),
            max_recv_sessions,
            index_tx,
            index_rx,
        }
    }

    fn broadcast_index(&self) {
        let mut list: Vec<SessionSummary> = self.sessions.values().map(Session::summary).collect();
        list.sort_by(|a, b| a.id.cmp(&b.id));
        let _ = self.index_tx.send(list);
    }

    fn set_state(&mut self, id: &str, state: MissionState) {
        if let Some(session) = self.sessions.get_mut(id) {
            if !session.is_active() {
                return;
            }
            session.state = state;
            let _ = session.events_tx.send(SessionEvent::StateChanged(state));
        }
        self.broadcast_index();
    }

    fn set_file_state(&mut self, id: &str, file_id: &str, state: FileState) {
        let mut fail_reason = None;
        if let Some(session) = self.sessions.get_mut(id) {
            if !session.is_active() {
                return;
            }
            if let Some(file) = session.files.get_mut(file_id) {
                file.state = state.clone();
                let _ = session.events_tx.send(SessionEvent::FileStateChanged {
                    file_id: file_id.to_string(),
                    state: state.clone(),
                });
            }
            if let FileState::Fail { msg } = &state {
                fail_reason = Some(msg.clone());
            }
        }
        if let Some(reason) = fail_reason {
            self.fail_session(id, reason);
            return;
        }
        self.check_finish(id);
        self.broadcast_index();
    }

    /// Mark the session finished when every file reached a terminal
    /// state (finished or skipped).
    fn check_finish(&mut self, id: &str) {
        let done = match self.sessions.get(id) {
            Some(session) => {
                session.is_active()
                    && !session.files.is_empty()
                    && session
                        .files
                        .values()
                        .all(|f| matches!(f.state, FileState::Finish | FileState::Skip))
            }
            None => false,
        };
        if done {
            self.set_state(id, MissionState::Finished);
        }
    }

    fn fail_session(&mut self, id: &str, reason: String) {
        if let Some(session) = self.sessions.get_mut(id) {
            if !session.is_active() {
                return;
            }
            session.state = MissionState::Failed;
            session.cancel_token.cancel();
            let _ = session
                .events_tx
                .send(SessionEvent::StateChanged(MissionState::Failed));
            // Sent last: watch receivers keep the latest value, and the
            // failure reason is the most useful terminal event.
            let _ = session.events_tx.send(SessionEvent::Failed {
                reason: reason.clone(),
            });
            // Unblock a still-waiting prepare-upload handler.
            if let Some(decision) = session.decision.take() {
                let _ = decision.send(Decision::Canceled);
            }
        }
        self.broadcast_index();
    }

    fn cancel_session(&mut self, id: &str) {
        if let Some(session) = self.sessions.get_mut(id) {
            if !session.is_active() {
                return;
            }
            session.state = MissionState::Canceled;
            session.cancel_token.cancel();
            let _ = session
                .events_tx
                .send(SessionEvent::StateChanged(MissionState::Canceled));
            if let Some(decision) = session.decision.take() {
                let _ = decision.send(Decision::Canceled);
            }
        }
        self.broadcast_index();
    }

    async fn handle_message(&mut self, msg: Message) {
        match msg {
            Message::CreateRecvSession {
                sender,
                files,
                respond_to,
            } => {
                let active = self
                    .sessions
                    .values()
                    .filter(|s| s.direction == SessionDirection::Receive && s.is_active())
                    .count();
                if active >= self.max_recv_sessions {
                    debug!("receive session rejected: busy ({active} active)");
                    let _ = respond_to.send(Err(SessionError::Busy));
                    return;
                }

                let id = Uuid::new_v4().to_string();
                let mut token_index = HashMap::new();
                let files = files
                    .into_iter()
                    .map(|(file_id, info)| {
                        let token = Uuid::new_v4().to_string();
                        token_index.insert(token.clone(), file_id.clone());
                        (
                            file_id.clone(),
                            FileEntry {
                                token: Some(token),
                                info,
                                state: FileState::Pending,
                            },
                        )
                    })
                    .collect();

                let (decision_tx, decision_rx) = oneshot::channel();
                let (events_tx, events_rx) =
                    watch::channel(SessionEvent::StateChanged(MissionState::Pending));
                let session = Session {
                    id: id.clone(),
                    direction: SessionDirection::Receive,
                    peer: sender,
                    state: MissionState::Pending,
                    via_relay: false,
                    route: "local".to_string(),
                    speed_bps: 0,
                    last_progress_at: None,
                    last_total_bytes: 0,
                    files,
                    token_index,
                    decision: Some(decision_tx),
                    events_tx,
                    events_rx,
                    cancel_token: CancellationToken::new(),
                };
                debug!("receive session created: {id}");
                self.sessions.insert(id.clone(), session);
                self.broadcast_index();
                let _ = respond_to.send(Ok(RecvPending {
                    session_id: id,
                    decision: decision_rx,
                }));
            }
            Message::CreateSendSession {
                target,
                files,
                respond_to,
            } => {
                let id = Uuid::new_v4().to_string();
                let files = files
                    .into_iter()
                    .map(|(file_id, info)| {
                        (
                            file_id.clone(),
                            FileEntry {
                                token: None,
                                info,
                                state: FileState::Pending,
                            },
                        )
                    })
                    .collect();
                let (events_tx, events_rx) =
                    watch::channel(SessionEvent::StateChanged(MissionState::Pending));
                let session = Session {
                    id: id.clone(),
                    direction: SessionDirection::Send,
                    peer: target,
                    state: MissionState::Pending,
                    via_relay: false,
                    route: "local".to_string(),
                    speed_bps: 0,
                    last_progress_at: None,
                    last_total_bytes: 0,
                    files,
                    token_index: HashMap::new(),
                    decision: None,
                    events_tx,
                    events_rx,
                    cancel_token: CancellationToken::new(),
                };
                debug!("send session created: {id}");
                self.sessions.insert(id.clone(), session);
                self.broadcast_index();
                let _ = respond_to.send(id);
            }
            Message::Accept {
                id,
                file_ids,
                respond_to,
            } => {
                let result = (|| {
                    let session = self.sessions.get_mut(&id).ok_or(SessionError::NotFound)?;
                    if session.direction != SessionDirection::Receive
                        || session.state != MissionState::Pending
                    {
                        return Err(SessionError::InvalidState);
                    }
                    let accepted: Vec<String> = match &file_ids {
                        None => session.files.keys().cloned().collect(),
                        Some(ids) => ids
                            .iter()
                            .filter(|fid| session.files.contains_key(*fid))
                            .cloned()
                            .collect(),
                    };
                    let mut tokens = HashMap::new();
                    let mut skipped = Vec::new();
                    for (file_id, file) in session.files.iter_mut() {
                        if accepted.contains(file_id) {
                            if let Some(token) = &file.token {
                                tokens.insert(file_id.clone(), token.clone());
                            }
                        } else {
                            file.state = FileState::Skip;
                            skipped.push(file_id.clone());
                        }
                    }
                    session.state = MissionState::Transfering;
                    for file_id in skipped {
                        let _ = session.events_tx.send(SessionEvent::FileStateChanged {
                            file_id,
                            state: FileState::Skip,
                        });
                    }
                    let _ = session
                        .events_tx
                        .send(SessionEvent::StateChanged(MissionState::Transfering));
                    if let Some(decision) = session.decision.take() {
                        let _ = decision.send(Decision::Accepted { files: tokens });
                    }
                    Ok(())
                })();
                self.broadcast_index();
                // A session where nothing was accepted finishes right away.
                self.check_finish(&id);
                let _ = respond_to.send(result);
            }
            Message::Decline { id, respond_to } => {
                let result = (|| {
                    let session = self.sessions.get_mut(&id).ok_or(SessionError::NotFound)?;
                    if session.direction != SessionDirection::Receive
                        || session.state != MissionState::Pending
                    {
                        return Err(SessionError::InvalidState);
                    }
                    session.state = MissionState::Canceled;
                    session.cancel_token.cancel();
                    let _ = session
                        .events_tx
                        .send(SessionEvent::StateChanged(MissionState::Canceled));
                    if let Some(decision) = session.decision.take() {
                        let _ = decision.send(Decision::Declined);
                    }
                    Ok(())
                })();
                self.broadcast_index();
                let _ = respond_to.send(result);
            }
            Message::Cancel { id, respond_to } => {
                debug!("cancel session {id}");
                self.cancel_session(&id);
                let _ = respond_to.send(());
            }
            Message::MarkViaRelay { id } => {
                if let Some(session) = self.sessions.get_mut(&id) {
                    session.via_relay = true;
                    if session.route == "local" {
                        session.route = "turn".to_string();
                    }
                }
                self.broadcast_index();
            }
            Message::MarkRoute { id, route } => {
                if let Some(session) = self.sessions.get_mut(&id) {
                    session.route = route;
                }
                self.broadcast_index();
            }
            Message::StartFile {
                id,
                token,
                respond_to,
            } => {
                let result = (|| {
                    let session = self.sessions.get_mut(&id).ok_or(SessionError::NotFound)?;
                    if session.direction != SessionDirection::Receive
                        || session.state != MissionState::Transfering
                    {
                        return Err(SessionError::InvalidState);
                    }
                    let file_id = session
                        .token_index
                        .get(&token)
                        .cloned()
                        .ok_or(SessionError::UnknownFile)?;
                    let file = session
                        .files
                        .get_mut(&file_id)
                        .ok_or(SessionError::UnknownFile)?;
                    if file.state.is_terminal() {
                        return Err(SessionError::InvalidState);
                    }
                    file.state = FileState::Transfer;
                    let _ = session.events_tx.send(SessionEvent::FileStateChanged {
                        file_id: file_id.clone(),
                        state: FileState::Transfer,
                    });
                    let (progress_tx, progress_rx) = watch::channel(0usize);
                    // Forward per-file progress back into the actor,
                    // which fans it out to the session event stream.
                    let forward_tx = self.sender.clone();
                    let forward_id = id.clone();
                    let forward_file = file_id.clone();
                    tokio::spawn(async move {
                        let mut rx = progress_rx;
                        while rx.changed().await.is_ok() {
                            let bytes = *rx.borrow_and_update();
                            if forward_tx
                                .send(Message::ReportProgress {
                                    id: forward_id.clone(),
                                    file_id: forward_file.clone(),
                                    bytes,
                                })
                                .await
                                .is_err()
                            {
                                break;
                            }
                        }
                    });
                    Ok(FileTask {
                        file_id,
                        info: file.info.clone(),
                        progress: progress_tx,
                        cancel: session.cancel_token.clone(),
                    })
                })();
                self.broadcast_index();
                let _ = respond_to.send(result);
            }
            Message::FinishFile {
                id,
                token,
                state,
                respond_to,
            } => {
                let file_id = self
                    .sessions
                    .get(&id)
                    .and_then(|s| s.token_index.get(&token).cloned());
                match file_id {
                    Some(file_id) => self.set_file_state(&id, &file_id, state),
                    None => warn!("finish_file: unknown token for session {id}"),
                }
                let _ = respond_to.send(());
            }
            Message::ReportProgress { id, file_id, bytes } => {
                if let Some(session) = self.sessions.get(&id) {
                    let _ = session
                        .events_tx
                        .send(SessionEvent::Progress { file_id, bytes });
                }
            }
            Message::ReportFileState {
                id,
                file_id,
                state,
                respond_to,
            } => {
                self.set_file_state(&id, &file_id, state);
                let _ = respond_to.send(());
            }
            Message::ReportState {
                id,
                state,
                respond_to,
            } => {
                self.set_state(&id, state);
                let _ = respond_to.send(());
            }
            Message::Fail {
                id,
                reason,
                respond_to,
            } => {
                self.fail_session(&id, reason);
                let _ = respond_to.send(());
            }
            Message::SessionEvents { id, respond_to } => {
                let _ = respond_to.send(self.sessions.get(&id).map(|s| s.events_rx.clone()));
            }
            Message::CancelToken { id, respond_to } => {
                let _ = respond_to.send(self.sessions.get(&id).map(|s| s.cancel_token.clone()));
            }
            Message::GetSession { id, respond_to } => {
                let _ = respond_to.send(self.sessions.get(&id).map(Session::summary));
            }
            Message::ListenIndex { respond_to } => {
                let _ = respond_to.send(self.index_rx.clone());
            }
        }
    }
}

async fn run_session_actor(mut actor: Actor) {
    while let Some(msg) = actor.receiver.recv().await {
        actor.handle_message(msg).await;
    }
}

#[derive(Clone)]
pub struct SessionHandle {
    sender: mpsc::Sender<Message>,
}

impl SessionHandle {
    pub fn new(max_recv_sessions: usize) -> Self {
        let (sender, receiver) = mpsc::channel(64);
        let actor = Actor::new(receiver, sender.clone(), max_recv_sessions);
        tokio::spawn(run_session_actor(actor));
        Self { sender }
    }

    pub async fn create_recv_session(
        &self,
        sender_device: NodeDevice,
        files: HashMap<String, FileInfo>,
    ) -> Result<RecvPending, SessionError> {
        let (send, recv) = oneshot::channel();
        let _ = self
            .sender
            .send(Message::CreateRecvSession {
                sender: sender_device,
                files,
                respond_to: send,
            })
            .await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn create_send_session(
        &self,
        target: NodeDevice,
        files: Vec<(String, FileInfo)>,
    ) -> String {
        let (send, recv) = oneshot::channel();
        let _ = self
            .sender
            .send(Message::CreateSendSession {
                target,
                files,
                respond_to: send,
            })
            .await;
        recv.await.expect("Actor task has been killed")
    }

    /// Accept a pending receive session. `file_ids == None` accepts all
    /// files; `Some(ids)` accepts that subset and marks the rest as
    /// skipped.
    pub async fn accept(
        &self,
        id: &str,
        file_ids: Option<Vec<String>>,
    ) -> Result<(), SessionError> {
        let (send, recv) = oneshot::channel();
        let _ = self
            .sender
            .send(Message::Accept {
                id: id.to_string(),
                file_ids,
                respond_to: send,
            })
            .await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn decline(&self, id: &str) -> Result<(), SessionError> {
        let (send, recv) = oneshot::channel();
        let _ = self
            .sender
            .send(Message::Decline {
                id: id.to_string(),
                respond_to: send,
            })
            .await;
        recv.await.expect("Actor task has been killed")
    }

    /// Cancel any active session (either direction, pending or
    /// transferring).
    pub async fn cancel(&self, id: &str) {
        let (send, recv) = oneshot::channel();
        let _ = self
            .sender
            .send(Message::Cancel {
                id: id.to_string(),
                respond_to: send,
            })
            .await;
        recv.await.expect("Actor task has been killed")
    }

    /// Flag a session as tunneled through the relay (send driver calls
    /// this after a successful relay fallback).
    pub async fn mark_via_relay(&self, id: &str) {
        let _ = self
            .sender
            .send(Message::MarkViaRelay { id: id.to_string() })
            .await;
    }

    /// Record the connection route ("local" | "turn" | "stun").
    pub async fn mark_route(&self, id: &str, route: &str) {
        let _ = self
            .sender
            .send(Message::MarkRoute {
                id: id.to_string(),
                route: route.to_string(),
            })
            .await;
    }

    pub async fn start_file(&self, id: &str, token: &str) -> Result<FileTask, SessionError> {
        let (send, recv) = oneshot::channel();
        let _ = self
            .sender
            .send(Message::StartFile {
                id: id.to_string(),
                token: token.to_string(),
                respond_to: send,
            })
            .await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn finish_file(&self, id: &str, token: &str, state: FileState) {
        let (send, recv) = oneshot::channel();
        let _ = self
            .sender
            .send(Message::FinishFile {
                id: id.to_string(),
                token: token.to_string(),
                state,
                respond_to: send,
            })
            .await;
        recv.await.expect("Actor task has been killed")
    }

    // --- send-side reporting -------------------------------------------

    /// Fire-and-forget progress report (used by the send driver).
    pub async fn report_progress(&self, id: &str, file_id: &str, bytes: usize) {
        let _ = self
            .sender
            .send(Message::ReportProgress {
                id: id.to_string(),
                file_id: file_id.to_string(),
                bytes,
            })
            .await;
    }

    pub async fn report_file_state(&self, id: &str, file_id: &str, state: FileState) {
        let (send, recv) = oneshot::channel();
        let _ = self
            .sender
            .send(Message::ReportFileState {
                id: id.to_string(),
                file_id: file_id.to_string(),
                state,
                respond_to: send,
            })
            .await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn report_state(&self, id: &str, state: MissionState) {
        let (send, recv) = oneshot::channel();
        let _ = self
            .sender
            .send(Message::ReportState {
                id: id.to_string(),
                state,
                respond_to: send,
            })
            .await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn fail(&self, id: &str, reason: String) {
        let (send, recv) = oneshot::channel();
        let _ = self
            .sender
            .send(Message::Fail {
                id: id.to_string(),
                reason,
                respond_to: send,
            })
            .await;
        recv.await.expect("Actor task has been killed")
    }

    // --- observation ----------------------------------------------------

    pub async fn session_events(&self, id: &str) -> Option<watch::Receiver<SessionEvent>> {
        let (send, recv) = oneshot::channel();
        let _ = self
            .sender
            .send(Message::SessionEvents {
                id: id.to_string(),
                respond_to: send,
            })
            .await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn cancel_token(&self, id: &str) -> Option<CancellationToken> {
        let (send, recv) = oneshot::channel();
        let _ = self
            .sender
            .send(Message::CancelToken {
                id: id.to_string(),
                respond_to: send,
            })
            .await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn get_session(&self, id: &str) -> Option<SessionSummary> {
        let (send, recv) = oneshot::channel();
        let _ = self
            .sender
            .send(Message::GetSession {
                id: id.to_string(),
                respond_to: send,
            })
            .await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn session_index(&self) -> watch::Receiver<Vec<SessionSummary>> {
        let (send, recv) = oneshot::channel();
        let _ = self
            .sender
            .send(Message::ListenIndex { respond_to: send })
            .await;
        recv.await.expect("Actor task has been killed")
    }
}
