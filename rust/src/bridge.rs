use std::{
    net::{IpAddr, Ipv4Addr, SocketAddr},
    str::FromStr as _,
    sync::Arc,
};

use lazy_static::lazy_static;
use log::debug;
use tokio::{net::UdpSocket, sync::OnceCell};

use crate::{
    actor::{
        core::{CoreActorHandle, CoreConfig},
        model::NodeDevice,
    },
    api,
    frb_generated::StreamSink,
    logger::{self, LogEntry},
    session::{
        model::SessionVm,
        progress::{get_progress, Progress},
        session::SESSION_HOLDER,
    },
};

lazy_static! {
    static ref CORE: OnceCell<CoreActorHandle> = OnceCell::new();
}

fn _get_core() -> CoreActorHandle {
    CORE.get().unwrap().clone()
}

pub async fn setup(device: NodeDevice, config: CoreConfig) {
    logger::init_logger(true);
    let _ = CORE.set(CoreActorHandle::new(device, config));
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

pub async fn restart_server() {
    _get_core().shutdown().await;
    _get_core().start().await;
}

pub async fn change_path(path: String) {
    _get_core().change_path(path).await;
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

pub async fn listen_session(s: StreamSink<Option<SessionVm>>) {
    let mut rx = SESSION_HOLDER.listen();
    loop {
        let _ = rx.changed().await;
        debug!("mission change");
        let data = rx.borrow().clone();
        let _ = s.add(data);
    }
}

pub async fn listen_progress(id: String, s: StreamSink<Progress>) {
    let rx = get_progress(id);
    match rx {
        Ok(mut rx) => loop {
            let _ = rx.changed().await;
            let data = rx.borrow().clone();
            let _ = s.add(data);
        },
        Err(_) => {}
    }
}

pub async fn clear_mission() {
    SESSION_HOLDER.clear().await;
}

pub async fn cancel_pending() {
    SESSION_HOLDER.clear().await;
}

pub async fn accept_pending() {
    debug!("session agree");
    SESSION_HOLDER.agree().await;
}

pub fn create_log_stream(s: StreamSink<LogEntry>) {
    logger::SendToDartLogger::set_stream_sink(s);
}

pub async fn announce() {
    let config = _get_core().get_config().await;
    let interface_addr = Ipv4Addr::from_str(&config.interface_addr).unwrap();
    let multicast_addr = Ipv4Addr::from_str(&config.multicast_addr).unwrap();
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

pub async fn send_file(path: String, node: NodeDevice, prog_sink: StreamSink<Progress>) {
    let current_node = _get_core().device.get_current_device().await;
    let client = api::client::Client::new(node, current_node);
    let file_map = api::client::read_file_info_map(vec![path.clone()]);
    let result = client.prepare_upload(file_map.clone());
    match result {
        Ok(response) => {
            let token_map = response.files;
            let sink = Arc::new(prog_sink);

            for (file_id, token) in token_map.iter() {
                let file_info = file_map.get(file_id).unwrap();
                let total_size = file_info.size;
                let client = client.clone();
                let file_id = file_id.clone();
                let token = token.clone();
                let session_id = response.session_id.clone();
                let path = path.clone();
                let (tx, mut rx) = tokio::sync::watch::channel(0);
                let sink = sink.clone();
                tokio::spawn(async move {
                    loop {
                        let _ = rx.changed().await;
                        let progress = rx.borrow().clone();
                        let _ = sink.add(Progress {
                            progress,
                            total: total_size as usize,
                        });
                        if progress == total_size as usize {
                            break;
                        }
                    }
                });
                let _ = tokio::spawn(async move {
                    let _ =
                        client.upload_file(session_id, path, file_id.clone(), token.clone(), tx);
                })
                .await;
            }
        }
        Err(_) => todo!(),
    }
}
