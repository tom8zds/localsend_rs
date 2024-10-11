use std::{collections::HashMap, fs::File, io::BufReader, path::Path};

use log::debug;

use crate::core::model::NodeDevice;

use std::fs::Metadata;

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

fn read_file_info(path: &str) -> FileInfo {
    let file_id = uuid::Uuid::new_v4().to_string();
    let f = File::open(path).unwrap();
    let file_name = Path::new(path)
        .file_name()
        .unwrap()
        .to_str()
        .unwrap()
        .to_string();
    let file_size = get_file_size(f.metadata().unwrap()) as i64;
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

pub fn send(path: String, node: NodeDevice, current_node: NodeDevice) {
    let file_info = read_file_info(&path);
    let file_id = file_info.id.clone();
    let request = FileRequest {
        info: current_node.to_sender(),
        files: HashMap::from([(file_id.clone(), file_info)]),
    };
    let base_api = format!(
        "http://{}:{}/{}",
        node.address, node.port, "api/localsend/v2/"
    );
    let result = prepare(&base_api, request);
    match result {
        Ok(file_response) => {
            debug!("prepare success");
            upload(
                &base_api,
                &path,
                &file_response.session_id,
                &file_id,
                &file_response.files[&file_id],
            );
        }
        Err(err) => {
            debug!("prepare error: {:?}", err)
        }
    }
}

// prepare transfer
// POST /api/localsend/v2/prepare-upload
//optional query("pin", "123456")
fn prepare(base_api: &str, req: FileRequest) -> Result<FileResponse, String> {
    let data = serde_json::to_string(&req).unwrap();
    let api = format!("{}prepare-upload", base_api);

    debug!("prepare upload: {}", api);

    match ureq::post(&api).send_string(&data) {
        Ok(resp) => {
            let body = resp.into_string().unwrap();
            let file_resp: FileResponse = serde_json::from_str(&body).unwrap();
            return Result::Ok(file_resp);
        }
        Err(err) => {
            debug!("prepare error: {:?}", err);
            return Result::Err(err.to_string());
        }
    };
}

fn upload(base_api: &str, path: &str, session_id: &str, file_id: &str, token: &str) {
    let f = File::open(path).unwrap();
    let buffered_reader = BufReader::new(f);
    let api = format!("{}upload", base_api);

    debug!("upload file: {}", api);

    let r = ureq::post(&api)
        .query("sessionId", session_id)
        .query("fileId", file_id)
        .query("token", token)
        .send(buffered_reader);
    match r {
        Ok(_) => debug!("upload success"),
        Err(err) => debug!("upload error: {:?}", err),
    };
}
