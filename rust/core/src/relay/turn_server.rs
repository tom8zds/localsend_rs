//! Minimal TURN-over-TCP server (RFC 6062 subset), the data plane
//! behind `localsend-cli relay`.
//!
//! Speaks exactly what our client (`turn.rs`) speaks: Allocate (401
//! challenge, then draft-uberti REST credentials verified through
//! MESSAGE-INTEGRITY), CreatePermission, Connect, ConnectionBind,
//! Refresh; after a successful bind both sockets become a plain byte
//! pipe. UDP TURN is intentionally absent — the bundled client only
//! uses the TCP path.

use std::collections::HashMap;
use std::net::{Ipv4Addr, SocketAddr, SocketAddrV4};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

use hmac::{Hmac, KeyInit, Mac};
use log::{debug, info};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};

use super::stun::{base64_encode, Attr, Incoming, Message, MessageClass, Method};

#[derive(Debug, Clone)]
pub struct TurnServerConfig {
    pub listen: SocketAddr,
    /// Address advertised in XOR-RELAYED-ADDRESS (informational for
    /// TCP TURN — data connections always originate from this
    /// server).
    pub external: Ipv4Addr,
    pub realm: String,
    pub secret: String,
    /// Allocation lifetime; idle allocations are dropped.
    pub lifetime: Duration,
}

impl Default for TurnServerConfig {
    fn default() -> Self {
        TurnServerConfig {
            listen: SocketAddr::from(([0, 0, 0, 0], 3478)),
            external: Ipv4Addr::LOCALHOST,
            realm: "localsend".to_string(),
            secret: String::new(),
            lifetime: Duration::from_secs(600),
        }
    }
}

/// Peer sockets minted by Connect, waiting for their ConnectionBind
/// to arrive on a second connection.
static PENDING: Mutex<Option<HashMap<u32, TcpStream>>> = Mutex::new(None);

struct Allocation {
    permissions: Vec<Ipv4Addr>,
    connections: Vec<u32>,
    deadline: Instant,
}

struct Session {
    nonce: String,
    username: Option<String>,
    allocations: HashMap<u16, Allocation>, // keyed by relayed port
}

/// Run the TURN server until the process exits.
pub async fn serve(cfg: TurnServerConfig) -> std::io::Result<()> {
    *PENDING.lock().unwrap() = Some(HashMap::new());
    let listener = TcpListener::bind(cfg.listen).await?;
    info!("TURN server listening on {}", cfg.listen);
    let cfg = Arc::new(cfg);
    loop {
        let (stream, peer) = listener.accept().await?;
        let cfg = cfg.clone();
        tokio::spawn(async move {
            if let Err(e) = handle_client(stream, peer, cfg).await {
                debug!("turn client {peer} ended: {e}");
            }
        });
    }
}

async fn handle_client(
    mut stream: TcpStream,
    peer: SocketAddr,
    cfg: Arc<TurnServerConfig>,
) -> Result<(), String> {
    // Protocol demux: discovery heartbeats arrive as plain HTTP on
    // this port; TURN speaks binary STUN. Peek the first bytes.
    use tokio::io::AsyncReadExt as _;
    let mut peek = [0u8; 7];
    if let Ok(n) = stream.peek(&mut peek).await {
        if n >= 4 && (&peek[..4] == b"GET " || &peek[..4] == b"POST") {
            return handle_http(stream, peer, &cfg).await;
        }
        if n >= 7 && &peek[..7] == b"BRIDGE " {
            return handle_bridge(stream, peer).await;
        }
    }
    let mut session = Session {
        nonce: format!("{:016x}", rand_nonce()),
        username: None,
        allocations: HashMap::new(),
    };
    let mut buf = vec![0u8; 8192];

    loop {
        session
            .allocations
            .retain(|_, a| a.deadline > Instant::now());

        let n = tokio::time::timeout(cfg.lifetime, stream.read(&mut buf))
            .await
            .map_err(|_| "idle".to_string())?
            .map_err(|e| e.to_string())?;
        if n == 0 {
            return Ok(());
        }
        let raw = &buf[..n];
        let msg = Incoming::decode(raw).map_err(|e| e.to_string())?;
        if msg.class != MessageClass::Request {
            continue;
        }
        if msg.method == Method::ConnectionBind {
            return connection_bind(stream, raw, &msg).await;
        }
        let resp = match msg.method {
            // STUN Binding: liveness probe (the app's connection test);
            // answered with the caller's reflexive address, no auth.
            Method::Binding => {
                let mut m = Message::new(Method::Binding, MessageClass::SuccessResponse, msg.tid);
                m.push_xor_address(Attr::XorMappedAddress, peer);
                m.push_xor_address(Attr::XorPeerAddress, peer);
                m.encode(None)
            }
            Method::Allocate => allocate(&mut session, raw, &msg, &cfg),
            Method::Refresh => refresh(&mut session, raw, &msg, &cfg),
            Method::CreatePermission => permission(&mut session, raw, &msg, &cfg),
            Method::Connect => connect(&mut session, &msg, &cfg).await,
            _ => error_resp(&msg, 400, "unsupported method"),
        };
        stream.write_all(&resp).await.map_err(|e| e.to_string())?;
    }
}

