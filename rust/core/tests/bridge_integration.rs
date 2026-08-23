//! Full bridge relay integration test — sender + relay + receiver, all
//! in one process, exercising the EXACT path a cross-network send takes.

use tokio::io::{AsyncReadExt, AsyncWriteExt};

#[tokio::test]
async fn bridge_relay_end_to_end_transfer() {
    use localsend_core::relay::{serve_turn, TurnServerConfig};

    // === 1. Start the relay (TURN + HTTP + bridge on one port) ===
    let relay_port = {
        let l = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
        l.local_addr().unwrap().port()
    };
    let secret = "bridge-test-secret";
    tokio::spawn(async move {
        serve_turn(TurnServerConfig {
            listen: format!("127.0.0.1:{relay_port}").parse().unwrap(),
            external: std::net::Ipv4Addr::LOCALHOST,
            realm: "localsend".into(),
            secret: secret.into(),
            lifetime: std::time::Duration::from_secs(600),
        })
        .await
        .unwrap();
    });
    tokio::time::sleep(std::time::Duration::from_millis(300)).await;

    // === 2. Receiver: start a local HTTP echo server ===
    let rx_http = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let rx_http_port = rx_http.local_addr().unwrap().port();
    tokio::spawn(async move {
        loop {
            let Ok((mut s, _)) = rx_http.accept().await else {
                return;
            };
            tokio::spawn(async move {
                let mut b = [0u8; 8192];
                if let Ok(n) = s.read(&mut b).await {
                    // Echo: just return 200 with the body length.
                    let resp = format!(
                        "HTTP/1.1 200 OK\r\ncontent-length: 2\r\nconnection: close\r\n\r\nok"
                    );
                    let _ = s.write_all(resp.as_bytes()).await;
                    let _ = n;
                }
            });
        }
    });

    // === 3. Receiver: bridge listener (connect to relay, send LISTEN) ===
    let rx_fingerprint = "RECEIVER-FP-12345";
    let relay_addr = format!("127.0.0.1:{relay_port}");
    let la = relay_addr.clone();
    let fp = rx_fingerprint.to_string();
    let rx_http_p = rx_http_port;
    tokio::spawn(async move {
        loop {
            let Ok(mut conn) = tokio::net::TcpStream::connect(&la).await else {
                tokio::time::sleep(std::time::Duration::from_millis(200)).await;
                continue;
            };
            let _ = conn.set_nodelay(true);
            let mut hdr = String::from("BRIDGE LISTEN ");
            hdr.push_str(&fp);
            hdr.push('\n');
            if conn.write_all(hdr.as_bytes()).await.is_err() {
                continue;
            }
            eprintln!("[TEST] listener sent LISTEN for {fp}");
            // Proxy the tunnel to the local HTTP server.
            let Ok(mut local) =
                tokio::net::TcpStream::connect(format!("127.0.0.1:{rx_http_p}")).await
            else {
                continue;
            };
            let _ = local.set_nodelay(true);
            eprintln!("[TEST] listener connected to local HTTP, waiting for splice");
            tokio::io::copy_bidirectional(&mut conn, &mut local)
                .await
                .ok();
            eprintln!("[TEST] listener splice ended, reconnecting");
            tokio::time::sleep(std::time::Duration::from_millis(50)).await;
        }
    });
    tokio::time::sleep(std::time::Duration::from_millis(300)).await;

    // === 4. Sender: dial a bridge and send HTTP through it ===
    let mut hdr = String::from("BRIDGE CONNECT ");
    hdr.push_str(rx_fingerprint);
    hdr.push('\n');
    let mut tunnel = tokio::net::TcpStream::connect(&relay_addr)
        .await
        .expect("conn relay");
    let _ = tunnel.set_nodelay(true);
    tunnel
        .write_all(hdr.as_bytes())
        .await
        .expect("send CONNECT");
    eprintln!("[TEST] sender sent CONNECT");

    // Read the BRIDGE OK handshake.
    let mut hs = [0u8; 64];
    let n = tokio::time::timeout(std::time::Duration::from_secs(3), tunnel.read(&mut hs))
        .await
        .expect("handshake timeout")
        .expect("hs read failed");
    assert!(
        &hs[..n] == b"BRIDGE OK\n",
        "expected BRIDGE OK, got: {:?}",
        String::from_utf8_lossy(&hs[..n])
    );

    // Send an HTTP request through the tunnel.
    let http_req = "GET /test HTTP/1.1\r\nhost: x\r\nconnection: close\r\n\r\n";
    tunnel
        .write_all(http_req.as_bytes())
        .await
        .expect("send http");

    // Read the HTTP response.
    let mut resp = vec![0u8; 1024];
    match tokio::time::timeout(std::time::Duration::from_secs(5), tunnel.read(&mut resp)).await {
        Ok(Ok(n)) if n > 0 => {
            let text = String::from_utf8_lossy(&resp[..n]);
            eprintln!("[TEST] sender got response: {text}");
            assert!(text.contains("200"), "expected 200, got: {text}");
        }
        other => panic!("bridge tunnel read failed: {other:?}"),
    }
}

