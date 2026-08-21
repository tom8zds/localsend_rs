//! Minimal coturn telnet-CLI client.
//!
//! Protocol (verified against coturn's turn_admin_server.c): connect,
//! the first line must be the CLI password, then text commands with
//! single-line responses terminated by a cursor prompt.

use std::time::Duration;

use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::TcpStream;

use crate::state::PanelConfig;

const IO: Duration = Duration::from_secs(4);

/// One live TURN session row as parsed from `ps`.
#[derive(Debug, Clone, serde::Serialize)]
pub struct CoturnSession {
    pub id: String,
    pub user: String,
    pub transport: String,
    pub received_bytes: u64,
    pub sent_bytes: u64,
    pub rate: String,
    pub peers: String,
}

async fn run_command(cfg: &PanelConfig, cmd: &str) -> Result<String, String> {
    let mut stream = TcpStream::connect(&cfg.cli_addr)
        .await
        .map_err(|e| format!("connect cli: {e}"))?;
    let (r, mut w) = stream.split();
    let mut reader = BufReader::new(r);

    if !cfg.cli_password.is_empty() {
        let pw = format!("{}\n", cfg.cli_password);
        w.write_all(pw.as_bytes())
            .await
            .map_err(|e| e.to_string())?;
        let _ = read_prompt(&mut reader).await; // "Enter password:" or cursor
    }
    w.write_all(format!("{cmd}\n").as_bytes())
        .await
        .map_err(|e| e.to_string())?;
    let out = read_prompt(&mut reader).await?;
    let _ = w.write_all(b"bye\n").await;
    Ok(out)
}

/// Read lines until the CLI cursor appears or the stream pauses.
async fn read_prompt<R: tokio::io::AsyncRead + Unpin>(
    reader: &mut BufReader<R>,
) -> Result<String, String> {
    let mut out = String::new();
    let mut line = String::new();
    loop {
        line.clear();
        let n = tokio::time::timeout(IO, reader.read_line(&mut line))
            .await
            .map_err(|_| "cli read timeout".to_string())?
            .map_err(|e| e.to_string())?;
        if n == 0 {
            break;
        }
        let trimmed = line.trim_end();
        if trimmed.ends_with('>') {
            out.push_str(trimmed.trim_end_matches('>'));
            break;
        }
        out.push_str(trimmed);
        out.push('\n');
    }
    Ok(out)
}

/// `ps` output (coturn format, stable since 4.5):
/// ```text
/// 000000000000000001: user=alice realm=localsend origin=<unknown> transport=tcp
///   usage: rp=3, rb=1024, sp=2, sb=512
///   rate: 0 r/s, 0 total bytes per s
///   peer: 10.0.0.5:53317
/// ```
pub async fn list_sessions(cfg: &PanelConfig) -> Result<Vec<CoturnSession>, String> {
    let raw = run_command(cfg, "ps").await?;
    let mut sessions = Vec::new();
    let mut current: Option<CoturnSession> = None;
    for line in raw.lines() {
        let line = line.trim();
        if let Some(rest) = line.strip_suffix(':').and_then(|h| {
            h.chars()
                .next()
                .is_some_and(|c| c.is_ascii_hexdigit())
                .then_some(h)
        }) {
            if let Some(c) = current.take() {
                sessions.push(c);
            }
            let mut id = String::new();
            let mut user = String::new();
            let mut transport = String::new();
            for part in rest.split_whitespace() {
                if let Some(v) = part.strip_prefix("user=") {
                    user = v.to_string();
                } else if let Some(v) = part.strip_prefix("transport=") {
                    transport = v.to_string();
                } else if !part.contains('=') && part.chars().all(|c| c.is_ascii_hexdigit()) {
                    id = part.to_string();
                }
            }
            current = Some(CoturnSession {
                id,
                user,
                transport,
                received_bytes: 0,
                sent_bytes: 0,
                rate: String::new(),
                peers: String::new(),
            });
        } else if let Some(rest) = line.strip_prefix("usage:") {
            if let Some(c) = current.as_mut() {
                for kv in rest.split(',') {
                    let kv = kv.trim();
                    if let Some(v) = kv.strip_prefix("rb=") {
                        c.received_bytes = v.parse().unwrap_or(0);
                    } else if let Some(v) = kv.strip_prefix("sb=") {
                        c.sent_bytes = v.parse().unwrap_or(0);
                    }
                }
            }
        } else if let Some(rest) = line.strip_prefix("rate:") {
            if let Some(c) = current.as_mut() {
                c.rate = rest.trim().to_string();
            }
        } else if let Some(rest) = line.strip_prefix("peer:") {
            if let Some(c) = current.as_mut() {
                if c.peers.is_empty() {
                    c.peers = rest.trim().to_string();
                } else {
                    c.peers.push_str(", ");
                    c.peers.push_str(rest.trim());
                }
            }
        }
    }
    if let Some(c) = current.take() {
        sessions.push(c);
    }
    Ok(sessions)
}

pub async fn kick(cfg: &PanelConfig, sid: &str) -> Result<(), String> {
    if !sid.chars().all(|c| c.is_ascii_hexdigit()) {
        return Err("bad session id".into());
    }
    let out = run_command(cfg, &format!("cs {sid}")).await?;
    if out.to_lowercase().contains("error") {
        return Err(out.trim().to_string());
    }
    Ok(())
}
