//! UI-facing state model and pure reducers.
//!
//! The TUI event loop feeds core observations ([`SessionSummary`]
//! snapshots, [`SessionEvent`]s, device list updates) into [`App`]
//! methods and renders the result. All reduction logic lives here so
//! it can be unit-tested without a terminal.

use std::collections::HashSet;
use std::path::PathBuf;

use localsend_core::{
    FileState, MissionState, NodeDevice, SessionDirection, SessionEvent, SessionSummary,
};

/// One file within a session, with a live byte counter fed by
/// `SessionEvent::Progress`.
#[derive(Debug, Clone, PartialEq)]
pub struct FileView {
    pub id: String,
    pub name: String,
    pub size: i64,
    pub transferred: usize,
    pub state: FileState,
}

impl FileView {
    pub fn progress_ratio(&self) -> Option<f64> {
        if self.size <= 0 {
            return None;
        }
        Some((self.transferred as f64 / self.size as f64).clamp(0.0, 1.0))
    }
}

/// A session card in the UI.
#[derive(Debug, Clone, PartialEq)]
pub struct SessionView {
    pub id: String,
    pub direction: SessionDirection,
    pub peer_alias: String,
    pub peer_addr: String,
    pub state: MissionState,
    pub files: Vec<FileView>,
    /// Set when the session failed (from `SessionEvent::Failed` or a
    /// per-file `FileState::Fail`).
    pub fail_reason: Option<String>,
}

impl SessionView {
    pub fn is_pending_receive(&self) -> bool {
        self.direction == SessionDirection::Receive && self.state == MissionState::Pending
    }

    pub fn is_terminal(&self) -> bool {
        matches!(
            self.state,
            MissionState::Finished | MissionState::Failed | MissionState::Canceled
        )
    }

    fn from_summary(s: &SessionSummary) -> Self {
        SessionView {
            id: s.id.clone(),
            direction: s.direction,
            peer_alias: s.peer.alias.clone(),
            peer_addr: format!("{}:{}", s.peer.address, s.peer.port),
            state: s.state,
            files: s
                .files
                .iter()
                .map(|f| FileView {
                    id: f.info.id.clone(),
                    name: f.info.file_name.clone(),
                    size: f.info.size,
                    transferred: 0,
                    state: f.state.clone(),
                })
                .collect(),
            fail_reason: None,
        }
    }

    /// Refresh metadata/states from a new snapshot without losing the
    /// live byte counters (summaries carry no progress).
    fn update_from_summary(&mut self, s: &SessionSummary) {
        self.state = s.state;
        for f in &s.files {
            match self.files.iter_mut().find(|v| v.id == f.info.id) {
                Some(v) => v.state = f.state.clone(),
                None => self.files.push(FileView {
                    id: f.info.id.clone(),
                    name: f.info.file_name.clone(),
                    size: f.info.size,
                    transferred: 0,
                    state: f.state.clone(),
                }),
            }
        }
    }

    fn apply_event(&mut self, event: &SessionEvent) {
        match event {
            SessionEvent::StateChanged(state) => self.state = *state,
            SessionEvent::FileStateChanged { file_id, state } => {
                if let Some(v) = self.files.iter_mut().find(|v| &v.id == file_id) {
                    v.state = state.clone();
                }
                if let FileState::Fail { msg } = state {
                    self.fail_reason = Some(msg.clone());
                }
            }
            SessionEvent::Progress { file_id, bytes } => {
                if let Some(v) = self.files.iter_mut().find(|v| &v.id == file_id) {
                    v.transferred = *bytes;
                }
            }
            SessionEvent::Failed { reason } => {
                self.state = MissionState::Failed;
                self.fail_reason = Some(reason.clone());
            }
        }
    }
}

/// Input mode of the bottom prompt line.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub enum InputMode {
    #[default]
    Normal,
    /// Collecting a file path after pressing `a`.
    AddingFile { buffer: String },
}

