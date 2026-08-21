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
use tokio::net::TcpListener;

use super::credentials::endpoint_from_secret;
use super::turn::{dial_via_relay, RelayEndpoint};

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
