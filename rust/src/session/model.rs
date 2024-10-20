use std::collections::HashMap;

use serde_derive::{Deserialize, Serialize};

use crate::{actor::model::NodeDevice, api::model::FileInfo};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum Status {
    Pending,
    Transfer { start_time: u128 },
    Finish,
    Fail { msg: String },
    Cancel,
    Rejected,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TaskVm {
    pub id: String,
    pub name: String,
    pub size: usize,
    pub status: Status,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum SessionType {
    Send,
    Receive,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Session {
    pub id: String,
    pub node: NodeDevice,
    pub session_type: SessionType,
    pub status: Status,
    pub status_map: HashMap<String, Status>,
    pub file_map: HashMap<String, FileInfo>,
    pub token_map: HashMap<String, String>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SessionVm {
    pub id: String,
    pub node: NodeDevice,
    pub tasks: Vec<TaskVm>,
    pub status: Status,
}

impl Session {
    pub fn new_send(node: NodeDevice, file_map: HashMap<String, FileInfo>) -> Self {
        let id = uuid::Uuid::new_v4().to_string();
        let token_map = file_map
            .iter()
            .map(|(_, file)| (file.id.clone(), uuid::Uuid::new_v4().to_string()))
            .collect();
        let status_map = file_map
            .iter()
            .map(|(_, file)| (file.id.clone(), Status::Pending))
            .collect();

        Self {
            id,
            node: node,
            session_type: SessionType::Send,
            status: Status::Pending,
            status_map,
            file_map,
            token_map,
        }
    }

    pub fn to_vm(&self) -> SessionVm {
        let tasks: Vec<TaskVm> = self
            .file_map
            .iter()
            .map(|(_, file)| TaskVm {
                id: file.id.clone(),
                name: file.file_name.clone(),
                size: file.size as usize,
                status: self.status_map[&file.id].clone(),
            })
            .collect();
        SessionVm {
            id: self.id.clone(),
            node: self.node.clone(),
            tasks,
            status: self.status.clone(),
        }
    }
}