fn rand_nonce() -> u64 {
    let mut b = [0u8; 8];
    getrandom_fallback(&mut b);
    u64::from_be_bytes(b)
}

fn getrandom_fallback(b: &mut [u8]) {
    use std::time::{SystemTime, UNIX_EPOCH};
    // Good enough for nonce uniqueness within one process.
    let t = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_nanos();
    for (i, byte) in b.iter_mut().enumerate() {
        *byte = (t >> ((i % 16) * 8)) as u8 ^ (i as u8).wrapping_mul(0x9e);
    }
}

// --- authentication --------------------------------------------------

/// draft-uberti password for a username: base64(HMAC-SHA1(secret, u)).
fn rest_password(secret: &str, username: &str) -> String {
    let mut mac =
        Hmac::<sha1::Sha1>::new_from_slice(secret.as_bytes()).expect("hmac accepts any key length");
    mac.update(username.as_bytes());
    base64_encode(&mac.finalize().into_bytes())
}

/// Verify MESSAGE-INTEGRITY: recompute the MAC over the received
/// bytes with the length field patched to cover the integrity
/// attribute, using key = MD5(user:realm:derived-password).
fn verify_integrity(raw: &[u8], msg: &Incoming, realm: &str, secret: &str) -> bool {
    let Some(username) = msg.string_attr(Attr::Username) else {
        return false;
    };
    let Some(received) = msg.find(Attr::MessageIntegrity) else {
        return false;
    };
    // Locate the integrity attribute inside the raw datagram: it is
    // the last attribute, so its offset = len - 24.
    let Some(mac_off) = raw.len().checked_sub(24) else {
        return false;
    };
    if raw[mac_off..mac_off + 2] != (Attr::MessageIntegrity as u16).to_be_bytes() {
        let _ = received;
        return false;
    }
    let body_len = u16::from_be_bytes([raw[2], raw[3]]) as usize;
    let covered = 20 + body_len; // includes the integrity attribute
    if covered != raw.len() && covered + padding(raw.len() - 20 - (body_len - 24)) != raw.len() {
        // padded attribute after MAC? tolerate: fall through with raw
    }
    let password = rest_password(secret, &username);
    let key = super::stun::long_term_key(&username, realm, &password);
    let mut input = raw[..mac_off].to_vec();
    // Patch the STUN length to include the 24-byte integrity attr.
    let total = mac_off - 20 + 24;
    input[2..4].copy_from_slice(&(total as u16).to_be_bytes());
    let mut mac = Hmac::<sha1::Sha1>::new_from_slice(&key).expect("hmac key len");
    mac.update(&input);
    constant_time_eq(&mac.finalize().into_bytes(), &raw[mac_off + 4..])
}

fn padding(len: usize) -> usize {
    (4 - (len % 4)) % 4
}

fn constant_time_eq(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    a.iter().zip(b).fold(0u8, |acc, (x, y)| acc | (x ^ y)) == 0
}

// --- request handlers ------------------------------------------------

