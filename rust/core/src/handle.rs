//! [`CoreHandle`] — the single entry point frontends use to drive the
//! core: server lifecycle, configuration, device list, session
//! decisions, event subscriptions and sending files.

use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::{Arc, Mutex};

use log::{debug, error, warn};
use tokio::sync::{mpsc, oneshot, watch, Semaphore};
use uuid::Uuid;

use crate::client::{Client, SendError};
use crate::config::CoreConfig;
use crate::device::DeviceActorHandle;
use crate::model::{
    FileInfo, FileRequest, FileState, MissionState, NodeDevice, SenderInfo, SessionEvent,
    SessionSummary,
};
use crate::server::HttpServerHandle;
use crate::session::{SessionError, SessionHandle, DEFAULT_MAX_RECV_SESSIONS};

/// Tuning knobs that are not part of the FRB-exposed [`CoreConfig`].
#[derive(Clone, Debug)]
pub struct CoreOptions {
    /// Whether multicast UDP discovery runs alongside the HTTP server.
    pub enable_discovery: bool,
    /// Maximum concurrent receive sessions (pending + transferring).
    pub max_recv_sessions: usize,
}

impl Default for CoreOptions {
    fn default() -> Self {
        CoreOptions {
            enable_discovery: true,
            max_recv_sessions: DEFAULT_MAX_RECV_SESSIONS,
        }
    }
}

struct AppContext {
    config: CoreConfig,
}

enum CoreMessage {
    GetConfig {
        respond_to: oneshot::Sender<CoreConfig>,
    },
    ChangeConfig {
        new_config: CoreConfig,
        respond_to: oneshot::Sender<()>,
    },
    Start {
        core: CoreHandle,
        respond_to: oneshot::Sender<()>,
    },
    Shutdown {
        respond_to: oneshot::Sender<()>,
    },
    Listen {
        respond_to: oneshot::Sender<watch::Receiver<bool>>,
    },
}

struct CoreActor {
    receiver: mpsc::Receiver<CoreMessage>,
    context: AppContext,
    server: Option<HttpServerHandle>,
    server_state_sender: watch::Sender<bool>,
    server_state_listener: watch::Receiver<bool>,
    server_error_sender: watch::Sender<Option<String>>,
}

impl CoreActor {
    fn new(
        receiver: mpsc::Receiver<CoreMessage>,
        device: NodeDevice,
        mut config: CoreConfig,
        server_error_sender: watch::Sender<Option<String>>,
    ) -> Self {
        let (tx, rx) = watch::channel(false);
        config.port = device.port;
        CoreActor {
            receiver,
            context: AppContext { config },
            server: None,
            server_state_sender: tx,
            server_state_listener: rx,
            server_error_sender,
        }
    }

    async fn handle_message(&mut self, msg: CoreMessage) {
        match msg {
            CoreMessage::GetConfig { respond_to } => {
                let config = self.context.config.clone();
                let _ = respond_to.send(config);
            }
            CoreMessage::ChangeConfig {
                new_config,
                respond_to,
            } => {
                self.context.config = new_config;
                let _ = respond_to.send(());
            }
            CoreMessage::Start { core, respond_to } => {
                if let Some(server) = self.server.take() {
                    server.shutdown().await;
                }

                let mut handle = HttpServerHandle::new(core.clone(), self.context.config.clone());
                match handle.wait_bound().await {
                    Ok(port) => {
                        if port != self.context.config.port {
                            debug!("bound on fallback port {port}");
                            self.context.config.port = port;
                            let mut current = core.device.get_current_device().await;
                            current.port = port;
                            core.device.set_current_device(current).await;
                        }
                        let _ = self.server_error_sender.send(None);
                        let _ = self.server_state_sender.send(true);
                    }
                    Err(e) => {
                        error!("http server failed to start: {e}");
                        let _ = self.server_error_sender.send(Some(e));
                        let _ = self.server_state_sender.send(false);
                    }
                }
                self.server.replace(handle);
                let _ = respond_to.send(());
            }
            CoreMessage::Shutdown { respond_to } => {
                let handler = self.server.take();
                if let Some(handler) = handler {
                    handler.shutdown().await;
                } else {
                    debug!("server not started")
                }
                let _ = respond_to.send(());
                let _ = self.server_state_sender.send(false);
            }
            CoreMessage::Listen { respond_to } => {
                let _ = respond_to.send(self.server_state_listener.clone());
            }
        }
    }
}

