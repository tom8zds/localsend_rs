//! `localsend-cli diagnose` — step-by-step relay link test.
//!
//! Tests each stage independently and prints PASS/FAIL with details,
//! so both the user and the developer can see exactly where the
//! cross-network path breaks. No guessing.

use reqwest;
use serde_json;

use anyhow::Result;
use localsend_core::relay::{self, RelaySettings};

fn ok(step: &str, detail: impl std::fmt::Display) {
    println!("  ✓ {step}  {detail}");
}

fn fail(step: &str, detail: impl std::fmt::Display) {
    println!("  ✗ {step}  {detail}");
}

pub async fn run(addr: &str, secret: &str) -> Result<()> {
    println!("diagnosing relay link: {addr} (secret: {secret})");
    println!();

    // Step 1: TCP reachability
    print!("1. TCP connect to relay  ");
    let sock: std::net::SocketAddr = addr
        .parse()
        .map_err(|e| anyhow::anyhow!("invalid address '{addr}': {e}"))?;
    match tokio::time::timeout(
        std::time::Duration::from_secs(5),
        tokio::net::TcpStream::connect(sock),
    )
    .await
    {
        Ok(Ok(_)) => {
            ok("", "connected");
        }
        Ok(Err(e)) => {
            fail("", "refused/errored");
            println!("     → {e}");
            println!("\n  The relay server is not accepting connections on {addr}.");
            println!("    Check: firewall (3478/tcp), relay process running, --listen 0.0.0.0");
            anyhow::bail!("cannot reach relay");
        }
        Err(_) => {
            fail("", "timeout (5s)");
            println!("\n  The relay is unreachable (timeout). Check network/firewall.");
            anyhow::bail!("relay unreachable");
        }
    }

    // Step 2: STUN probe (mapped address)
    print!("2. STUN binding probe     ");
    match tokio::time::timeout(std::time::Duration::from_secs(5), relay::probe(addr)).await {
        Ok(Ok((rt, mapped))) => {
            let mapped_str = mapped
                .map(|m| m.to_string())
                .unwrap_or_else(|| "(none)".into());
            ok("", format!("{}ms, mapped={mapped_str}", rt.as_millis()));
        }
        Ok(Err(e)) => {
            fail("", format!("STUN error: {e}"));
            println!("     → relay may be old binary without STUN binding support");
        }
        Err(_) => fail("", "timeout"),
    }

    // Step 3: BRIDGE protocol support
    print!("3. BRIDGE protocol       ");
    {
        use tokio::io::{AsyncReadExt, AsyncWriteExt};
        let mut conn = tokio::net::TcpStream::connect(sock).await?;
        conn.write_all(b"BRIDGE CONNECT diagnose-probe-no-listener\n")
            .await?;
        let mut resp = [0u8; 64];
        match tokio::time::timeout(std::time::Duration::from_secs(5), conn.read(&mut resp)).await {
            Ok(Ok(n)) => {
                let text = String::from_utf8_lossy(&resp[..n]);
                if text.contains("NOT_FOUND") {
                    ok("", "relay supports BRIDGE (NOT_FOUND as expected)");
                } else if text.contains("OK") {
                    ok(
                        "",
                        "relay supports BRIDGE (unexpected OK — probe matches a listener?)",
                    );
                } else {
                    fail("", format!("unexpected reply: {text:?}"));
                    println!("     → relay binary may not support BRIDGE protocol (old version?)");
                }
            }
            Ok(Err(e)) => fail("", format!("read error: {e}")),
            Err(_) => {
                fail("", "timeout (relay didn't reply to BRIDGE)");
                println!("     → relay binary is OLD (no BRIDGE support). Update the server.");
            }
        }
    }

    // Step 4: BRIDGE OK handshake check (byte comparison)
    print!("4. BRIDGE handshake parse");
    {
        use tokio::io::{AsyncReadExt, AsyncWriteExt};
        let mut conn = tokio::net::TcpStream::connect(sock).await?;
        conn.write_all(b"BRIDGE CONNECT diagnose-probe-no-listener\n")
            .await?;
        let mut resp = [0u8; 64];
        if let Ok(Ok(n)) =
            tokio::time::timeout(std::time::Duration::from_secs(3), conn.read(&mut resp)).await
        {
            let text = String::from_utf8_lossy(&resp[..n]);
            if text.starts_with("BRIDGE NOT_FOUND") {
                ok("", "handshake parse correct");
            } else if text.starts_with("BRIDGE OK") {
                // This means someone has fingerprint "diagnose-probe-no-listener"
                ok("", "got OK (unexpected but parseable)");
            } else {
                fail("", format!("unparseable: {text:?}"));
            }
        }
    }

    // Step 5: Discovery heartbeat (register + get list)
    print!("5. Discovery heartbeat  ");
    {
        let expiry = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            + 60;
        let (username, password) = relay::generate_credentials(secret, expiry, "diagnose");
        let url = format!("http://{addr}/api/discovery/register");
        let payload = serde_json::json!({
            "fingerprint": "diagnose-probe",
            "alias": "diagnose",
            "deviceModel": "cli",
            "deviceType": "headless",
            "protocol": "https",
            "port": 0,
            "username": username,
            "candidates": [],
        });
        let client = reqwest::Client::new();
        match tokio::time::timeout(
            std::time::Duration::from_secs(5),
            client
                .post(&url)
                .header("Authorization", format!("Bearer {password}"))
                .json(&payload)
                .send(),
        )
        .await
        {
            Ok(Ok(resp)) => {
                let status = resp.status();
                if status.is_success() {
                    if let Ok(list) = resp.json::<serde_json::Value>().await {
                        let count = list.as_array().map(|a| a.len()).unwrap_or(0);
                        let devices: Vec<String> = list
                            .as_array()
                            .map(|a| {
                                a.iter()
                                    .filter_map(|d| {
                                        d.get("alias").and_then(|v| v.as_str()).map(String::from)
                                    })
                                    .collect()
                            })
                            .unwrap_or_default();
                        ok("", format!("{count} device(s): {devices:?}"));
                    } else {
                        fail("", "got 200 but can't parse list");
                    }
                } else {
                    fail("", format!("HTTP {status}"));
                    println!("     → credential auth failed or relay discovery not running");
                }
            }
            Ok(Err(e)) => fail("", format!("request error: {e}")),
            Err(_) => fail("", "timeout"),
        }
    }

    // Step 6: Full bridge round-trip (LISTEN + CONNECT + data)
    print!("6. Bridge data path     ");
    {
        use tokio::io::{AsyncReadExt, AsyncWriteExt};

        // Echo server
        let echo = tokio::net::TcpListener::bind("127.0.0.1:0").await?;
        let echo_port = echo.local_addr()?.port();
        tokio::spawn(async move {
            loop {
                let Ok((mut s, _)) = echo.accept().await else {
                    return;
                };
                tokio::spawn(async move {
                    let mut b = [0u8; 1024];
                    if let Ok(n) = s.read(&mut b).await {
                        let _ = s.write_all(b"bridge-echo-ok").await;
                        let _ = n;
                    }
                });
            }
        });

        // Listener
        let mut listener = tokio::net::TcpStream::connect(sock).await?;
        let fp = "diagnose-bridge-rt";
        listener
            .write_all(format!("BRIDGE LISTEN {fp}\n").as_bytes())
            .await?;

        // Connect local echo
        let mut local = tokio::net::TcpStream::connect(("127.0.0.1", echo_port)).await?;

        // Give listener time to register
        tokio::time::sleep(std::time::Duration::from_millis(300)).await;

        // Sender
        let mut sender = tokio::net::TcpStream::connect(sock).await?;
        sender
            .write_all(format!("BRIDGE CONNECT {fp}\n").as_bytes())
            .await?;

        // Read handshake
        let mut hs = [0u8; 64];
        match tokio::time::timeout(std::time::Duration::from_secs(5), sender.read(&mut hs)).await {
            Ok(Ok(n)) => {
                let text = String::from_utf8_lossy(&hs[..n]);
                if !text.starts_with("BRIDGE OK") {
                    fail("", "handshake rejected");
                    anyhow::bail!("bridge handshake failed: {text:?}");
                }
            }
            Ok(Err(e)) => {
                fail("", format!("handshake error: {e}"));
                anyhow::bail!("bridge handshake error");
            }
            Err(_) => {
                fail("", "handshake timeout");
                anyhow::bail!("bridge handshake timeout");
            }
        }

        // Send data through bridge
        sender.write_all(b"ping").await?;
        tokio::time::sleep(std::time::Duration::from_millis(200)).await;

        // Listener proxies to echo
        let mut lbuf = [0u8; 128];
        if let Ok(Ok(ln)) =
            tokio::time::timeout(std::time::Duration::from_secs(5), listener.read(&mut lbuf)).await
        {
            local.write_all(&lbuf[..ln]).await?;
        }

        // Read echo response
        let mut ebuf = [0u8; 128];
        if let Ok(Ok(en)) =
            tokio::time::timeout(std::time::Duration::from_secs(3), local.read(&mut ebuf)).await
        {
            listener.write_all(&ebuf[..en]).await?;
        }

        // Sender reads response
        let mut rbuf = [0u8; 128];
        match tokio::time::timeout(std::time::Duration::from_secs(5), sender.read(&mut rbuf)).await
        {
            Ok(Ok(n)) => {
                let text = String::from_utf8_lossy(&rbuf[..n]);
                if text.contains("bridge-echo-ok") {
                    ok("", format!("data round-trip: {text:?}"));
                } else {
                    fail("", format!("unexpected data: {text:?}"));
                }
            }
            Ok(Err(e)) => fail("", format!("read error: {e}")),
            Err(_) => fail("", "response timeout"),
        }
    }

    println!();
    println!("done.");
    println!();
    println!("If steps 1-5 pass but step 6 fails, the relay supports BRIDGE");
    println!("but the data path is broken. If step 3 fails, the relay binary");
    println!("is outdated — update the server with the latest musl binary.");

    Ok(())
}

// Re-export for the CLI
