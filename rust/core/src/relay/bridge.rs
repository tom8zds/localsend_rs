//! Loopback bridge: exposes one relay tunnel as a local TCP port.
//!
//! The existing HTTP client (reqwest) dials the bridge port exactly
//! as it would dial the peer, and every byte is pumped through the
//! TURN tunnel — no HTTP re-implementation, no client changes. One
//! bridge serves one send session; it accepts a single connection
//! and exits when either side closes.

use std::net::SocketAddr;

use log::{debug, info, warn};
use tokio::io::AsyncWriteExt as _;
use tokio::net::{TcpListener, TcpStream};

use super::credentials::endpoint_from_secret;
use super::turn::{dial_via_relay, RelayEndpoint, RelayStream};

/// Settings for relaying through a TURN server, as stored in
/// [`crate::config::CoreConfig`].
#[derive(Debug, Clone, PartialEq)]
pub struct RelaySettings {
    /// TURN server `host:port` (TCP listener, usually 3478).
    pub addr: String,
    /// Shared secret for draft-uberti time-limited credentials.
    pub secret: String,
    /// Realm advertised by the server (left empty unless known).
    pub realm: String,
}

/// Spawn a bridge for `target` and return the local port serving it.
///
/// The returned listener accepts exactly one connection (the send
/// session's HTTP client) and lives until that connection or the
/// tunnel closes.
pub async fn spawn_bridge(settings: &RelaySettings, target: SocketAddr) -> std::io::Result<u16> {
    let listener = TcpListener::bind(("127.0.0.1", 0)).await?;
    let port = listener.local_addr()?.port();

    let relay: RelayEndpoint = endpoint_from_secret(
        &settings.addr,
        &settings.secret,
        600,
        "localsend",
        &settings.realm,
    );

    tokio::spawn(async move {
        let Ok((mut incoming, _)) = listener.accept().await else {
            return;
        };
        debug!("relay bridge accepted local connection for {target}");
        match dial_via_relay(&relay, target).await {
            Ok(mut tunnel) => {
                match tokio::io::copy_bidirectional(&mut incoming, &mut tunnel).await {
                    Ok((sent, received)) => {
                        // Traffic accounting hook (Q8): one line per
                        // tunnel, greppable when reporting is needed.
                        info!("relay tunnel {target} closed: sent={sent}B received={received}B");
                        let _ = tunnel.shutdown().await;
                    }
                    Err(e) => debug!("relay bridge closed: {e}"),
                }
            }
            Err(e) => {
                // Surface the failure to the client as a closed
                // connection; the send driver turns that into its
                // own relay-fallback error path.
                warn!("relay bridge dial failed: {e}");
                let _ = incoming.shutdown().await;
            }
        }
    });

    Ok(port)
}

/// A [`crate::model::NodeDevice`] view whose address points at a
/// relay bridge — requests to it transparently reach `target`.
pub fn bridged_view(target: &crate::model::NodeDevice, port: u16) -> crate::model::NodeDevice {
    let mut view = target.clone();
    view.address = "127.0.0.1".to_string();
    view.port = port;
    view
}

/// A TLS-wrapped bridge: local plaintext port → TLS session →
/// (directly or through the relay) the peer. Used by the send
/// driver when the device identity is configured; the HTTP layer
/// keeps talking plain `http://127.0.0.1:<port>` and TLS stays
/// strictly between the two endpoints.
/// Either transport under the TLS session.
enum RemoteStream {
    Tcp(TcpStream),
    Relay(RelayStream),
}

impl tokio::io::AsyncRead for RemoteStream {
    fn poll_read(
        mut self: std::pin::Pin<&mut Self>,
        cx: &mut std::task::Context<'_>,
        buf: &mut tokio::io::ReadBuf<'_>,
    ) -> std::task::Poll<std::io::Result<()>> {
        match &mut *self {
            RemoteStream::Tcp(s) => std::pin::Pin::new(s).poll_read(cx, buf),
            RemoteStream::Relay(s) => std::pin::Pin::new(s).poll_read(cx, buf),
        }
    }
}

impl tokio::io::AsyncWrite for RemoteStream {
    fn poll_write(
        mut self: std::pin::Pin<&mut Self>,
        cx: &mut std::task::Context<'_>,
        buf: &[u8],
    ) -> std::task::Poll<std::io::Result<usize>> {
        match &mut *self {
            RemoteStream::Tcp(s) => std::pin::Pin::new(s).poll_write(cx, buf),
            RemoteStream::Relay(s) => std::pin::Pin::new(s).poll_write(cx, buf),
        }
    }

    fn poll_flush(
        mut self: std::pin::Pin<&mut Self>,
        cx: &mut std::task::Context<'_>,
    ) -> std::task::Poll<std::io::Result<()>> {
        match &mut *self {
            RemoteStream::Tcp(s) => std::pin::Pin::new(s).poll_flush(cx),
            RemoteStream::Relay(s) => std::pin::Pin::new(s).poll_flush(cx),
        }
    }

    fn poll_shutdown(
        mut self: std::pin::Pin<&mut Self>,
        cx: &mut std::task::Context<'_>,
    ) -> std::task::Poll<std::io::Result<()>> {
        match &mut *self {
            RemoteStream::Tcp(s) => std::pin::Pin::new(s).poll_shutdown(cx),
            RemoteStream::Relay(s) => std::pin::Pin::new(s).poll_shutdown(cx),
        }
    }
}

pub async fn spawn_tls_bridge(
    tls: std::sync::Arc<rustls::ClientConfig>,
    target: SocketAddr,
    relay: Option<RelayEndpoint>,
) -> std::io::Result<u16> {
    let listener = TcpListener::bind(("127.0.0.1", 0)).await?;
    let port = listener.local_addr()?.port();

    tokio::spawn(async move {
        let Ok((mut incoming, _)) = listener.accept().await else {
            return;
        };
        let remote: RemoteStream = match relay {
            Some(relay) => match dial_via_relay(&relay, target).await {
                Ok(t) => RemoteStream::Relay(t),
                Err(e) => {
                    warn!("tls bridge relay dial failed: {e}");
                    let _ = incoming.shutdown().await;
                    return;
                }
            },
            None => {
                // Black-holed addresses drop SYN silently; bound the
                // dial so the relay fallback isn't left waiting on
                // the kernel's ~2min timeout.
                let dialed = tokio::time::timeout(
                    std::time::Duration::from_secs(3),
                    TcpStream::connect(target),
                )
                .await;
                match dialed {
                    Ok(Ok(s)) => RemoteStream::Tcp(s),
                    Ok(Err(e)) => {
                        warn!("tls bridge connect failed: {e}");
                        let _ = incoming.shutdown().await;
                        return;
                    }
                    Err(_) => {
                        warn!("tls bridge connect to {target} timed out");
                        let _ = incoming.shutdown().await;
                        return;
                    }
                }
            }
        };
        // The verifier ignores the name; "localsend" is a placeholder.
        let name = rustls::pki_types::ServerName::try_from("localsend").expect("valid server name");
        let connector = tokio_rustls::TlsConnector::from(tls);
        match connector.connect(name, remote).await {
            Ok(mut session) => {
                debug!("tls bridge established to {target}");
                if let Err(e) = tokio::io::copy_bidirectional(&mut incoming, &mut session).await {
                    debug!("tls bridge closed: {e}");
                }
            }
            Err(e) => {
                warn!("tls bridge handshake with {target} failed: {e}");
                let _ = incoming.shutdown().await;
            }
        }
    });

    Ok(port)
}