async fn run_context_actor(mut actor: CoreActor) {
    while let Some(msg) = actor.receiver.recv().await {
        actor.handle_message(msg).await;
    }
}

struct CoreInner {
    sender: mpsc::Sender<CoreMessage>,
    sessions: SessionHandle,
    client: Client,
    options: CoreOptions,
    server_error_rx: watch::Receiver<Option<String>>,
    /// Serializes send sessions per target device (fingerprint or
    /// `address:port` for manual targets). Different targets run
    /// concurrently.
    target_locks: Mutex<HashMap<String, Arc<Semaphore>>>,
}

/// Clone-cheap handle to a running core. All state lives in
/// background actors; cloning only clones channel senders and `Arc`s.
#[derive(Clone)]
pub struct CoreHandle {
    inner: Arc<CoreInner>,
    pub device: DeviceActorHandle,
}

impl CoreHandle {
    pub fn new(device: NodeDevice, config: CoreConfig) -> Self {
        Self::with_options(device, config, CoreOptions::default())
    }

    pub fn with_options(device: NodeDevice, config: CoreConfig, options: CoreOptions) -> Self {
        let (server_error_tx, server_error_rx) = watch::channel(None);

        let (sender, receiver) = mpsc::channel(8);
        let actor = CoreActor::new(receiver, device.clone(), config, server_error_tx);
        tokio::spawn(run_context_actor(actor));

        let device = DeviceActorHandle::new(device);
        let sessions = SessionHandle::new(options.max_recv_sessions);

        Self {
            inner: Arc::new(CoreInner {
                sender,
                sessions,
                client: Client::new(),
                options,
                server_error_rx,
                target_locks: Mutex::new(HashMap::new()),
            }),
            device,
        }
    }

    pub(crate) fn options(&self) -> &CoreOptions {
        &self.inner.options
    }

    pub(crate) fn sessions(&self) -> &SessionHandle {
        &self.inner.sessions
    }

    // --- server lifecycle ------------------------------------------------

    pub async fn start(&self) {
        let (send, recv) = oneshot::channel();
        let msg = CoreMessage::Start {
            core: self.clone(),
            respond_to: send,
        };
        let _ = self.inner.sender.send(msg).await;
        recv.await.expect("Actor task has been killed");
        self.device.clear_devices().await;
    }

    pub async fn shutdown(&self) {
        let (send, recv) = oneshot::channel();
        let msg = CoreMessage::Shutdown { respond_to: send };
        let _ = self.inner.sender.send(msg).await;
        recv.await.expect("Actor task has been killed");
        self.device.clear_devices().await;
    }

    /// Whether the HTTP server is currently running.
    pub async fn server_state(&self) -> watch::Receiver<bool> {
        let (send, recv) = oneshot::channel();
        let msg = CoreMessage::Listen { respond_to: send };
        let _ = self.inner.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }

    /// Last server startup error, if any (e.g. no free port).
    pub fn server_error(&self) -> watch::Receiver<Option<String>> {
        self.inner.server_error_rx.clone()
    }

    // --- configuration ----------------------------------------------------

