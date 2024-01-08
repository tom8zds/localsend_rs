use std::{
    collections::HashMap,
    net::{Ipv4Addr, UdpSocket},
    sync::Arc,
};

use axum::{
    body::Bytes,
    extract::{Query, Request, State},
    http::StatusCode,
    routing::post,
    BoxError, Json, Router,
};
use futures::{Stream, TryStreamExt};
use log::{error, info};
use tokio::{
    fs::File,
    io::BufWriter,
    sync::{mpsc, Mutex},
};
use tokio_util::io::StreamReader;

use crate::core::{
    adapter::ProgressReadAdapter,
    model::{DeviceInfo, FileInfo, FileRequest, FileResponse, Progress, UploadTask},
};

pub struct UdpAnnounceProvicer {
    fingerprint: String,
    pub socket: UdpSocket,
    sender: mpsc::Sender<Announce>,
    interface_addr: Ipv4Addr,
    multicast_addr: Ipv4Addr,
}

type Announce = DeviceInfo;

impl UdpAnnounceProvicer {
    pub async fn new(
        fingerprint: String,
        interface_addr: Ipv4Addr,
        multicast_addr: Ipv4Addr,
        multicast_port: u16,
    ) -> (Self, mpsc::Receiver<Announce>) {
        let socket =
            UdpSocket::bind((interface_addr, multicast_port)).expect("couldn't bind to address");

        let (tx, rx) = mpsc::channel(1);

        (
            Self {
                sender: tx,
                socket,
                fingerprint,
                interface_addr,
                multicast_addr,
            },
            rx,
        )
    }

    pub async fn serve(&mut self) {
        self.socket
            .join_multicast_v4(&self.multicast_addr, &self.interface_addr)
            .expect("failed to join multicast");

        let mut buf = [0; 1024];

        while let Ok((size, addr)) = self.socket.recv_from(&mut buf) {
            let message = String::from_utf8_lossy(&buf[..size]);
            let device: DeviceInfo = serde_json::from_str(&message).unwrap();
            let device = DeviceInfo {
                address: Some(addr.ip().to_string()),
                ..device
            };
            if device.fingerprint != self.fingerprint {
                self.sender.send(device).await.unwrap();
            }
        }
    }
}

pub struct HttpServer {
    current_device: DeviceInfo,
    port: u16,
    sender: mpsc::Sender<Announce>,
    receiver: Arc<Mutex<mpsc::Receiver<bool>>>,
    progress: mpsc::Sender<Progress>,
    store_path: String,
}

#[derive(Debug, Clone, PartialEq)]
pub struct SendSession {
    pub id: String,
    pub token_map: HashMap<String, String>,
    pub info_map: HashMap<String, FileInfo>,
}

pub struct AppState {
    pub current_device: DeviceInfo,
    pub sender_tx: mpsc::Sender<Announce>,
    pub store_path: String,
    pub progress_tx: mpsc::Sender<Progress>,
    pub accept_rx: Arc<Mutex<mpsc::Receiver<bool>>>,
    pub current_session: Mutex<Option<SendSession>>,
}

async fn stream_to_file<S, E>(
    path: &str,
    file_path: &str,
    stream: S,
    tx: mpsc::Sender<Progress>,
    total_bytes: usize,
) -> Result<(), (StatusCode, String)>
where
    S: Stream<Item = Result<Bytes, E>>,
    E: Into<BoxError>,
{
    async {
        // Convert the stream into an `AsyncRead`.
        let body_with_io_error =
            stream.map_err(|err| std::io::Error::new(std::io::ErrorKind::Other, err));
        let body_reader = StreamReader::new(body_with_io_error);
        futures::pin_mut!(body_reader);

        // Create the file. `File` implements `AsyncWrite`.
        let path = std::path::Path::new(path).join(file_path);
        let dir = path.parent().unwrap();
        if dir.exists() == false {
            tokio::fs::create_dir_all(dir).await?;
        }

        let mut file = BufWriter::new(File::create(path).await?);
        // let mut read = ProgressReadAdapter::new(body_reader, total_bytes, tx.clone());

        // Copy the body into the file.
        tokio::io::copy(&mut body_reader, &mut file).await?;

        tx.send(Progress::Done).await.unwrap();

        Ok::<_, std::io::Error>(())
    }
    .await
    .map_err(|err| {
        error!("store file error {:?} in {}", err, path);
        (StatusCode::INTERNAL_SERVER_ERROR, err.to_string())
    })
}

