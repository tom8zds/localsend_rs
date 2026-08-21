//! draft-uberti REST-style time-limited TURN credentials.
//!
//! username  = `<unix-expiry>:<suffix>`
//! password  = base64(HMAC-SHA1(secret, username))
//!
//! Both `turn-rs` and coturn accept this scheme when configured with
//! the same shared secret.

use hmac::{Hmac, KeyInit, Mac};
use sha1::Sha1;

use super::turn::RelayEndpoint;

/// Generate a `(username, password)` credential pair valid until
/// `expiry_unix`. `suffix` exists so operators can tell credentials
/// apart in logs (e.g. a device alias or user id).
pub fn generate_credentials(secret: &str, expiry_unix: u64, suffix: &str) -> (String, String) {
    let username = if suffix.is_empty() {
        format!("{expiry_unix}")
    } else {
        format!("{expiry_unix}:{suffix}")
    };
    let mut mac =
        Hmac::<Sha1>::new_from_slice(secret.as_bytes()).expect("hmac accepts any key length");
    mac.update(username.as_bytes());
    let password = crate::relay::stun::base64_encode(&mac.finalize().into_bytes());
    (username, password)
}

/// Build a ready-to-use relay endpoint from a secret, minting a
/// fresh credential pair with the given lifetime.
pub fn endpoint_from_secret(
    addr: &str,
    secret: &str,
    ttl_seconds: u64,
    suffix: &str,
    realm: &str,
) -> RelayEndpoint {
    let expiry = unix_now() + ttl_seconds;
    let (username, password) = generate_credentials(secret, expiry, suffix);
    RelayEndpoint {
        addr: addr.to_string(),
        username,
        password,
        realm: realm.to_string(),
        lifetime_seconds: 3600,
    }
}

#[cfg(not(target_family = "wasm"))]
fn unix_now() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or_default()
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Stability check: the scheme must be reproducible and the
    /// digest 28 base64 chars (20 bytes HMAC-SHA1).
    #[test]
    fn credentials_are_deterministic() {
        let a = generate_credentials("s3cr3t", 1731242457, "desk");
        let b = generate_credentials("s3cr3t", 1731242457, "desk");
        assert_eq!(a, b);
        assert_eq!(a.0, "1731242457:desk");
        assert_eq!(a.1.len(), 28);
        let other = generate_credentials("other", 1731242457, "desk");
        assert_ne!(a.1, other.1);
    }
}
