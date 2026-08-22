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
    pub fn from_args() -> Self {
        let args = PanelArgs::parse();
        PanelConfig {
            admin_password: args.admin_password,
            relay_secret: args.relay_secret,
            relay_public_addr: args.relay_public_addr,
            prom_url: args.prom_url,
            cli_addr: args.cli_addr,
            cli_password: args.cli_password,
        }
    }
}

/// CLI surface: every setting accepts a flag or the corresponding
/// environment variable (flags win); clap validates everything up
/// front so a missing secret prints usage instead of a panic.
use clap::Parser;

#[derive(Parser)]
#[command(
    name = "relay-panel",
    version,
    about = "Admin panel for a localsend coturn deployment: credential issuing, live sessions, traffic trends",
    after_help = "Example:\n  \
relay-panel --relay-secret s3cr3t --relay-public-addr relay.example.com:3478 \\\n    \
  --admin-password $(cat /run/secrets/panel-pw) --bind 127.0.0.1:8787\n\n  \
All flags have RELAY_SECRET / RELAY_PUBLIC_ADDR / PANEL_ADMIN_PASSWORD /\n  \
PANEL_BIND / COTURN_PROM_URL / COTURN_CLI_ADDR / COTURN_CLI_PASSWORD_PLAIN\n  \
environment equivalents. Binds loopback by default — use an ssh tunnel,\n  \
or --bind 0.0.0.0:8787 behind an HTTPS reverse proxy."
)]
pub struct PanelArgs {
    /// Shared TURN secret (must match coturn's static-auth-secret).
    #[arg(long, env = "RELAY_SECRET")]
    pub relay_secret: String,

    /// Address clients dial, advertised in issued configs (host:port).
    #[arg(long, env = "RELAY_PUBLIC_ADDR")]
    pub relay_public_addr: String,

    /// Admin login password for the panel UI.
    #[arg(long, env = "PANEL_ADMIN_PASSWORD", default_value = "changeme")]
    pub admin_password: String,

    /// Listen address.
    #[arg(long, env = "PANEL_BIND", default_value = "127.0.0.1:8787")]
    pub bind: String,

    /// coturn Prometheus metrics URL.
    #[arg(
        long,
        env = "COTURN_PROM_URL",
        default_value = "http://127.0.0.1:9641/metrics"
    )]
    pub prom_url: String,

    /// coturn telnet admin CLI address.
    #[arg(long, env = "COTURN_CLI_ADDR", default_value = "127.0.0.1:5766")]
    pub cli_addr: String,

    /// coturn admin CLI password (plaintext; the conf stores the hash).
    #[arg(long, env = "COTURN_CLI_PASSWORD_PLAIN", default_value = "")]
    pub cli_password: String,
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
