use std::collections::HashMap;

use serde::{Deserialize, Serialize};

/// Current protocol version implemented by this crate.
pub const PROTOCOL_VERSION: &str = "2.2";

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
    /// Build a target device directly from an `address:port` string,
    /// allowing sends to a peer that was never discovered via multicast.
    pub fn manual(addr: &str) -> Option<NodeDevice> {
        let (address, port) = addr.rsplit_once(':')?;
        let port: u16 = port.trim().parse().ok()?;
        let address = address.trim().trim_matches(['[', ']']).to_string();
        if address.is_empty() {
            return None;
        }
        Some(NodeDevice {
            alias: format!("{address}:{port}"),
            version: PROTOCOL_VERSION.to_string(),
            device_model: "unknown".to_string(),
            device_type: "unknown".to_string(),
            fingerprint: format!("manual-{address}:{port}"),
            address,
            port,
            protocol: "http".to_string(),
            download: true,
            announcement: false,
            announce: false,
        })
    }

    pub fn from_announce(announce: &NodeAnnounce, address: &str) -> NodeDevice {
        NodeDevice {
            alias: announce.alias.clone(),
            version: announce.version.clone(),
            device_model: announce.device_model.clone(),
            device_type: announce.device_type.clone(),
            fingerprint: announce.fingerprint.clone(),
            address: address.to_string(),
            port: announce.port,
            protocol: announce.protocol.clone(),
            download: announce.download,
            announcement: announce.announcement,
            announce: announce.announce,
        }
    }

    pub fn to_announce(&self) -> NodeAnnounce {
        NodeAnnounce {
            alias: self.alias.clone(),
            version: self.version.clone(),
            device_model: self.device_model.clone(),
            device_type: self.device_type.clone(),
            fingerprint: self.fingerprint.clone(),
            port: self.port,
            protocol: self.protocol.clone(),
            download: self.download,
            announcement: self.announcement,
            announce: self.announce,
        }
    }

    /// Base URL of this device's HTTP API, e.g. `http://192.168.1.2:53317`.
    pub fn base_url(&self) -> String {
        format!("{}://{}:{}", self.protocol, self.address, self.port)
    }
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct NodeAnnounce {
    pub alias: String,
    #[serde(default)]
    pub version: String,
    #[serde(default)]
    pub device_model: String,
    #[serde(default)]
    pub device_type: String,
    pub fingerprint: String,
    pub port: u16,
    #[serde(default = "default_protocol")]
    pub protocol: String,
    #[serde(default)]
    pub download: bool,
    // Official apps omit these in some protocol revisions — parse
    // leniently or their announcements get dropped entirely.
    #[serde(default)]
    pub announcement: bool,
    #[serde(default)]
    pub announce: bool,
}

fn default_protocol() -> String {
    "http".to_string()
}

// ---------------------------------------------------------------------------
// v2 protocol DTOs
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SenderInfo {
    pub alias: String,
    pub version: String,
    pub device_model: String,
    pub device_type: String,
    pub fingerprint: String,
    pub port: i64,
    pub protocol: String,
    pub download: bool,
}

impl SenderInfo {
    pub fn from_device(device: &NodeDevice) -> Self {
        SenderInfo {
            alias: device.alias.clone(),
            version: device.version.clone(),
            device_model: device.device_model.clone(),
            device_type: device.device_type.clone(),
            fingerprint: device.fingerprint.clone(),
            port: device.port as i64,
            protocol: device.protocol.clone(),
            download: device.download,
        }
    }

