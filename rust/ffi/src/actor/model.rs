//! FRB boundary mirror of `localsend_core` device/session-state types.
//! See `actor/core.rs` for why these stay in this crate.

use serde_derive::{Deserialize, Serialize};

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
#[derive(Debug, Clone, Copy)]
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
