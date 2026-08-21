//! FRB boundary mirrors of `localsend_core` device/session types.
//! See `actor/core.rs` for why these stay in this crate.
//!
//! Wire notes: `usize` counts are mirrored as `u32`/`i64` so the Dart
//! side sees plain `int` instead of `BigInt`; enum variant order is the
//! SSE wire index and must not be reordered once released.

use serde_derive::{Deserialize, Serialize};

use crate::api::model::FileInfo;

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct NodeDevice {
    pub alias: String,
    pub version: String,
    pub device_model: String,
    pub device_type: String,
    pub fingerprint: String,
    pub address: String,
    pub port: u16,
    pub protocol: String,
    pub download: bool,
    pub announcement: bool,
    pub announce: bool,
}

impl NodeDevice {
    pub fn to_core(&self) -> localsend_core::NodeDevice {
        localsend_core::NodeDevice {
            alias: self.alias.clone(),
            version: self.version.clone(),
            device_model: self.device_model.clone(),
            device_type: self.device_type.clone(),
            fingerprint: self.fingerprint.clone(),
            address: self.address.clone(),
            port: self.port,
            protocol: self.protocol.clone(),
            download: self.download,
            announcement: self.announcement,
            announce: self.announce,
        }
    }
}

impl From<localsend_core::NodeDevice> for NodeDevice {
    fn from(d: localsend_core::NodeDevice) -> Self {
        NodeDevice {
            alias: d.alias,
            version: d.version,
            device_model: d.device_model,
            device_type: d.device_type,
            fingerprint: d.fingerprint,
            address: d.address,
            port: d.port,
            protocol: d.protocol,
            download: d.download,
            announcement: d.announcement,
            announce: d.announce,
        }
    }
}

/// NOTE: variant order is the FRB wire index; do not reorder.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MissionState {
    Idle,
    Pending,
    Transfering,
    Finished,
    Failed,
    Canceled,
    Busy,
}

impl From<localsend_core::MissionState> for MissionState {
    fn from(s: localsend_core::MissionState) -> Self {
        match s {
            localsend_core::MissionState::Idle => MissionState::Idle,
            localsend_core::MissionState::Pending => MissionState::Pending,
            localsend_core::MissionState::Transfering => MissionState::Transfering,
            localsend_core::MissionState::Finished => MissionState::Finished,
            localsend_core::MissionState::Failed => MissionState::Failed,
            localsend_core::MissionState::Canceled => MissionState::Canceled,
            localsend_core::MissionState::Busy => MissionState::Busy,
        }
    }
}

/// NOTE: variant order is the FRB wire index; do not reorder.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum FileState {
    Pending,
    Transfer,
    Finish,
    Skip,
    Fail { msg: String },
}

impl From<localsend_core::FileState> for FileState {
    fn from(s: localsend_core::FileState) -> Self {
        match s {
            localsend_core::FileState::Pending => FileState::Pending,
            localsend_core::FileState::Transfer => FileState::Transfer,
            localsend_core::FileState::Finish => FileState::Finish,
            localsend_core::FileState::Skip => FileState::Skip,
            localsend_core::FileState::Fail { msg } => FileState::Fail { msg },
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct MissionFileInfo {
    pub info: FileInfo,
    pub state: FileState,
}

impl From<localsend_core::MissionFileInfo> for MissionFileInfo {
    fn from(f: localsend_core::MissionFileInfo) -> Self {
        MissionFileInfo {
            info: f.info.into(),
            state: f.state.into(),
        }
    }
}

/// NOTE: variant order is the FRB wire index; do not reorder.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SessionDirection {
    Send,
    Receive,
}

impl From<localsend_core::SessionDirection> for SessionDirection {
    fn from(d: localsend_core::SessionDirection) -> Self {
        match d {
            localsend_core::SessionDirection::Send => SessionDirection::Send,
            localsend_core::SessionDirection::Receive => SessionDirection::Receive,
        }
    }
}

/// Mirror of `localsend_core::SessionSummary` (session index snapshot
/// entry).
#[derive(Debug, Clone, PartialEq)]
pub struct SessionSummary {
    pub id: String,
    pub direction: SessionDirection,
    pub peer: NodeDevice,
    pub file_count: u32,
    pub state: MissionState,
    /// True when this session's traffic is tunneled through the
    /// configured TURN relay.
    pub via_relay: bool,
    /// Per-file metadata and state, sorted by file name. Live byte
    /// counters are not included; subscribe to the per-session event
    /// stream for those.
    pub files: Vec<MissionFileInfo>,
}

impl From<localsend_core::SessionSummary> for SessionSummary {
    fn from(s: localsend_core::SessionSummary) -> Self {
        SessionSummary {
            id: s.id,
            direction: s.direction.into(),
            peer: s.peer.into(),
            file_count: s.file_count as u32,
            state: s.state.into(),
            via_relay: s.via_relay,
            files: s.files.into_iter().map(Into::into).collect(),
        }
    }
}

/// Mirror of `localsend_core::SessionEvent` (per-session event stream
/// item). NOTE: variant order is the FRB wire index; do not reorder.
#[derive(Debug, Clone, PartialEq)]
pub enum SessionEvent {
    /// Overall session state changed.
    StateChanged(MissionState),
    /// State of one file changed.
    FileStateChanged { file_id: String, state: FileState },
    /// Bytes transferred so far for one file.
    Progress { file_id: String, bytes: i64 },
    /// The session failed with a human-readable reason.
    Failed { reason: String },
}

impl From<localsend_core::SessionEvent> for SessionEvent {
    fn from(e: localsend_core::SessionEvent) -> Self {
        match e {
            localsend_core::SessionEvent::StateChanged(state) => {
                SessionEvent::StateChanged(state.into())
            }
            localsend_core::SessionEvent::FileStateChanged { file_id, state } => {
                SessionEvent::FileStateChanged {
                    file_id,
                    state: state.into(),
                }
            }
            localsend_core::SessionEvent::Progress { file_id, bytes } => SessionEvent::Progress {
                file_id,
                bytes: bytes as i64,
            },
            localsend_core::SessionEvent::Failed { reason } => SessionEvent::Failed { reason },
        }
    }
}