#[tokio::test]
async fn bridge_relay_multi_request_session() {
    use localsend_core::relay::{serve_turn, TurnServerConfig};

    let relay_port = {
        let l = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
        l.local_addr().unwrap().port()
    };
    tokio::spawn(async move {
        serve_turn(TurnServerConfig {
            listen: format!("127.0.0.1:{relay_port}").parse().unwrap(),
            secret: "s".into(),
            ..TurnServerConfig::default()
        })
        .await
        .unwrap();
    });
    tokio::time::sleep(std::time::Duration::from_millis(300)).await;

    // Receiver HTTP server
    let rx_http = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let rx_port = rx_http.local_addr().unwrap().port();
    tokio::spawn(async move {
        loop {
            let Ok((mut s, _)) = rx_http.accept().await else {
                return;
            };
            tokio::spawn(async move {
                let mut b = [0u8; 4096];
                let _ = s.read(&mut b).await;
                let resp = "HTTP/1.1 200 OK\r\ncontent-length: 2\r\nconnection: close\r\n\r\nok";
                let _ = s.write_all(resp.as_bytes()).await;
            });
        }
    });

    // Receiver listener
    let fp = "multi-test-fp";
    let ra = format!("127.0.0.1:{relay_port}");
    let ra2 = ra.clone();
    tokio::spawn(async move {
        loop {
            let Ok(mut conn) = tokio::net::TcpStream::connect(&ra2).await else {
                continue;
            };
            let mut h = String::from("BRIDGE LISTEN ");
            h.push_str(fp);
            h.push('\n');
            if conn.write_all(h.as_bytes()).await.is_err() {
                continue;
            }
            eprintln!("[MULTI-TEST] LISTEN sent for {}", fp);
            eprintln!("[MULTI-TEST] listener sent LISTEN for {fp}");
            let Ok(mut local) =
                tokio::net::TcpStream::connect(format!("127.0.0.1:{rx_port}")).await
            else {
                continue;
            };
            eprintln!("[MULTI-TEST] listener waiting for splice");
            tokio::io::copy_bidirectional(&mut conn, &mut local)
                .await
                .ok();
            eprintln!("[MULTI-TEST] splice ended, reconnecting");
            tokio::time::sleep(std::time::Duration::from_millis(50)).await;
        }
    });
    tokio::time::sleep(std::time::Duration::from_millis(300)).await;

    // Sender: 3 sequential requests with fresh bridge + retry.
    for i in 0..3 {
        let mut t = None;
        for _ in 0..15 {
            let mut conn = tokio::net::TcpStream::connect(&ra).await.unwrap();
            let mut h = String::from("BRIDGE CONNECT ");
            h.push_str(fp);
            h.push('\n');
            conn.write_all(h.as_bytes()).await.unwrap();
            let mut resp = [0u8; 64];
            match tokio::time::timeout(std::time::Duration::from_secs(2), conn.read(&mut resp))
                .await
            {
                Ok(Ok(n)) if &resp[..n.min(9)] == b"BRIDGE OK" => {
                    eprintln!("[MULTI-TEST] bridge OK");
                    t = Some(conn);
                    break;
                }
                Ok(Ok(n)) => {
                    eprintln!(
                        "[MULTI-TEST] bridge resp: {:?}",
                        String::from_utf8_lossy(&resp[..n])
                    );
                    drop(conn);
                    tokio::time::sleep(std::time::Duration::from_millis(200)).await;
                }
                _ => {
                    eprintln!("[MULTI-TEST] bridge timeout/err");
                    drop(conn);
                    tokio::time::sleep(std::time::Duration::from_millis(200)).await;
                }
            }
        }
        let mut t = t.unwrap_or_else(|| panic!("req {i}: no bridge after retries"));
        let req = format!(
            "GET /req{} HTTP/1.1\r\nhost: x\r\nconnection: close\r\n\r\n",
            i
        );
        t.write_all(req.as_bytes()).await.unwrap();
        let mut buf = vec![0u8; 512];
        match tokio::time::timeout(std::time::Duration::from_secs(3), t.read(&mut buf)).await {
            Ok(Ok(n)) if n > 0 => {
                let text = String::from_utf8_lossy(&buf[..n]);
                assert!(text.contains("200"), "req {i} got: {text}");
            }
            other => panic!("req {i} failed: {other:?}"),
        }
    }
}
