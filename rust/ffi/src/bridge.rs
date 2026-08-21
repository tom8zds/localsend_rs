//! FRB API surface: session-based bridge over
//! [`localsend_core::CoreHandle`].
//!
//! One static instance ([`RUNNING_CORE`]) backs the whole app; `setup`
//! replaces it, stopping the previous instance first so hot restarts do
//! not leak a bound port.
//!
//! Stream functions forward `watch` receivers to Dart and exit as soon
//! as the Dart side cancels (a failed `sink.add` means the receive port
//! is gone). Errors before a stream is established are reported through
//! `sink.add_error`; fallible one-shot calls return `anyhow::Result`,
//! which FRB surfaces as a Dart exception.

use std::sync::LazyLock;

use anyhow::{anyhow, Context, Result};
use log::debug;
use tokio::sync::{watch, RwLock};

use crate::{
    actor::{
        core::CoreConfig,
        model::{NodeDevice, SessionEvent, SessionSummary},
    },
    frb_generated::StreamSink,
    logger::{self, LogEntry},
};

static RUNNING_CORE: LazyLock<RwLock<Option<localsend_core::CoreHandle>>> =
    LazyLock::new(|| RwLock::new(None));

async fn get_core() -> Result<localsend_core::CoreHandle> {
    RUNNING_CORE
        .read()
        .await
        .clone()
        .context("core not initialized; call setup first")
}

/// Forward a `watch` receiver to a Dart stream until either side goes
/// away. The current value is emitted immediately, then every change;
/// a failed `sink.add` means the Dart subscription was cancelled.
async fn forward_watch<T, M, F>(mut rx: watch::Receiver<T>, sink: StreamSink<M>, map: F)
where
    T: Clone + Send + Sync,
    M: crate::frb_generated::SseEncode,
    F: Fn(T) -> M,
{
    loop {
        if sink.add(map(rx.borrow_and_update().clone())).is_err() {
            debug!("stream closed by Dart side, stopping forwarder");
            return;
        }
        if rx.changed().await.is_err() {
            debug!("watch sender dropped, stopping forwarder");
            return;
        }
    }
}

// --- lifecycle ---------------------------------------------------------------

pub async fn setup(device: NodeDevice, config: CoreConfig) {
    logger::init_logger(true);
    // A hot restart re-runs Dart `main` while the previous core (and its
    // bound port) is still alive; stop it before replacing.
    let old = RUNNING_CORE.write().await.take();
    if let Some(old) = old {
        debug!("setup: shutting down previous core instance");
        old.shutdown().await;
    }
    let core = localsend_core::CoreHandle::new(device.to_core(), config.to_core());
    *RUNNING_CORE.write().await = Some(core.clone());
    core.start().await;
}

pub async fn start_server() -> Result<()> {
    get_core().await?.start().await;
    Ok(())
}

pub async fn shutdown_server() -> Result<()> {
    get_core().await?.shutdown().await;
    Ok(())
}

pub async fn restart_server() -> Result<()> {
    let core = get_core().await?;
    core.shutdown().await;
    core.start().await;
    Ok(())
}

// --- configuration -------------------------------------------------------------

pub async fn change_path(path: String) -> Result<()> {
    get_core().await?.change_path(path).await;
    Ok(())
}

pub async fn change_config(config: CoreConfig) -> Result<()> {
    get_core().await?.change_config(config.to_core()).await;
    Ok(())
}

// --- discovery -----------------------------------------------------------------

/// Announce this device on the multicast group.
pub async fn announce() -> Result<()> {
    get_core().await?.announce().await;
    Ok(())
}

/// Build a send target directly from an `address[:port]` string, for
/// peers that were never discovered via multicast. A missing port
/// defaults to the LocalSend default (53317).
pub fn manual_device(addr: String) -> Option<NodeDevice> {
    let with_port = if addr.contains(':') {
        addr
    } else {
        format!("{addr}:53317")
    };
    localsend_core::NodeDevice::manual(&with_port).map(Into::into)
}

// --- server observation ----------------------------------------------------------

pub async fn listen_server_state(s: StreamSink<bool>) -> Result<()> {
    let rx = get_core().await?.server_state().await;
    forward_watch(rx, s, |running| running).await;
    Ok(())
}

/// Last server startup error, if any (`None` once the server binds).
pub async fn listen_server_error(s: StreamSink<Option<String>>) -> Result<()> {
    let rx = get_core().await?.server_error();
    forward_watch(rx, s, |err| err).await;
    Ok(())
}

pub async fn listen_device(s: StreamSink<Vec<NodeDevice>>) -> Result<()> {
    let rx = get_core().await?.device.listen().await;
    forward_watch(rx, s, |devices| {
        devices.into_iter().map(Into::into).collect()
    })
    .await;
    Ok(())
}

// --- sessions --------------------------------------------------------------------

/// Low-frequency full snapshot of all sessions (both directions).
pub async fn listen_session_index(s: StreamSink<Vec<SessionSummary>>) -> Result<()> {
    let rx = get_core().await?.session_index().await;
    forward_watch(rx, s, |sessions| {
        sessions.into_iter().map(Into::into).collect()
    })
    .await;
    Ok(())
}

/// Per-session event stream. Unknown session ids are reported on the
/// stream as an error.
pub async fn listen_session(session_id: String, s: StreamSink<SessionEvent>) -> Result<()> {
    let core = get_core().await?;
    let Some(rx) = core.session_events(&session_id).await else {
        let _ = s.add_error(anyhow!("session not found: {session_id}"));
        return Ok(());
    };
    forward_watch(rx, s, Into::into).await;
    Ok(())
}

/// Accept a pending receive session. `file_ids == None` accepts all
/// files; `Some(ids)` accepts only that subset.
pub async fn accept_session(session_id: String, file_ids: Option<Vec<String>>) -> Result<()> {
    get_core()
        .await?
        .accept(&session_id, file_ids)
        .await
        .map_err(|e| anyhow!("{e}"))
}

pub async fn decline_session(session_id: String) -> Result<()> {
    get_core()
        .await?
        .decline(&session_id)
        .await
        .map_err(|e| anyhow!("{e}"))
}

/// Cancel any active session (send or receive).
pub async fn cancel_session(session_id: String) -> Result<()> {
    get_core().await?.cancel(&session_id).await;
    Ok(())
}

// --- sending -----------------------------------------------------------------------

/// Send files to a target device. Returns the new session id
/// immediately; progress is reported through `listen_session_index` /
/// `listen_session`. Sessions to the same target are serialized by the
/// core.
pub async fn send_files(target: NodeDevice, files: Vec<String>) -> Result<String> {
    if files.is_empty() {
        return Err(anyhow!("no files to send"));
    }
    let paths = files.iter().map(std::path::PathBuf::from).collect();
    get_core()
        .await?
        .send_files(target.to_core(), paths)
        .await
        .map_err(|e| anyhow!("{e}"))
}

// --- logging -------------------------------------------------------------------------

pub fn create_log_stream(s: StreamSink<LogEntry>) {
    logger::SendToDartLogger::set_stream_sink(s);
}
