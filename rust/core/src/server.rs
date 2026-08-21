//! HTTP server: axum routes for the v2 (and legacy v1 info) API plus
//! the server lifecycle actor with port-retry and graceful shutdown.

use std::net::SocketAddr;
use std::sync::Arc;

use axum::{
    body::Bytes,
    extract::{ConnectInfo, Query, Request, State},
    http::StatusCode,
    routing::{get, post},
    BoxError, Json, Router,
};
use futures::{Stream, TryStreamExt};
use log::{debug, error, info, warn};
use serde::Deserialize;
use serde_json::{json, Value};
use tokio::{
    fs::File,
    io::BufWriter,
    sync::{mpsc, oneshot, watch},
};
use tokio_util::io::StreamReader;

use crate::discovery::DiscoverHandle;
use crate::handle::CoreHandle;
use crate::model::{FileRequest, FileResponse, NodeAnnounce, NodeDevice, UploadTask};
use crate::session::{Decision, SessionError};
use crate::{model::FileState, util::ProgressWriteAdapter};

/// How far past the configured port the server probes when the port is
/// already occupied.
const MAX_PORT_RETRY: u16 = 10;

enum ServerMessage {
    Shutdown,
}

pub struct HttpServerHandle {
    sender: mpsc::Sender<ServerMessage>,
    shutdown_receiver: watch::Receiver<bool>,
    bound: Option<oneshot::Receiver<Result<u16, String>>>,
}

impl HttpServerHandle {
    /// `config` is passed in (rather than queried from the core actor)
    /// because the core actor is the one awaiting [`wait_bound`]; asking
    /// it for the config from here would deadlock.
    pub fn new(core: CoreHandle, config: crate::config::CoreConfig) -> Self {
        let (sender, receiver) = mpsc::channel(8);
        let (s_sender, s_receiver) = watch::channel(true);
        let (bound_tx, bound_rx) = oneshot::channel();

        tokio::spawn(run_http_actor(core, config, receiver, s_sender, bound_tx));

        Self {
            sender,
            shutdown_receiver: s_receiver,
            bound: Some(bound_rx),
        }
    }

    /// Wait until the socket is bound (or all port retries failed).
    pub async fn wait_bound(&mut self) -> Result<u16, String> {
        match self.bound.take() {
            Some(rx) => rx
                .await
                .unwrap_or_else(|_| Err("http actor died before binding".to_string())),
            None => Err("bind result already consumed".to_string()),
        }
    }

    pub async fn shutdown(mut self) {
        let _ = self.sender.send(ServerMessage::Shutdown).await;
        let _ = self.shutdown_receiver.changed().await;
    }
}

async fn run_http_actor(
    core: CoreHandle,
    config: crate::config::CoreConfig,
    mut receiver: mpsc::Receiver<ServerMessage>,
    shutdown_callback: watch::Sender<bool>,
    bound: oneshot::Sender<Result<u16, String>>,
) {
    let base_port = config.port;

    let discover_handle = if core.options().enable_discovery {
        Some(DiscoverHandle::new(core.clone(), config.clone()))
    } else {
        None
    };

    // Port-retry: if the configured port is occupied, probe upwards.
    let mut listener = None;
    let mut bound_port = base_port;
    for offset in 0..=MAX_PORT_RETRY {
        let port = base_port.saturating_add(offset);
        let addr = SocketAddr::from(([0, 0, 0, 0], port));
        match tokio::net::TcpListener::bind(addr).await {
            Ok(l) => {
                listener = Some(l);
                bound_port = port;
                break;
            }
            Err(e) => {
                warn!("port {port} unavailable ({e}), trying next");
            }
        }
    }

    let listener = match listener {
        Some(l) => l,
        None => {
            let msg = format!(
                "no free port in range {base_port}..={}",
                base_port.saturating_add(MAX_PORT_RETRY)
            );
            error!("{msg}");
            let _ = bound.send(Err(msg));
            if let Some(discover) = discover_handle {
                discover.shutdown().await;
            }
            let _ = shutdown_callback.send(true);
            return;
        }
    };

    info!("http service {bound_port} started");
    let _ = bound.send(Ok(bound_port));

    let app = app(core);

    let shutdown = async move {
        while let Some(msg) = receiver.recv().await {
            if matches!(msg, ServerMessage::Shutdown) {
                break;
            }
        }
    };

    let serve = axum::serve(
        listener,
        app.into_make_service_with_connect_info::<SocketAddr>(),
    )
    .with_graceful_shutdown(shutdown)
    .await;

    if let Err(e) = serve {
        error!("http service {bound_port} failed: {e}");
    }

    info!("http service {bound_port} shutdown");

    if let Some(discover) = discover_handle {
        discover.shutdown().await;
    }

    let _ = shutdown_callback.send(true);
}