/// Root application state.
#[derive(Debug, Default)]
pub struct App {
    pub devices: Vec<NodeDevice>,
    pub sessions: Vec<SessionView>,
    /// Index into `sessions` of the card decisions/cancel apply to.
    pub focus: usize,
    /// Files staged for sending (via `-f` or the `a` key).
    pub pending_files: Vec<PathBuf>,
    pub input: InputMode,
    /// Sessions the user cleared with `x`; filtered from future
    /// snapshots so they do not reappear.
    hidden: HashSet<String>,
    /// One-line message shown in the status bar (last action result).
    pub notice: Option<String>,
}

impl App {
    pub fn new(pending_files: Vec<PathBuf>) -> Self {
        App {
            pending_files,
            ..App::default()
        }
    }

    pub fn apply_devices(&mut self, devices: Vec<NodeDevice>) {
        self.devices = devices;
    }

    pub fn apply_index(&mut self, index: Vec<SessionSummary>) {
        for summary in &index {
            if self.hidden.contains(&summary.id) {
                continue;
            }
            match self.sessions.iter_mut().find(|v| v.id == summary.id) {
                Some(view) => view.update_from_summary(summary),
                None => self.sessions.push(SessionView::from_summary(summary)),
            }
        }
        // The core never forgets sessions; mirror any removal anyway.
        self.sessions
            .retain(|v| !self.hidden.contains(&v.id) && index.iter().any(|s| s.id == v.id));
        self.clamp_focus();
    }

    pub fn apply_event(&mut self, session_id: &str, event: &SessionEvent) {
        if let Some(view) = self.sessions.iter_mut().find(|v| v.id == session_id) {
            view.apply_event(event);
        }
    }

    pub fn focused(&self) -> Option<&SessionView> {
        self.sessions.get(self.focus)
    }

    pub fn cycle_focus(&mut self, delta: isize) {
        if self.sessions.is_empty() {
            self.focus = 0;
            return;
        }
        let len = self.sessions.len() as isize;
        self.focus = ((self.focus as isize + delta).rem_euclid(len)) as usize;
    }

    fn clamp_focus(&mut self) {
        if self.sessions.is_empty() {
            self.focus = 0;
        } else if self.focus >= self.sessions.len() {
            self.focus = self.sessions.len() - 1;
        }
    }

    /// Hide terminal sessions (finished/failed/canceled); active ones
    /// stay. Returns the number cleared.
    pub fn clear_terminal(&mut self) -> usize {
        let terminal: Vec<String> = self
            .sessions
            .iter()
            .filter(|v| v.is_terminal())
            .map(|v| v.id.clone())
            .collect();
        let count = terminal.len();
        for id in terminal {
            self.hidden.insert(id);
        }
        self.sessions.retain(|v| !self.hidden.contains(&v.id));
        self.clamp_focus();
        count
    }

    /// Add staged files, returning the paths that do not exist.
    pub fn stage_files(&mut self, paths: Vec<PathBuf>) -> Vec<PathBuf> {
        let mut missing = Vec::new();
        for p in paths {
            if p.exists() {
                self.pending_files.push(p);
            } else {
                missing.push(p);
            }
        }
        missing
    }

