use std::collections::HashMap;
use std::net::{Ipv4Addr, SocketAddrV4};
use std::sync::{self, Arc};

use log::info;
use tokio::sync::{mpsc, Mutex};

use crate::core::model::{self, Progress};

use crate::core::server::{HttpServer, UdpAnnounceProvicer};
use crate::frb_generated::StreamSink;

use crate::logger;

pub struct LogEntry {
    pub time_millis: i64,
    pub level: i32,
    pub tag: String,
    pub msg: String,
}

pub fn create_log_stream(s: StreamSink<LogEntry>) -> Result<(), String> {
    logger::SendToDartLogger::set_stream_sink(s);
    Ok(())
}

pub fn rust_set_up(is_debug: bool) {
    logger::init_logger(is_debug);
}

#[derive(Default, Debug, Clone)]
pub struct DeviceConfig {
    pub alias: String,
    pub fingerprint: String,
    pub device_model: String,
    pub device_type: String,
    pub store_path: String,
}

#[derive(Default, Debug, Clone)]
pub struct ServerConfig {
    pub multicast_addr: String,
    pub port: u16,
    pub protocol: String,
    pub download: bool,
    pub announcement: bool,
    pub announce: bool,
}

impl model::DeviceInfo {
    pub fn from(device: DeviceConfig, config: ServerConfig) -> Self {
        Self {
            alias: device.alias,
            version: String::from("2.0"),
            device_model: device.device_model,
            device_type: device.device_type,
            fingerprint: device.fingerprint,
            address: None,
            port: config.port,
            protocol: config.protocol,
            download: config.download,
            announcement: config.announcement,
            announce: config.announce,
        }
    }
}

struct Server {
    device: DeviceConfig,
}

#[derive(Debug, Clone)]
pub enum ServerStatus {
    Starting,
    Started,
    Stopping,
    Stopped,
}

pub enum DiscoverState {
    Discovering(Vec<model::DeviceInfo>),
    Done,
}

pub enum ServerRequest {
    Start(ServerConfig),
    Accept(bool),
    Discover,
    Stop,
    Status,
}

enum ServerResponse {
    Status(ServerStatus),
}

struct StatusWrapper {
    status: ServerStatus,
    tx: mpsc::Sender<ServerResponse>,
}

impl StatusWrapper {
    async fn change(&mut self, status: ServerStatus) {
        self.status = status;
        self.notify().await;
    }

    async fn notify(&self) {
        let _ = self
            .tx
            .send(ServerResponse::Status(self.status.clone()))
            .await;
    }
}

type DevicePool = Arc<Mutex<DevicePoolWrapper>>;

struct DevicePoolWrapper {
    devices: HashMap<String, model::DeviceInfo>,
    tx: mpsc::Sender<DiscoverState>,
}

impl DevicePoolWrapper {
    fn contains_key(&self, key: &String) -> bool {
        self.devices.contains_key(key)
    }
    fn insert(&mut self, key: String, value: model::DeviceInfo) {
        self.devices.insert(key, value);
        let state = DiscoverState::Discovering(self.devices.values().cloned().collect());
        let tx = self.tx.clone();
        tokio::spawn(async move {
            let _ = tx.send(state).await;
        });
    }
}

