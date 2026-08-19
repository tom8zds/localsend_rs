//! FRB boundary mirror of the legacy mission view types.

use super::model::{MissionState, NodeDevice};
use crate::api::model::FileInfo;

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

impl From<localsend_core::MissionFileInfo> for MissionFileInfo {
    fn from(f: localsend_core::MissionFileInfo) -> Self {
        MissionFileInfo {
            info: f.info.into(),
            state: f.state.into(),
        }
    }
}

impl From<localsend_core::MissionInfo> for MissionInfo {
    fn from(m: localsend_core::MissionInfo) -> Self {
        MissionInfo {
            id: m.id,
            sender: m.sender.into(),
            files: m.files.into_iter().map(Into::into).collect(),
            state: m.state.into(),
        }
    }
}
