use std::time::{SystemTime, UNIX_EPOCH};

use crate::{
    repository::SingleRepository,
    session::model::{Session, Status},
};

use async_trait::async_trait;
use tokio::sync::watch;

use super::ChangeNotifier;

#[async_trait(?Send)]
pub trait SessionService: ChangeNotifier<Session> {
    async fn create(&self, session: Session) -> Result<Session, String>;
    async fn agree(&self, id: String) -> Result<Session, String>;
    async fn reject(&self, id: String) -> Result<Session, String>;
    async fn cancel(&self, id: String) -> Result<Session, String>;
    async fn finish(&self, id: String) -> Result<Session, String>;
}

pub struct SessionServiceImpl {
    repo: Box<dyn SingleRepository<Session>>,
}

impl ChangeNotifier<Session> for SessionServiceImpl {
    fn notify(&self, data: Session) -> Result<(), String> {
        todo!()
    }

    fn listen(&self) -> Result<watch::Receiver<Session>, String> {
        todo!()
    }
}

fn get_time() -> u128 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_millis()
}

#[async_trait(?Send)]
impl SessionService for SessionServiceImpl {
    async fn create(&self, session: Session) -> Result<Session, String> {
        if self.repo.get().await.is_some() {
            return Err("session exist".to_string());
        }
        self.repo.set(session.clone()).await;
        self.notify(session.clone()).unwrap();
        Ok(session)
    }

    async fn agree(&self, id: String) -> Result<Session, String> {
        if let Some(mut session) = self.repo.get().await {
            if session.id == id {
                session.status = Status::Transfer {
                    start_time: get_time(),
                };
                self.repo.set(session.clone()).await;
                // todo
                self.notify(session.clone()).unwrap();
                return Ok(session);
            }
        }
        Err("session not exist".to_string())
    }

    async fn reject(&self, id: String) -> Result<Session, String> {
        todo!()
    }

    async fn cancel(&self, id: String) -> Result<Session, String> {
        todo!()
    }

    async fn finish(&self, id: String) -> Result<Session, String> {
        todo!()
    }
}
