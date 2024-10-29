pub mod session;
use async_trait::async_trait;

#[async_trait(?Send)]
pub trait SingleRepository<T: Clone> {
    async fn get(&self) -> Option<T>;
    async fn set(&self, item: T);
    async fn clear(&self);
}

#[async_trait(?Send)]
pub trait MapRepository<T: Clone> {
    fn get(&self, id: String) -> Result<T, String>;
    fn save(&self, item: T) -> Result<T, String>;
    fn delete(&self, id: String) -> Result<(), String>;
    fn list(&self) -> Result<Vec<T>, String>;
}
