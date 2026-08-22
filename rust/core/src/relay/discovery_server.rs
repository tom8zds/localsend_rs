//! Discovery rendezvous shared by the TURN server (on the TURN port)
//! and the panel process. The registry is process-global so both
//! entry points see the same devices.

use std::collections::HashMap;
use std::net::SocketAddr;
use std::sync::Mutex;
use std::time::{Duration, Instant};

use serde::{Deserialize, Serialize};

const TTL: Duration = Duration::from_secs(75);

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DeviceRegistration {
    pub fingerprint: String,
    pub alias: String,
    pub device_model: String,
    pub device_type: String,
    pub protocol: String,
    pub port: u16,
    pub username: String,
    #[serde(default)]
    pub candidates: Vec<String>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DeviceEntry {
    pub fingerprint: String,
    pub alias: String,
    pub device_model: String,
    pub device_type: String,
    pub protocol: String,
    pub address: String,
    pub port: u16,
    #[serde(default)]
    pub candidates: Vec<String>,
}

static REGISTRY: Mutex<Option<HashMap<String, (DeviceEntry, Instant)>>> = Mutex::new(None);

fn with_registry<R>(f: impl FnOnce(&mut HashMap<String, (DeviceEntry, Instant)>) -> R) -> R {
    let mut guard = REGISTRY.lock().unwrap();
    let map = guard.get_or_insert_with(HashMap::new);
    map.retain(|_, (_, at)| at.elapsed() < TTL);
    f(map)
}

fn verify(secret: &str, username: &str, password: &str) -> bool {
    use hmac::{Hmac, KeyInit, Mac};
    let mut mac = Hmac::<sha1::Sha1>::new_from_slice(secret.as_bytes()).expect("hmac key len");
    mac.update(username.as_bytes());
    let expected = super::stun::base64_encode(&mac.finalize().into_bytes());
    let expired = username
        .split(':')
        .next()
        .and_then(|t| t.parse::<u64>().ok())
        .map(|exp| exp <= now())
        .unwrap_or(false);
    !expired && constant_time_eq(expected.as_bytes(), password.as_bytes())
}

fn now() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

fn constant_time_eq(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    a.iter().zip(b).fold(0u8, |acc, (x, y)| acc | (x ^ y)) == 0
}

fn bearer_of(auth: Option<&str>) -> Option<&str> {
    auth.and_then(|h| h.strip_prefix("Bearer "))
}

/// Handle POST /api/discovery/register on the TURN port.
/// Returns (http_status, json_body).
pub async fn handle_register(
    secret: &str,
    body: &str,
    auth: Option<&str>,
    source: SocketAddr,
) -> (u16, String) {
    let Some(reg) = serde_json::from_str::<DeviceRegistration>(body).ok() else {
        return (400, r#"{"error":"bad json"}"#.into());
    };
    let Some(password) = bearer_of(auth) else {
        return (401, r#"{"error":"missing auth"}"#.into());
    };
    if !verify(secret, &reg.username, password) {
        return (401, r#"{"error":"bad credentials"}"#.into());
    }
    let entry = DeviceEntry {
        fingerprint: reg.fingerprint.clone(),
        alias: reg.alias,
        device_model: reg.device_model,
        device_type: reg.device_type,
        protocol: reg.protocol,
        address: source.ip().to_string(),
        port: reg.port,
        candidates: reg.candidates,
    };
    let list = with_registry(|map| {
        map.insert(reg.fingerprint, (entry, Instant::now()));
        map.values().map(|(e, _)| e.clone()).collect::<Vec<_>>()
    });
    (200, serde_json::to_string(&list).unwrap_or_default())
}

/// Handle GET /api/discovery/devices.
pub async fn handle_list(secret: &str, _auth: Option<&str>) -> (u16, String) {
    // Auth verified via register; list is open to anyone who reached
    // the TURN port (network-level trust).
    let _ = secret;
    let list = with_registry(|map| map.values().map(|(e, _)| e.clone()).collect::<Vec<_>>());
    (200, serde_json::to_string(&list).unwrap_or_default())
}
