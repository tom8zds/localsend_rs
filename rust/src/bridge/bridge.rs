use std::{
    net::{Ipv4Addr, SocketAddrV4},
    sync::Arc,
};

use flutter_rust_bridge::DartFnFuture;
use log::{debug, info};
use tokio::sync::{mpsc, Mutex};

use crate::{
    api::model::{FileInfo, Mission, MissionState},
    discovery::{handler, model::Node},
};
use crate::{
    api::{self, mission},
    frb_generated::StreamSink,
};

use crate::logger;

pub fn create_log_stream(s: StreamSink<logger::LogEntry>) -> Result<(), String> {
    logger::SendToDartLogger::set_stream_sink(s);
    Ok(())
}

pub fn rust_set_up(is_debug: bool) {
    logger::init_logger(is_debug);
}

#[tokio::main]
pub async fn setup() {
    let addr = SocketAddrV4::new(Ipv4Addr::new(0, 0, 0, 0), 53317);
    let multi_addr = SocketAddrV4::new(Ipv4Addr::new(224, 0, 0, 167), 53317);

    let (sender, receiver) = mpsc::channel(1);
    SERVER_SIGNAL_TX.lock().await.replace(sender);
    SERVER_SIGNAL_RX.lock().await.replace(receiver);

    let fingerprint: String = uuid::Uuid::new_v4().to_string();

    let node: Node = Node {
        alias: String::from("test"),
        version: String::from("2.0"),
        device_model: String::from("rust"),
        device_type: String::from("mobile"),
        fingerprint: fingerprint.clone(),
        address: String::from(""),
        port: addr.port(),
        protocol: String::from("http"),
        download: false,
        announcement: true,
        announce: true,
    };

    handler::set_current_node(node).await;
    logger::init_logger(true);
}

#[tokio::main]
pub async fn start() {
    SERVER_CONTEXT.lock().await.state = ServerState::Running;
    let _ = start_server().await;
}

#[tokio::main]
pub async fn stop() {
    handle_stop().await;
}

#[tokio::main]
pub async fn state() -> ServerState {
    SERVER_CONTEXT.lock().await.state.clone()
}

#[tokio::main]
pub async fn discover() {
    handler::discover().await;
}

#[tokio::main]
pub async fn accept_mission(mission_id: String, accept: bool) {
    if accept {
        mission::accept_mission(&mission_id).await;
    } else {
        mission::reject_mission(&mission_id).await;
    }
}

#[tokio::main]
pub async fn clear_missions() {
    mission::clear_missions().await;
}

#[tokio::main]
pub async fn node_channel(dart_callback: impl Fn(Vec<Node>) -> DartFnFuture<String>) {
    let mut listener = handler::get_node_listener();
    loop {
        let _ = listener.changed().await;
        let nodes = listener.borrow().clone();

        dart_callback(nodes.iter().map(|item| item.1.clone()).collect()).await;
    }
}

#[derive(Default, Debug, Clone, PartialEq)]
pub struct MissionItem {
    pub id: String,
    pub state: MissionState,
    pub file_info: Vec<FileInfo>,
}

#[tokio::main]
pub async fn mission_channel(dart_callback: impl Fn(Vec<MissionItem>) -> DartFnFuture<String>) {
    let mut listener = mission::get_mission_listener();
    loop {
        let _ = listener.changed().await;
        let missions = listener.borrow().clone();
        let mission_items = missions.iter().map(|(_, value)| MissionItem {
            id: value.id.clone(),
            state: value.state.clone(),
            file_info: value.info_map.values().map(|item| item.clone()).collect(),
        });

        dart_callback(mission_items.collect()).await;
    }
}

async fn start_server() {
    let api_handle = tokio::spawn(async move {
        let _ = api::server::serve(53317).await;
    });

    let discover_handle = tokio::spawn(async move {
        let interface_addr = Ipv4Addr::new(0, 0, 0, 0);
        let multicast_addr = Ipv4Addr::new(224, 0, 0, 167);
        let multicast_port = 53317;
        let _ = handler::serve(interface_addr, multicast_addr, multicast_port).await;
    });

    let handles = vec![api_handle, discover_handle];

    while let Some(_) = SERVER_SIGNAL_RX.lock().await.as_mut().unwrap().recv().await {
        debug!("received stop signal");
        break;
    }

    SERVER_CONTEXT.lock().await.state = ServerState::Stopping;
    debug!("server stopping...");

    for handle in &handles {
        handle.abort();
    }

    for handle in handles {
        assert!(handle.await.unwrap_err().is_cancelled());
    }

    handler::stop().await;

    debug!("server stopped");
    SERVER_CONTEXT.lock().await.state = ServerState::Stopped;
}

#[derive(Debug, Clone, PartialEq)]
pub enum ServerState {
    Stopped,
    Running,
    Stopping,
}

struct ServerContext {
    state: ServerState,
}

impl ServerContext {
    fn default() -> Self {
        Self {
            state: ServerState::Stopped,
        }
    }
}

async fn handle_stop() {
    let _ = SERVER_SIGNAL_TX
        .lock()
        .await
        .as_ref()
        .unwrap()
        .clone()
        .send(true)
        .await;
    info!("stopping server...");
    loop {
        let state = SERVER_CONTEXT.lock().await.state.clone();
        if state == ServerState::Stopped {
            break;
        }
        debug!("waiting for server to stop...");
        tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
    }
}

lazy_static::lazy_static! {
    static ref SERVER_SIGNAL_TX: Arc<Mutex<Option<mpsc::Sender<bool>>>> = Arc::new(Mutex::new(None));
    static ref SERVER_SIGNAL_RX: Arc<Mutex<Option<mpsc::Receiver<bool>>>> = Arc::new(Mutex::new(None));
    static ref SERVER_CONTEXT: Arc<Mutex<ServerContext>> = Arc::new(Mutex::new(ServerContext::default()));
}
