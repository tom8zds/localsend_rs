use std::{collections::HashMap, sync::Arc};

use futures::future::Pending;
use lazy_static::lazy_static;
use log::trace;
use tokio::{
    fs::File,
    io::BufReader,
    sync::{watch, Mutex},
};

use crate::{
    actor::{
        mission::MissionInfo,
        model::{MissionState, NodeDevice},
    },
    api::model::{FileRequest, FileResponse},
    util::ProgressReadAdapter,
};

lazy_static! {
    pub static ref SESSION_HOLDER: Arc<Mutex<Option<Session>>> = Arc::new(Mutex::new(None));
    pub static ref TASK_BROKER: Arc<Mutex<HashMap<String, watch::Receiver<TaskState>>>> =
        Arc::new(Mutex::new(HashMap::new()));
}

pub struct Session {
    id: String,
    node: NodeDevice,
    tasks: Vec<Task>,
    current: usize,
}

pub enum TaskState {
    Pending {},
    Transfering { progress: usize, total: usize },
    Finished {},
    Failed { msg: String },
}

pub struct Task {
    id: String,
    token: String,
    path: String,
    session: String,
    progress: usize,
    total: usize,
}

impl Session {
    pub fn new(id: String, node: NodeDevice, request: FileRequest, response: FileResponse) -> Self {
        let files = request.files;
        let token_map = response.files;
        let mut tasks = vec![];
        for (id, file) in files {
            let token = token_map.get(&id).unwrap();
            tasks.push(Task {
                id,
                token: token.clone(),
                path: file.file_name,
                session: id,
                progress: 0,
                total: 0,
            });
        }
        Session {
            id,
            node,
            tasks: tasks,
            current: 0,
        }
    }

    pub async fn execute(&mut self) {
        let task = self.tasks.get(self.current).unwrap();
        let path = task.path.clone();
        let token = task.token.clone();
        let session = task.session.clone();
    }
}

impl Task {
    pub async fn execute(&mut self) {
        let (tx, mut rx) = watch::channel(0);

        let f = File::open(self.path.clone()).await.unwrap();
        let buffered_reader = BufReader::new(f);
        let progress_reader = ProgressReadAdapter::new(buffered_reader, tx);
        while rx.changed().await.is_ok() {
            self.progress = *rx.borrow();
        }
    }
}
