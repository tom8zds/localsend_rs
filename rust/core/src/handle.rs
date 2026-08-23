//! [`CoreHandle`] — the single entry point frontends use to drive the
//! core: server lifecycle, configuration, device list, session
//! decisions, event subscriptions and sending files.

use std::collections::HashMap;
use std::net::SocketAddr;
use std::path::PathBuf;
use std::sync::{Arc, Mutex};

use log::{debug, error, warn};
use tokio::sync::{mpsc, oneshot, watch, Semaphore};
use uuid::Uuid;

use crate::client::{Client, SendError};
use crate::config::CoreConfig;
use crate::device::DeviceActorHandle;
use crate::model::{
    FileInfo, FileRequest, FileState, MissionState, NodeDevice, SenderInfo, SessionEvent,
    SessionSummary,
};
use crate::server::HttpServerHandle;
use crate::session::{SessionError, SessionHandle, DEFAULT_MAX_RECV_SESSIONS};

/// Tuning knobs that are not part of the FRB-exposed [`CoreConfig`].
#[derive(Clone, Debug)]
pub struct CoreOptions {
    /// Whether multicast UDP discovery runs alongside the HTTP server.
    pub enable_discovery: bool,
    /// Maximum concurrent receive sessions (pending + transferring).
    pub max_recv_sessions: usize,
}

impl Default for CoreOptions {
    fn default() -> Self {
        CoreOptions {
            enable_discovery: true,
            max_recv_sessions: DEFAULT_MAX_RECV_SESSIONS,
        }
    }
}

struct AppContext {
    config: CoreConfig,
}

enum CoreMessage {
    GetConfig {
        respond_to: oneshot::Sender<CoreConfig>,
    },
    ChangeConfig {
        new_config: CoreConfig,
        respond_to: oneshot::Sender<()>,
    },
    Start {
        core: CoreHandle,
        respond_to: oneshot::Sender<()>,
    },
    Shutdown {
        respond_to: oneshot::Sender<()>,
    },
    Listen {
        respond_to: oneshot::Sender<watch::Receiver<bool>>,
    },
}

struct CoreActor {
    receiver: mpsc::Receiver<CoreMessage>,
    context: AppContext,
    server: Option<HttpServerHandle>,
    server_state_sender: watch::Sender<bool>,
    server_state_listener: watch::Receiver<bool>,
    server_error_sender: watch::Sender<Option<String>>,
}

impl CoreActor {
    fn new(
        receiver: mpsc::Receiver<CoreMessage>,
        device: NodeDevice,
        mut config: CoreConfig,
        server_error_sender: watch::Sender<Option<String>>,
    ) -> Self {
        let (tx, rx) = watch::channel(false);
        config.port = device.port;
        CoreActor {
            receiver,
            context: AppContext { config },
            server: None,
            server_state_sender: tx,
            server_state_listener: rx,
            server_error_sender,
        }
    }

    async fn handle_message(&mut self, msg: CoreMessage) {
        match msg {
            CoreMessage::GetConfig { respond_to } => {
                let config = self.context.config.clone();
                let _ = respond_to.send(config);
            }
            CoreMessage::ChangeConfig {
                new_config,
                respond_to,
            } => {
                self.context.config = new_config;
                let _ = respond_to.send(());
            }
            CoreMessage::Start { core, respond_to } => {
                if let Some(server) = self.server.take() {
                    server.shutdown().await;
                }

                // Relay rendezvous: heartbeat our identity to the
                // configured relay and merge the online device list
                // back — the only discovery channel that works across
                // networks.
                {
                    let core = core.clone();
                    tokio::spawn(async move {
                        let mut tick = tokio::time::interval(std::time::Duration::from_secs(30));
                        loop {
                            tick.tick().await;
                            relay_discovery(&core).await;
                        }
                    });
                }

                // Bridge listener: peers behind NAT reach us through
                // the relay's splice.
                {
                    let core = core.clone();
                    tokio::spawn(async move {
                        maintain_bridge_listener(&core).await;
                    });
                }

                // Periodic self-announce lives in the core so every
                // frontend (CLI, FFI, future ones) gets continuous
                // discovery; a single reactive discovery actor never
                // breaks the silence between two localsend_rs peers.
                let ticker_core = core.clone();
                tokio::spawn(async move {
                    let mut state = ticker_core.server_state().await;
                    let mut tick = tokio::time::interval(std::time::Duration::from_secs(5));
                    loop {
                        tokio::select! {
                            _ = tick.tick() => ticker_core.announce().await,
                            _ = state.changed() => {
                                if !*state.borrow() {
                                    // server stopped (shutdown or hot
                                    // restart) — stop announcing too
                                    break;
                                }
                            }
                        }
                    }
                });

                // Advertise the real scheme: clients (official app
                // included) pick plaintext vs TLS from this field.
                {
                    let mut current = core.device.get_current_device().await;
                    let tls = core
                        .tls()
                        .filter(|_| !self.context.config.allow_plain_tls.unwrap_or(false));
                    // LocalSend v2.2: with HTTPS the announced
                    // fingerprint IS the SHA-256 of the certificate —
                    // peers use it to trust us without a CA. Plain
                    // HTTP keeps the random device identity.
                    if let Some(tls) = tls {
                        current.protocol = "https".to_string();
                        current.fingerprint = tls.identity.fingerprint.clone();
                    } else {
                        current.protocol = "http".to_string();
                    }
                    core.device.set_current_device(current).await;
                }

                let mut handle = HttpServerHandle::new(core.clone(), self.context.config.clone());
                match handle.wait_bound().await {
                    Ok(port) => {
                        if port != self.context.config.port {
                            debug!("bound on fallback port {port}");
                            self.context.config.port = port;
                            let mut current = core.device.get_current_device().await;
                            current.port = port;
                            core.device.set_current_device(current).await;
                        }
                        let _ = self.server_error_sender.send(None);
                        let _ = self.server_state_sender.send(true);
                    }
                    Err(e) => {
                        error!("http server failed to start: {e}");
                        let _ = self.server_error_sender.send(Some(e));
                        let _ = self.server_state_sender.send(false);
                    }
                }
                self.server.replace(handle);
                let _ = respond_to.send(());
            }
            CoreMessage::Shutdown { respond_to } => {
                let handler = self.server.take();
                if let Some(handler) = handler {
                    handler.shutdown().await;
                } else {
                    debug!("server not started")
                }
                let _ = respond_to.send(());
                let _ = self.server_state_sender.send(false);
            }
            CoreMessage::Listen { respond_to } => {
                let _ = respond_to.send(self.server_state_listener.clone());
            }
        }
    }
}

