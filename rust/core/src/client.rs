//! LocalSend v2 protocol client (sender side), built on reqwest.

use std::path::Path;

use futures::StreamExt as _;
use log::debug;
use tokio::sync::watch;
use tokio_util::io::ReaderStream;

use crate::model::{FileRequest, FileResponse, NodeAnnounce, NodeDevice};

#[derive(Debug)]
pub enum ClientError {
    Http(reqwest::Error),
    Io(std::io::Error),
    /// The peer answered with a non-success status code.
    Status(u16, String),
}

impl std::fmt::Display for ClientError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ClientError::Http(e) => write!(f, "http error: {e}"),
            ClientError::Io(e) => write!(f, "io error: {e}"),
            ClientError::Status(code, body) => write!(f, "peer answered {code}: {body}"),
        }
    }
}

impl std::error::Error for ClientError {}

impl From<reqwest::Error> for ClientError {
    fn from(e: reqwest::Error) -> Self {
        ClientError::Http(e)
    }
}

impl From<std::io::Error> for ClientError {
    fn from(e: std::io::Error) -> Self {
        ClientError::Io(e)
    }
}

impl ClientError {
    pub fn status(&self) -> Option<u16> {
        match self {
            ClientError::Status(code, _) => Some(*code),
            _ => None,
        }
    }
}

/// Error returned synchronously by
/// [`crate::CoreHandle::send_files`] before the background driver takes
/// over.
#[derive(Debug)]
pub enum SendError {
    Io(std::io::Error),
    EmptySelection,
}

impl std::fmt::Display for SendError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            SendError::Io(e) => write!(f, "io error: {e}"),
            SendError::EmptySelection => write!(f, "no files to send"),
        }
    }
}

impl std::error::Error for SendError {}

impl From<std::io::Error> for SendError {
    fn from(e: std::io::Error) -> Self {
        SendError::Io(e)
    }
}

#[derive(Clone)]
pub struct Client {
    http: reqwest::Client,
}

impl Default for Client {
    fn default() -> Self {
        Self::new()
    }
}

impl Client {
    pub fn new() -> Self {
        let http = reqwest::Client::builder()
            .build()
            .expect("failed to build reqwest client");
        Client { http }
    }

    /// `POST /api/localsend/v2/register`
    pub async fn register(
        &self,
        target: &NodeDevice,
        current: &NodeDevice,
    ) -> Result<(), ClientError> {
        let url = format!("{}/api/localsend/v2/register", target.base_url());
        let announce: NodeAnnounce = current.to_announce();
        let resp = self.http.post(&url).json(&announce).send().await?;
        if resp.status().is_success() {
            debug!("register to {} success", target.base_url());
            Ok(())
        } else {
            Err(ClientError::Status(
                resp.status().as_u16(),
                resp.text().await.unwrap_or_default(),
            ))
        }
    }

    /// `POST /api/localsend/v2/prepare-upload`
    pub async fn prepare_upload(
        &self,
        target: &NodeDevice,
        request: &FileRequest,
    ) -> Result<FileResponse, ClientError> {
        let url = format!("{}/api/localsend/v2/prepare-upload", target.base_url());
        let resp = self.http.post(&url).json(request).send().await?;
        if resp.status().is_success() {
            Ok(resp.json::<FileResponse>().await?)
        } else {
            Err(ClientError::Status(
                resp.status().as_u16(),
                resp.text().await.unwrap_or_default(),
            ))
        }
    }

    /// `POST /api/localsend/v2/upload?sessionId&fileId&token`
    ///
    /// Streams the file body and reports total-bytes-sent through
    /// `progress`.
    pub async fn upload_file(
        &self,
        target: &NodeDevice,
        session_id: &str,
        file_id: &str,
        token: &str,
        path: &Path,
        progress: watch::Sender<usize>,
    ) -> Result<(), ClientError> {
        let url = format!("{}/api/localsend/v2/upload", target.base_url());
        let file = tokio::fs::File::open(path).await?;
        let size = file.metadata().await?.len();

        let mut sent = 0usize;
        let stream = ReaderStream::new(file).map(move |chunk| match chunk {
            Ok(bytes) => {
                sent += bytes.len();
                let _ = progress.send(sent);
                Ok::<_, std::io::Error>(bytes)
            }
            Err(e) => Err(e),
        });

        let resp = self
            .http
            .post(&url)
            .query(&[
                ("sessionId", session_id),
                ("fileId", file_id),
                ("token", token),
            ])
            .header(reqwest::header::CONTENT_LENGTH, size)
            .body(reqwest::Body::wrap_stream(stream))
            .send()
            .await?;

        if resp.status().is_success() {
            Ok(())
        } else {
            Err(ClientError::Status(
                resp.status().as_u16(),
                resp.text().await.unwrap_or_default(),
            ))
        }
    }

    /// `POST /api/localsend/v2/cancel?sessionId=...`
    pub async fn cancel(&self, target: &NodeDevice, session_id: &str) -> Result<(), ClientError> {
        let url = format!("{}/api/localsend/v2/cancel", target.base_url());
        let resp = self
            .http
            .post(&url)
            .query(&[("sessionId", session_id)])
            .send()
            .await?;
        if resp.status().is_success() {
            Ok(())
        } else {
            Err(ClientError::Status(
                resp.status().as_u16(),
                resp.text().await.unwrap_or_default(),
            ))
        }
    }
}