impl Server {
    async fn handle_register(message: model::DeviceInfo, fingerprint: String, devices: DevicePool) {
        if &message.fingerprint == &fingerprint {
            info!("self announce detected");
            return;
        }
        let mut devices = devices.lock().await;
        if devices.contains_key(&message.fingerprint) {
            info!("device already exists");
        } else {
            devices.insert(message.fingerprint.clone(), message.clone());
        }
    }
    async fn send_register(target: String, current_device: &model::DeviceInfo) -> Result<(), &str> {
        // let api: String = target + "/api/localsend/v2/register";

        // info!("register to {}", api);

        // let client = reqwest::Client::builder()
        //     .danger_accept_invalid_certs(true)
        //     .build()
        //     .unwrap();
        // let res = client
        //     .post(api)
        //     .body(serde_json::to_string(current_device).unwrap())
        //     .send()
        //     .await;
        // if res.is_err() {
        //     info!("http register error: {:?}", res.err());
        //     info!("fallback to udp register  announce");
        //     return Err("fallback to udp register  announce");
        // }
        // let body = res.unwrap().text().await.unwrap();
        // info!("Register respone:\n{}", body);
        Ok(())
    }
    async fn handle_serve(
        devices: DevicePool,
        device: DeviceConfig,
        config: ServerConfig,
        mut rx: mpsc::Receiver<ServerRequest>,
        tx: mpsc::Sender<Progress>,
    ) {
        let addr = SocketAddrV4::new(Ipv4Addr::new(0, 0, 0, 0), config.port);
        let multi_addr = SocketAddrV4::new(
            config.multicast_addr.parse::<Ipv4Addr>().unwrap(),
            config.port,
        );

        info!("Starting server on: {}", addr);
        info!("Multicast address: {}\n", multi_addr);

        let current_device = model::DeviceInfo::from(device.clone(), config);
        let fingerprint = current_device.fingerprint.clone();

        info!("start server");

        let (mut server, mut announce) = UdpAnnounceProvicer::new(
            fingerprint.clone(),
            Ipv4Addr::new(0, 0, 0, 0),
            Ipv4Addr::new(224, 0, 0, 167),
            53317,
        )
        .await;

        let udp_socket = server.socket.try_clone().unwrap();

        let server_handle: tokio::task::JoinHandle<()> = tokio::spawn(async move {
            server.serve().await;
        });

        let fingerprint_clone = fingerprint.clone();
        let devices_clone = devices.clone();
        let current_device_clone = current_device.clone();

        let announce_handle = tokio::spawn(async move {
            while let Some(message) = announce.recv().await {
                info!("device announce : {:?}", message.alias);
                let target = format!(
                    "{}://{}:{}",
                    message.protocol,
                    message.address.clone().unwrap(),
                    message.port
                );
                match Self::send_register(target, &current_device_clone).await {
                    Ok(_) => {
                        Self::handle_register(
                            message,
                            fingerprint_clone.clone(),
                            devices_clone.clone(),
                        )
                        .await;
                    }
                    Err(_) => {}
                }
            }
        });

        let current_device_clone = current_device.clone();
        let device_clone = device.clone();
        let devices_clone = devices.clone();
        let (accept_tx, accept_rx) = mpsc::channel::<bool>(1);

        let (mut http_server, mut api_handler) =
            HttpServer::new(current_device_clone, device_clone.store_path.clone(),addr.port(), tx.clone(), accept_rx);

        let http_handle = tokio::spawn(async move {
            http_server.serve().await;
        });

        let api_handle = tokio::spawn(async move {
            while let Some(message) = api_handler.recv().await {
                Self::handle_register(message, fingerprint.clone(), devices_clone.clone()).await;
            }
        });

        let send_buf: Vec<u8> = serde_json::to_vec(&current_device.clone()).unwrap();
        let handles = vec![server_handle, announce_handle, http_handle, api_handle];

        while let Some(command) = rx.recv().await {
            match command {
                ServerRequest::Discover => {
                    info!("send announce");
                    for _ in 0..5 {
                        let _ = udp_socket.send_to(&send_buf, multi_addr);
                        std::thread::sleep(std::time::Duration::from_secs(1));
                    }
                },
                ServerRequest::Accept(is_accept) => {
                    accept_tx.send(is_accept).await.unwrap();
                },
                ServerRequest::Stop => {
                    for h in handles {
                        h.abort();
                        match h.await {
                            Ok(_) => {}
                            Err(_) => {}
                        }
                    }
                    info!("server stopped");
                    break;
                },
                _ => {}
            }
        }
    }

    async fn serve(
        &self,
        mut rx: mpsc::Receiver<ServerRequest>,
        status_tx: mpsc::Sender<ServerResponse>,
        discover_tx: mpsc::Sender<DiscoverState>,
        progress_tx: mpsc::Sender<Progress>,
    ) -> Result<(), AppError> {
        let mut optx: Option<mpsc::Sender<ServerRequest>> = None;
        let mut status = StatusWrapper {
            status: ServerStatus::Stopped,
            tx: status_tx.clone(),
        };
        let devices: DevicePool = Arc::new(Mutex::new(DevicePoolWrapper {
            devices: HashMap::new(),
            tx: discover_tx.clone(),
        }));
        // ...
        while let Some(command) = rx.recv().await {
            match command {
                ServerRequest::Start(config) => {
                    if optx.is_some() {
                        info!("server already started");
                    }

                    let (inner_tx, inner_rx) = mpsc::channel::<ServerRequest>(1);

                    optx.replace(inner_tx);

                    info!("server started");
                    status.change(ServerStatus::Starting).await;

                    let config = config.clone();
                    let devices_clone = devices.clone();
                    let device = self.device.clone();
                    let progress_tx = progress_tx.clone();

                    tokio::spawn(async move {
                        let handle = tokio::spawn(async move {
                            Self::handle_serve(
                                devices_clone,
                                device,
                                config,
                                inner_rx,
                                progress_tx,
                            )
                            .await;
                        });

                        handle.await.unwrap();
                        info!("server stopped , send status");
                        match CONTEXT.get() {
                            Some(context) => {
                                let _ = context.signal_tx.send(ServerRequest::Status).await;
                            }
                            None => {}
                        }
                    });

                    status.change(ServerStatus::Started).await;
                    discover_tx.send(DiscoverState::Done).await.unwrap();
                }
                ServerRequest::Discover => {
                    let optx = optx.clone();
                    if optx.is_some() {
                        devices.lock().await.devices.clear();
                        info!("announce signal sent");
                        optx.unwrap().send(ServerRequest::Discover).await.unwrap();
                    } else {
                        info!("server not started");
                    }
                }
                ServerRequest::Stop => {
                    let optx = optx.take();
                    if optx.is_some() {
                        status.change(ServerStatus::Stopping).await;
                        info!("stop signal sent");
                        optx.unwrap().send(ServerRequest::Stop).await.unwrap();
                    } else {
                        info!("server not started");
                    }
                    status.change(ServerStatus::Stopped).await;
                }
                ServerRequest::Status => {
                    status.notify().await;
                }
                ServerRequest::Accept(_) => {
                    let optx = optx.clone();
                    if optx.is_some() {
                        devices.lock().await.devices.clear();
                        info!("accept signal sent");
                        optx.unwrap().send(command).await.unwrap();
                    } else {
                        info!("server not started");
                    }
                },
            }
        }
        info!("server stopped");
        Ok(())
    }
}