fn allocate(session: &mut Session, raw: &[u8], msg: &Incoming, cfg: &TurnServerConfig) -> Vec<u8> {
    let tcp = msg
        .find(Attr::RequestedTransport)
        .map(|v| v.first() == Some(&6))
        .unwrap_or(false);
    if !tcp {
        return error_resp(msg, 442, "TCP only");
    }
    if !verify_integrity(raw, msg, &cfg.realm, &cfg.secret) {
        let mut m = Message::new(Method::Allocate, MessageClass::ErrorResponse, msg.tid);
        m.push(Attr::ErrorCode, vec![0, 0, 4, 1]);
        m.push(Attr::Realm, cfg.realm.as_bytes().to_vec());
        m.push(Attr::Nonce, session.nonce.as_bytes().to_vec());
        return m.encode(None);
    }
    let username = msg.string_attr(Attr::Username).unwrap_or_default();
    match &session.username {
        None => session.username = Some(username),
        Some(u) if *u == username => {}
        Some(_) => return error_resp(msg, 441, "wrong credentials"),
    }

    let relayed_port: u16 = 49152 + (rand_nonce() % 16384) as u16;
    let lifetime = requested_lifetime(msg, cfg);
    session.allocations.insert(
        relayed_port,
        Allocation {
            permissions: Vec::new(),
            connections: Vec::new(),
            deadline: Instant::now() + lifetime,
        },
    );
    let mut m = Message::new(Method::Allocate, MessageClass::SuccessResponse, msg.tid);
    m.push_xor_address(
        Attr::XorRelayedAddress,
        SocketAddr::V4(SocketAddrV4::new(cfg.external, relayed_port)),
    );
    m.push_lifetime(lifetime.as_secs() as u32);
    m.encode(None)
}

fn requested_lifetime(msg: &Incoming, cfg: &TurnServerConfig) -> Duration {
    msg.lifetime()
        .filter(|s| *s > 0)
        .map(|s| Duration::from_secs(s as u64))
        .unwrap_or(cfg.lifetime)
}

fn refresh(session: &mut Session, raw: &[u8], msg: &Incoming, cfg: &TurnServerConfig) -> Vec<u8> {
    if !verify_integrity(raw, msg, &cfg.realm, &cfg.secret) {
        return error_resp(msg, 401, "unauthorized");
    }
    let lifetime = requested_lifetime(msg, cfg);
    for a in session.allocations.values_mut() {
        a.deadline = Instant::now() + lifetime;
    }
    let mut m = Message::new(Method::Refresh, MessageClass::SuccessResponse, msg.tid);
    m.push_lifetime(lifetime.as_secs() as u32);
    m.encode(None)
}

fn permission(
    session: &mut Session,
    raw: &[u8],
    msg: &Incoming,
    cfg: &TurnServerConfig,
) -> Vec<u8> {
    if !verify_integrity(raw, msg, &cfg.realm, &cfg.secret) {
        return error_resp(msg, 401, "unauthorized");
    }
    let Some(peer) = msg.xor_address(Attr::XorPeerAddress) else {
        return error_resp(msg, 400, "missing xor-peer-address");
    };
    let ip = match peer.ip() {
        std::net::IpAddr::V4(v4) => v4,
        _ => return error_resp(msg, 443, "peer family mismatch"),
    };
    for a in session.allocations.values_mut() {
        if !a.permissions.contains(&ip) {
            a.permissions.push(ip);
        }
        a.deadline = Instant::now() + cfg.lifetime;
    }
    Message::new(
        Method::CreatePermission,
        MessageClass::SuccessResponse,
        msg.tid,
    )
    .encode(None)
}

async fn connect(session: &mut Session, msg: &Incoming, cfg: &TurnServerConfig) -> Vec<u8> {
    let Some(peer) = msg.xor_address(Attr::XorPeerAddress) else {
        return error_resp(msg, 400, "missing xor-peer-address");
    };
    let ip = match peer.ip() {
        std::net::IpAddr::V4(v4) => v4,
        _ => return error_resp(msg, 443, "peer family mismatch"),
    };
    let permitted = session
        .allocations
        .values()
        .any(|a| a.permissions.contains(&ip));
    if !permitted {
        return error_resp(msg, 403, "no permission for peer");
    }
    match TcpStream::connect(peer).await {
        Ok(stream) => {
            let conn_id = (rand_nonce() >> 32) as u32;
            {
                let mut guard = PENDING.lock().unwrap();
                if let Some(map) = guard.as_mut() {
                    map.insert(conn_id, stream);
                }
            }
            for a in session.allocations.values_mut() {
                a.connections.push(conn_id);
                a.deadline = Instant::now() + cfg.lifetime;
            }
            let mut m = Message::new(Method::Connect, MessageClass::SuccessResponse, msg.tid);
            m.push_connection_id(conn_id);
            m.encode(None)
        }
        Err(_) => error_resp(msg, 447, "connection failed"),
    }
}

