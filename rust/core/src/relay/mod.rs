//! TURN relay client (RFC 6062 TURN-over-TCP).
//!
//! [`dial_via_relay`] walks the full client flow — Allocate (with
//! long-term credential challenge), CreatePermission, Connect, and a
//! ConnectionBind on a second TCP connection — and hands back a
//! transparent byte pipe to the peer, over which the plain LocalSend
//! HTTP session runs unchanged.

pub mod bridge;
pub mod credentials;
pub mod identity;
pub mod quic;
pub mod stun;
pub mod tls;
pub mod turn;
pub mod turn_server;

pub use bridge::{bridged_view, spawn_bridge, spawn_quic_bridge, spawn_tls_bridge, RelaySettings};
pub use credentials::{endpoint_from_secret, generate_credentials};
pub use quic::{send_request, HttpRequest, HttpResponse, QuicTransport};
pub use turn::{dial_via_relay, ping, probe, RelayEndpoint, RelayError, RelayStream};
pub use turn_server::{serve as serve_turn, TurnServerConfig};
