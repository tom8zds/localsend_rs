/// Runtime configuration for a [`crate::CoreHandle`].
///
/// NOTE: the field set and order are part of the Flutter Rust Bridge
/// boundary (the ffi crate mirrors this struct); do not add or remove
/// fields without regenerating the FRB bindings.
#[derive(Clone, Debug)]
pub struct CoreConfig {
    pub port: u16,
    pub interface_addr: String,
    pub multicast_addr: String,
    pub multicast_port: u16,
    pub store_path: String,
    /// TURN relay `host:port` for the automatic fallback path
    /// (`None` disables relaying entirely).
    pub relay_addr: Option<String>,
    /// Shared secret for draft-uberti time-limited relay credentials.
    pub relay_secret: Option<String>,
    /// Directory holding the device TLS identity (tls-cert.pem /
    /// tls-key.pem); when set, the HTTP server speaks TLS and sends
    /// are wrapped in a TOFU TLS connection. `None` keeps plain HTTP
    /// (pre-TLS behavior, e.g. for tests and legacy peers).
    pub identity_dir: Option<String>,
    /// Permit falling back to plain HTTP when the peer does not
    /// speak TLS. Defaults to false (TLS-only).
    pub allow_plain_tls: Option<bool>,
}

impl Default for CoreConfig {
    fn default() -> Self {
        CoreConfig {
            port: 53317,
            interface_addr: "0.0.0.0".to_string(),
            multicast_addr: "224.0.0.167".to_string(),
            multicast_port: 53317,
            store_path: "./".to_string(),
            relay_addr: None,
            relay_secret: None,
            identity_dir: None,
            allow_plain_tls: None,
        }
    }
}

impl CoreConfig {
    /// Relay settings when both address and secret are configured.
    pub fn relay_settings(&self) -> Option<crate::relay::RelaySettings> {
        let addr = self.relay_addr.as_deref()?.trim().to_string();
        let secret = self.relay_secret.as_deref()?.trim().to_string();
        if addr.is_empty() || secret.is_empty() {
            return None;
        }
        Some(crate::relay::RelaySettings {
            addr,
            secret,
            realm: "localsend".to_string(),
        })
    }
}
