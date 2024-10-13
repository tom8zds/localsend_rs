use std::{collections::HashMap, fs::File, io::BufReader, path::Path};

use log::debug;
use tokio::sync::watch;

use crate::{actor::model::NodeDevice, util::ProgressReadAdapter};

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

#[derive(Debug, Clone)]
pub struct Client {
    target: String,
    current_node: NodeDevice,
    agent: ureq::Agent,
}

impl Client {
    pub fn new(node: NodeDevice, current_node: NodeDevice) -> Self {
        let target = format!("http://{}:{}/api/localsend/v2", node.address, node.port);
        let agent = ureq::AgentBuilder::new()
            .timeout_read(std::time::Duration::from_secs(60))
            .build();

        Self {
            target,
            current_node,
            agent,
        }
    }

    pub fn prepare_upload(&self, files: HashMap<String, FileInfo>) -> Result<FileResponse, String> {
        let req = FileRequest {
            info: self.current_node.to_sender(),
            files,
        };

        let data = serde_json::to_string(&req).unwrap();
        let api = format!("{}/prepare-upload", self.target);

        debug!("prepare upload: {}", api);

        match self.agent.post(&api).send_string(&data) {
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

    pub fn upload_file(
        &self,
        session_id: String,
        path: String,
        file_id: String,
        token: String,
        tx: watch::Sender<usize>,
    ) {
        let f = File::open(path).unwrap();
        let buffered_reader = BufReader::new(f);
        let progress_reader = ProgressReadAdapter::new(buffered_reader, tx);
        let api = format!("{}/upload", self.target);

        let r = ureq::post(&api)
            .query("sessionId", &session_id)
            .query("fileId", &file_id)
            .query("token", &token)
            .send(progress_reader);
        match r {
            Ok(_) => debug!("upload success"),
            Err(err) => debug!("upload error: {:?}", err),
        };
    }
}

pub fn read_file_info_map(files: Vec<String>) -> HashMap<String, FileInfo> {
    let mut res = HashMap::new();
    for file in files {
        let info = read_file_info(&file);
        res.insert(info.id.clone(), info);
    }
    res
}

pub fn read_file_info(path: &str) -> FileInfo {
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