    /// Number of pending receive sessions waiting for a decision.
    pub fn pending_receive_count(&self) -> usize {
        self.sessions
            .iter()
            .filter(|s| s.is_pending_receive())
            .count()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use localsend_core::{FileInfo, MissionFileInfo};

    fn device(alias: &str) -> NodeDevice {
        NodeDevice {
            alias: alias.to_string(),
            address: "127.0.0.1".into(),
            port: 53317,
            fingerprint: format!("fp-{alias}"),
            ..NodeDevice::default()
        }
    }

    fn file(id: &str, name: &str, size: i64, state: FileState) -> MissionFileInfo {
        MissionFileInfo {
            info: FileInfo {
                id: id.to_string(),
                file_name: name.to_string(),
                size,
                file_type: "txt".into(),
                sha256: None,
                preview: None,
            },
            state,
        }
    }

    fn summary(id: &str, dir: SessionDirection, state: MissionState) -> SessionSummary {
        SessionSummary {
            id: id.to_string(),
            direction: dir,
            peer: device("peer"),
            file_count: 2,
            via_relay: false,
            state,
            files: vec![
                file("f1", "a.txt", 100, FileState::Pending),
                file("f2", "b.txt", 200, FileState::Pending),
            ],
        }
    }

    #[test]
    fn index_adds_and_updates_sessions() {
        let mut app = App::default();
        app.apply_index(vec![summary(
            "s1",
            SessionDirection::Receive,
            MissionState::Pending,
        )]);
        assert_eq!(app.sessions.len(), 1);
        assert_eq!(app.sessions[0].files.len(), 2);
        assert_eq!(app.sessions[0].files[0].name, "a.txt");
        assert!(app.sessions[0].is_pending_receive());
        assert_eq!(app.pending_receive_count(), 1);

        // A new snapshot updates state in place.
        app.apply_index(vec![summary(
            "s1",
            SessionDirection::Receive,
            MissionState::Transfering,
        )]);
        assert_eq!(app.sessions.len(), 1);
        assert_eq!(app.sessions[0].state, MissionState::Transfering);
    }

    #[test]
    fn events_drive_progress_and_failure() {
        let mut app = App::default();
        app.apply_index(vec![summary(
            "s1",
            SessionDirection::Send,
            MissionState::Transfering,
        )]);

        app.apply_event(
            "s1",
            &SessionEvent::Progress {
                file_id: "f1".into(),
                bytes: 50,
            },
        );
        let f1 = &app.sessions[0].files[0];
        assert_eq!(f1.transferred, 50);
        assert_eq!(f1.progress_ratio(), Some(0.5));

        // Summary refresh must not clobber the live byte counter.
        app.apply_index(vec![summary(
            "s1",
            SessionDirection::Send,
            MissionState::Transfering,
        )]);
        assert_eq!(app.sessions[0].files[0].transferred, 50);

        app.apply_event(
            "s1",
            &SessionEvent::FileStateChanged {
                file_id: "f2".into(),
                state: FileState::Fail { msg: "boom".into() },
            },
        );
        app.apply_event(
            "s1",
            &SessionEvent::Failed {
                reason: "boom".into(),
            },
        );
        assert_eq!(app.sessions[0].state, MissionState::Failed);
        assert_eq!(app.sessions[0].fail_reason.as_deref(), Some("boom"));
        assert!(app.sessions[0].is_terminal());
    }

    #[test]
    fn focus_cycles_and_clamps() {
        let mut app = App::default();
        app.apply_index(vec![
            summary("a", SessionDirection::Send, MissionState::Idle),
            summary("b", SessionDirection::Send, MissionState::Idle),
            summary("c", SessionDirection::Send, MissionState::Idle),
        ]);
        assert_eq!(app.sessions.len(), 3);
        app.focus = 0;
        app.cycle_focus(1);
        assert_eq!(app.focus, 1);
        app.cycle_focus(-2);
        assert_eq!(app.focus, 2);
        app.cycle_focus(1);
        assert_eq!(app.focus, 0);
        // Shrinking the list clamps the focus.
        app.focus = 2;
        app.apply_index(vec![summary(
            "a",
            SessionDirection::Send,
            MissionState::Idle,
        )]);
        assert_eq!(app.focus, 0);
    }

    #[test]
    fn clear_terminal_hides_forever() {
        let mut app = App::default();
        app.apply_index(vec![
            summary("s1", SessionDirection::Send, MissionState::Finished),
            summary("s2", SessionDirection::Send, MissionState::Transfering),
        ]);
        assert_eq!(app.clear_terminal(), 1);
        assert_eq!(app.sessions.len(), 1);
        assert_eq!(app.sessions[0].id, "s2");

        // A later snapshot still containing s1 must not resurrect it.
        app.apply_index(vec![
            summary("s1", SessionDirection::Send, MissionState::Finished),
            summary("s2", SessionDirection::Send, MissionState::Transfering),
        ]);
        assert_eq!(app.sessions.len(), 1);
        assert_eq!(app.sessions[0].id, "s2");
    }

    #[test]
    fn staging_rejects_missing_files() {
        let tmp = tempfile::tempdir().unwrap();
        let good = tmp.path().join("good.txt");
        std::fs::write(&good, b"x").unwrap();
        let bad = tmp.path().join("bad.txt");

        let mut app = App::default();
        let missing = app.stage_files(vec![good.clone(), bad.clone()]);
        assert_eq!(app.pending_files, vec![good]);
        assert_eq!(missing, vec![bad]);
    }
}