async fn run_context_actor(mut actor: CoreActor) {
    while let Some(msg) = actor.receiver.recv().await {
        actor.handle_message(msg).await;
    }
}

/// Process-wide TLS material (identity + peer pins), initialized
/// when the config carries an identity dir.
pub struct TlsContext {
    pub identity: crate::relay::identity::DeviceIdentity,
    pub tofu: std::sync::Arc<crate::relay::tls::TofuStore>,
}

struct CoreInner {
    sender: mpsc::Sender<CoreMessage>,
    sessions: SessionHandle,
    client: Client,
    options: CoreOptions,
    tls: Option<TlsContext>,
    quic: tokio::sync::Mutex<Option<std::sync::Arc<crate::relay::quic::QuicTransport>>>,
    server_error_rx: watch::Receiver<Option<String>>,
    /// Serializes send sessions per target device (fingerprint or
    /// `address:port` for manual targets). Different targets run
    /// concurrently.
    target_locks: Mutex<HashMap<String, Arc<Semaphore>>>,
}

/// Clone-cheap handle to a running core. All state lives in
/// background actors; cloning only clones channel senders and `Arc`s.
#[derive(Clone)]
pub struct CoreHandle {
    inner: Arc<CoreInner>,
    pub device: DeviceActorHandle,
}

impl CoreHandle {
    pub fn new(device: NodeDevice, config: CoreConfig) -> Self {
        Self::with_options(device, config, CoreOptions::default())
    }

    pub fn with_options(device: NodeDevice, config: CoreConfig, options: CoreOptions) -> Self {
        let (server_error_tx, server_error_rx) = watch::channel(None);

        let tls = config.identity_dir.as_deref().and_then(|dir| {
            match crate::relay::identity::DeviceIdentity::load_or_create(std::path::Path::new(dir))
            {
                Ok(identity) => {
                    let tofu = crate::relay::tls::TofuStore::load(
                        std::path::Path::new(dir).join("pinned-peers.json"),
                    )
                    .ok()?;
                    Some(TlsContext {
                        identity,
                        tofu: std::sync::Arc::new(tofu),
                    })
                }
                Err(e) => {
                    log::warn!("tls identity unavailable, staying on plain http: {e}");
                    None
                }
            }
        });

        let (sender, receiver) = mpsc::channel(8);
        let actor = CoreActor::new(receiver, device.clone(), config, server_error_tx);
        tokio::spawn(run_context_actor(actor));

        let device = DeviceActorHandle::new(device);
        let sessions = SessionHandle::new(options.max_recv_sessions);

        Self {
            inner: Arc::new(CoreInner {
                sender,
                sessions,
                client: Client::new(),
                options,
                tls,
                quic: tokio::sync::Mutex::new(None),
                server_error_rx,
                target_locks: Mutex::new(HashMap::new()),
            }),
            device,
        }
    }

    pub(crate) fn options(&self) -> &CoreOptions {
        &self.inner.options
    }

    /// Probe the configured relay with a STUN binding request.
    /// Returns the round-trip time in milliseconds.
    pub async fn relay_ping(&self) -> Result<u64, String> {
        let settings = self
            .get_config()
            .await
            .relay_settings()
            .ok_or_else(|| "no relay configured".to_string())?;
        let rt = crate::relay::ping(&settings.addr)
            .await
            .map_err(|e| e.to_string())?;
        Ok(rt.as_millis() as u64)
    }

    /// TLS material when the device identity is configured.
    pub(crate) fn tls(&self) -> Option<&TlsContext> {
        self.inner.tls.as_ref()
    }

    /// Our advertised hole-punch candidates (reflexive + locals with
    /// the QUIC port). Used by both sides of the exchange.
    pub async fn our_candidates(&self) -> Vec<String> {
        self.hole_punch_candidates(Vec::new()).await
    }

