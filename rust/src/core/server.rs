use std::{
    collections::HashMap,
    net::{Ipv4Addr, UdpSocket}, sync::Arc,
};

use axum::{
    body::Bytes,
    extract::{Query, Request, State},
    http::StatusCode,
    routing::post,
    BoxError, Json, Router,
};
use futures::{Stream, TryStreamExt};
use tokio::{fs::File, io::BufWriter, sync::{Mutex, mpsc}};
use tokio_util::io::StreamReader;

use crate::core::{model::{DeviceInfo, FileInfo, FileRequest, FileResponse, UploadTask, Progress}, adapter::ProgressReadAdapter};

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
    progress: mpsc::Sender<Progress>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct SendSession {
    pub id: String,
    pub token_map: HashMap<String, String>,
    pub info_map: HashMap<String, FileInfo>,
}

pub struct AppState {
    pub progress_tx: mpsc::Sender<Progress>,
    pub session_map: Arc<Mutex<HashMap<String, SendSession>>>,
}

async fn stream_to_file<S, E>(path: &str, stream: S, tx: mpsc::Sender<Progress>, total_bytes: usize) -> Result<(), (StatusCode, String)>
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
        let path = std::path::Path::new("./").join(path);
        let dir = path.parent().unwrap();
        if dir.exists() == false {
            tokio::fs::create_dir_all(dir).await?;
        }
        
        let mut file = BufWriter::new(File::create(path).await?);
        let mut read = ProgressReadAdapter::new(body_reader, total_bytes, tx.clone());

        // Copy the body into the file.
        tokio::io::copy(&mut read, &mut file).await?;

        tx.send(
            Progress::Done
        ).await.unwrap();

        Ok::<_, std::io::Error>(())
    }
    .await
    .map_err(|err| (StatusCode::INTERNAL_SERVER_ERROR, err.to_string()))
}

// Save a `Stream` to a fil

impl HttpServer {
    async fn handle_upload(
        State(state): State<Arc<AppState>>,
        task: Query<UploadTask>,
        request: Request,
    ) -> Result<(), (StatusCode, String)> {
        let task: UploadTask = task.0;
        println!("handle_upload {:?}", task);
        let state: Arc<AppState> = state;
        let session_map = state.session_map.lock().await;
        println!("session_map {:?}", session_map);
        let session = session_map.get(&task.session_id).unwrap();
        let token = session.token_map.get(&task.file_id).unwrap();
        let file_info = session.info_map.get(token).unwrap();
        let file_name = file_info.file_name.clone();
        let file_size = file_info.size;
        // ...
        let body_stream = request.into_body().into_data_stream();
        stream_to_file(&file_name, body_stream, state.progress_tx.clone(), file_size as usize).await
    }

    async fn prepare_upload(
        State(state): State<Arc<AppState>>,
        Json(payload): Json<FileRequest>,
    ) -> Json<FileResponse> {
        println!("prepare_upload {:?}", payload);
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
        let state: Arc<AppState> = state;
        state
            .session_map
            .lock()
            .await
            .insert(session.id.clone(), session);
        Json(FileResponse {
            session_id: "1234567890".to_string(),
            files: files,
        })
    }

    async fn handle_register(
        Json(payload): Json<DeviceInfo>,
        sender: Arc<mpsc::Sender<Announce>>,
        current_device: DeviceInfo,
    ) -> Json<DeviceInfo> {
        println!("register {:?}", payload);
        match sender.send(payload).await {
            Ok(_) => {
                return Json(current_device);
            }
            Err(_) => {
                panic!("failed to send announce")
            }
        }
    }
    pub fn new(current_device: DeviceInfo, port: u16, progress_tx: mpsc::Sender<Progress>) -> (Self, mpsc::Receiver<Announce>) {
        let (tx, rx) = mpsc::channel(1);

        (
            Self {
                current_device,
                port,
                sender: tx,
                progress: progress_tx,
            },
            rx
        )
    }

    pub async fn serve(&mut self) {
        let app_state = Arc::new(AppState {
            progress_tx: self.progress.clone(),
            session_map: Arc::new(Mutex::new(HashMap::new())),
        });
        let api_routes = Router::new()
            .route(
                "/register",
                post({
                    let sender = Arc::new(self.sender.clone());
                    let current_device = self.current_device.clone();
                    move |body| Self::handle_register(body, sender, current_device)
                }),
            )
            .route("/prepare-upload", post(Self::prepare_upload))
            .route("/upload", post(Self::handle_upload))
            .with_state(app_state);

        let app = Router::new().nest("/api/localsend/v2/", api_routes);

        let bind_addr = format!("0.0.0.0:{}", self.port);

        println!("http listening on {}", bind_addr);

        let listener = tokio::net::TcpListener::bind(bind_addr).await.unwrap();
        axum::serve(listener, app).await.unwrap();
    }
}
