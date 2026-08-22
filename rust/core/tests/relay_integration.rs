//! End-to-end relay flow against a real turn-rs server.
//!
//! Requires the local relay from `docker/turn` to be running
//! (`docker compose -f docker/turn/compose.yaml up -d`) — hence the
//! `#[ignore]`; run with `cargo test -p localsend_core --test
//! relay_integration -- --ignored`.

use std::time::Duration;

use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};

use localsend_core::relay::{dial_via_relay, endpoint_from_secret};

const SECRET: &str = "localsend-relay-test-secret";

/// A trivial TCP echo server on loopback, standing in for the
/// receiving localsend endpoint.
async fn spawn_echo() -> std::net::SocketAddr {
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        loop {
            let Ok((mut sock, _)) = listener.accept().await else {
                return;
            };
            tokio::spawn(async move {
                let mut buf = [0u8; 4096];
                loop {
                    match sock.read(&mut buf).await {
                        Ok(0) | Err(_) => return,
                        Ok(n) => {
                            if sock.write_all(&buf[..n]).await.is_err() {
                                return;
                            }
                        }
                    }
                }
            });
        }
    });
    addr
}

#[tokio::test]
#[ignore = "needs docker/turn relay on 127.0.0.1:3478"]
async fn tunnels_bytes_through_a_real_turn_server() {
    let echo_addr = spawn_echo().await;

    let relay = endpoint_from_secret("127.0.0.1:3478", SECRET, 600, "it", "");
    let mut tunnel = dial_via_relay(&relay, echo_addr).await.expect("relay dial");

    let payload = b"hello through the relay";
    tunnel.write_all(payload).await.unwrap();
    tunnel.flush().await.unwrap();

    let mut buf = vec![0u8; payload.len()];
    tokio::time::timeout(Duration::from_secs(5), tunnel.read_exact(&mut buf))
        .await
        .expect("echo timed out")
        .unwrap();
    assert_eq!(&buf, payload);
}

#[tokio::test]
#[ignore = "needs docker/turn relay on 127.0.0.1:3478"]
async fn rejects_a_peer_that_refuses_the_connection() {
    // Bind then immediately drop a listener so the port is closed.
    let refuse_addr = {
        let l = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let a = l.local_addr().unwrap();
        drop(l);
        a
    };

    let relay = endpoint_from_secret("127.0.0.1:3478", SECRET, 600, "it", "");
    let result = dial_via_relay(&relay, refuse_addr).await;
    assert!(result.is_err(), "expected connect refusal via relay");
}

/// The control connection must not be shared across dials; two
/// concurrent tunnels to the same peer must both work.
#[tokio::test]
#[ignore = "needs docker/turn relay on 127.0.0.1:3478"]
async fn two_concurrent_tunnels_are_independent() {
    let echo_addr = spawn_echo().await;
    let relay = endpoint_from_secret("127.0.0.1:3478", SECRET, 600, "it", "");

    let (a, b) = tokio::join!(
        dial_via_relay(&relay, echo_addr),
        dial_via_relay(&relay, echo_addr)
    );
    let mut a = a.expect("first tunnel");
    let mut b = b.expect("second tunnel");

    a.write_all(b"first").await.unwrap();
    b.write_all(b"second").await.unwrap();

    let mut buf = [0u8; 5];
    tokio::time::timeout(Duration::from_secs(5), a.read_exact(&mut buf))
        .await
        .unwrap()
        .unwrap();
    assert_eq!(&buf, b"first");
    tokio::time::timeout(Duration::from_secs(5), b.read_exact(&mut buf))
        .await
        .unwrap()
        .unwrap();
    assert_eq!(&buf, b"secon".as_slice());
    let mut rest = [0u8; 1];
    b.read_exact(&mut rest).await.unwrap();
    assert_eq!(&rest, b"d");
    let _ = TcpStream::connect("127.0.0.1:3478").await;
}

// ---------------------------------------------------------------------------
// embedded TURN server (turn_server.rs) — client ⇄ own-server loopback
// ---------------------------------------------------------------------------

/// Full loopback through `localsend-cli relay`'s embedded server:
/// issue REST credentials, dial an echo server through the embedded
/// TURN server, and verify the bytes round-trip.
#[tokio::test]
async fn embedded_turn_server_relays_bytes() {
    use localsend_core::relay::{serve_turn, TurnServerConfig};

    let secret = "embedded-test-secret";
    let port = {
        let l = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
        l.local_addr().unwrap().port()
    };
    tokio::spawn(async move {
        let cfg = TurnServerConfig {
            listen: format!("127.0.0.1:{port}").parse().unwrap(),
            external: std::net::Ipv4Addr::LOCALHOST,
            realm: "localsend".into(),
            secret: secret.into(),
            lifetime: std::time::Duration::from_secs(600),
        };
        serve_turn(cfg).await.unwrap();
    });
    tokio::time::sleep(std::time::Duration::from_millis(200)).await;

    let echo = spawn_echo().await;
    let relay = endpoint_from_secret(&format!("127.0.0.1:{port}"), secret, 600, "it", "localsend");
    let mut tunnel = dial_via_relay(&relay, echo)
        .await
        .expect("dial embedded relay");
    let payload = b"hello through the embedded server";
    tunnel.write_all(payload).await.unwrap();
    tunnel.flush().await.unwrap();
    let mut buf = vec![0u8; payload.len()];
    tokio::time::timeout(
        std::time::Duration::from_secs(5),
        tunnel.read_exact(&mut buf),
    )
    .await
    .expect("echo via embedded server timed out")
    .unwrap();
    assert_eq!(&buf, payload);
}

#[tokio::test]
async fn embedded_turn_server_rejects_bad_secret() {
    use localsend_core::relay::{serve_turn, TurnServerConfig};

    let secret = "right-secret";
    let port = {
        let l = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
        l.local_addr().unwrap().port()
    };
    tokio::spawn(async move {
        let cfg = TurnServerConfig {
            listen: format!("127.0.0.1:{port}").parse().unwrap(),
            external: std::net::Ipv4Addr::LOCALHOST,
            realm: "localsend".into(),
            secret: secret.into(),
            lifetime: std::time::Duration::from_secs(600),
        };
        serve_turn(cfg).await.unwrap();
    });
    tokio::time::sleep(std::time::Duration::from_millis(200)).await;

    let echo = spawn_echo().await;
    let relay = endpoint_from_secret(
        &format!("127.0.0.1:{port}"),
        "wrong-secret",
        600,
        "it",
        "localsend",
    );
    let result = dial_via_relay(&relay, echo).await;
    assert!(result.is_err(), "bad-secret dial must fail");
}

#[tokio::test]
async fn embedded_turn_server_answers_stun_ping() {
    use localsend_core::relay::{serve_turn, TurnServerConfig};
    let port = {
        let l = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
        l.local_addr().unwrap().port()
    };
    tokio::spawn(async move {
        serve_turn(TurnServerConfig {
            listen: format!("127.0.0.1:{port}").parse().unwrap(),
            secret: "s".into(),
            ..TurnServerConfig::default()
        })
        .await
        .unwrap();
    });
    tokio::time::sleep(std::time::Duration::from_millis(200)).await;
    localsend_core::relay::ping(&format!("127.0.0.1:{port}"))
        .await
        .expect("embedded server must answer STUN binding");
}