    /// Merge with the peer IP observed at the HTTP layer to a full device.
    pub fn to_device(&self, address: &str) -> NodeDevice {
        NodeDevice {
            alias: self.alias.clone(),
            version: self.version.clone(),
            device_model: self.device_model.clone(),
            device_type: self.device_type.clone(),
            fingerprint: self.fingerprint.clone(),
            address: address.to_string(),
            port: self.port.max(0) as u16,
            protocol: self.protocol.clone(),
            download: self.download,
            announcement: false,
            announce: false,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct FileRequest {
    pub info: SenderInfo,
    pub files: HashMap<String, FileInfo>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct FileInfo {
    pub id: String,
    pub file_name: String,
    pub size: i64,
    pub file_type: String,
    pub sha256: Option<String>,
    pub preview: Option<Vec<u8>>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct FileResponse {
    pub session_id: String,
    pub files: HashMap<String, String>,
}

/// Query parameters of `POST /api/localsend/v2/upload`.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UploadTask {
    pub session_id: String,
    pub file_id: String,
    pub token: String,
}

// ---------------------------------------------------------------------------
// Session state model
// ---------------------------------------------------------------------------

/// State of a transfer session.
///
/// NOTE: mirrored by the ffi crate for the FRB boundary; the variant
/// order is load-bearing (it is the wire index in the SSE codec).
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

/// State of a single file within a session.
///
/// NOTE: mirrored by the ffi crate for the FRB boundary.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum FileState {
    Pending,
    Transfer,
    Finish,
    Skip,
    Fail { msg: String },
}

impl FileState {
    pub fn is_terminal(&self) -> bool {
        matches!(
            self,
            FileState::Finish | FileState::Skip | FileState::Fail { .. }
        )
    }
}

/// Per-file view of a session, used by [`SessionSummary`] for per-file
/// progress rendering.
#[derive(Debug, Clone, PartialEq)]
pub struct MissionFileInfo {
    pub info: FileInfo,
    pub state: FileState,
}

// ---------------------------------------------------------------------------
// Session observation API (session index + per-session events)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum SessionDirection {
    Send,
    Receive,
}

/// Low-frequency snapshot entry of [`crate::CoreHandle::session_index`].
#[derive(Debug, Clone, PartialEq)]
pub struct SessionSummary {
    pub id: String,
    pub direction: SessionDirection,
    pub peer: NodeDevice,
    pub file_count: usize,
    pub state: MissionState,
    /// True when this session's traffic is being tunneled through the
    /// configured TURN relay.
    pub via_relay: bool,
    /// Connection path label: "local" (direct) or "turn" (relayed);
    /// "stun" is reserved for future P2P hole-punching.
    pub route: String,
    /// Per-file metadata and state, sorted by file name. Live byte
    /// counters are not included; subscribe to
    /// [`crate::CoreHandle::session_events`] for those.
    pub files: Vec<MissionFileInfo>,
}

/// Per-session event stream item, see [`crate::CoreHandle::session_events`].
#[derive(Debug, Clone, PartialEq)]
pub enum SessionEvent {
    /// Overall session state changed.
    StateChanged(MissionState),
    /// State of one file changed.
    FileStateChanged { file_id: String, state: FileState },
    /// Bytes transferred so far for one file.
    Progress { file_id: String, bytes: usize },
    /// The session failed with a human-readable reason.
    Failed { reason: String },
}

#[cfg(test)]
mod announce_tests {
    use super::*;

    /// Official apps omit fields across protocol revisions; every
    /// optional-since-v2.2 field must default instead of failing.
    #[test]
    fn sparse_official_announcement_decodes() {
        let raw = r#"{
            "alias": "Pixel#8",
            "fingerprint": "abc123",
            "port": 53317,
            "protocol": "https"
        }"#;
        let a: NodeAnnounce = serde_json::from_str(raw).unwrap();
        assert_eq!(a.alias, "Pixel#8");
        assert_eq!(a.protocol, "https");
        assert!(!a.download);
        assert!(!a.announcement);
        assert!(!a.announce);
    }

    #[test]
    fn announce_without_protocol_defaults_to_http() {
        let raw = r#"{"alias":"x","fingerprint":"f","port":1}"#;
        let a: NodeAnnounce = serde_json::from_str(raw).unwrap();
        assert_eq!(a.protocol, "http");
    }
}
