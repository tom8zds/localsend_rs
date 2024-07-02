use crate::{
    actor::{
        core::{CoreActorHandle, CoreConfig},
        model::NodeDevice,
    },
    frb_generated::StreamSink,
    logger,
};
use lazy_static::lazy_static;
lazy_static! {
    static ref CORE: CoreActorHandle = CoreActorHandle::new();
}

pub async fn setup() {
    logger::init_logger(true);
    CORE.start().await;
}

pub async fn start_server() {
    CORE.start().await;
}

pub async fn shutdown_server() {
    CORE.shutdown().await;
}

pub async fn change_config(config: CoreConfig) {
    CORE.change_config(config).await;
}

pub fn get_log() -> logger::LogEntry {
    logger::LogEntry {
        time_millis: 0,
        level: 0,
        tag: String::new(),
        msg: String::new(),
    }
}

pub async fn listen_device(s: StreamSink<Vec<NodeDevice>>) {
    let mut rx = CORE.device.listen().await;
    loop {
        let _ = rx.changed().await;
        let data = rx.borrow().clone();
        let _ = s.add(data);
    }
}
