use std::collections::HashMap;

use serde_derive::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SenderInfo {
    pub alias: String,
    pub version: String,
    pub device_model: String,
    pub device_type: String,
    pub fingerprint: String,
    pub port: u16,
    pub protocol: String,
    pub download: bool,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct FileRequest {
    pub info: SenderInfo,
    pub files: HashMap<String, FileInfo>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct FileInfo {
    pub id: String,
    pub file_name: String,
    pub size: i64,
    pub file_type: String,
    pub sha256: Option<String>,
    pub preview: Option<Vec<u8>>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct FileResponse {
    pub session_id: String,
    pub files: HashMap<String, String>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UploadTask {
    pub session_id: String,
    pub file_id: String,
    pub token: String,
}
