//! TURN relay client (RFC 6062 TURN-over-TCP).
//!
//! [`dial_via_relay`] walks the full client flow — Allocate (with
//! long-term credential challenge), CreatePermission, Connect, and a
//! ConnectionBind on a second TCP connection — and hands back a
//! transparent byte pipe to the peer, over which the plain LocalSend
//! HTTP session runs unchanged.

pub mod bridge;
pub mod credentials;
pub mod stun;
pub mod turn;

pub use bridge::{bridged_view, spawn_bridge, RelaySettings};
pub use credentials::{endpoint_from_secret, generate_credentials};
pub use turn::{dial_via_relay, RelayEndpoint, RelayError, RelayStream};
