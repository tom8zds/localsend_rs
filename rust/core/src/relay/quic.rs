//! QUIC transport: the STUN hole-punch data plane.
//!
//! A `QuicTransport` owns one UDP socket serving both roles — it
//! listens for incoming connections (peers punching toward us) and
//! can dial out (us punching toward peers). Once a connection is
//! established, HTTP/1.1 sessions run over bidirectional QUIC
//! streams: the server side feeds them to the existing axum router
//! via hyper; the client side gets a `send_request` helper built on
//! hyper's connection API. Certificates are the device identity
//! (TOFU fingerprints stay meaningful end to end).

use std::net::SocketAddr;

use std::sync::Arc;

use log::debug;

use super::identity::DeviceIdentity;
use super::tls;

/// A QUIC endpoint bound to one UDP socket.
pub struct QuicTransport {
    endpoint: quinn::Endpoint,
    server_name: String,
}

impl QuicTransport {
    /// Bind on `bind` (use port 0 for an ephemeral allocation when
    /// only dialing out). `peer_fingerprint` anchors the first
    /// connection to this peer via TOFU (None = trust on first use).
    pub fn new(
        bind: SocketAddr,
        identity: &DeviceIdentity,
        tofu: Arc<tls::TofuStore>,
        peer_id: &str,
        expected_fingerprint: Option<&str>,
    ) -> std::io::Result<Self> {
        // Client crypto: TOFU verifier over the device identity —
        // endpoints need a default client config to dial out.
        // Server: present our certificate, no client-cert requirement
        // (the peer verifies ours; its identity comes from the TOFU
        // check on our side of the client role).
        // QUIC mandates TLS 1.3 — the shared TCP configs also offer
        // TLS 1.2, which quinn rejects.
        let server_crypto = tls::server_config_tls13(identity).map_err(std::io::Error::other)?;
        let server_config = quinn::ServerConfig::with_crypto(Arc::new(
            quinn::crypto::rustls::QuicServerConfig::try_from(server_crypto)
                .map_err(|e| std::io::Error::other(format!("quic tls: {e}")))?,
        ));
        let mut endpoint = quinn::Endpoint::server(server_config, bind)?;
        let client_crypto = tls::tofu_client_config_tls13(
            tofu,
            peer_id,
            expected_fingerprint,
            Some((identity.cert_der.as_slice(), identity.key_der.as_slice())),
        );
        let quinn_client = quinn::ClientConfig::new(Arc::new(
            quinn::crypto::rustls::QuicClientConfig::try_from(client_crypto)
                .map_err(|e| std::io::Error::other(format!("quic client tls: {e}")))?,
        ));
        endpoint.set_default_client_config(quinn_client);
        Ok(QuicTransport {
            endpoint,
            server_name: "localsend".to_string(),
        })
    }

    pub fn local_addr(&self) -> std::io::Result<SocketAddr> {
        self.endpoint.local_addr()
    }

    /// Dial a peer (this both punches the hole and, on success, runs
    /// the TLS handshake inside QUIC).
    pub async fn connect(&self, peer: SocketAddr) -> Result<quinn::Connection, String> {
        self.endpoint
            .connect(peer, &self.server_name)
            .map_err(|e| e.to_string())?
            .await
            .map_err(|e| e.to_string())
    }

    /// Accept an incoming connection (a peer punching toward us).
    pub async fn accept(&self) -> Option<quinn::Connection> {
        let incoming = self.endpoint.accept().await?;
        incoming.await.ok()
    }

    pub fn endpoint(&self) -> &quinn::Endpoint {
        &self.endpoint
    }
}

// ---------------------------------------------------------------------------
// HTTP/1.1 over a QUIC connection
// ---------------------------------------------------------------------------

/// Serve HTTP on every incoming stream of `conn` using the router.
/// One task per connection; runs until the connection dies.
pub async fn serve_http_on(conn: quinn::Connection, router: axum::Router) {
    while let Ok((tx, rx)) = conn.accept_bi().await {
        let router = router.clone();
        tokio::spawn(async move {
            let stream = QuicStream { tx, rx };
            if let Err(e) = serve_stream(stream, router).await {
                debug!("quic http stream ended: {e}");
            }
        });
    }
}