/// The bind arrives on a NEW connection: answer it, then splice this
/// socket with the parked peer socket forever.
async fn connection_bind(mut stream: TcpStream, raw: &[u8], msg: &Incoming) -> Result<(), String> {
    let _ = raw;
    let Some(conn_id) = msg.connection_id() else {
        stream
            .write_all(&error_resp(msg, 400, "missing connection id"))
            .await
            .map_err(|e| e.to_string())?;
        return Ok(());
    };
    let peer_stream = {
        let mut guard = PENDING.lock().unwrap();
        guard.as_mut().and_then(|m| m.remove(&conn_id))
    };
    let Some(mut peer_stream) = peer_stream else {
        stream
            .write_all(&error_resp(msg, 437, "allocation mismatch"))
            .await
            .map_err(|e| e.to_string())?;
        return Ok(());
    };
    let ok = Message::new(
        Method::ConnectionBind,
        MessageClass::SuccessResponse,
        msg.tid,
    )
    .encode(None);
    stream.write_all(&ok).await.map_err(|e| e.to_string())?;
    let _ = stream.set_nodelay(true);
    let _ = peer_stream.set_nodelay(true);
    tokio::io::copy_bidirectional(&mut stream, &mut peer_stream)
        .await
        .map(|_| ())
        .map_err(|e| e.to_string())
}

fn error_resp(req: &Incoming, code: u16, reason: &str) -> Vec<u8> {
    let mut m = Message::new(req.method, MessageClass::ErrorResponse, req.tid);
    m.push(
        Attr::ErrorCode,
        [0u8, 0, (code / 100) as u8, (code % 100) as u8]
            .into_iter()
            .chain(reason.bytes())
            .collect(),
    );
    m.encode(None)
}

// ---------------------------------------------------------------------------
// HTTP on the TURN port — discovery rendezvous
// ---------------------------------------------------------------------------

