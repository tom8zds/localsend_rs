//! TURN relay client (RFC 6062 TURN-over-TCP).
//!
//! Every dial walks the complete sequence on fresh connections and
//! lets the allocation expire server-side when the returned stream
//! drops; there is no shared allocation state to manage. The extra
//! round trips (~5) are one-shot per HTTP request, which the
//! file-transfer workload absorbs easily.
//!
//! TODO(M2): react to 438 stale-nonce by re-running the challenge
//! round once.

use std::net::SocketAddr;
use std::pin::Pin;
use std::task::{Context, Poll};
use std::time::Duration;

use log::debug;
use tokio::io::{AsyncRead, AsyncReadExt, AsyncWrite, AsyncWriteExt, ReadBuf};
use tokio::net::TcpStream;

use super::stun::{
    long_term_key, Attr, Incoming, Message, MessageClass, Method, TransactionId, HEADER_LEN,
};

/// Where and how to reach the TURN server.
#[derive(Debug, Clone)]
pub struct RelayEndpoint {
    /// `host:port` of the TURN server's TCP listener (usually 3478).
    pub addr: String,
    /// Long-term credentials. For time-limited REST credentials
    /// (draft-uberti) the username is `<expiry-epoch-seconds>:<suffix>`
    /// and the password is the base64 HMAC-SHA1 of the username
    /// under the shared secret — see [`super::credentials`].
    pub username: String,
    pub password: String,
    /// Authentication realm learned from the server's 401 challenge;
    /// left empty for the first attempt.
    pub realm: String,
    /// How long the server should keep the allocation alive.
    pub lifetime_seconds: u32,
}

/// A transparent TCP pipe to the peer, reached through the relay.
///
/// The control connection is carried alongside: RFC 6062 §5.2 says
/// deleting (or expiring) the allocation closes its data
/// connections, so the control socket must live exactly as long as
/// the pipe. Dropping this struct drops both.
#[derive(Debug)]
pub struct RelayStream {
    data: TcpStream,
    _control: TcpStream,
}

impl AsyncRead for RelayStream {
    fn poll_read(
        mut self: Pin<&mut Self>,
        cx: &mut Context<'_>,
        buf: &mut ReadBuf<'_>,
    ) -> Poll<std::io::Result<()>> {
        Pin::new(&mut self.data).poll_read(cx, buf)
    }
}

impl AsyncWrite for RelayStream {
    fn poll_write(
        mut self: Pin<&mut Self>,
        cx: &mut Context<'_>,
        buf: &[u8],
    ) -> Poll<std::io::Result<usize>> {
        Pin::new(&mut self.data).poll_write(cx, buf)
    }

    fn poll_flush(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<std::io::Result<()>> {
        Pin::new(&mut self.data).poll_flush(cx)
    }

    fn poll_shutdown(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<std::io::Result<()>> {
        Pin::new(&mut self.data).poll_shutdown(cx)
    }
}

impl RelayStream {
    pub fn set_nodelay(&self, nodelay: bool) -> std::io::Result<()> {
        self.data.set_nodelay(nodelay)
    }
}

#[derive(Debug)]
pub enum RelayError {
    Io(std::io::Error),
    Protocol(&'static str),
    /// The server rejected a step with this STUN error code.
    Server(u16, String),
    /// TCP connection to the relay itself failed.
    Connect(std::io::Error),
}

impl std::fmt::Display for RelayError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            RelayError::Io(e) => write!(f, "relay io error: {e}"),
            RelayError::Protocol(m) => write!(f, "relay protocol error: {m}"),
            RelayError::Server(code, reason) => {
                write!(f, "relay rejected (code {code}): {reason}")
            }
            RelayError::Connect(e) => write!(f, "connect to relay failed: {e}"),
        }
    }
}

impl std::error::Error for RelayError {}

impl From<std::io::Error> for RelayError {
    fn from(e: std::io::Error) -> Self {
        RelayError::Io(e)
    }
}

const IO_TIMEOUT: Duration = Duration::from_secs(10);