// ---------------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------------

struct AppState {
    core: CoreHandle,
}

pub fn app(core: CoreHandle) -> Router {
    let shared_state = Arc::new(AppState { core });

    let v1 = Router::new().route("/info", get(handle_info));
    let v2 = Router::new()
        .route("/info", get(handle_info))
        .route("/register", post(handle_register))
        .route("/prepare-upload", post(prepare_upload))
        .route("/upload", post(handle_upload))
        .route("/cancel", post(handle_cancel))
        .route("/devices", get(get_devices));

    Router::new()
        .nest("/api/localsend/v1", v1)
        .nest("/api/localsend/v2", v2)
        .with_state(shared_state)
}

/// `GET /api/localsend/v{1,2}/info` — legacy clients probe this to
/// discover this device without multicast.
async fn handle_info(State(state): State<Arc<AppState>>) -> Json<NodeAnnounce> {
    let current = state.core.device.get_current_device().await;
    Json(current.to_announce())
}

async fn handle_register(
    State(state): State<Arc<AppState>>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(payload): Json<NodeAnnounce>,
) -> Json<NodeAnnounce> {
    let device = NodeDevice::from_announce(&payload, &addr.ip().to_string());
    debug!("device registered {:?}", device);
    state.core.device.add_node_device(device).await;
    Json(payload)
}

async fn get_devices(State(state): State<Arc<AppState>>) -> Json<Value> {
    let device_map = state.core.device.get_device_map().await;
    Json(json!({ "code": 200, "data": device_map }))
}

/// Aborts the pending session when the sender goes away while we wait
/// for the accept/decline decision.
struct Guard {
    tx: mpsc::Sender<bool>,
}

impl Drop for Guard {
    fn drop(&mut self) {
        let tx = self.tx.clone();
        tokio::spawn(async move {
            let _ = tx.send(true).await;
        });
        debug!("request guard was dropped")
    }
}

async fn prepare_upload(
    State(state): State<Arc<AppState>>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(payload): Json<FileRequest>,
) -> Result<Json<FileResponse>, (StatusCode, String)> {
    debug!("prepare_upload from {}", addr.ip());

    let sender_device = payload.info.to_device(&addr.ip().to_string());
    state
        .core
        .device
        .add_node_device(sender_device.clone())
        .await;

    let pending = state
        .core
        .sessions()
        .create_recv_session(sender_device, payload.files)
        .await;

    let pending = match pending {
        Ok(p) => p,
        Err(SessionError::Busy) => {
            return Err((
                StatusCode::CONFLICT,
                "too many concurrent sessions".to_string(),
            ))
        }
        Err(e) => return Err((StatusCode::INTERNAL_SERVER_ERROR, e.to_string())),
    };

    let session_id = pending.session_id.clone();
    let (tx, mut rx) = mpsc::channel(8);
    let _guard = Guard { tx: tx.clone() };
    let state_clone = state.clone();
    let guard_session = session_id.clone();

    tokio::spawn(async move {
        if let Some(flag) = rx.recv().await {
            if flag {
                debug!("prepare-upload client disconnected, cancelling {guard_session}");
                state_clone.core.sessions().cancel(&guard_session).await;
            }
        }
    });

    let result = match pending.decision.await {
        Ok(Decision::Accepted { files }) => Ok(Json(FileResponse { session_id, files })),
        Ok(Decision::Declined) => {
            debug!("session declined");
            Err((StatusCode::FORBIDDEN, "mission rejected".to_string()))
        }
        Ok(Decision::Canceled) | Err(_) => {
            debug!("session canceled while pending");
            Err((StatusCode::FORBIDDEN, "mission canceled".to_string()))
        }
    };
    let _ = tx.send(false).await;
    result
}

