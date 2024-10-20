use lazy_static::lazy_static;
use log::debug;
use std::{
    sync::Arc,
    time::{SystemTime, UNIX_EPOCH},
};
use tokio::sync::{watch, Mutex};

use super::{
    model::{Session, SessionVm, Status},
    progress::{set_progress, Progress},
};

lazy_static! {
    pub static ref SESSION_HOLDER: Arc<SessionHolder> = Arc::new(SessionHolder::new());
}

pub struct SessionHolder {
    internal: Mutex<Option<Session>>,
    notify: watch::Sender<Option<SessionVm>>,
    listener: watch::Receiver<Option<SessionVm>>,
}

fn get_time() -> u128 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_millis()
}

impl SessionHolder {
    pub fn new() -> Self {
        let (tx, rx) = watch::channel(None);

        Self {
            internal: Mutex::new(None),
            notify: tx,
            listener: rx,
        }
    }

    pub async fn get(&self) -> Option<Session> {
        let internal = self.internal.lock().await;
        internal.clone()
    }

    pub async fn clear(&self) {
        debug!("clear session");
        let mut internal = self.internal.lock().await;
        internal.take();
        let _ = self.notify.send(None);
    }

    pub async fn add(&self, session: Session) -> bool {
        let mut internal = self.internal.lock().await;
        if internal.is_none() {
            internal.replace(session.clone());
            let _ = self.notify.send(Some(session.to_vm()));
            debug!("session added");
            if internal.is_some() {
                return true;
            }
            return false;
        }
        false
    }

    pub async fn agree(&self) {
        self.update_status(Status::Transfer {
            start_time: get_time(),
        })
        .await
    }

    pub async fn reject(&self) {
        self.update_status(Status::Rejected).await
    }

    pub async fn finish(&self) {
        self.update_status(Status::Finish).await
    }

    pub async fn fail(&self, id: String, msg: String) {
        let mut internal = self.internal.lock().await;
        if let Some(session) = internal.as_mut() {
            session.status = Status::Fail { msg: msg.clone() };
            session.status_map.insert(id, Status::Fail { msg });
            let _ = self.notify.send(Some(session.to_vm()));
        }
    }

    pub async fn start_task(&self, id: String) -> Result<watch::Sender<Progress>, ()> {
        let mut internal = self.internal.lock().await;
        if let Some(session) = internal.as_mut() {
            session.status_map.insert(
                id.clone(),
                Status::Transfer {
                    start_time: get_time(),
                },
            );
            let tx = set_progress(id);
            let _ = self.notify.send(Some(session.to_vm()));
            return Ok(tx);
        }
        Err(())
    }

    pub async fn check(&self) {
        let internal = self.internal.lock().await;
        if internal.is_some() {
            debug!("session found")
        } else {
            debug!("no session found ");
        }
    }

    async fn update_status(&self, status: Status) {
        let mut internal = self.internal.lock().await;
        if internal.is_some() {
            debug!("update status to {:?}", status)
        } else {
            debug!("no session found ");
        }
        if let Some(session) = internal.as_mut() {
            session.status = status;
            let _ = self.notify.send(Some(session.to_vm()));
        }
    }

    pub fn listen(&self) -> watch::Receiver<Option<SessionVm>> {
        self.listener.clone()
    }
}