async fn serve_stream(
    mut stream: QuicStream,
    mut router: axum::Router,
) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    use tower::Service as _;

    // Read the request head (to the blank line).
    let mut head = Vec::with_capacity(1024);
    let mut chunk = [0u8; 1024];
    loop {
        if head.windows(4).any(|w| w == b"\r\n\r\n") {
            break;
        }
        let n = stream.read(&mut chunk).await?;
        if n == 0 {
            return Err(format!(
                "request head truncated after {} bytes: {:?}",
                head.len(),
                String::from_utf8_lossy(&head)
            )
            .into());
        }
        head.extend_from_slice(&chunk[..n]);
    }
    let head_text = String::from_utf8_lossy(&head);
    let mut lines = head_text.split("\r\n");
    let request_line = lines.next().unwrap_or_default();
    let mut parts = request_line.split_whitespace();
    let method = parts.next().unwrap_or("GET");
    let path = parts.next().unwrap_or("/");
    let _version = parts.next();

    // Content-Length announces the body, if any.
    let mut content_length: usize = 0;
    let mut content_type: Option<String> = None;
    for line in lines {
        if line.is_empty() {
            break;
        }
        if let Some((k, v)) = line.split_once(':') {
            if k.trim().eq_ignore_ascii_case("content-length") {
                content_length = v.trim().parse().unwrap_or(0);
            } else if k.trim().eq_ignore_ascii_case("content-type") {
                content_type = Some(v.trim().to_string());
            }
        }
    }
    let head_end = head
        .windows(4)
        .position(|w| w == b"\r\n\r\n")
        .map(|p| p + 4)
        .unwrap_or(head.len());
    let mut body = head[head_end..].to_vec();
    while body.len() < content_length {
        let n = stream.read(&mut chunk).await?;
        if n == 0 {
            break;
        }
        body.extend_from_slice(&chunk[..n]);
    }

    // Dispatch through the axum router (same handlers as TCP).
    let mut req = http::Request::builder().method(method).uri(path);
    if content_length > 0 {
        req = req.header("content-length", content_length);
    }
    if let Some(ct) = &content_type {
        req = req.header("content-type", ct);
    }
    let (mut parts, _) = req
        .body(())
        .map_err(|e| format!("build request: {e}"))?
        .into_parts();
    parts
        .extensions
        .insert(axum::extract::ConnectInfo(crate::server::ConnAddr(
            "0.0.0.0:0".parse().unwrap(),
        )));
    let req = http::Request::from_parts(parts, http_body_util::Full::new(bytes::Bytes::from(body)));
    let resp = router.call(req).await.map_err(|e| format!("router: {e}"))?;
    let (parts, resp_body) = resp.into_parts();
    let body_bytes = http_body_util::BodyExt::collect(resp_body)
        .await
        .map_err(|e| e.to_string())?
        .to_bytes();

    let mut out = format!(
        "HTTP/1.1 {} reason\r\ncontent-length: {}\r\nconnection: close\r\n\r\n",
        parts.status.as_u16(),
        body_bytes.len()
    )
    .into_bytes();
    out.extend_from_slice(&body_bytes);
    stream.write_all(&out).await?;
    stream.shutdown().await?;
    Ok(())
}

struct QuicStream {
    tx: quinn::SendStream,
    rx: quinn::RecvStream,
}

impl tokio::io::AsyncRead for QuicStream {
    fn poll_read(
        mut self: std::pin::Pin<&mut Self>,
        cx: &mut std::task::Context<'_>,
        buf: &mut tokio::io::ReadBuf<'_>,
    ) -> std::task::Poll<std::io::Result<()>> {
        std::pin::Pin::new(&mut self.rx).poll_read(cx, buf)
    }
}

impl tokio::io::AsyncWrite for QuicStream {
    fn poll_write(
        mut self: std::pin::Pin<&mut Self>,
        cx: &mut std::task::Context<'_>,
        buf: &[u8],
    ) -> std::task::Poll<Result<usize, std::io::Error>> {
        <quinn::SendStream as tokio::io::AsyncWrite>::poll_write(
            std::pin::Pin::new(&mut self.tx),
            cx,
            buf,
        )
    }

    fn poll_flush(
        mut self: std::pin::Pin<&mut Self>,
        cx: &mut std::task::Context<'_>,
    ) -> std::task::Poll<Result<(), std::io::Error>> {
        std::pin::Pin::new(&mut self.tx).poll_flush(cx)
    }

    fn poll_shutdown(
        mut self: std::pin::Pin<&mut Self>,
        cx: &mut std::task::Context<'_>,
    ) -> std::task::Poll<Result<(), std::io::Error>> {
        std::pin::Pin::new(&mut self.tx).poll_shutdown(cx)
    }
}

