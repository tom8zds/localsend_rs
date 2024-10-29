use std::sync::Arc;

use tokio::sync::Mutex;

use crate::session::model::Session;
use async_trait::async_trait;

use super::SingleRepository;

struct SessionRepo {
    holder: Arc<Mutex<Option<Session>>>,
}

#[async_trait(?Send)]
impl SingleRepository<Session> for SessionRepo {
    async fn get(&self) -> Option<Session> {
        return self.holder.lock().await.clone();
    }

    async fn set(&self, item: Session) {
        self.holder.lock().await.replace(item);
    }

    async fn clear(&self) {
        self.holder.lock().await.take();
    }
}
