//! Core library for the LocalSend protocol implementation.
//!
//! Platform-independent business logic: device discovery, the HTTP
//! server/client for the v2 protocol, and multi-session transfer
//! management. Frontends (Flutter via the `rust_lib` ffi crate, or the
//! `localsend-cli` crate) drive it through [`CoreHandle`].

pub mod client;
pub mod config;
pub mod device;
pub mod discovery;
pub mod handle;
pub mod model;
pub mod relay;
pub mod server;
pub mod session;
pub mod util;

pub use client::{Client, ClientError, SendError};
pub use config::CoreConfig;
pub use device::DeviceActorHandle;
pub use handle::{CoreHandle, CoreOptions};
pub use model::{
    FileInfo, FileRequest, FileResponse, FileState, MissionFileInfo, MissionState, NodeAnnounce,
    NodeDevice, SenderInfo, SessionDirection, SessionEvent, SessionSummary, UploadTask,
    PROTOCOL_VERSION,
};
pub use session::{Decision, FileTask, SessionError, SessionHandle, DEFAULT_MAX_RECV_SESSIONS};
