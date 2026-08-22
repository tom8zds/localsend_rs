//! Device identity: a self-signed certificate generated on first
//! run and persisted, whose SHA-256 digest serves as the device's
//! TLS fingerprint under the TOFU trust model.

use std::io;
use std::path::Path;

use sha2::Sha256;

/// A device's TLS identity material.
pub struct DeviceIdentity {
    pub cert_der: Vec<u8>,
    pub key_der: Vec<u8>,
    /// Lowercase hex SHA-256 of the DER certificate — the fingerprint
    /// peers pin under TOFU.
    pub fingerprint: String,
}

const CERT_FILE: &str = "tls-cert.pem";
const KEY_FILE: &str = "tls-key.pem";

impl DeviceIdentity {
    /// Load the identity from `dir`, generating and persisting a new
    /// one when absent.
    pub fn load_or_create(dir: &Path) -> io::Result<Self> {
        std::fs::create_dir_all(dir)?;
        let cert_path = dir.join(CERT_FILE);
        let key_path = dir.join(KEY_FILE);

        if cert_path.exists() && key_path.exists() {
            let cert_pem = std::fs::read_to_string(&cert_path)?;
            let key_pem = std::fs::read_to_string(&key_path)?;
            let cert =
                pem::parse(cert_pem).map_err(|e| io::Error::other(format!("bad cert pem: {e}")))?;
            let key =
                pem::parse(key_pem).map_err(|e| io::Error::other(format!("bad key pem: {e}")))?;
            return Ok(Self::from_der(
                cert.contents().to_vec(),
                key.contents().to_vec(),
            ));
        }

        // Subject CN carries the device alias slot; peers match on
        // the fingerprint, never on the name.
        let mut params = rcgen::CertificateParams::new(vec!["localsend".to_string()])
            .map_err(|e| io::Error::other(format!("cert params: {e}")))?;
        params.distinguished_name.push(
            rcgen::DnType::CommonName,
            rcgen::DnValue::Utf8String("localsend".into()),
        );
        // Match the official app's validity span: near-eternal, so
        // clock skew between peers can never flunk validity checks
        // (the official verifier DOES check NotBefore/NotAfter).
        params.not_before = rcgen::date_time_ymd(1975, 1, 1);
        params.not_after = rcgen::date_time_ymd(4096, 1, 1);
        let key_pair =
            rcgen::KeyPair::generate().map_err(|e| io::Error::other(format!("key pair: {e}")))?;
        let cert = params
            .self_signed(&key_pair)
            .map_err(|e| io::Error::other(format!("self-signed cert: {e}")))?;

        let cert_der = cert.der().to_vec();
        let key_der = key_pair.serialize_der();
        std::fs::write(&cert_path, cert.pem())?;
        std::fs::write(
            &key_path,
            pem::Pem::new("PRIVATE KEY", key_der.clone()).to_string(),
        )?;
        Ok(Self::from_der(cert_der, key_der))
    }

    fn from_der(cert_der: Vec<u8>, key_der: Vec<u8>) -> Self {
        use sha2::Digest as _;
        let mut h = Sha256::new();
        h.update(&cert_der);
        let fingerprint = h
            .finalize()
            .iter()
            .map(|b| format!("{b:02X}"))
            .collect::<String>();
        DeviceIdentity {
            cert_der,
            key_der,
            fingerprint,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn generates_persists_and_reloads() {
        let dir = tempfile::tempdir().unwrap();
        let a = DeviceIdentity::load_or_create(dir.path()).unwrap();
        assert!(a.fingerprint.len() == 64);
        let b = DeviceIdentity::load_or_create(dir.path()).unwrap();
        assert_eq!(a.fingerprint, b.fingerprint);
        assert_eq!(a.cert_der, b.cert_der);
    }

    #[test]
    fn distinct_dirs_yield_distinct_fingerprints() {
        let a = DeviceIdentity::load_or_create(tempfile::tempdir().unwrap().path()).unwrap();
        let b = DeviceIdentity::load_or_create(tempfile::tempdir().unwrap().path()).unwrap();
        assert_ne!(a.fingerprint, b.fingerprint);
    }
}