pub struct AppError {
    pub code: usize,
    pub message: String,
}

struct AppContext {
    server: Server,
    signal_tx: mpsc::Sender<ServerRequest>,
    accept_tx: mpsc::Sender<bool>,
    status_rx: Mutex<mpsc::Receiver<ServerResponse>>,
    discover_rx: Mutex<mpsc::Receiver<DiscoverState>>,
    progress_rx: Mutex<mpsc::Receiver<Progress>>,
}

static CONTEXT: sync::OnceLock<AppContext> = sync::OnceLock::new();

#[tokio::main]
pub async fn init_server(device: DeviceConfig) {
    let (tx, rx) = mpsc::channel::<ServerRequest>(1);
    let (tx2, rx2) = mpsc::channel::<ServerResponse>(1);
    let (tx3, rx3) = mpsc::channel::<DiscoverState>(1);
    let (tx4, rx4) = mpsc::channel::<Progress>(16);
    let (tx5, rx5) = mpsc::channel::<bool>(1);

    let server = Server { device };
    let context = AppContext {
        server,
        signal_tx: tx,
        accept_tx: tx5,
        status_rx: Mutex::new(rx2),
        discover_rx: Mutex::new(rx3),
        progress_rx: Mutex::new(rx4),
    };

    CONTEXT.get_or_init(|| {
        info!("App context is being created..."); // 初始化打印
        context
    });

    let server = &CONTEXT.get().unwrap().server;
    let _ = server.serve(rx, tx2, tx3, tx4).await;
}

#[tokio::main]
pub async fn start_server(config: ServerConfig) {
    let _ = CONTEXT
        .get()
        .unwrap()
        .signal_tx
        .send(ServerRequest::Start(config))
        .await;
}

#[tokio::main]
pub async fn stop_server() {
    let _ = CONTEXT
        .get()
        .unwrap()
        .signal_tx
        .send(ServerRequest::Stop)
        .await;
}

#[tokio::main]
pub async fn discover() {
    let _ = CONTEXT
        .get()
        .unwrap()
        .signal_tx
        .send(ServerRequest::Discover)
        .await;
}

#[tokio::main]
pub async fn accept(is_accept: bool) {
    let _ = CONTEXT
        .get()
        .unwrap()
        .signal_tx
        .send(ServerRequest::Accept(is_accept))
        .await;
}

#[tokio::main]
pub async fn listen_progress(sink: StreamSink<Progress>) {
    match CONTEXT.get() {
        Some(context) => {
            let mut rx: tokio::sync::MutexGuard<'_, mpsc::Receiver<Progress>> =
                context.progress_rx.lock().await;
            while let Some(response) = rx.recv().await {
                sink.add(response);
            }
        }
        None => {}
    }
}

#[tokio::main]
pub async fn listen_discover(sink: StreamSink<DiscoverState>) {
    match CONTEXT.get() {
        Some(context) => {
            let mut rx: tokio::sync::MutexGuard<'_, mpsc::Receiver<DiscoverState>> =
                context.discover_rx.lock().await;
            while let Some(response) = rx.recv().await {
                sink.add(response);
            }
        }
        None => {}
    }
}

#[tokio::main]
pub async fn server_status(sink: StreamSink<ServerStatus>) {
    match CONTEXT.get() {
        Some(context) => {
            let _ = context.signal_tx.send(ServerRequest::Status).await;

            let mut rx: tokio::sync::MutexGuard<'_, mpsc::Receiver<ServerResponse>> =
                context.status_rx.lock().await;
            while let Some(response) = rx.recv().await {
                match response {
                    ServerResponse::Status(status) => {
                        sink.add(status);
                    }
                    _ => {}
                }
            }
        }
        None => {}
    }
}
