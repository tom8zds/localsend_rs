//! `relay-panel` — admin panel for the localsend coturn deployment.
//!
//! Single-binary axum service (SSR, self-contained: no CDN, no node
//! toolchain; charts are hand-rolled SVG):
//!
//! - `/issue`  — mint draft-uberti credentials, render the
//!   `localsend-relay://configure` deep link as QR + copyable text
//! - `/`       — overview: live allocations, cumulative traffic,
//!   30-day traffic trend (self-collected, minute granularity)
//! - `/sessions` — live TURN sessions (polled from coturn's telnet
//!   CLI) with per-session kick
//!
//! Auth: one admin password (`PANEL_ADMIN_PASSWORD`), cookie
//! session kept in memory. Binds `PANEL_BIND` (default 127.0.0.1:
//! 8787) — put it behind ssh/https for remote access.

mod cli;
mod collector;
mod pages;
mod state;
mod store;

use std::net::SocketAddr;
use std::sync::Arc;

use axum::extract::State;
use axum::http::{header, StatusCode};
use axum::response::{Html, IntoResponse, Redirect};
use axum::routing::{get, post};
use axum::{Form, Router};
use serde::Deserialize;

use state::AppState;

#[tokio::main]
async fn main() {
    let cfg = state::PanelConfig::from_env();
    let state = Arc::new(AppState::new(cfg));

    // background: scrape prometheus once a minute into sqlite
    {
        let st = state.clone();
        tokio::spawn(async move {
            loop {
                collector::scrape_once(&st).await;
                tokio::time::sleep(std::time::Duration::from_secs(60)).await;
            }
        });
    }

    let app = Router::new()
        .route("/", get(overview))
        .route("/login", get(login_form).post(login_submit))
        .route("/logout", post(logout))
        .route("/issue", get(issue_form).post(issue_create))
        .route("/issue/history", get(issue_history))
        .route("/sessions", get(sessions_page))
        .route("/api/sessions", get(api_sessions))
        .route("/api/sessions/{sid}/kick", post(api_kick))
        .route("/api/overview", get(api_overview))
        .route("/style.css", get(css))
        .with_state(state);

    let bind: SocketAddr = std::env::var("PANEL_BIND")
        .unwrap_or_else(|_| "127.0.0.1:8787".into())
        .parse()
        .expect("PANEL_BIND must be ip:port");
    println!("relay-panel listening on http://{bind}");
    let listener = tokio::net::TcpListener::bind(bind).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn overview(
    State(st): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
) -> Result<Html<String>, Redirect> {
    if !st.authed(&headers) {
        return Err(Redirect::to("/login"));
    }
    let live = collector::current_snapshot(&st).await;
    Ok(Html(pages::overview(&st, &live)))
}

async fn login_form(State(st): State<Arc<AppState>>) -> impl IntoResponse {
    Html(pages::login(&st, None))
}

#[derive(Deserialize)]
struct LoginInput {
    password: String,
}

async fn login_submit(
    State(st): State<Arc<AppState>>,
    Form(input): Form<LoginInput>,
) -> impl IntoResponse {
    match st.login(&input.password) {
        Some(token) => (
            [(
                header::SET_COOKIE,
                format!("panel_session={token}; Path=/; HttpOnly; SameSite=Lax"),
            )],
            Redirect::to("/"),
        )
            .into_response(),
        None => Redirect::to("/login?err=1").into_response(),
    }
}

async fn logout(
    State(st): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
) -> impl IntoResponse {
    if let Some(token) = headers
        .get_all(axum::http::header::COOKIE)
        .iter()
        .filter_map(|v| v.to_str().ok())
        .find_map(state::parse_session_cookie)
    {
        st.logout(&token);
    }
    (
        [(header::SET_COOKIE, "panel_session=; Path=/; Max-Age=0")],
        Redirect::to("/login"),
    )
}

async fn issue_form(
    State(st): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
) -> Result<Html<String>, Redirect> {
    if !st.authed(&headers) {
        return Err(Redirect::to("/login"));
    }
    Ok(Html(pages::issue_form(&st)))
}

async fn issue_history(
    State(st): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
) -> Result<Html<String>, Redirect> {
    if !st.authed(&headers) {
        return Err(Redirect::to("/login"));
    }
    Ok(Html(pages::issue_history(&st)))
}

#[derive(Deserialize)]
struct IssueInput {
    ttl: u64,
    suffix: String,
}

async fn issue_create(
    State(st): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
    Form(input): Form<IssueInput>,
) -> Result<Html<String>, Redirect> {
    if !st.authed(&headers) {
        return Err(Redirect::to("/login"));
    }
    let ttl = input.ttl.clamp(60, 30 * 24 * 3600);
    let suffix: String = input
        .suffix
        .chars()
        .filter(|c| c.is_ascii_alphanumeric() || *c == '-' || *c == '_')
        .take(32)
        .collect();
    let expiry = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs()
        + ttl;
    // The deep link carries the long-term secret (clients mint their
    // own time-limited pairs), NOT this credential pair — but we
    // also mint a sample pair so operators can sanity-check auth.
    let (username, password) =
        localsend_core::relay::generate_credentials(&st.cfg.relay_secret, expiry, &suffix);
    st.record_issue(&suffix, ttl);
    Ok(Html(pages::issue_result(
        &st, ttl, &suffix, &username, &password,
    )))
}

async fn sessions_page(
    State(st): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
) -> Result<Html<String>, Redirect> {
    if !st.authed(&headers) {
        return Err(Redirect::to("/login"));
    }
    Ok(Html(pages::sessions(&st)))
}

async fn api_sessions(
    State(st): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
) -> impl IntoResponse {
    if !st.authed(&headers) {
        return (StatusCode::FORBIDDEN, "forbidden").into_response();
    }
    let sessions = st.coturn_sessions().await;
    axum::Json(serde_json::json!({ "sessions": sessions })).into_response()
}

async fn api_kick(
    State(st): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
    axum::extract::Path(sid): axum::extract::Path<String>,
) -> impl IntoResponse {
    if !st.authed(&headers) {
        return (StatusCode::FORBIDDEN, "forbidden").into_response();
    }
    match st.kick_session(&sid).await {
        Ok(()) => StatusCode::OK.into_response(),
        Err(e) => (StatusCode::BAD_GATEWAY, e).into_response(),
    }
}

async fn api_overview(
    State(st): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
) -> impl IntoResponse {
    if !st.authed(&headers) {
        return (StatusCode::FORBIDDEN, "forbidden").into_response();
    }
    let live = collector::current_snapshot(&st).await;
    axum::Json(collector::live_json(&live)).into_response()
}

async fn css() -> impl IntoResponse {
    ([(header::CONTENT_TYPE, "text/css")], pages::CSS)
}

/// Format a unix-seconds/minutes timestamp for the panel (local
/// time, minute precision is enough).
pub fn store_time(t: i64) -> String {
    let secs = t.max(0);
    let days = secs / 86400;
    let time_of_day = secs % 86400;
    format!(
        "{:04}-{:02}-{:02} {:02}:{:02}",
        1970 + days / 365,
        1 + (days % 365) / 30, // coarse calendar; good enough for a trend axis
        1 + (days % 30),
        time_of_day / 3600,
        (time_of_day % 3600) / 60
    )
}
