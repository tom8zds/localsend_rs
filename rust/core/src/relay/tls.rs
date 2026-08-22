//! TLS for the endpoint-to-endpoint link: rustls server with the
//! device's self-signed certificate, and a TOFU (trust-on-first-use)
//! client verifier that pins the peer's certificate fingerprint on
//! first contact and refuses changes afterwards. The relay stays a
//! byte pipe — this TLS is strictly between the two localsend
//! endpoints, including when they talk through a relay tunnel.

use std::collections::HashMap;
use std::io;
use std::path::PathBuf;
use std::sync::{Arc, Mutex};

use rustls::client::danger::{HandshakeSignatureValid, ServerCertVerified, ServerCertVerifier};
use rustls::crypto::ring as provider;
use rustls::pki_types::{CertificateDer, ServerName, UnixTime};
use rustls::DigitallySignedStruct;
use sha2::Digest as _;

use super::identity::DeviceIdentity;

/// Persisted peer fingerprint pins: `peer-id -> sha256(cert-der)`.
pub struct TofuStore {
    path: PathBuf,
    pinned: Mutex<HashMap<String, String>>,
}

impl TofuStore {
    pub fn load(path: PathBuf) -> io::Result<Self> {
        let pinned = std::fs::read(&path)
            .ok()
            .and_then(|raw| serde_json::from_slice::<HashMap<String, String>>(&raw).ok())
            .unwrap_or_default();
        Ok(TofuStore {
            path,
            pinned: Mutex::new(pinned),
        })
    }

    pub fn pinned_fingerprint(&self, peer: &str) -> Option<String> {
        self.pinned.lock().unwrap().get(peer).cloned()
    }

    fn pin(&self, peer: &str, fingerprint: &str) {
        let mut map = self.pinned.lock().unwrap();
        map.insert(peer.to_string(), fingerprint.to_string());
        if let Ok(raw) = serde_json::to_vec_pretty(&*map) {
            let _ = std::fs::write(&self.path, raw);
        }
    }
}

fn fingerprint_of(cert: &CertificateDer<'_>) -> String {
    let mut h = sha2::Sha256::new();
    h.update(cert.as_ref());
    h.finalize().iter().map(|b| format!("{b:02X}")).collect()
}

struct TofuVerifier {
    store: Arc<TofuStore>,
    /// Peer identifier to pin under (the remote device fingerprint or
    /// address — stable across reconnects of the same device).
    peer_id: String,
    /// First contact in this process is also verified against the
    /// announce-time fingerprint when the caller knows it.
    expected: Option<String>,
}

impl std::fmt::Debug for TofuVerifier {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("TofuVerifier")
            .field("peer_id", &self.peer_id)
            .finish_non_exhaustive()
    }
}

impl ServerCertVerifier for TofuVerifier {
    fn verify_server_cert(
        &self,
        end_entity: &CertificateDer<'_>,
        _intermediates: &[CertificateDer<'_>],
        _server_name: &ServerName<'_>,
        _ocsp_response: &[u8],
        _now: UnixTime,
    ) -> Result<ServerCertVerified, rustls::Error> {
        let fingerprint = fingerprint_of(end_entity);
        match self.store.pinned_fingerprint(&self.peer_id) {
            Some(pinned) if pinned == fingerprint => Ok(ServerCertVerified::assertion()),
            Some(pinned) => Err(rustls::Error::General(format!(
                "peer certificate changed: pinned {pinned}, presented {fingerprint}"
            ))),
            None => {
                // No pin yet: accept, optionally cross-checking an
                // out-of-band fingerprint, then pin.
                if let Some(expected) = &self.expected {
                    if expected != &fingerprint {
                        return Err(rustls::Error::General(format!(
                            "peer certificate mismatch: expected {expected}, presented {fingerprint}"
                        )));
                    }
                }
                self.store.pin(&self.peer_id, &fingerprint);
                Ok(ServerCertVerified::assertion())
            }
        }
    }

    fn verify_tls12_signature(
        &self,
        message: &[u8],
        cert: &CertificateDer<'_>,
        dss: &DigitallySignedStruct,
    ) -> Result<HandshakeSignatureValid, rustls::Error> {
        rustls::crypto::verify_tls12_signature(
            message,
            cert,
            dss,
            &provider::default_provider().signature_verification_algorithms,
        )
    }

    fn verify_tls13_signature(
        &self,
        message: &[u8],
        cert: &CertificateDer<'_>,
        dss: &DigitallySignedStruct,
    ) -> Result<HandshakeSignatureValid, rustls::Error> {
        rustls::crypto::verify_tls13_signature(
            message,
            cert,
            dss,
            &provider::default_provider().signature_verification_algorithms,
        )
    }

    fn supported_verify_schemes(&self) -> Vec<rustls::SignatureScheme> {
        provider::default_provider()
            .signature_verification_algorithms
            .supported_schemes()
    }
}

/// A client TLS config that trusts `peer` on first use and pins its
/// certificate fingerprint.
pub fn tofu_client_config(
    store: Arc<TofuStore>,
    peer_id: &str,
    expected_fingerprint: Option<&str>,
) -> Arc<rustls::ClientConfig> {
    let builder = rustls::ClientConfig::builder_with_provider(provider::default_provider().into())
        .with_protocol_versions(&[&rustls::version::TLS13, &rustls::version::TLS12])
        .expect("built-in versions")
        .dangerous()
        .with_custom_certificate_verifier(Arc::new(TofuVerifier {
            store,
            peer_id: peer_id.to_string(),
            expected: expected_fingerprint.map(str::to_string),
        }));
    Arc::new(builder.with_no_client_auth())
}

/// A server TLS config presenting the device identity.
pub fn server_config(identity: &DeviceIdentity) -> io::Result<Arc<rustls::ServerConfig>> {
    let certs = vec![CertificateDer::from(identity.cert_der.clone())];
    let key = rustls::pki_types::PrivateKeyDer::try_from(identity.key_der.clone())
        .map_err(|e| io::Error::other(format!("bad private key: {e}")))?;
    let config = rustls::ServerConfig::builder_with_provider(provider::default_provider().into())
        .with_protocol_versions(&[&rustls::version::TLS13, &rustls::version::TLS12])
        .expect("built-in versions")
        .with_no_client_auth()
        .with_single_cert(certs, key)
        .map_err(|e| io::Error::other(format!("tls server config: {e}")))?;
    Ok(Arc::new(config))
}