    pub async fn get_config(&self) -> CoreConfig {
        let (send, recv) = oneshot::channel();
        let msg = CoreMessage::GetConfig { respond_to: send };
        let _ = self.inner.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn change_port(&self, port: u16) {
        let mut value = self.get_config().await;
        value.port = port;
        self.change_config(value).await;
    }

    pub async fn change_path(&self, path: String) {
        let mut value = self.get_config().await;
        value.store_path = path;
        self.change_config(value).await;
    }

    pub async fn change_config(&self, config: CoreConfig) {
        let (send, recv) = oneshot::channel();
        let msg = CoreMessage::ChangeConfig {
            new_config: config.clone(),
            respond_to: send,
        };

        let mut current = self.device.get_current_device().await;
        current.port = config.port;
        self.device.set_current_device(current).await;

        let _ = self.inner.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }

    // --- discovery ---------------------------------------------------------

    /// Announce this device on the multicast group.
    pub async fn announce(&self) {
        let config = self.get_config().await;
        let current = self.device.get_current_device().await;
        let message = serde_json::to_string(&current.to_announce()).unwrap_or_default();
        self.device.clear_devices().await;
        tokio::spawn(async move {
            crate::discovery::announce(&config, &message).await;
        });
    }

    // --- session decisions --------------------------------------------------

    /// Accept a pending receive session. `file_ids == None` accepts all
    /// files; `Some(ids)` accepts only that subset.
    pub async fn accept(
        &self,
        session_id: &str,
        file_ids: Option<Vec<String>>,
    ) -> Result<(), SessionError> {
        self.inner.sessions.accept(session_id, file_ids).await
    }

    pub async fn decline(&self, session_id: &str) -> Result<(), SessionError> {
        self.inner.sessions.decline(session_id).await
    }

    /// Cancel any active session (send or receive).
    pub async fn cancel(&self, session_id: &str) {
        self.inner.sessions.cancel(session_id).await
    }

    // --- session observation -------------------------------------------------

    /// Low-frequency full snapshot of all sessions.
    pub async fn session_index(&self) -> watch::Receiver<Vec<SessionSummary>> {
        self.inner.sessions.session_index().await
    }

    /// Per-session event stream. `None` if the session is unknown.
    pub async fn session_events(
        &self,
        session_id: &str,
    ) -> Option<watch::Receiver<SessionEvent>> {
        self.inner.sessions.session_events(session_id).await
    }

    // --- sending --------------------------------------------------------------

    fn target_lock(&self, target: &NodeDevice) -> Arc<Semaphore> {
        let key = if target.fingerprint.is_empty() {
            format!("{}:{}", target.address, target.port)
        } else {
            target.fingerprint.clone()
        };
        let mut locks = self.inner.target_locks.lock().unwrap();
        locks
            .entry(key)
            .or_insert_with(|| Arc::new(Semaphore::new(1)))
            .clone()
    }

    /// Send files to a target device.
    ///
    /// Returns the new session id immediately; the transfer runs in the
    /// background and reports through [`CoreHandle::session_events`] /
    /// [`CoreHandle::session_index`]. Sessions to the same target are
    /// serialized; different targets transfer concurrently.
    ///
    /// The target may be constructed manually with
    /// [`NodeDevice::manual`] when it was not discovered.
    pub async fn send_files(
        &self,
        target: NodeDevice,
        files: Vec<PathBuf>,
    ) -> Result<String, SendError> {
        if files.is_empty() {
            return Err(SendError::EmptySelection);
        }

        let mut entries = Vec::with_capacity(files.len());
        for path in &files {
            let meta = std::fs::metadata(path)?;
            let file_name = path
                .file_name()
                .map(|n| n.to_string_lossy().to_string())
                .unwrap_or_else(|| "file".to_string());
            let file_type = path
                .extension()
                .map(|e| e.to_string_lossy().to_lowercase())
                .unwrap_or_else(|| "application/octet-stream".to_string());
            let id = Uuid::new_v4().to_string();
            entries.push((
                id.clone(),
                FileInfo {
                    id,
                    file_name,
                    size: meta.len() as i64,
                    file_type,
                    sha256: None,
                    preview: None,
                },
            ));
        }

        let session_id = self
            .inner
            .sessions
            .create_send_session(target.clone(), entries.clone())
            .await;

        let core = self.clone();
        let lock = self.target_lock(&target);
        let driver_session = session_id.clone();
        tokio::spawn(async move {
            run_send_driver(core, driver_session, target, files, entries, lock).await;
        });

        Ok(session_id)
    }
}

/// Drives one send session: register -> prepare -> upload each file ->
/// finish/fail. All state changes go through the session manager.
async fn run_send_driver(
    core: CoreHandle,
    session_id: String,
    target: NodeDevice,
    files: Vec<PathBuf>,
    entries: Vec<(String, FileInfo)>,
    lock: Arc<Semaphore>,
) {
    let sessions = core.sessions().clone();
    let client = core.inner.client.clone();

    // Queue behind other sessions targeting the same device.
    debug!("send driver {session_id} waiting for target lock");
    let _permit = lock.acquire().await;
    debug!("send driver {session_id} acquired target lock");

    let cancel = sessions.cancel_token(&session_id).await;
    let Some(cancel) = cancel else {
        return;
    };

    macro_rules! bail {
        ($reason:expr) => {{
            sessions.fail(&session_id, $reason).await;
            return;
        }};
    }

    // Best-effort register so the peer knows us; failure is not fatal.
    let current = core.device.get_current_device().await;
    if let Err(e) = client.register(&target, &current).await {
        warn!("register before send failed: {e}");
    }

    let request = FileRequest {
        info: SenderInfo::from_device(&current),
        files: entries.iter().cloned().collect(),
    };

    let prepared = tokio::select! {
        res = client.prepare_upload(&target, &request) => res,
        _ = cancel.cancelled() => return,
    };

    let response = match prepared {
        Ok(r) => r,
        Err(e) => {
            let reason = match e.status() {
                Some(403) => "declined by receiver".to_string(),
                Some(409) => "receiver busy".to_string(),
                _ => format!("prepare-upload failed: {e}"),
            };
            bail!(reason);
        }
    };

    if response.files.is_empty() {
        debug!("receiver accepted no files");
        for (file_id, _) in &entries {
            sessions
                .report_file_state(&session_id, file_id, FileState::Skip)
                .await;
        }
        return;
    }

    sessions
        .report_state(&session_id, MissionState::Transfering)
        .await;

    // The receiver assigns its own session id; all further protocol
    // calls must use it (the local `session_id` is only for local
    // reporting).
    let remote_session_id = response.session_id.clone();

    let paths: HashMap<String, PathBuf> = entries
        .iter()
        .map(|(id, _)| id.clone())
        .zip(files.iter().cloned())
        .collect();

    for (file_id, token) in &response.files {
        let Some(path) = paths.get(file_id) else {
            continue;
        };
        let (progress_tx, mut progress_rx) = watch::channel(0usize);
        let progress_sessions = sessions.clone();
        let progress_session = session_id.clone();
        let progress_file = file_id.clone();
        let forwarder = tokio::spawn(async move {
            while progress_rx.changed().await.is_ok() {
                let bytes = *progress_rx.borrow_and_update();
                progress_sessions
                    .report_progress(&progress_session, &progress_file, bytes)
                    .await;
            }
        });

        sessions
            .report_file_state(&session_id, file_id, FileState::Transfer)
            .await;

        let uploaded = tokio::select! {
            res = client.upload_file(
                &target,
                &remote_session_id,
                file_id,
                token,
                path,
                progress_tx,
            ) => res,
            _ = cancel.cancelled() => {
                forwarder.abort();
                // Notify the receiver, best effort.
                let _ = client.cancel(&target, &remote_session_id).await;
                return;
            }
        };
        forwarder.abort();

        match uploaded {
            Ok(_) => {
                sessions
                    .report_file_state(&session_id, file_id, FileState::Finish)
                    .await;
            }
            Err(e) => {
                sessions
                    .report_file_state(
                        &session_id,
                        file_id,
                        FileState::Fail {
                            msg: e.to_string(),
                        },
                    )
                    .await;
                // Failing one file fails the session (report_file_state
                // with Fail already failed the session); also tell the
                // receiver.
                let _ = client.cancel(&target, &remote_session_id).await;
                return;
            }
        }
    }

    debug!("send session {session_id} driver complete");
}