// Save a `Stream` to a fil

impl HttpServer {
    async fn handle_upload(
        State(state): State<Arc<AppState>>,
        task: Query<UploadTask>,
        request: Request,
    ) -> Result<(), (StatusCode, String)> {
        let task: UploadTask = task.0;
        info!("handle_upload {:?}", task);
        let session = state.current_session.lock().await;
        if session.is_none() {
            return Err((StatusCode::BAD_REQUEST, "session not found".to_string()));
        }
        let session = session.as_ref().unwrap();
        if session.id != task.session_id {
            return Err((StatusCode::BAD_REQUEST, "session not match".to_string()));
        }
        let token = session.token_map.get(&task.file_id).unwrap();
        let file_info = session.info_map.get(token).unwrap();
        let file_name = file_info.file_name.clone();
        let file_size = file_info.size;
        let store_path = state.store_path.clone();
        // ...
        let body_stream = request.into_body().into_data_stream();
        stream_to_file(
            &store_path,
            &file_name,
            body_stream,
            state.progress_tx.clone(),
            file_size as usize,
        )
        .await
    }

    async fn prepare_upload(
        State(state): State<Arc<AppState>>,
        Json(payload): Json<FileRequest>,
    ) -> Result<Json<FileResponse>, (StatusCode, String)> {
        info!("prepare_upload {:?}", payload);
        let mut files = HashMap::new();
        let mut tokens = HashMap::new();
        payload.files.iter().for_each(|(key, value)| {
            files.insert(key.clone(), value.id.clone());
            tokens.insert(key.clone(), key.clone());
        });
        let session = SendSession {
            id: "1234567890".to_string(),
            token_map: tokens,
            info_map: payload.files.clone(),
        };
        state.current_session.lock().await.replace(session);
        state.progress_tx.send(Progress::Prepare).await.unwrap();
        let result = state.accept_rx.lock().await.recv().await.unwrap();
        if result == false {
            return Err((StatusCode::BAD_REQUEST, "user reject".to_string()));
        }
        state.progress_tx.send(Progress::Idle).await.unwrap();
        Ok(Json(FileResponse {
            session_id: "1234567890".to_string(),
            files: files,
        }))
    }

    async fn handle_register(
        State(state): State<Arc<AppState>>,
        Json(payload): Json<DeviceInfo>,
    ) -> Json<DeviceInfo> {
        info!("register {:?}", payload);
        let current_device = state.current_device.clone();
        let sender = state.sender_tx.clone();
        match sender.send(payload).await {
            Ok(_) => {
                return Json(current_device);
            }
            Err(_) => {
                panic!("failed to send announce")
            }
        }
    }
    pub fn new(
        current_device: DeviceInfo,
        store_path: String,
        port: u16,
        progress_tx: mpsc::Sender<Progress>,
        accept_rx: mpsc::Receiver<bool>,
    ) -> (Self, mpsc::Receiver<Announce>) {
        let (tx, rx) = mpsc::channel(1);

        (
            Self {
                current_device,
                port,
                sender: tx,
                receiver: Arc::new(Mutex::new(accept_rx)),
                progress: progress_tx,
                store_path,
            },
            rx,
        )
    }

    pub async fn serve(&mut self) {
        let app_state = Arc::new(AppState {
            current_device: self.current_device.clone(),
            sender_tx: self.sender.clone(),
            accept_rx: self.receiver.clone(),
            store_path: self.store_path.clone(),
            progress_tx: self.progress.clone(),
            current_session: Mutex::new(None),
        });
        let api_routes = Router::new()
            .route("/register", post(Self::handle_register))
            .route("/prepare-upload", post(Self::prepare_upload))
            .route("/upload", post(Self::handle_upload))
            .with_state(app_state);

        let app = Router::new().nest("/api/localsend/v2/", api_routes);

        let bind_addr = format!("0.0.0.0:{}", self.port);

        info!("http listening on {}", bind_addr);

        let listener = tokio::net::TcpListener::bind(bind_addr).await.unwrap();
        axum::serve(listener, app).await.unwrap();
    }
}
