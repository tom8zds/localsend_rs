use std::{net::SocketAddr, result, sync::Arc};

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
        model::{NodeAnnounce, NodeDevice},
    },
    session::{
        model::{Session, Status},
        progress::Progress,
        session::SESSION_HOLDER,
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
    total_size: usize,
    stream: S,
    progress: watch::Sender<Progress>,
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
        let mut writer = ProgressWriteAdapter::new(file, total_size, progress);

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

    let store_path = state.core.get_config().await.store_path;

    let session = SESSION_HOLDER.get().await;

    match session {
        Some(session) => {
            if !session.file_map.contains_key(&task.file_id) {
                return Err((StatusCode::CONFLICT, "file not exist".to_string()));
            }

            let file = session.file_map[&task.file_id].clone();
            let file_name = file.file_name;
            let file_size = file.size as usize;

            // ...
            let body_stream = request.into_body().into_data_stream();

            let tx = SESSION_HOLDER.start_task(task.file_id).await.unwrap();

            let res = stream_to_file(&store_path, &file_name, file_size, body_stream, tx).await;

            match res {
                Ok(_) => {
                    // handle
                    //     .state_task(task.token.clone(), FileState::Finish)
                    //     .await;
                    Ok(())
                }
                Err(e) => {
                    // handle
                    //     .state_task(task.token, FileState::Fail { msg: e.1.clone() })
                    //     .await;
                    Err(e)
                }
            }
        }
        None => {
            return Err((StatusCode::NOT_FOUND, "session not found".to_string()));
        }
    }
}
#[axum::debug_handler]
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

    let session = Session::new_send(device.unwrap(), payload.files);

    let id = session.id.clone();

    let token_map = session.token_map.clone();

    let flag = SESSION_HOLDER.add(session).await;

    if !flag {
        debug!("core is resolving another mission");
        return Err((StatusCode::CONFLICT, "mission rejected".to_string()));
    }

    SESSION_HOLDER.check().await;

    let (tx, mut rx) = mpsc::channel(8);

    let _guard = Guard { tx: tx.clone() };

    tokio::spawn(async move {
        while let Some(flag) = rx.recv().await {
            if flag {
                debug!("client side close");
                SESSION_HOLDER.clear().await;
            } else {
                debug!("normal complete");
            }
            break;
        }
    });

    SESSION_HOLDER.check().await;

    let mut listenr = SESSION_HOLDER.listen();

    let result: Result<Json<FileResponse>, (StatusCode, String)>;

    loop {
        let _ = listenr.changed().await;
        result = match listenr.borrow().clone() {
            Some(vm) => match vm.status {
                Status::Transfer { start_time } => {
                    let id_token_map = token_map
                        .iter()
                        .map(|(k, v)| (k.clone(), v.clone()))
                        .collect();

                    Ok(Json(FileResponse {
                        session_id: id.clone(),
                        files: id_token_map,
                    }))
                }
                Status::Fail { msg } => Err((StatusCode::INTERNAL_SERVER_ERROR, msg)),
                Status::Pending => {
                    debug!("mission pending");
                    continue;
                }
                _state => {
                    debug!("mission rejected {:?}", _state);
                    Err((StatusCode::FORBIDDEN, "mission rejected".to_string()))
                }
            },
            None => {
                debug!("mission rejected");
                Err((StatusCode::FORBIDDEN, "mission rejected".to_string()))
            }
        };
        break;
    }
    let _ = tx.send(false).await;
    result
}

#[derive(Deserialize)]
struct SessionId {
    #[serde(alias = "sessionId")]
    id: String,
}

async fn cancel(State(state): State<Arc<AppState>>, session_id: Query<SessionId>) {
    // let handle = state.core.mission.transfer.clone();
    // handle.cancel(session_id.id.clone()).await;
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
