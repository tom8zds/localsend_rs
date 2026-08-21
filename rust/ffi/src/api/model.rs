//! FRB boundary mirror of `localsend_core::FileInfo`.

use serde_derive::{Deserialize, Serialize};

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

impl From<localsend_core::FileInfo> for FileInfo {
    fn from(f: localsend_core::FileInfo) -> Self {
        FileInfo {
            id: f.id,
            file_name: f.file_name,
            size: f.size,
            file_type: f.file_type,
            sha256: f.sha256,
            preview: f.preview,
        }
    }
}
