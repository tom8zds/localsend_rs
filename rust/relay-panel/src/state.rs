//! Panel state: config, sessions, sqlite handles, coturn CLI cache.

use std::collections::HashMap;
use std::sync::Mutex;
use std::time::{Duration, Instant};

use crate::cli::{self, CoturnSession};
use crate::store::Store;

pub struct PanelConfig {
    pub admin_password: String,
    pub relay_secret: String,
    /// Address clients dial (advertised in issued configs).
    pub relay_public_addr: String,
    pub prom_url: String,
    pub cli_addr: String,
    pub cli_password: String,
}

impl PanelConfig {
    pub fn from_env() -> Self {
        let admin_password = std::env::var("PANEL_ADMIN_PASSWORD").unwrap_or_else(|_| {
            eprintln!("WARNING: PANEL_ADMIN_PASSWORD unset, using dev default");
            "changeme".to_string()
        });
        PanelConfig {
            admin_password,
            relay_secret: std::env::var("RELAY_SECRET").expect("RELAY_SECRET is required"),
            relay_public_addr: std::env::var("RELAY_PUBLIC_ADDR")
                .expect("RELAY_PUBLIC_ADDR is required (e.g. relay.example.com:3478)"),
            prom_url: std::env::var("COTURN_PROM_URL")
                .unwrap_or_else(|_| "http://127.0.0.1:9641/metrics".into()),
            cli_addr: std::env::var("COTURN_CLI_ADDR").unwrap_or_else(|_| "127.0.0.1:5766".into()),
            cli_password: std::env::var("COTURN_CLI_PASSWORD_PLAIN").unwrap_or_default(),
        }
    }
}

pub struct AppState {
    pub cfg: PanelConfig,
    pub store: Store,
    pub sessions: Mutex<HashMap<String, Instant>>,
    pub http: reqwest::Client,
    session_cache: tokio::sync::Mutex<Option<(Instant, Vec<CoturnSession>)>>,
}

const SESSION_TTL: Duration = Duration::from_secs(12 * 3600);
const SESSIONS_TTL: Duration = Duration::from_secs(5);

impl AppState {
    pub fn new(cfg: PanelConfig) -> Self {
        let db_path = std::env::var("PANEL_DB").unwrap_or_else(|_| "panel.db".into());
        AppState {
            store: Store::open(std::path::Path::new(&db_path)).expect("open panel db"),
            cfg,
            sessions: Mutex::new(HashMap::new()),
            http: reqwest::Client::builder()
                .timeout(Duration::from_secs(5))
                .build()
                .unwrap(),
            session_cache: tokio::sync::Mutex::new(None),
        }
    }

    pub fn login(&self, password: &str) -> Option<String> {
        // constant-time-ish compare without pulling a crate
        if !same_str(password, &self.cfg.admin_password) {
            return None;
        }
        let token = uuid::Uuid::new_v4().to_string();
        self.sessions
            .lock()
            .unwrap()
            .insert(token.clone(), Instant::now() + SESSION_TTL);
        Some(token)
    }

    pub fn check_session(&self, token: Option<&str>) -> bool {
        let Some(token) = token else { return false };
        let mut map = self.sessions.lock().unwrap();
        match map.get(token) {
            Some(expiry) if *expiry > Instant::now() => true,
            _ => {
                map.remove(token);
                false
            }
        }
    }

    pub fn logout(&self, token: &str) {
        self.sessions.lock().unwrap().remove(token);
    }

    pub fn authed(&self, headers: &axum::http::HeaderMap) -> bool {
        let token = headers
            .get_all(axum::http::header::COOKIE)
            .iter()
            .filter_map(|v| v.to_str().ok())
            .find_map(parse_session_cookie);
        self.check_session(token.as_deref())
    }

    pub fn record_issue(&self, suffix: &str, ttl: u64) {
        self.store.record_issue(suffix, ttl);
    }

    /// Live TURN sessions via coturn CLI, cached for a few seconds.
    pub async fn coturn_sessions(&self) -> Vec<CoturnSession> {
        let mut cache = self.session_cache.lock().await;
        if let Some((at, list)) = cache.as_ref() {
            if at.elapsed() < SESSIONS_TTL {
                return list.clone();
            }
        }
        let list = cli::list_sessions(&self.cfg).await.unwrap_or_default();
        *cache = Some((Instant::now(), list.clone()));
        list
    }

    pub async fn kick_session(&self, sid: &str) -> Result<(), String> {
        // invalidate the cached list so the UI reflects the kick
        *self.session_cache.lock().await = None;
        cli::kick(&self.cfg, sid).await
    }
}

fn same_str(a: &str, b: &str) -> bool {
    if a.len() != b.len() {
        return false;
    }
    a.bytes()
        .zip(b.bytes())
        .fold(0u8, |acc, (x, y)| acc | (x ^ y))
        == 0
}

/// Extract panel_session from a Cookie header value.
pub fn parse_session_cookie(header: &str) -> Option<String> {
    header.split(';').find_map(|pair| {
        let (k, v) = pair.trim().split_once('=')?;
        (k == "panel_session").then(|| v.to_string())
    })
}
