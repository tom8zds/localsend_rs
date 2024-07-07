use std::net::{IpAddr, SocketAddr};

use lazy_static::lazy_static;
use log::debug;
use tokio::{net::UdpSocket, sync::OnceCell};

use crate::{
    actor::{
        core::{CoreActorHandle, CoreConfig},
        mission::{MissionInfo, MISSION_NOTIFY},
        model::NodeDevice,
    },
    frb_generated::StreamSink,
    logger::{self, LogEntry},
};

lazy_static! {
    static ref CORE: OnceCell<CoreActorHandle> = OnceCell::new();
}

fn _get_core() -> CoreActorHandle {
    CORE.get().unwrap().clone()
}

pub async fn setup(device: NodeDevice) {
    logger::init_logger(true);
    let _ = CORE.set(CoreActorHandle::new(device));
    _get_core().start().await;
}

pub async fn listen_server_state(s: StreamSink<bool>) {
    let mut rx = _get_core().listen().await;
    loop {
        let _ = rx.changed().await;
        let data = rx.borrow().clone();
        let _ = s.add(data);
    }
}

pub async fn start_server() {
    _get_core().start().await;
}

pub async fn shutdown_server() {
    _get_core().shutdown().await;
}

pub async fn change_address(addr: String) {
    _get_core().shutdown().await;
    _get_core().change_address(addr).await;
    _get_core().start().await;
}

pub async fn change_config(config: CoreConfig) {
    _get_core().change_config(config).await;
}

pub async fn listen_device(s: StreamSink<Vec<NodeDevice>>) {
    let mut rx = _get_core().device.listen().await;
    loop {
        let _ = rx.changed().await;
        let data = rx.borrow().clone();
        let _ = s.add(data);
    }
}

pub async fn listen_mission(s: StreamSink<Option<MissionInfo>>) {
    let mut rx = MISSION_NOTIFY.listen().await;
    loop {
        let _ = rx.changed().await;
        debug!("mission change");
        let data = rx.borrow().clone();
        let _ = s.add(data);
    }
}

pub async fn clear_mission() {
    MISSION_NOTIFY.clear().await;
}

pub async fn cancel_pending(id: String) {
    _get_core().mission.pending.cancel(id).await;
}

pub async fn accept_pending(id: String) {
    _get_core().mission.pending.accept(id).await;
}

pub fn create_log_stream(s: StreamSink<LogEntry>) {
    logger::SendToDartLogger::set_stream_sink(s);
}

pub async fn announce() {
    let config = _get_core().get_config().await;
    let interface_addr = config.interface_addr;
    let multicast_addr = config.multicast_addr;
    let multicast_port = config.multicast_port;

    _get_core().device.clear_devices().await;

    let send_socket: UdpSocket = UdpSocket::bind((interface_addr, multicast_port + 2))
        .await
        .expect("couldn't bind to address");

    send_socket
        .join_multicast_v4(multicast_addr, interface_addr)
        .expect("failed to join multicast");

    let current = _get_core().device.get_current_device().await;
    let s_message = serde_json::to_string(&current).unwrap();

    let buf = s_message.as_bytes();
    for _ in 1..3 {
        let _ = send_socket
            .send_to(
                buf,
                SocketAddr::new(IpAddr::from(multicast_addr), multicast_port),
            )
            .await;
    }
}
