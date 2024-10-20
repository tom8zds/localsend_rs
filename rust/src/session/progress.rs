use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};

use lazy_static::lazy_static;
use tokio::sync::watch;

#[derive(Debug, Clone)]
pub struct Progress {
    pub progress: usize,
    pub total: usize,
}

lazy_static! {
    static ref PROGRESS_MAP: Arc<Mutex<HashMap<String, watch::Receiver<Progress>>>> =
        Arc::new(Mutex::new(HashMap::new()));
}

pub fn get_progress(id: String) -> Result<watch::Receiver<Progress>, ()> {
    let map = PROGRESS_MAP.lock().unwrap();
    if map.contains_key(&id) {
        return Ok(map.get(&id).cloned().unwrap());
    }
    Err(())
}

pub fn set_progress(id: String) -> watch::Sender<Progress> {
    let (tx, rx) = watch::channel(Progress {
        progress: 0,
        total: 0,
    });
    PROGRESS_MAP.lock().unwrap().insert(id, rx);
    tx
}
