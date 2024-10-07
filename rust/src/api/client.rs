use std::{collections::HashMap, path::Path};

use futures::StreamExt;
use log::debug;
use reqwest::Body;
use std::fs::Metadata;
use tokio::fs::File;
use tokio_util::io::ReaderStream;

use crate::actor::model::NodeDevice;

use super::model::{FileInfo, FileRequest, FileResponse};

#[cfg(target_os = "android")]
fn get_file_size(metadata: Metadata) -> u64 {
    use std::os::android::fs::MetadataExt;

    metadata.st_size()
}

#[cfg(target_os = "linux")]
fn get_file_size(metadata: Metadata) -> u64 {
    use std::os::linux::fs::MetadataExt;

    metadata.st_size()
}

#[cfg(target_os = "windows")]
fn get_file_size(metadata: Metadata) -> u64 {
    use std::os::windows::fs::MetadataExt;

    metadata.file_size()
}

async fn read_file_info(path: &str) -> FileInfo {
    let file_id = uuid::Uuid::new_v4().to_string();
    let f = File::open(path).await.unwrap();
    let file_name = Path::new(path)
        .file_name()
        .unwrap()
        .to_str()
        .unwrap()
        .to_string();
    let file_size = get_file_size(f.metadata().await.unwrap()) as i64;
    let file_type = mime_guess::from_path(path).first().unwrap().to_string();
    FileInfo {
        id: file_id,
        file_name: file_name,
        size: file_size,
        file_type: file_type,
        sha256: None,
        preview: None,
    }
}

pub async fn send(path: String, node: NodeDevice, current_node: NodeDevice) {
    let file_info = read_file_info(&path).await;
    let file_id = file_info.id.clone();
    let request = FileRequest {
        info: current_node.to_sender(),
        files: HashMap::from([(file_id.clone(), file_info)]),
    };
    let base_api = format!(
        "http://{}:{}/{}",
        node.address, node.port, "api/localsend/v2/"
    );
    let result = prepare(&base_api, request).await;
    match result {
        Ok(file_response) => {
            debug!("prepare success");
            upload(
                &base_api,
                &path,
                &file_response.session_id,
                &file_id,
                &file_response.files[&file_id],
            )
            .await;
        }
        Err(err) => {
            debug!("prepare error: {:?}", err)
        }
    }
}

// prepare transfer
// POST /api/localsend/v2/prepare-upload
//optional query("pin", "123456")
async fn prepare(base_api: &str, req: FileRequest) -> Result<FileResponse, String> {
    let data = serde_json::to_string(&req).unwrap();
    let api = format!("{}prepare-upload", base_api);

    debug!("prepare upload: {}", api);

    let client = reqwest::Client::new();
    let req = client.post(api).body(data).send().await;

    match req {
        Ok(resp) => {
            let file_resp: FileResponse = resp.json().await.unwrap();
            return Result::Ok(file_resp);
        }
        Err(err) => {
            debug!("prepare error: {:?}", err);
            return Result::Err(err.to_string());
        }
    };
}

async fn upload(base_api: &str, path: &str, session_id: &str, file_id: &str, token: &str) {
    let file = File::open(path).await.unwrap();
    let total_size = get_file_size(file.metadata().await.unwrap());
    let api = format!("{}upload", base_api);

    debug!("upload file: {}", api);

    let mut reader_stream = ReaderStream::new(file);
    let mut uploaded = 0;

    let async_stream = async_stream::stream! {
        let counter = 0;
        while let Some(chunk) = reader_stream.next().await {
            if let Ok(chunk) = &chunk {
                uploaded = uploaded + (chunk.len() as u64);
                if counter % 10 == 0 {
                    debug!("uploaded: {}/{}", uploaded, total_size);
                }
            }
            yield chunk;
        }
    };

    let client = reqwest::Client::new();
    let req = client
        .post(api)
        .query(&[
            ("sessionId", session_id),
            ("fileId", file_id),
            ("token", token),
        ])
        .body(Body::wrap_stream(async_stream))
        .send()
        .await;

    match req {
        Ok(_) => debug!("upload success"),
        Err(err) => debug!("upload error: {:?}", err),
    };
}