/// Minimal HTTP/1.1 handling for the discovery endpoints, sharing the
/// registry with the panel process.
async fn handle_http(
    mut stream: TcpStream,
    peer: SocketAddr,
    cfg: &TurnServerConfig,
) -> Result<(), String> {
    let mut buf = vec![0u8; 8192];
    let n = stream.read(&mut buf).await.map_err(|e| e.to_string())?;
    if n == 0 {
        return Ok(());
    }
    let text = String::from_utf8_lossy(&buf[..n]);
    let mut lines = text.split("\r\n");
    let request_line = lines.next().unwrap_or_default();
    let method = request_line.split_whitespace().next().unwrap_or("");
    let path = request_line.split_whitespace().nth(1).unwrap_or("");

    let mut auth = None;
    let mut content_length = 0usize;
    for line in lines {
        if line.is_empty() {
            break;
        }
        if let Some((k, v)) = line.split_once(':') {
            if k.trim().eq_ignore_ascii_case("authorization") {
                auth = Some(v.trim().to_string());
            } else if k.trim().eq_ignore_ascii_case("content-length") {
                content_length = v.trim().parse().unwrap_or(0);
            }
        }
    }
    let head_end = buf[..n]
        .windows(4)
        .position(|w| w == b"\r\n\r\n")
        .map(|p| p + 4)
        .unwrap_or(n);
    let mut body = buf[head_end..n].to_vec();
    // For simplicity assume the body arrived with the head (small JSON).
    let body_text = String::from_utf8_lossy(&body).to_string();
    let _ = content_length;

    let (status, resp_body) = match (method, path) {
        ("POST", "/api/discovery/register") => {
            crate::relay::discovery_server::handle_register(
                &cfg.secret,
                &body_text,
                auth.as_deref(),
                peer,
            )
            .await
        }
        ("GET", "/api/discovery/devices") => {
            crate::relay::discovery_server::handle_list(&cfg.secret, auth.as_deref()).await
        }
        _ => (404, r#"{"error":"not found"}"#.to_string()),
    };

    let resp = format!(
        "HTTP/1.1 {status} status\r\ncontent-type: application/json\r\ncontent-length: {}\r\nconnection: close\r\n\r\n{}",
        resp_body.len(),
        resp_body
    );
    use tokio::io::AsyncWriteExt as _;
    stream
        .write_all(resp.as_bytes())
        .await
        .map_err(|e| e.to_string())?;
    Ok(())
}

// ---------------------------------------------------------------------------
// Bidirectional relay bridge — both peers connect OUT to the relay,
// the relay splices them. This is the only path that reliably works
// when both peers are behind NAT.
// ---------------------------------------------------------------------------

use std::collections::HashMap as BridgeMap;
use tokio::sync::mpsc;

/// Parked listener connections, keyed by the listener's fingerprint.
static BRIDGE_LISTENERS: std::sync::Mutex<
    Option<BridgeMap<String, mpsc::Sender<tokio::net::TcpStream>>>,
> = std::sync::Mutex::new(None);

/// Handle a `BRIDGE ` connection:
///   `BRIDGE LISTEN <fingerprint>\n` — register as a listener (the
///     receiver holds this connection open; it's reused for one
///     pairing, then the receiver reconnects)
///   `BRIDGE CONNECT <target-fingerprint>\n` — pair with the target
///     listener; both connections become a raw byte tunnel
async fn handle_bridge(mut stream: TcpStream, _peer: SocketAddr) -> Result<(), String> {
    use tokio::io::AsyncReadExt as _;
    let mut buf = [0u8; 256];
    let n = stream.read(&mut buf).await.map_err(|e| e.to_string())?;
    let header = String::from_utf8_lossy(&buf[..n]);
    let line = header.lines().next().unwrap_or_default();
    let parts: Vec<&str> = line.split_whitespace().collect();
    if parts.len() < 3 || parts[0] != "BRIDGE" {
        return Err("bad bridge header".into());
    }

    match parts[1] {
        "LISTEN" => {
            let fingerprint = parts[2].to_string();
            let (tx, mut rx) = mpsc::channel::<TcpStream>(1);
            {
                let mut guard = BRIDGE_LISTENERS.lock().unwrap();
                let listeners = guard.get_or_insert_with(BridgeMap::new);
                // Replace any stale listener for this fingerprint.
                listeners.insert(fingerprint.clone(), tx);
            }
            log::info!("[BRIDGE] listener registered: fp={fingerprint}");
            // Wait for a sender to be paired (or the connection to close).
            match rx.recv().await {
                Some(sender_stream) => {
                    // Splice: this connection ↔ sender's connection.
                    // Drop the tx so the registry entry is stale.
                    {
                        let mut guard = BRIDGE_LISTENERS.lock().unwrap();
                        if let Some(l) = guard.as_mut() {
                            l.remove(&fingerprint);
                        }
                    }
                    let mut peer_stream = sender_stream;
                    let _ = stream.set_nodelay(true);
                    let _ = peer_stream.set_nodelay(true);
                    tokio::io::copy_bidirectional(&mut stream, &mut peer_stream)
                        .await
                        .map(|_| ())
                        .map_err(|e| e.to_string())
                }
                None => {
                    // Channel closed (sender dropped without pairing).
                    let mut guard = BRIDGE_LISTENERS.lock().unwrap();
                    if let Some(l) = guard.as_mut() {
                        l.remove(&fingerprint);
                    }
                    Ok(())
                }
            }
        }
        "CONNECT" => {
            let target = parts[2].to_string();
            let tx = {
                let guard = BRIDGE_LISTENERS.lock().unwrap();
                guard.as_ref().and_then(|l| l.get(&target).cloned())
            };
            let Some(tx) = tx else {
                // Target not listening.
                log::info!("[BRIDGE] CONNECT target={target} NOT_FOUND (no listener)");
                use tokio::io::AsyncWriteExt as _;
                let _ = stream.write_all(b"BRIDGE NOT_FOUND\n").await;
                let _ = stream.shutdown().await;
                return Ok(());
            };
            // Confirm to the sender that the splice is being set up,
            // so it can distinguish success from NOT_FOUND.
            use tokio::io::AsyncWriteExt as _;
            if stream.write_all(b"BRIDGE OK\n").await.is_err() {
                return Ok(());
            }
            log::info!("[BRIDGE] CONNECT target={target} OK — splicing");
            // Hand our stream to the listener; it will splice.
            if tx.send(stream).await.is_err() {
                return Ok(());
            }
            Ok(())
        }
        _ => Err("unknown bridge command".into()),
    }
}