async fn stream_to_file<S, E>(
    dir: &str,
    file_name: &str,
    stream: S,
    progress: watch::Sender<usize>,
) -> Result<(), (StatusCode, String)>
where
    S: Stream<Item = Result<Bytes, E>>,
    E: Into<BoxError>,
{
    async {
        let body_with_io_error = stream.map_err(std::io::Error::other);
        let body_reader = StreamReader::new(body_with_io_error);
        futures::pin_mut!(body_reader);

        let dir_path = std::path::Path::new(dir);
        if !dir_path.exists() {
            tokio::fs::create_dir_all(dir_path).await?;
        }
        let file_path = dedup_path(dir_path, file_name);

        let file = BufWriter::new(File::create(file_path).await?);
        let mut writer = ProgressWriteAdapter::new(file, progress);

        tokio::io::copy(&mut body_reader, &mut writer).await?;
        tokio::io::AsyncWriteExt::shutdown(&mut writer).await?;

        Ok::<_, std::io::Error>(())
    }
    .await
    .map_err(|err| (StatusCode::INTERNAL_SERVER_ERROR, err.to_string()))
}

/// Avoid clobbering an existing file (e.g. two concurrent sessions
/// receiving the same file name) by appending ` (n)`.
fn dedup_path(dir: &std::path::Path, file_name: &str) -> std::path::PathBuf {
    let candidate = dir.join(file_name);
    if !candidate.exists() {
        return candidate;
    }
    let path = std::path::Path::new(file_name);
    let stem = path
        .file_stem()
        .map(|s| s.to_string_lossy().to_string())
        .unwrap_or_else(|| file_name.to_string());
    let ext = path.extension().map(|e| e.to_string_lossy().to_string());
    for n in 1..1000u32 {
        let name = match &ext {
            Some(ext) => format!("{stem} ({n}).{ext}"),
            None => format!("{stem} ({n})"),
        };
        let candidate = dir.join(name);
        if !candidate.exists() {
            return candidate;
        }
    }
    candidate
}

async fn handle_upload(
    State(state): State<Arc<AppState>>,
    task: Query<UploadTask>,
    request: Request,
) -> Result<(), (StatusCode, String)> {
    let task: UploadTask = task.0;
    debug!("handle_upload {:?}", task);

    let sessions = state.core.sessions().clone();
    let store_path = state.core.get_config().await.store_path;

    let file_task = sessions.start_file(&task.session_id, &task.token).await;

    let file_task = match file_task {
        Ok(t) => t,
        Err(e) => {
            debug!("upload rejected: {e}");
            return Err((StatusCode::FORBIDDEN, e.to_string()));
        }
    };

    let file_name = file_task.info.file_name.clone();
    let cancel = file_task.cancel.clone();
    let body_stream = request.into_body().into_data_stream();

    let copy = stream_to_file(&store_path, &file_name, body_stream, file_task.progress);

    tokio::select! {
        res = copy => {
            match res {
                Ok(_) => {
                    sessions
                        .finish_file(&task.session_id, &task.token, FileState::Finish)
                        .await;
                    Ok(())
                }
                Err(e) => {
                    sessions
                        .finish_file(
                            &task.session_id,
                            &task.token,
                            FileState::Fail { msg: e.1.clone() },
                        )
                        .await;
                    Err(e)
                }
            }
        }
        _ = cancel.cancelled() => {
            debug!("upload aborted: session {} canceled", task.session_id);
            sessions
                .finish_file(
                    &task.session_id,
                    &task.token,
                    FileState::Fail { msg: "session canceled".to_string() },
                )
                .await;
            Err((StatusCode::REQUEST_TIMEOUT, "session canceled".to_string()))
        }
    }
}

#[derive(Deserialize)]
struct SessionId {
    #[serde(alias = "sessionId")]
    id: String,
}

/// `POST /api/localsend/v2/cancel?sessionId=...` — the sender cancels
/// an active (or pending) session.
async fn handle_cancel(
    State(state): State<Arc<AppState>>,
    session_id: Query<SessionId>,
) -> StatusCode {
    debug!("cancel from remote: {}", session_id.id);
    state.core.sessions().cancel(&session_id.id).await;
    StatusCode::OK
}