    /// Hole-punch exchange: given the peer's UDP candidates, return
    /// ours (reflexive address via the relay + all local IPv4s) and
    /// make sure our QUIC endpoint is listening and punching toward
    /// the peer's candidates.
    pub async fn hole_punch_candidates(&self, peer_candidates: Vec<String>) -> Vec<String> {
        let mut out = Vec::new();

        // Reflexive address via the configured relay, when present.
        if let Some(relay) = self.get_config().await.relay_settings() {
            let probed = tokio::time::timeout(
                std::time::Duration::from_secs(2),
                crate::relay::probe(&relay.addr),
            )
            .await;
            if let Ok(Ok((_, Some(mapped)))) = probed {
                out.push(mapped.to_string());
            }
        }

        // All local IPv4 candidates.
        if let Ok(ifs) = if_addrs::get_if_addrs() {
            for i in ifs {
                if let std::net::IpAddr::V4(v4) = i.ip() {
                    out.push(SocketAddr::new(std::net::IpAddr::V4(v4), 0).to_string());
                }
            }
        }

        // Start / reuse the QUIC endpoint and punch toward the peer.
        if let Some(tls) = self.tls() {
            let quic = self.ensure_quic(tls).await;
            for cand in &peer_candidates {
                if let Ok(addr) = cand.parse::<SocketAddr>() {
                    let quic = quic.clone();
                    tokio::spawn(async move {
                        // Punch: an unanswered connect attempt still
                        // sends Initial packets that open our NAT for
                        // the peer's return traffic.
                        let _ = tokio::time::timeout(
                            std::time::Duration::from_secs(8),
                            quic.connect(addr),
                        )
                        .await;
                    });
                }
            }
        }

        // Advertise the QUIC socket's real port (it was bound on :0).
        if let Some(q) = self.inner.quic.lock().await.as_ref() {
            if let Ok(addr) = q.local_addr() {
                // Replace the :0 placeholders with the real port.
                let port = addr.port();
                out = out
                    .into_iter()
                    .map(|c| c.replace(":0", &format!(":{port}")))
                    .collect();
            }
        }
        out
    }

    /// The process-wide QUIC endpoint (lazily bound).
    async fn ensure_quic(
        &self,
        tls: &TlsContext,
    ) -> std::sync::Arc<crate::relay::quic::QuicTransport> {
        let mut guard = self.inner.quic.lock().await;
        if let Some(q) = guard.as_ref() {
            return q.clone();
        }
        let quic = std::sync::Arc::new(
            crate::relay::quic::QuicTransport::new(
                SocketAddr::from(([0, 0, 0, 0], 0)),
                &tls.identity,
                tls.tofu.clone(),
                "any",
                None,
            )
            .expect("bind quic"),
        );
        *guard = Some(quic.clone());

        // Serve HTTP on every peer connection punching toward us —
        // without an accept loop the handshakes are never answered.
        {
            let quic = quic.clone();
            let core = self.clone();
            tokio::spawn(async move {
                loop {
                    if let Some(conn) = quic.accept().await {
                        let router = crate::server::app(core.clone());
                        tokio::spawn(async move {
                            crate::relay::quic::serve_http_on(conn, router).await;
                        });
                    }
                }
            });
        }
        quic
    }

    pub(crate) fn sessions(&self) -> &SessionHandle {
        &self.inner.sessions
    }

    // --- server lifecycle ------------------------------------------------

    pub async fn start(&self) {
        let (send, recv) = oneshot::channel();
        let msg = CoreMessage::Start {
            core: self.clone(),
            respond_to: send,
        };
        let _ = self.inner.sender.send(msg).await;
        recv.await.expect("Actor task has been killed");
        self.device.clear_devices().await;
    }

    pub async fn shutdown(&self) {
        let (send, recv) = oneshot::channel();
        let msg = CoreMessage::Shutdown { respond_to: send };
        let _ = self.inner.sender.send(msg).await;
        recv.await.expect("Actor task has been killed");
        self.device.clear_devices().await;
    }

    /// Whether the HTTP server is currently running.
    pub async fn server_state(&self) -> watch::Receiver<bool> {
        let (send, recv) = oneshot::channel();
        let msg = CoreMessage::Listen { respond_to: send };
        let _ = self.inner.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }

    /// Last server startup error, if any (e.g. no free port).
    pub fn server_error(&self) -> watch::Receiver<Option<String>> {
        self.inner.server_error_rx.clone()
    }

    // --- configuration ----------------------------------------------------

