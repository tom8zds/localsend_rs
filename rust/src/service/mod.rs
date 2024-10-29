use tokio::sync::watch;

pub mod session;

pub trait ChangeNotifier<T> {
    fn notify(&self, data: T) -> Result<(), String>;
    fn listen(&self) -> Result<watch::Receiver<T>, String>;
}