/// Minimal HTTP/1.1 client on one QUIC bidirectional stream: write
/// the request head + optional body, read the response head and
/// whatever body the `Content-Length` announces. LocalSend's API is
/// entirely small request/response pairs (the only large body is the
/// upload stream, which callers feed through `send_request_stream`).
pub async fn send_request(
    conn: &quinn::Connection,
    req: HttpRequest,
) -> Result<HttpResponse, String> {
    let (mut tx, mut rx) = conn.open_bi().await.map_err(|e| e.to_string())?;
    tx.write_all(&req.encode_head())
        .await
        .map_err(|e| e.to_string())?;
    if let Some(body) = req.body {
        tx.write_all(&body).await.map_err(|e| e.to_string())?;
    }
    // Half-close the send side so servers that read-to-EOF see the
    // request boundary; QUIC finish() does exactly that.
    tx.finish().map_err(|e| e.to_string())?;

    let mut buf = Vec::with_capacity(8192);
    let mut chunk = [0u8; 8192];
    let _ = tokio::time::timeout(std::time::Duration::from_secs(10), async {
        loop {
            match rx.read(&mut chunk).await {
                Ok(Some(0)) | Err(_) | Ok(None) => break,
                Ok(Some(n)) => buf.extend_from_slice(&chunk[..n]),
            }
        }
    })
    .await;
    HttpResponse::decode(&buf)
}

/// Streaming variant: body is written chunk by chunk while reporting
/// progress, mirroring `Client::upload_file`.
pub async fn send_request_stream(
    conn: &quinn::Connection,
    req: HttpRequest,
    mut body: tokio::fs::File,
    size: u64,
) -> Result<HttpResponse, String> {
    let (mut tx, mut rx) = conn.open_bi().await.map_err(|e| e.to_string())?;
    tx.write_all(&req.encode_head())
        .await
        .map_err(|e| e.to_string())?;
    let mut remaining = size;
    let mut chunk = vec![0u8; 256 * 1024];
    while remaining > 0 {
        let want = chunk.len().min(remaining as usize);
        let n = body
            .read(&mut chunk[..want])
            .await
            .map_err(|e| e.to_string())?;
        if n == 0 {
            break;
        }
        tx.write_all(&chunk[..n]).await.map_err(|e| e.to_string())?;
        remaining -= n as u64;
    }
    tx.finish().map_err(|e| e.to_string())?;

    let mut buf = Vec::with_capacity(8192);
    let mut rchunk = [0u8; 8192];
    loop {
        let n = rx.read(&mut rchunk).await.map_err(|e| e.to_string())?;
        match n {
            Some(0) | None => break,
            Some(n) => buf.extend_from_slice(&rchunk[..n]),
        }
    }
    HttpResponse::decode(&buf)
}

use tokio::io::AsyncReadExt as _;
use tokio::io::AsyncWriteExt as _;

#[derive(Debug, Clone)]
pub struct HttpRequest {
    pub method: String,
    pub path_and_query: String,
    pub host: String,
    pub content_type: Option<String>,
    pub content_length: Option<u64>,
    pub body: Option<Vec<u8>>,
}

impl HttpRequest {
    fn encode_head(&self) -> Vec<u8> {
        let mut head = format!(
            "{} {} HTTP/1.1\r\nhost: {}\r\nconnection: close\r\n",
            self.method, self.path_and_query, self.host
        )
        .into_bytes();
        if let Some(ct) = &self.content_type {
            head.extend_from_slice(format!("content-type: {ct}\r\n").as_bytes());
        }
        if let Some(len) = self.content_length {
            head.extend_from_slice(format!("content-length: {len}\r\n").as_bytes());
        }
        head.extend_from_slice(b"\r\n");
        head
    }
}

#[derive(Debug)]
pub struct HttpResponse {
    pub status: u16,
    pub body: Vec<u8>,
}

impl HttpResponse {
    fn decode(raw: &[u8]) -> Result<Self, String> {
        let text = String::from_utf8_lossy(raw);
        let mut lines = text.split("\r\n");
        let status_line = lines.next().ok_or("empty response")?;
        let status = status_line
            .split_whitespace()
            .nth(1)
            .and_then(|s| s.parse().ok())
            .ok_or_else(|| format!("bad status line: {status_line}"))?;
        let mut content_length: Option<u64> = None;
        for line in lines {
            if line.is_empty() {
                break;
            }
            if let Some(v) = line.split_once(':') {
                if v.0.trim().eq_ignore_ascii_case("content-length") {
                    content_length = v.1.trim().parse().ok();
                }
            }
        }
        // Body starts after the first \r\n\r\n.
        let body_start = raw
            .windows(4)
            .position(|w| w == b"\r\n\r\n")
            .map(|p| p + 4)
            .unwrap_or(raw.len());
        let mut body = raw[body_start..].to_vec();
        if let Some(len) = content_length {
            body.truncate(len as usize);
        }
        Ok(HttpResponse { status, body })
    }
}