    pub async fn get_config(&self) -> CoreConfig {
        let (send, recv) = oneshot::channel();
        let msg = CoreMessage::GetConfig { respond_to: send };
        let _ = self.inner.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn change_port(&self, port: u16) {
        let mut value = self.get_config().await;
        value.port = port;
        self.change_config(value).await;
    }

    pub async fn change_path(&self, path: String) {
        let mut value = self.get_config().await;
        value.store_path = path;
        self.change_config(value).await;
    }

    pub async fn change_config(&self, config: CoreConfig) {
        let (send, recv) = oneshot::channel();
        let msg = CoreMessage::ChangeConfig {
            new_config: config.clone(),
            respond_to: send,
        };

        let mut current = self.device.get_current_device().await;
        current.port = config.port;
        self.device.set_current_device(current).await;

        let _ = self.inner.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }

    // --- discovery ---------------------------------------------------------

    /// Announce this device on the multicast group.
    pub async fn announce(&self) {
        let config = self.get_config().await;
        let current = self.device.get_current_device().await;
        let message = serde_json::to_string(&current.to_announce()).unwrap_or_default();
        // Announcing must NOT touch the device map — the periodic
        // ticker calls this every few seconds and clearing here
        // wiped the peer list (and repopulated it via the peer's
        // next register), which is exactly the observed list
        // flicker.
        tokio::spawn(async move {
            crate::discovery::announce(&config, &message).await;
        });
    }

    // --- session decisions --------------------------------------------------

    /// Accept a pending receive session. `file_ids == None` accepts all
    /// files; `Some(ids)` accepts only that subset.
    pub async fn accept(
        &self,
        session_id: &str,
        file_ids: Option<Vec<String>>,
    ) -> Result<(), SessionError> {
        self.inner.sessions.accept(session_id, file_ids).await
    }

    pub async fn decline(&self, session_id: &str) -> Result<(), SessionError> {
        self.inner.sessions.decline(session_id).await
    }

    /// Cancel any active session (send or receive).
    pub async fn cancel(&self, session_id: &str) {
        self.inner.sessions.cancel(session_id).await
    }

    // --- session observation -------------------------------------------------

    /// Low-frequency full snapshot of all sessions.
    pub async fn session_index(&self) -> watch::Receiver<Vec<SessionSummary>> {
        self.inner.sessions.session_index().await
    }

    /// Per-session event stream. `None` if the session is unknown.
    pub async fn session_events(&self, session_id: &str) -> Option<watch::Receiver<SessionEvent>> {
        self.inner.sessions.session_events(session_id).await
    }

    // --- sending --------------------------------------------------------------

    fn target_lock(&self, target: &NodeDevice) -> Arc<Semaphore> {
        let key = if target.fingerprint.is_empty() {
            format!("{}:{}", target.address, target.port)
        } else {
            target.fingerprint.clone()
        };
        let mut locks = self.inner.target_locks.lock().unwrap();
        locks
            .entry(key)
            .or_insert_with(|| Arc::new(Semaphore::new(1)))
            .clone()
    }

    /// Send files to a target device.
    ///
    /// Returns the new session id immediately; the transfer runs in the
    /// background and reports through [`CoreHandle::session_events`] /
    /// [`CoreHandle::session_index`]. Sessions to the same target are
    /// serialized; different targets transfer concurrently.
    ///
    /// The target may be constructed manually with
    /// [`NodeDevice::manual`] when it was not discovered.
    pub async fn send_files(
        &self,
        target: NodeDevice,
        files: Vec<PathBuf>,
    ) -> Result<String, SendError> {
        self.send_files_internal(target, files, false).await
    }

    /// [`CoreHandle::send_files`] with an explicit route: `true`
    /// skips the direct attempt and tunnels through the configured
    /// relay from the start.
    pub async fn send_files_via(
        &self,
        target: NodeDevice,
        files: Vec<PathBuf>,
        via_relay: bool,
    ) -> Result<String, SendError> {
        self.send_files_internal(target, files, via_relay).await
    }

    async fn send_files_internal(
        &self,
        target: NodeDevice,
        files: Vec<PathBuf>,
        force_relay: bool,
    ) -> Result<String, SendError> {
        if files.is_empty() {
            return Err(SendError::EmptySelection);
        }

        let mut entries = Vec::with_capacity(files.len());
        for path in &files {
            let meta = std::fs::metadata(path)?;
            let file_name = path
                .file_name()
                .map(|n| n.to_string_lossy().to_string())
                .unwrap_or_else(|| "file".to_string());
            let file_type = path
                .extension()
                .map(|e| e.to_string_lossy().to_lowercase())
                .unwrap_or_else(|| "application/octet-stream".to_string());
            let id = Uuid::new_v4().to_string();
            entries.push((
                id.clone(),
                FileInfo {
                    id,
                    file_name,
                    size: meta.len() as i64,
                    file_type,
                    sha256: None,
                    preview: None,
                },
            ));
        }

        let session_id = self
            .inner
            .sessions
            .create_send_session(target.clone(), entries.clone())
            .await;

        let core = self.clone();
        let lock = self.target_lock(&target);
        let driver_session = session_id.clone();
        tokio::spawn(async move {
            run_send_driver(
                core,
                driver_session,
                target,
                files,
                entries,
                lock,
                force_relay,
            )
            .await;
        });

        Ok(session_id)
    }
}

/// Try a QUIC hole punch toward the peer: exchange candidates via
/// the peer's HTTP endpoint over the existing (possibly relayed)
/// TCP path, then race QUIC connects toward every peer candidate —
/// the first success is the punched hole. None = fall back.
async fn try_hole_punch(
    core: &CoreHandle,
    peer: SocketAddr,
    peer_is_https: bool,
) -> Result<Option<quinn::Connection>, String> {
    let Some(tls) = core.tls() else {
        return Ok(None);
    };
    let quic = core.ensure_quic(tls).await;

    let our_candidates = core.our_candidates().await;
    // The exchange rides the peer's advertised scheme. HTTPS peers
    // are reached through a short-lived TLS bridge (TOFU config, no
    // relay) — reqwest itself has no TLS backend here.
    let port = if peer_is_https {
        let Some(tls) = core.tls() else {
            return Ok(None);
        };
        let client_cfg = crate::relay::tls::tofu_client_config(
            tls.tofu.clone(),
            "hole-punch-exchange",
            None,
            Some((
                tls.identity.cert_der.as_slice(),
                tls.identity.key_der.as_slice(),
            )),
        );
        crate::relay::spawn_tls_bridge(client_cfg, peer, None)
            .await
            .map_err(|e| format!("exchange bridge: {e}"))?
    } else {
        peer.port()
    };
    let url = format!("http://127.0.0.1:{port}/api/localsend/v2/hole-punch");
    let client = reqwest::Client::new();
    let resp = client
        .post(&url)
        .json(&serde_json::json!({ "candidates": our_candidates }))
        .timeout(std::time::Duration::from_secs(10))
        .send()
        .await
        .map_err(|e| format!("hole-punch exchange: {e}"))?;
    let body: serde_json::Value = resp.json().await.map_err(|e| e.to_string())?;
    let peers: Vec<String> = body
        .get("candidates")
        .and_then(|c| c.as_array())
        .map(|a| {
            a.iter()
                .filter_map(|v| v.as_str().map(String::from))
                .collect()
        })
        .unwrap_or_default();

    let mut attempts: Vec<_> = peers
        .iter()
        .filter_map(|c| c.parse::<SocketAddr>().ok())
        .map(|addr| Box::pin(quic.connect(addr)))
        .collect();
    if attempts.is_empty() {
        return Ok(None);
    }
    // First successful connect wins; consume losers to keep them from
    // lingering.
    // First successful connect wins; each attempt is individually
    // bounded so dead candidates cannot stall the race.
    let overall = tokio::time::timeout(std::time::Duration::from_secs(5), async {
        while !attempts.is_empty() {
            let (res, _idx, remaining) = futures::future::select_all(attempts).await;
            attempts = remaining;
            if let Ok(conn) = res {
                return Some(conn);
            }
        }
        None
    })
    .await
    .unwrap_or(None);
    Ok(overall)
}

/// One relay-rendezvous cycle: mint fresh REST credentials, POST our
/// identity to the relay's discovery endpoint, merge the returned
/// device list into the local table (marking them reachable).
async fn relay_discovery(core: &CoreHandle) {
    let Some(relay) = core.get_config().await.relay_settings() else {
        return;
    };
    let Some(tls_fp) = core.tls().map(|t| t.identity.fingerprint.clone()) else {
        return;
    };

    let expiry = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
        + 120; // short-lived: regenerated every heartbeat
    let (username, password) =
        crate::relay::generate_credentials(&relay.secret, expiry, "discovery");

    let current = core.device.get_current_device().await;

    // STUN-probe our own reflexive address first: the local listen
    // port is NOT the port the NAT maps for outbound traffic. A peer
    // discovered via this registry needs the NAT-mapped port, or
    // TURN Connect to our public address always fails.
    let (our_port, mapped_addr) = match tokio::time::timeout(
        std::time::Duration::from_secs(3),
        crate::relay::probe(&relay.addr),
    )
    .await
    {
        Ok(Ok((_, Some(mapped)))) => {
            let port = mapped.port();
            (port, Some(mapped.to_string()))
        }
        _ => (current.port, None),
    };

    let payload = serde_json::json!({
        "fingerprint": current.fingerprint,
        "alias": current.alias,
        "deviceModel": current.device_model,
        "deviceType": current.device_type,
        "protocol": current.protocol,
        "port": our_port,
        "username": username,
        "candidates": if let Some(m) = mapped_addr {
            vec![m]
        } else {
            vec![]
        },
    });

    let url = format!("http://{}/api/discovery/register", relay.addr);
    let client = reqwest::Client::new();
    let Ok(resp) = client
        .post(&url)
        .header("Authorization", format!("Bearer {password}"))
        .json(&payload)
        .timeout(std::time::Duration::from_secs(10))
        .send()
        .await
    else {
        log::debug!("relay discovery heartbeat failed");
        return;
    };
    let Ok(body) = resp.json::<serde_json::Value>().await else {
        return;
    };

    // Merge the returned list (skip ourselves).
    if let Some(list) = body.as_array() {
        for dev in list {
            let fp = dev
                .get("fingerprint")
                .and_then(|v| v.as_str())
                .unwrap_or("");
            if fp.is_empty() || fp == current.fingerprint {
                continue;
            }
            // A pre-TLS heartbeat may have registered a random-UUID
            // self entry; also skip if the alias matches ours.
            let alias = dev.get("alias").and_then(|v| v.as_str()).unwrap_or("");
            if !alias.is_empty() && alias == current.alias {
                continue;
            }
            let peer = crate::model::NodeDevice {
                alias: dev
                    .get("alias")
                    .and_then(|v| v.as_str())
                    .unwrap_or("?")
                    .to_string(),
                version: "2.2".to_string(),
                device_model: dev
                    .get("deviceModel")
                    .and_then(|v| v.as_str())
                    .unwrap_or("")
                    .to_string(),
                device_type: dev
                    .get("deviceType")
                    .and_then(|v| v.as_str())
                    .unwrap_or("")
                    .to_string(),
                fingerprint: fp.to_string(),
                address: dev
                    .get("address")
                    .and_then(|v| v.as_str())
                    .unwrap_or("")
                    .to_string(),
                port: dev.get("port").and_then(|v| v.as_u64()).unwrap_or(53317) as u16,
                protocol: dev
                    .get("protocol")
                    .and_then(|v| v.as_str())
                    .unwrap_or("https")
                    .to_string(),
                download: true,
                announcement: true,
                announce: true,
            };
            let _ = tls_fp;
            core.device.add_node_device(peer).await;
        }
    }
}

/// Maintain a persistent BRIDGE LISTEN connection to the relay.
/// When a sender pairs with us, the relay splices their tunnel to
/// our listener; we then proxy the tunnel to our own HTTP server.
async fn maintain_bridge_listener(core: &CoreHandle) {
    loop {
        let Some(relay) = core.get_config().await.relay_settings() else {
            tokio::time::sleep(std::time::Duration::from_secs(30)).await;
            continue;
        };
        let current = core.device.get_current_device().await;
        let fingerprint = current.fingerprint.clone();
        let port = core.get_config().await.port;

        let addr: SocketAddr = match relay.addr.parse() {
            Ok(a) => a,
            Err(_) => match tokio::net::lookup_host(&relay.addr).await {
                Ok(mut it) => it
                    .next()
                    .unwrap_or_else(|| SocketAddr::from(([127, 0, 0, 1], 3478))),
                Err(_) => {
                    tokio::time::sleep(std::time::Duration::from_secs(30)).await;
                    continue;
                }
            },
        };

        let Ok(mut conn) = tokio::net::TcpStream::connect(addr).await else {
            tokio::time::sleep(std::time::Duration::from_secs(15)).await;
            continue;
        };
        let _ = conn.set_nodelay(true);

        let mut header = String::from("BRIDGE LISTEN ");
        header.push_str(&fingerprint);
        header.push(char::from(10));
        if tokio::io::AsyncWriteExt::write_all(&mut conn, header.as_bytes())
            .await
            .is_err()
        {
            tokio::time::sleep(std::time::Duration::from_secs(15)).await;
            continue;
        }
        log::debug!("bridge listener registered on relay {}", relay.addr);

        let Ok(mut local) =
            tokio::net::TcpStream::connect(SocketAddr::from(([127, 0, 0, 1], port))).await
        else {
            tokio::time::sleep(std::time::Duration::from_secs(15)).await;
            continue;
        };
        let _ = local.set_nodelay(true);
        let _ = tokio::io::copy_bidirectional(&mut conn, &mut local).await;

        // Tunnel closed — reconnect immediately (the sender may
        // dial a fresh bridge for the very next request).
        tokio::time::sleep(std::time::Duration::from_millis(100)).await;
    }
}

/// Dial a relay bridge to `target_fingerprint`.
pub(crate) async fn dial_bridge(
    relay_addr: &str,
    target_fingerprint: &str,
) -> Result<tokio::net::TcpStream, String> {
    // Returns the raw tunnel stream on success.
    let addr: SocketAddr = relay_addr
        .parse::<SocketAddr>()
        .map_err(|e: std::net::AddrParseError| e.to_string())?;
    let mut conn = tokio::net::TcpStream::connect(addr)
        .await
        .map_err(|e| format!("bridge connect: {e}"))?;
    let _ = conn.set_nodelay(true);
    let mut header = String::from("BRIDGE CONNECT ");
    header.push_str(target_fingerprint);
    header.push(char::from(10));
    tokio::io::AsyncWriteExt::write_all(&mut conn, header.as_bytes())
        .await
        .map_err(|e| e.to_string())?;
    Ok(conn)
}

/// Local plaintext port pumping into a raw tunnel stream.
async fn spawn_raw_bridge(relay_addr: String, target_fingerprint: String) -> u16 {
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0")
        .await
        .expect("bind raw bridge");
    let port = listener.local_addr().expect("raw bridge addr").port();
    tokio::spawn(async move {
        // Each local HTTP connection gets a FRESH bridge tunnel. The
        // relay tears down the splice after each request (HTTP
        // connection:close), so a shared tunnel only survives the
        // first request.
        while let Ok((mut incoming, _)) = listener.accept().await {
            let addr = relay_addr.clone();
            let fp = target_fingerprint.clone();
            tokio::spawn(async move {
                // The receiver may still be reconnecting its listener
                // after a previous splice — retry briefly.
                for _ in 0..10 {
                    match dial_bridge(&addr, &fp).await {
                        Ok(mut tunnel) => {
                            let _ = tokio::io::copy_bidirectional(&mut incoming, &mut tunnel).await;
                            return;
                        }
                        Err(_) => {
                            tokio::time::sleep(std::time::Duration::from_millis(200)).await;
                        }
                    }
                }
            });
        }
    });
    port
}

/// True for RFC-1918/loopback/link-local addresses — peers on those
/// are reachable directly on the LAN.
fn is_private_or_lan(addr: &str) -> bool {
    addr.starts_with("127.")
        || addr.starts_with("10.")
        || addr.starts_with("192.168.")
        || addr.starts_with("169.254.")
        || addr.starts_with("0.0.0.0")
        || (addr.starts_with("172.")
            && addr
                .split('.')
                .nth(1)
                .and_then(|o| o.parse::<u8>().ok())
                .map(|o| (16..=31).contains(&o))
                .unwrap_or(false))
}

/// Resolve the transport route for `target` and return the local
/// view the HTTP client should dial:
///
/// - TLS configured (and not disabled): a TLS bridge, itself riding
///   the relay when one is given — TLS stays strictly endpoint to
///   endpoint, the relay is a byte pipe.
/// - No TLS: plain target, or a relay bridge when a relay is given.
async fn route_transport(
    core: &CoreHandle,
    settings: Option<&crate::relay::RelaySettings>,
    target: &NodeDevice,
    use_relay: bool,
    session_id: Option<&str>,
) -> Result<NodeDevice, String> {
    let addr = format!("{}:{}", target.address, target.port);
    // XOR-PEER-ADDRESS carries a literal IP only; resolve hostnames
    // (docker service names, mDNS names) before dialing.
    let sock: std::net::SocketAddr = match addr.parse() {
        Ok(s) => s,
        Err(_) => match tokio::net::lookup_host(&addr).await {
            Ok(mut it) => it
                .next()
                .ok_or_else(|| format!("cannot resolve target {addr}"))?,
            Err(e) => return Err(format!("cannot resolve target {addr}: {e}")),
        },
    };

    let relay_endpoint = match (use_relay, settings) {
        (true, Some(s)) => Some(crate::relay::endpoint_from_secret(
            &s.addr,
            &s.secret,
            600,
            "localsend",
            &s.realm,
        )),
        _ => None,
    };

    // STUN hole punch: exchange candidates through the peer's HTTP
    // endpoint over the (possibly relayed) TCP path, then try QUIC
    // direct. Only attempted on the cross-network path.
    let peer_https = target.protocol.eq_ignore_ascii_case("https");
    // Relay-discovered peer (public IP): use the bidirectional bridge
    // — both peers connect OUT to the relay, which splices them. This
    // is the only path that works when both peers are behind NAT.
    if let Some(settings) = settings {
        if !is_private_or_lan(&target.address) {
            match dial_bridge(&settings.addr, &target.fingerprint).await {
                Ok(_) => {
                    debug!(
                        "send routed via relay bridge to {} ({})",
                        target.alias, target.fingerprint
                    );
                    if let Some(id) = session_id {
                        core.sessions().mark_route(id, "turn").await;
                    }
                    let port =
                        spawn_raw_bridge(settings.addr.clone(), target.fingerprint.clone()).await;
                    return Ok(crate::relay::bridged_view(target, port));
                }
                Err(e) => debug!("bridge dial failed, trying hole punch: {e}"),
            }
        }
    }
    if relay_endpoint.is_some() {
        match try_hole_punch(core, sock, peer_https).await {
            Ok(Some(quic_conn)) => {
                debug!("send routed via stun (QUIC hole punch) to {sock}");
                if let Some(id) = session_id {
                    core.sessions().mark_route(id, "stun").await;
                }
                let port = crate::relay::spawn_quic_bridge(quic_conn).await;
                return Ok(crate::relay::bridged_view(target, port));
            }
            other => debug!("hole punch did not connect: {other:?}"),
        }
    }

    // Negotiate: peers advertising https (our own with TLS on) get
    // the TLS bridge; peers advertising http — notably the official
    // LocalSend app — get plaintext, direct or relayed.
    let tls_disabled = core.get_config().await.allow_plain_tls.unwrap_or(false);
    let tls = if tls_disabled || !peer_https {
        None
    } else {
        core.tls()
    };

    let (port, route) = match (&tls, relay_endpoint) {
        (Some(tls), relay) => {
            // Peers discovered via announce carry the certificate
            // hash in their fingerprint (v2.2); manual targets have
            // no announce to anchor on and stay pure TOFU.
            let expected = target
                .fingerprint
                .strip_prefix("manual-")
                .map(|_| None)
                .unwrap_or_else(|| Some(target.fingerprint.clone()));
            let client = crate::relay::tls::tofu_client_config(
                tls.tofu.clone(),
                &target.fingerprint,
                expected.as_deref(),
                Some((
                    tls.identity.cert_der.as_slice(),
                    tls.identity.key_der.as_slice(),
                )),
            );
            let via_relay = relay.is_some();
            let port = crate::relay::spawn_tls_bridge(client, sock, relay)
                .await
                .map_err(|e| format!("tls bridge failed: {e}"))?;
            (port, if via_relay { "tls+relay" } else { "tls" })
        }
        (None, Some(_)) => {
            // relay_endpoint only exists when settings are present
            let settings = settings.expect("relay settings");
            let port = crate::relay::spawn_bridge(settings, sock)
                .await
                .map_err(|e| format!("relay bridge failed: {e}"))?;
            (port, "relay")
        }
        (None, None) => return Ok(target.clone()),
    };
    debug!("send routed via {route} to {sock} (bridge 127.0.0.1:{port})");
    Ok(crate::relay::bridged_view(target, port))
}

/// Drives one send session: register -> prepare -> upload each file ->
/// finish/fail. All state changes go through the session manager.
///
/// Routing: with `force_relay` the session tunnels through the
/// configured relay from the start; otherwise a direct connection is
/// attempted first and a transport-level failure falls back to the
/// relay (when one is configured). Peer refusals (403/409) are
/// answers, not outages — they never trigger the fallback.
async fn run_send_driver(
    core: CoreHandle,
    session_id: String,
    mut target: NodeDevice,
    files: Vec<PathBuf>,
    entries: Vec<(String, FileInfo)>,
    lock: Arc<Semaphore>,
    force_relay: bool,
) {
    let sessions = core.sessions().clone();
    let client = core.inner.client.clone();

    // Queue behind other sessions targeting the same device.
    debug!("send driver {session_id} waiting for target lock");
    let _permit = lock.acquire().await;
    debug!("send driver {session_id} acquired target lock");

    let cancel = sessions.cancel_token(&session_id).await;
    let Some(cancel) = cancel else {
        return;
    };

    macro_rules! bail {
        ($reason:expr) => {{
            sessions.fail(&session_id, $reason).await;
            return;
        }};
    }

    // Best-effort register so the peer knows us; failure is not fatal.
    let current = core.device.get_current_device().await;
    let relay_settings = core.get_config().await.relay_settings();
    let mut direct_bridge_target: Option<NodeDevice> = None;

    if force_relay {
        if relay_settings.is_none() {
            bail!("via-relay requested but no relay is configured".to_string());
        }
        match route_transport(
            &core,
            relay_settings.as_ref(),
            &target,
            true,
            Some(&session_id),
        )
        .await
        {
            Ok(bridged) => {
                // mark_route("stun") may already have been set by a
                // successful punch inside route_transport; only mark
                // turn when it wasn't.
                let already_stun = sessions
                    .session_index()
                    .await
                    .borrow()
                    .iter()
                    .find(|s| s.id == session_id)
                    .map(|s| s.route == "stun")
                    .unwrap_or(false);
                if !already_stun {
                    sessions.mark_via_relay(&session_id).await;
                }
                target = bridged;
            }
            Err(reason) => bail!(reason),
        }
    } else {
        // TLS mode has no plaintext leg: even a direct send rides a
        // TLS bridge (the relay, when used, stacks underneath).
        let tls_on = core.tls().is_some()
            && !core.get_config().await.allow_plain_tls.unwrap_or(false)
            && target.protocol.eq_ignore_ascii_case("https");
        // Relay-discovered peers sit behind NAT: a direct TCP attempt
        // always burns the 3s timeout. Go straight to the relay path
        // (the peer's 30s heartbeat keeps the NAT mapping alive, so
        // the TURN Connect can reach it).
        let is_relay_discovered = relay_settings.is_some() && !is_private_or_lan(&target.address);
        if tls_on && !is_relay_discovered {
            match route_transport(&core, relay_settings.as_ref(), &target, false, None).await {
                Ok(bridged) => {
                    // Keep the pristine target: if this bridge fails we
                    // must fall back against the real peer, not the
                    // bridge address.
                    direct_bridge_target = Some(target);
                    target = bridged;
                }
                Err(reason) => bail!(reason),
            }
        }
    }

    if let Err(e) = client.register(&target, &current).await {
        warn!("register before send failed: {e}");
    }

    let request = FileRequest {
        info: SenderInfo::from_device(&current),
        files: entries.iter().cloned().collect(),
    };

    let mut prepared = tokio::select! {
        res = client.prepare_upload(&target, &request) => res,
        _ = cancel.cancelled() => return,
    };

    // Transport-level failure on the direct route: try the relay
    // once before declaring the session dead.
    if !force_relay
        && prepared.is_err()
        && !matches!(prepared, Err(crate::client::ClientError::Status(..)))
    {
        if let Some(settings) = &relay_settings {
            warn!(
                "direct prepare failed ({}), falling back to relay",
                prepared
                    .as_ref()
                    .err()
                    .map(|e| e.to_string())
                    .unwrap_or_default()
            );
            let pristine = direct_bridge_target
                .clone()
                .unwrap_or_else(|| target.clone());
            match route_transport(&core, Some(settings), &pristine, true, Some(&session_id)).await {
                Ok(bridged) => {
                    sessions.mark_via_relay(&session_id).await;
                    target = bridged;
                    let _ = client.register(&target, &current).await;
                    prepared = tokio::select! {
                        res = client.prepare_upload(&target, &request) => res,
                        _ = cancel.cancelled() => return,
                    };
                }
                Err(reason) => bail!(reason),
            }
        }
    }

    let response = match prepared {
        Ok(r) => r,
        Err(e) => {
            let reason = match e.status() {
                Some(403) => "declined by receiver".to_string(),
                Some(409) => "receiver busy".to_string(),
                _ => format!("prepare-upload failed: {e}"),
            };
            bail!(reason);
        }
    };

    if response.files.is_empty() {
        debug!("receiver accepted no files");
        for (file_id, _) in &entries {
            sessions
                .report_file_state(&session_id, file_id, FileState::Skip)
                .await;
        }
        return;
    }

    sessions
        .report_state(&session_id, MissionState::Transfering)
        .await;

    // The receiver assigns its own session id; all further protocol
    // calls must use it (the local `session_id` is only for local
    // reporting).
    let remote_session_id = response.session_id.clone();

    let paths: HashMap<String, PathBuf> = entries
        .iter()
        .map(|(id, _)| id.clone())
        .zip(files.iter().cloned())
        .collect();

    for (file_id, token) in &response.files {
        let Some(path) = paths.get(file_id) else {
            continue;
        };
        let (progress_tx, mut progress_rx) = watch::channel(0usize);
        let progress_sessions = sessions.clone();
        let progress_session = session_id.clone();
        let progress_file = file_id.clone();
        let forwarder = tokio::spawn(async move {
            while progress_rx.changed().await.is_ok() {
                let bytes = *progress_rx.borrow_and_update();
                progress_sessions
                    .report_progress(&progress_session, &progress_file, bytes)
                    .await;
            }
        });

        sessions
            .report_file_state(&session_id, file_id, FileState::Transfer)
            .await;

        let uploaded = tokio::select! {
            res = client.upload_file(
                &target,
                &remote_session_id,
                file_id,
                token,
                path,
                progress_tx,
            ) => res,
            _ = cancel.cancelled() => {
                forwarder.abort();
                // Notify the receiver, best effort.
                let _ = client.cancel(&target, &remote_session_id).await;
                return;
            }
        };
        forwarder.abort();

        match uploaded {
            Ok(_) => {
                sessions
                    .report_file_state(&session_id, file_id, FileState::Finish)
                    .await;
            }
            Err(e) => {
                sessions
                    .report_file_state(&session_id, file_id, FileState::Fail { msg: e.to_string() })
                    .await;
                // Failing one file fails the session (report_file_state
                // with Fail already failed the session); also tell the
                // receiver.
                let _ = client.cancel(&target, &remote_session_id).await;
                return;
            }
        }
    }

    debug!("send session {session_id} driver complete");
}
