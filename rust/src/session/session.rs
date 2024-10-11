use std::collections::HashMap;

use lazy_static::lazy_static;
use tokio::sync::watch;

use crate::{actor::model::NodeDevice, api::model::FileInfo};

#[derive(Debug, Clone)]
enum State {
    Pending,
    Transfering,
    Finish,
    Fail,
    Cancel,
    End,
}

#[derive(Debug, Clone)]
struct Session {
    id: String,
    sender: NodeDevice,
    receiver: NodeDevice,
    file_map: HashMap<String, FileInfo>,
    token_map: HashMap<String, String>,
    state: State,
}

struct Progress {
    total: usize,
    current: usize,
}

struct Task {
    id: String,
    state: State,
    progress: Progress,
}

lazy_static! {
    static ref SESSION_INFO_NOTIFY: std::sync::Mutex<HashMap<String, watch::Receiver<Vec<Task>>>> =
        std::sync::Mutex::new(HashMap::new());
    static ref SESSION_MAP: std::sync::Mutex<HashMap<String, Session>> =
        std::sync::Mutex::new(HashMap::new());
}

pub fn create_session(
    sender: NodeDevice,
    receiver: NodeDevice,
    file_map: HashMap<String, FileInfo>,
) -> Session {
    let id = uuid::Uuid::new_v4().to_string();
    let mut token_map: HashMap<String, String> = HashMap::new();
    for (_, file) in file_map.iter() {
        token_map.insert(file.id.clone(), uuid::Uuid::new_v4().to_string());
    }
    let session = Session {
        id: id.clone(),
        sender,
        receiver,
        file_map,
        token_map: HashMap::new(),
        state: State::Pending,
    };
    SESSION_MAP
        .lock()
        .unwrap()
        .insert(id.clone(), session.clone());
    session
}
