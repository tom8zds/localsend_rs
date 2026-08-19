//! FRB API surface. Thin adapter over [`localsend_core::CoreHandle`];
//! the function signatures (and the mirrored types) are unchanged so
//! the generated bindings and the Flutter app keep compiling. The full
//! bridge rewrite (exposing sessions/sending) is Phase 4.

use lazy_static::lazy_static;
use log::debug;
use tokio::sync::OnceCell;

use crate::{
    actor::{
        core::CoreConfig,
        mission::MissionInfo,
        model::NodeDevice,
    },
    frb_generated::StreamSink,
    logger::{self, LogEntry},
};

lazy_static! {
    static ref CORE: OnceCell<localsend_core::CoreHandle> = OnceCell::new();
}

fn _get_core() -> localsend_core::CoreHandle {
    CORE.get().unwrap().clone()
}

pub async fn setup(device: NodeDevice, config: CoreConfig) {
    logger::init_logger(true);
    let _ = CORE.set(localsend_core::CoreHandle::new(
        device.to_core(),
        config.to_core(),
    ));
    _get_core().start().await;
}

pub async fn listen_server_state(s: StreamSink<bool>) {
    let mut rx = _get_core().server_state().await;
    loop {
        let _ = rx.changed().await;
        let data = *rx.borrow();
        let _ = s.add(data);
    }
}

pub async fn start_server() {
    _get_core().start().await;
}

pub async fn shutdown_server() {
    _get_core().shutdown().await;
}

pub async fn restart_server() {
    _get_core().shutdown().await;
    _get_core().start().await;
}

pub async fn change_path(path: String) {
    _get_core().change_path(path).await;
}

pub async fn change_config(config: CoreConfig) {
    _get_core().change_config(config.to_core()).await;
}

pub async fn listen_device(s: StreamSink<Vec<NodeDevice>>) {
    let mut rx = _get_core().device.listen().await;
    loop {
        let _ = rx.changed().await;
        let data = rx
            .borrow()
            .clone()
            .into_iter()
            .map(Into::into)
            .collect::<Vec<NodeDevice>>();
        let _ = s.add(data);
    }
}

pub async fn listen_mission(s: StreamSink<Option<MissionInfo>>) {
    let mut rx = _get_core().mission_listen().await;
    loop {
        let _ = rx.changed().await;
        debug!("mission change");
        let data = rx.borrow().clone().map(Into::into);
        let _ = s.add(data);
    }
}

pub async fn listen_task_progress(s: StreamSink<usize>) {
    let mut rx = _get_core().task_progress_listen().await;
    loop {
        let _ = rx.changed().await;
        let data = *rx.borrow();
        let _ = s.add(data);
    }
}

pub async fn clear_mission() {
    _get_core().mission_clear().await;
}

pub async fn cancel_pending(id: String) {
    let _ = _get_core().decline(&id).await;
}

pub async fn accept_pending(id: String) {
    let _ = _get_core().accept(&id, None).await;
}

pub fn create_log_stream(s: StreamSink<LogEntry>) {
    logger::SendToDartLogger::set_stream_sink(s);
}

pub async fn announce() {
    _get_core().announce().await;
}
