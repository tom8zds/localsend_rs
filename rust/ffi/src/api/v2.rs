use std::{net::SocketAddr, sync::Arc};

use super::model::{FileRequest, FileResponse, UploadTask};
use axum::{
    body::Bytes,
    extract::{ConnectInfo, Query, Request, State},
    http::StatusCode,
    routing::{get, post},
    BoxError, Json, Router,
};
use futures::{Stream, TryStreamExt};
use log::debug;
use serde_derive::Deserialize;
use serde_json::{json, Value};
use tokio::{
    fs::File,
    io::BufWriter,
    sync::{mpsc, watch},
};
use tokio_util::io::StreamReader;

use crate::{
    actor::{
        core::CoreActorHandle,
        mission::FileState,
        model::{Mission, MissionState, NodeAnnounce, NodeDevice},
    },
    util::ProgressWriteAdapter,
};

async fn handle_register(
    State(state): State<Arc<AppState>>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(payload): Json<NodeAnnounce>,
) -> Json<NodeAnnounce> {
    let device = NodeDevice::from_announce(&payload, &addr.ip().to_string());
    debug!("device {:?}", device);
    state.core.device.add_node_device(device).await;
    Json(payload)
}

async fn get_devices(State(state): State<Arc<AppState>>) -> Json<Value> {
    let device_map = state.core.device.get_device_map().await;
    Json(json!( { "code":200, "data": device_map }))
}

struct Guard {
    tx: mpsc::Sender<bool>,
}

impl Drop for Guard {
    fn drop(&mut self) {
        let tx = self.tx.clone();
        tokio::spawn(async move { tx.send(true).await });
        debug!("request guard was dropped")
    }
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
        // Convert the stream into an `AsyncRead`.
        let body_with_io_error =
            stream.map_err(|err| std::io::Error::new(std::io::ErrorKind::Other, err));
        let body_reader = StreamReader::new(body_with_io_error);
        futures::pin_mut!(body_reader);

        // Create the file. `File` implements `AsyncWrite`.
        let file_path = std::path::Path::new(dir).join(file_name);
        let store_dir = file_path.parent().unwrap();
        if store_dir.exists() == false {
            tokio::fs::create_dir_all(store_dir).await?;
        }

        let file = BufWriter::new(File::create(file_path).await?);
        let mut writer = ProgressWriteAdapter::new(file, progress);

        // Copy the body into the file.
        tokio::io::copy(&mut body_reader, &mut writer).await?;

        Ok::<_, std::io::Error>(())
    }
    .await
    .map_err(|err| (StatusCode::INTERNAL_SERVER_ERROR, err.to_string()))
}

async fn handle_upload(
    State(state): State<Arc<AppState>>,
    task: Query<UploadTask>,
    request: Request,
) -> Result<(), (StatusCode, String)> {
    let task: UploadTask = task.0;
    debug!("handle_upload {:?}", task);

    let handle = state.core.mission.transfer.clone();
    let store_path = state.core.get_config().await.store_path;

    let res = handle.start_task(task.token.clone()).await;

    match res {
        Ok((tx, file)) => {
            let file_name = file.file_name.clone();
            // ...
            let body_stream = request.into_body().into_data_stream();

            let res = stream_to_file(&store_path, &file_name, body_stream, tx).await;

            match res {
                Ok(_) => {
                    handle
                        .state_task(task.token.clone(), FileState::Finish)
                        .await;
                    Ok(())
                }
                Err(e) => {
                    handle
                        .state_task(task.token, FileState::Fail { msg: e.1.clone() })
                        .await;
                    Err(e)
                }
            }
        }
        Err(_) => todo!(),
    }
}

async fn prepare_upload(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<FileRequest>,
) -> Result<Json<FileResponse>, (StatusCode, String)> {
    debug!("prepare_upload {:?}", payload);

    let device = state
        .core
        .device
        .get_device(payload.info.fingerprint.clone())
        .await;

    if device.is_none() {
        debug!("mission rejected");
        return Err((
            StatusCode::FORBIDDEN,
            "device not registerd, mission rejected".to_string(),
        ));
    }

    debug!("mission incoming");

    let mission = Mission::new(payload.files, device.unwrap());
    let id = mission.id.clone();

    let (tx, mut rx) = mpsc::channel(8);

    let _guard = Guard { tx: tx.clone() };
    let state_clone = state.clone();

    tokio::spawn(async move {
        while let Some(flag) = rx.recv().await {
            if flag {
                debug!("client side close");
                state_clone.core.mission.pending.cancel(id).await;
            } else {
                debug!("normal complete");
            }
            break;
        }
    });

    let result = pending_mission(state, mission).await;
    let _ = tx.send(false).await;
    result
}

async fn pending_mission(
    state: Arc<AppState>,
    mission: Mission,
) -> Result<Json<FileResponse>, (StatusCode, String)> {
    let mut state_rx = state.core.mission.pending.add(mission.clone()).await;

    let _ = state_rx.changed().await;

    let result = match *state_rx.borrow_and_update() {
        MissionState::Transfering => Ok(Json(FileResponse {
            session_id: mission.id,
            files: mission.id_token_map,
        })),
        MissionState::Busy => {
            debug!("core is resolving another mission");
            Err((StatusCode::CONFLICT, "mission rejected".to_string()))
        }
        _state => {
            debug!("mission rejected {:?}", _state);
            Err((StatusCode::FORBIDDEN, "mission rejected".to_string()))
        }
    };
    result
}

#[derive(Deserialize)]
struct SessionId {
    #[serde(alias = "sessionId")]
    id: String,
}

async fn cancel(State(state): State<Arc<AppState>>, session_id: Query<SessionId>) {
    let handle = state.core.mission.transfer.clone();
    handle.cancel(session_id.id.clone()).await;
}

struct AppState {
    core: CoreActorHandle,
}

pub fn app(core: CoreActorHandle) -> Router {
    let shared_state = Arc::new(AppState { core });
    let api_v2 = Router::new()
        .route("/devices", get(get_devices))
        .route("/register", post(handle_register))
        .route("/prepare-upload", post(prepare_upload))
        .route("/upload", post(handle_upload))
        .route("/cancel/:session_id", post(cancel))
        .with_state(shared_state);

    let app = Router::new().nest("/v2", api_v2);

    app
}