/// Dial `target` through the TURN relay and return a transparent
/// TCP pipe to it.
pub async fn dial_via_relay(
    relay: &RelayEndpoint,
    target: SocketAddr,
) -> Result<RelayStream, RelayError> {
    // The relay address may be a hostname (docker service names,
    // dns names) — resolve to a literal IP first.
    let relay_addr: SocketAddr = match relay.addr.parse() {
        Ok(s) => s,
        Err(_) => tokio::net::lookup_host(&relay.addr)
            .await
            .ok()
            .and_then(|mut it| it.next())
            .ok_or(RelayError::Protocol("relay address is not host:port"))?,
    };

    let mut control = TcpStream::connect(&relay_addr)
        .await
        .map_err(RelayError::Connect)?;
    control.set_nodelay(true).ok();
    debug!("relay control connected to {relay_addr}");

    // --- Allocate: first attempt triggers the 401 challenge ---
    let mut cred = CredentialState {
        username: relay.username.clone(),
        password: relay.password.clone(),
        realm: relay.realm.clone(),
        nonce: String::new(),
    };

    let challenge = {
        let mut allocate = Message::new(
            Method::Allocate,
            MessageClass::Request,
            TransactionId::new(),
        );
        allocate.push_requested_transport(6 /* TCP */);
        if relay.lifetime_seconds > 0 {
            allocate.push_lifetime(relay.lifetime_seconds);
        }
        transact(&mut control, &mut allocate, None).await?
    };

    match challenge.class {
        MessageClass::ErrorResponse => {
            let (class, num, reason) = challenge
                .error_code()
                .ok_or(RelayError::Protocol("error response without ERROR-CODE"))?;
            let code = class as u16 * 100 + num;
            if code != 401 {
                return Err(RelayError::Server(code, reason));
            }
            cred.realm = challenge
                .string_attr(Attr::Realm)
                .ok_or(RelayError::Protocol("401 without REALM"))?;
            cred.nonce = challenge
                .string_attr(Attr::Nonce)
                .ok_or(RelayError::Protocol("401 without NONCE"))?;
        }
        _ => {
            return Err(RelayError::Protocol(
                "relay accepted allocate without a challenge",
            ))
        }
    }

    let mut allocate = Message::new(
        Method::Allocate,
        MessageClass::Request,
        TransactionId::new(),
    );
    allocate.push_requested_transport(6);
    if relay.lifetime_seconds > 0 {
        allocate.push_lifetime(relay.lifetime_seconds);
    }
    let allocated = authenticated_transact(&mut control, &mut allocate, &cred).await?;
    expect_success(&allocated, "allocate")?;
    if let Some(relayed) = xor_address_of(&allocated, Attr::XorRelayedAddress) {
        debug!("relay allocated {relayed}");
    }

    // --- CreatePermission for the peer ---
    let mut permission = Message::new(
        Method::CreatePermission,
        MessageClass::Request,
        TransactionId::new(),
    );
    permission.push_xor_address(Attr::XorPeerAddress, target);
    let permitted = authenticated_transact(&mut control, &mut permission, &cred).await?;
    expect_success(&permitted, "create-permission")?;

    // --- Connect to the peer, learn CONNECTION-ID ---
    let mut connect = Message::new(Method::Connect, MessageClass::Request, TransactionId::new());
    connect.push_xor_address(Attr::XorPeerAddress, target);
    let connected = authenticated_transact(&mut control, &mut connect, &cred).await?;
    expect_success(&connected, "connect")?;
    let connection_id = connected.connection_id().ok_or(RelayError::Protocol(
        "connect success without CONNECTION-ID",
    ))?;

    // --- Bind a second connection to that id; it becomes the pipe ---
    let mut data = TcpStream::connect(&relay_addr)
        .await
        .map_err(RelayError::Connect)?;
    data.set_nodelay(true).ok();
    let mut bind = Message::new(
        Method::ConnectionBind,
        MessageClass::Request,
        TransactionId::new(),
    );
    bind.push_connection_id(connection_id);
    let bound = authenticated_transact(&mut data, &mut bind, &cred).await?;
    expect_success(&bound, "connection-bind")?;
    debug!("relay tunnel bound (connection {connection_id}) to {target}");

    Ok(RelayStream {
        data,
        _control: control,
    })
}

fn xor_address_of(msg: &Incoming, attr: Attr) -> Option<SocketAddr> {
    msg.xor_address(attr)
}

struct CredentialState {
    username: String,
    password: String,
    realm: String,
    nonce: String,
}

impl CredentialState {
    fn key(&self) -> Vec<u8> {
        long_term_key(&self.username, &self.realm, &self.password)
    }

    /// Stamp the authentication attributes onto the message and
    /// return the integrity key it must be signed with.
    fn sign(&self, msg: &mut Message) -> Vec<u8> {
        msg.push_username(&self.username);
        msg.push_realm(&self.realm);
        msg.push_nonce(&self.nonce);
        self.key()
    }
}

async fn authenticated_transact(
    conn: &mut TcpStream,
    msg: &mut Message,
    cred: &CredentialState,
) -> Result<Incoming, RelayError> {
    let key = cred.sign(msg);
    transact(conn, msg, Some(&key)).await
}

/// Send a request and read the matching response (same transaction
/// id) off the wire. STUN responses on a stream socket arrive whole;
/// anything bigger than the buffer is a protocol violation.
async fn transact(
    conn: &mut TcpStream,
    msg: &mut Message,
    key: Option<&[u8]>,
) -> Result<Incoming, RelayError> {
    let wire = msg.encode(key);
    let write = conn.write_all(&wire);
    tokio::time::timeout(IO_TIMEOUT, write)
        .await
        .map_err(|_| RelayError::Protocol("relay write timeout"))??;

    let mut buf = vec![0u8; 4096];
    let read = conn.read(&mut buf);
    let n = tokio::time::timeout(IO_TIMEOUT, read)
        .await
        .map_err(|_| RelayError::Protocol("relay response timeout"))??;
    if n < HEADER_LEN {
        return Err(RelayError::Protocol("short STUN response"));
    }
    let incoming = Incoming::decode(&buf[..n])
        .map_err(|_| RelayError::Protocol("undecodable STUN response from relay"))?;
    if incoming.tid != msg.tid {
        return Err(RelayError::Protocol("transaction id mismatch"));
    }
    Ok(incoming)
}

fn expect_success(msg: &Incoming, step: &str) -> Result<(), RelayError> {
    match msg.class {
        MessageClass::SuccessResponse => Ok(()),
        MessageClass::ErrorResponse => {
            let (class, num, reason) = msg.error_code().unwrap_or((4, 0, format!("{step} failed")));
            Err(RelayError::Server(class as u16 * 100 + num, reason))
        }
        _ => Err(RelayError::Protocol("unexpected response class")),
    }
}
