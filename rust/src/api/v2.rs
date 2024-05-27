use core::panic;
use std::net::SocketAddr;

use axum::{
    body::Bytes,
    extract::{ConnectInfo, Query, Request},
    http::StatusCode,
    routing::post,
    BoxError, Json, Router,
};
use futures::{Stream, TryStreamExt};
use log::debug;
use tokio::{fs::File, io::BufWriter};
use tokio_util::io::StreamReader;

use crate::{
    api::{mission, model::MissionState},
    discovery::{
        handler,
        model::{Node, NodeAnnounce},
    },
};

use super::model::{FileRequest, FileResponse, UploadTask};

async fn stream_to_file<S, E>(path: &str, stream: S) -> Result<(), (StatusCode, String)>
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

        // Copy the body into the file.
        tokio::io::copy(&mut body_reader, &mut file).await?;

        Ok::<_, std::io::Error>(())
    }
    .await
    .map_err(|err| (StatusCode::INTERNAL_SERVER_ERROR, err.to_string()))
}

async fn handle_upload(
    task: Query<UploadTask>,
    request: Request,
) -> Result<(), (StatusCode, String)> {
    let task: UploadTask = task.0;
    debug!("handle_upload {:?}", task);
    let session = mission::get_mission(&task.session_id).await.unwrap();
    if ![MissionState::Accepted, MissionState::Receiving].contains(&session.state) {
        panic!("mission not accepted");
    }
    let file_info = session.get_file_info(&task.token);
    if file_info.is_none() {
        panic!("file info not found");
    }
    let file_name = file_info.unwrap().file_name.clone();
    // ...
    let body_stream = request.into_body().into_data_stream();

    mission::update_mission_state(&task.session_id, MissionState::Receiving).await;

    let res = stream_to_file(&file_name, body_stream).await;

    match res {
        Ok(_) => {
            mission::update_file_state(&task.session_id, file_name).await;
            Ok(())
        }
        Err(e) => {
            mission::update_mission_state(&task.session_id, MissionState::Failed).await;
            Err(e)
        }
    }
}

async fn prepare_upload(
    Json(payload): Json<FileRequest>,
) -> Result<Json<FileResponse>, (StatusCode, String)> {
    debug!("prepare_upload {:?}", payload);
    let (id, files) = mission::create_mission(payload.files).await;

    let mut watcher = mission::get_mission_listener();
    while let Ok(_) = watcher.changed().await {
        let missions = watcher.borrow();
        if missions.contains_key(&id) {
            if missions.get(&id).unwrap().state == MissionState::Accepted {
                return Ok(Json(FileResponse {
                    session_id: id,
                    files,
                }));
            }
            if missions.get(&id).unwrap().state == MissionState::Rejected {
                debug!("mission rejected");
                return Err((StatusCode::FORBIDDEN, "mission rejected".to_string()));
            }
            if missions.get(&id).unwrap().state != MissionState::Accepting {
                panic!("mission state changed before");
            }
        }
    }
    mission::update_mission_state(&id, MissionState::Failed).await;
    panic!("mission failed");
}

async fn handle_register(
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(payload): Json<NodeAnnounce>,
) -> Json<NodeAnnounce> {
    let node = Node::from_announce(&payload, &addr.ip().to_string());
    debug!("node {:?}", node);
    handler::add_node(node).await;
    Json(payload)
}

pub fn app() -> Router {
    let api_v2 = Router::new()
        .route("/register", post(handle_register))
        .route("/prepare-upload", post(prepare_upload))
        .route("/upload", post(handle_upload));

    let app = Router::new().nest("/v2", api_v2);

    app
}
