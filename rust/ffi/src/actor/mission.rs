use lazy_static::lazy_static;

use crate::api::model::FileInfo;

use super::model::{MissionState, NodeDevice};

pub mod notify;
pub mod pending;
pub mod transfer;

lazy_static! {
    pub static ref MISSION_NOTIFY: notify::Handle = notify::Handle::new();
}

#[derive(Clone)]
pub struct MissionInfo {
    pub id: String,
    pub sender: NodeDevice,
    pub files: Vec<MissionFileInfo>,
    pub state: MissionState,
}

#[derive(Debug, Clone)]
pub struct MissionFileInfo {
    pub info: FileInfo,
    pub state: FileState,
}

#[derive(Debug, Clone)]
pub enum FileState {
    Pending,
    Transfer,
    Finish,
    Skip,
    Fail { msg: String },
}

#[derive(Clone)]
pub struct MissionHandle {
    pub pending: pending::Handle,
    pub transfer: transfer::Handle,
}

impl MissionHandle {
    pub fn new() -> Self {
        let transfer = transfer::Handle::new();
        let pending = pending::Handle::new(transfer.clone());

        Self { pending, transfer }
    }
}
