//! End-to-end tests: two (or three) `CoreHandle` instances talking over
//! loopback HTTP. Multicast discovery is disabled; peers are addressed
//! directly via `NodeDevice::manual`.

use std::path::{Path, PathBuf};
use std::time::Duration;

use localsend_core::{
    CoreConfig, CoreHandle, CoreOptions, MissionState, NodeDevice, SessionDirection, SessionSummary,
};
use tokio::io::AsyncWriteExt;

const TIMEOUT: Duration = Duration::from_secs(15);

/// Ask the OS for a free port (the core's own port-retry adds
/// resilience against the bind race).
fn free_port() -> u16 {
    std::net::TcpListener::bind(("127.0.0.1", 0))
        .unwrap()
        .local_addr()
        .unwrap()
        .port()
}

fn test_device(alias: &str, port: u16) -> NodeDevice {
    NodeDevice {
        alias: alias.to_string(),
        version: "2.2".to_string(),
        device_model: "test".to_string(),
        device_type: "test".to_string(),
        fingerprint: format!("fp-{alias}"),
        address: "127.0.0.1".to_string(),
        port,
        protocol: "http".to_string(),
        download: true,
        announcement: false,
        announce: false,
    }
}

fn test_config(port: u16, store_path: &Path) -> CoreConfig {
    CoreConfig {
        port,
        interface_addr: "127.0.0.1".to_string(),
        multicast_addr: "224.0.0.167".to_string(),
        multicast_port: 53317,
        relay_addr: None,
        relay_secret: None,
        identity_dir: None,
        allow_plain_tls: None,
        store_path: store_path.to_string_lossy().to_string(),
    }
}

async fn make_core(alias: &str, port: u16, store_path: &Path) -> CoreHandle {
    make_core_with(alias, port, store_path, CoreOptions::default()).await
}

async fn make_core_with(
    alias: &str,
    port: u16,
    store_path: &Path,
    mut options: CoreOptions,
) -> CoreHandle {
    options.enable_discovery = false;
    let core = CoreHandle::with_options(
        test_device(alias, port),
        test_config(port, store_path),
        options,
    );
    core.start().await;
    assert!(
        *core.server_state().await.borrow(),
        "server of {alias} failed to start"
    );
    core
}

async fn write_file(dir: &Path, name: &str, content: &[u8]) -> PathBuf {
    let path = dir.join(name);
    let mut f = tokio::fs::File::create(&path).await.unwrap();
    f.write_all(content).await.unwrap();
    f.flush().await.unwrap();
    path
}

fn target_of(port: u16) -> NodeDevice {
    NodeDevice::manual(&format!("127.0.0.1:{port}")).unwrap()
}

/// Spawn an auto-accept loop: every pending receive session is accepted
/// (optionally with a file subset).
fn auto_accept(core: CoreHandle) -> tokio::task::JoinHandle<()> {
    tokio::spawn(async move {
        let mut rx = core.session_index().await;
        loop {
            let pending: Vec<String> = rx
                .borrow()
                .iter()
                .filter(|s| {
                    s.direction == SessionDirection::Receive && s.state == MissionState::Pending
                })
                .map(|s| s.id.clone())
                .collect();
            for id in pending {
                let _ = core.accept(&id, None).await;
            }
            if rx.changed().await.is_err() {
                return;
            }
        }
    })
}

/// Wait until `pred` matches a session summary.
async fn wait_session<F: Fn(&SessionSummary) -> bool>(core: &CoreHandle, id: &str, pred: F) {
    let mut rx = core.session_index().await;
    let result = tokio::time::timeout(TIMEOUT, async move {
        loop {
            if let Some(s) = rx.borrow().iter().find(|s| s.id == id) {
                if pred(s) {
                    return;
                }
            }
            rx.changed().await.unwrap();
        }
    })
    .await;
    if result.is_err() {
        let event = core.session_events(id).await.map(|rx| rx.borrow().clone());
        let index = core.session_index().await.borrow().clone();
        panic!("timed out waiting for session {id}; last event: {event:?}; index: {index:?}");
    }
}

async fn read_file(path: &Path) -> Vec<u8> {
    tokio::fs::read(path).await.unwrap()
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[tokio::test]
async fn send_receive_multi_file() {
    let tmp = tempfile::tempdir().unwrap();
    let (dir_a, dir_b) = (tmp.path().join("a"), tmp.path().join("b"));
    tokio::fs::create_dir_all(&dir_a).await.unwrap();
    tokio::fs::create_dir_all(&dir_b).await.unwrap();

    let (port_a, port_b) = (free_port(), free_port());
    let a = make_core("a", port_a, &dir_a).await;
    let b = make_core("b", port_b, &dir_b).await;
    let accept = auto_accept(b.clone());

    let content1 = b"hello localsend".to_vec();
    let content2: Vec<u8> = (0..100_000u32).map(|i| (i % 251) as u8).collect();
    let f1 = write_file(&dir_a, "one.txt", &content1).await;
    let f2 = write_file(&dir_a, "two.bin", &content2).await;

    let session_id = a.send_files(target_of(port_b), vec![f1, f2]).await.unwrap();

    // Sender side reaches Finished.
    wait_session(&a, &session_id, |s| s.state == MissionState::Finished).await;

    // Receiver side: the mirrored receive session finishes too and the
    // contents match.
    let mut rx = b.session_index().await;
    let recv_id = tokio::time::timeout(TIMEOUT, async {
        loop {
            if let Some(s) = rx
                .borrow()
                .iter()
                .find(|s| s.direction == SessionDirection::Receive)
            {
                if s.state == MissionState::Finished {
                    return s.id.clone();
                }
            }
            rx.changed().await.unwrap();
        }
    })
    .await
    .expect("receive session did not finish");

    assert_eq!(read_file(&dir_b.join("one.txt")).await, content1);
    assert_eq!(read_file(&dir_b.join("two.bin")).await, content2);

    // Per-session event stream was observable.
    let events = a.session_events(&session_id).await;
    assert!(events.is_some());
    let recv_events = b.session_events(&recv_id).await;
    assert!(recv_events.is_some());

    accept.abort();
    a.shutdown().await;
    b.shutdown().await;
}

#[tokio::test]
async fn decline_is_reported_to_sender() {
    let tmp = tempfile::tempdir().unwrap();
    let (dir_a, dir_b) = (tmp.path().join("a"), tmp.path().join("b"));
    tokio::fs::create_dir_all(&dir_a).await.unwrap();
    tokio::fs::create_dir_all(&dir_b).await.unwrap();

    let (port_a, port_b) = (free_port(), free_port());
    let a = make_core("a", port_a, &dir_a).await;
    let b = make_core("b", port_b, &dir_b).await;

    // Decline every incoming session.
    let b_clone = b.clone();
    let decliner = tokio::spawn(async move {
        let mut rx = b_clone.session_index().await;
        loop {
            let pending: Vec<String> = rx
                .borrow()
                .iter()
                .filter(|s| {
                    s.direction == SessionDirection::Receive && s.state == MissionState::Pending
                })
                .map(|s| s.id.clone())
                .collect();
            for id in pending {
                let _ = b_clone.decline(&id).await;
            }
            if rx.changed().await.is_err() {
                return;
            }
        }
    });

    let f = write_file(&dir_a, "refused.txt", b"nope").await;
    let session_id = a.send_files(target_of(port_b), vec![f]).await.unwrap();

    wait_session(&a, &session_id, |s| s.state == MissionState::Failed).await;

    // The failure reason mentions the decline.
    let mut events = a.session_events(&session_id).await.unwrap();
    let mut saw_failed = false;
    let _ = tokio::time::timeout(Duration::from_secs(2), async {
        loop {
            let ev = events.borrow().clone();
            if let localsend_core::SessionEvent::Failed { reason } = ev {
                assert!(reason.contains("declined"), "unexpected reason: {reason}");
                saw_failed = true;
                return;
            }
            if events.changed().await.is_err() {
                return;
            }
        }
    })
    .await;
    assert!(saw_failed, "no Failed event observed");

    assert!(!dir_b.join("refused.txt").exists());

    decliner.abort();
    a.shutdown().await;
    b.shutdown().await;
}

#[tokio::test]
async fn cancel_during_transfer() {
    let tmp = tempfile::tempdir().unwrap();
    let (dir_a, dir_b) = (tmp.path().join("a"), tmp.path().join("b"));
    tokio::fs::create_dir_all(&dir_a).await.unwrap();
    tokio::fs::create_dir_all(&dir_b).await.unwrap();

    let (port_a, port_b) = (free_port(), free_port());
    let a = make_core("a", port_a, &dir_a).await;
    let b = make_core("b", port_b, &dir_b).await;
    let accept = auto_accept(b.clone());

    // 64 MiB: large enough that the transfer is still in flight when the
    // receiver cancels right after accepting.
    let content: Vec<u8> = (0..64 * 1024 * 1024u32).map(|i| (i % 253) as u8).collect();
    let f = write_file(&dir_a, "big.bin", &content).await;

    let b_clone = b.clone();
    let canceller = tokio::spawn(async move {
        let mut rx = b_clone.session_index().await;
        loop {
            let active: Vec<String> = rx
                .borrow()
                .iter()
                .filter(|s| {
                    s.direction == SessionDirection::Receive && s.state == MissionState::Transfering
                })
                .map(|s| s.id.clone())
                .collect();
            if let Some(id) = active.into_iter().next() {
                b_clone.cancel(&id).await;
                return;
            }
            if rx.changed().await.is_err() {
                return;
            }
        }
    });

    let session_id = a.send_files(target_of(port_b), vec![f]).await.unwrap();

    // Receiver session ends up canceled...
    tokio::time::timeout(TIMEOUT, async {
        let mut rx = b.session_index().await;
        loop {
            if rx.borrow().iter().any(|s| {
                s.direction == SessionDirection::Receive && s.state == MissionState::Canceled
            }) {
                return;
            }
            rx.changed().await.unwrap();
        }
    })
    .await
    .expect("receiver session was not canceled");

    // ...and the sender session terminates (failed, not finished).
    wait_session(&a, &session_id, |s| {
        matches!(s.state, MissionState::Failed | MissionState::Canceled)
    })
    .await;
    wait_session(&a, &session_id, |s| s.state != MissionState::Transfering).await;
    let summary = a
        .session_index()
        .await
        .borrow()
        .iter()
        .find(|s| s.id == session_id)
        .cloned();
    assert_ne!(summary.map(|s| s.state), Some(MissionState::Finished));

    accept.abort();
    canceller.abort();
    a.shutdown().await;
    b.shutdown().await;
}

#[tokio::test]
async fn concurrent_receive_from_two_senders() {
    let tmp = tempfile::tempdir().unwrap();
    let (dir_a, dir_b, dir_c) = (
        tmp.path().join("a"),
        tmp.path().join("b"),
        tmp.path().join("c"),
    );
    for d in [&dir_a, &dir_b, &dir_c] {
        tokio::fs::create_dir_all(d).await.unwrap();
    }

    let (port_a, port_b, port_c) = (free_port(), free_port(), free_port());
    let a = make_core("a", port_a, &dir_a).await;
    let b = make_core("b", port_b, &dir_b).await;
    let c = make_core("c", port_c, &dir_c).await;
    let accept = auto_accept(a.clone());

    let content_b = b"from b".to_vec();
    let content_c = b"from c".to_vec();
    let fb = write_file(&dir_b, "b.txt", &content_b).await;
    let fc = write_file(&dir_c, "c.txt", &content_c).await;

    let (sb, sc) = tokio::join!(
        b.send_files(target_of(port_a), vec![fb]),
        c.send_files(target_of(port_a), vec![fc]),
    );
    let sb = sb.unwrap();
    let sc = sc.unwrap();

    tokio::join!(
        wait_session(&b, &sb, |s| s.state == MissionState::Finished),
        wait_session(&c, &sc, |s| s.state == MissionState::Finished),
    );

    assert_eq!(read_file(&dir_a.join("b.txt")).await, content_b);
    assert_eq!(read_file(&dir_a.join("c.txt")).await, content_c);

    accept.abort();
    a.shutdown().await;
    b.shutdown().await;
    c.shutdown().await;
}

#[tokio::test]
async fn concurrent_send_to_two_targets_and_queue_same_target() {
    let tmp = tempfile::tempdir().unwrap();
    let (dir_a, dir_b, dir_c) = (
        tmp.path().join("a"),
        tmp.path().join("b"),
        tmp.path().join("c"),
    );
    for d in [&dir_a, &dir_b, &dir_c] {
        tokio::fs::create_dir_all(d).await.unwrap();
    }

    let (port_a, port_b, port_c) = (free_port(), free_port(), free_port());
    let a = make_core("a", port_a, &dir_a).await;
    let b = make_core("b", port_b, &dir_b).await;
    let c = make_core("c", port_c, &dir_c).await;
    let accept_b = auto_accept(b.clone());
    let accept_c = auto_accept(c.clone());

    let c1 = b"batch one".to_vec();
    let c2 = b"batch two".to_vec();
    let c3 = b"for c".to_vec();
    let f1 = write_file(&dir_a, "one.txt", &c1).await;
    let f2 = write_file(&dir_a, "two.txt", &c2).await;
    let f3 = write_file(&dir_a, "three.txt", &c3).await;

    // Two sessions to b (must queue, but both complete) plus one to c
    // (runs concurrently).
    let (s1, s2, s3) = tokio::join!(
        a.send_files(target_of(port_b), vec![f1]),
        a.send_files(target_of(port_b), vec![f2]),
        a.send_files(target_of(port_c), vec![f3]),
    );
    let (s1, s2, s3) = (s1.unwrap(), s2.unwrap(), s3.unwrap());

    wait_session(&a, &s1, |s| s.state == MissionState::Finished).await;
    wait_session(&a, &s2, |s| s.state == MissionState::Finished).await;
    wait_session(&a, &s3, |s| s.state == MissionState::Finished).await;

    assert_eq!(read_file(&dir_b.join("one.txt")).await, c1);
    assert_eq!(read_file(&dir_b.join("two.txt")).await, c2);
    assert_eq!(read_file(&dir_c.join("three.txt")).await, c3);

    accept_b.abort();
    accept_c.abort();
    a.shutdown().await;
    b.shutdown().await;
    c.shutdown().await;
}

#[tokio::test]
async fn prepare_upload_over_limit_returns_409() {
    let tmp = tempfile::tempdir().unwrap();
    let dir_a = tmp.path().join("a");
    tokio::fs::create_dir_all(&dir_a).await.unwrap();

    // Shrink the limit so the test does not need 8 parallel senders.
    let options = CoreOptions {
        max_recv_sessions: 2,
        ..CoreOptions::default()
    };
    let port_a = free_port();
    let a = make_core_with("a", port_a, &dir_a, options).await;

    let client = reqwest::Client::new();
    let url = format!("http://127.0.0.1:{port_a}/api/localsend/v2/prepare-upload");

    let body = |fp: &str| {
        serde_json::json!({
            "info": {
                "alias": fp,
                "version": "2.2",
                "deviceModel": "test",
                "deviceType": "test",
                "fingerprint": fp,
                "port": 40000,
                "protocol": "http",
                "download": true
            },
            "files": {
                "f1": {
                    "id": "f1",
                    "fileName": "x.txt",
                    "size": 3,
                    "fileType": "txt",
                    "sha256": null,
                    "preview": null
                }
            }
        })
    };

    // Fill both slots with pending sessions (nobody accepts, so these
    // requests stay open in spawned tasks).
    let mut pending = Vec::new();
    for i in 0..2 {
        let req = client.post(&url).json(&body(&format!("fp-{i}")));
        pending.push(tokio::spawn(async move { req.send().await }));
    }

    // Wait until both sessions are registered as pending.
    tokio::time::timeout(TIMEOUT, async {
        let mut rx = a.session_index().await;
        loop {
            let count = rx
                .borrow()
                .iter()
                .filter(|s| {
                    s.direction == SessionDirection::Receive && s.state == MissionState::Pending
                })
                .count();
            if count == 2 {
                return;
            }
            rx.changed().await.unwrap();
        }
    })
    .await
    .expect("pending sessions did not register");

    // The third one is rejected with 409 Busy.
    let resp = client.post(&url).json(&body("fp-3")).send().await.unwrap();
    assert_eq!(resp.status(), reqwest::StatusCode::CONFLICT);

    // Clean up: decline the pending sessions so their handlers resolve.
    let ids: Vec<String> = a
        .session_index()
        .await
        .borrow()
        .iter()
        .filter(|s| s.direction == SessionDirection::Receive)
        .map(|s| s.id.clone())
        .collect();
    for id in ids {
        let _ = a.decline(&id).await;
    }
    for task in pending {
        let resp = task.await.unwrap().unwrap();
        assert_eq!(resp.status(), reqwest::StatusCode::FORBIDDEN);
    }

    a.shutdown().await;
}

#[tokio::test]
async fn info_endpoint_returns_device() {
    let tmp = tempfile::tempdir().unwrap();
    let dir_a = tmp.path().join("a");
    tokio::fs::create_dir_all(&dir_a).await.unwrap();
    let port_a = free_port();
    let a = make_core("alice", port_a, &dir_a).await;

    let client = reqwest::Client::new();
    for version in ["v1", "v2"] {
        let resp: serde_json::Value = client
            .get(format!(
                "http://127.0.0.1:{port_a}/api/localsend/{version}/info"
            ))
            .send()
            .await
            .unwrap()
            .json()
            .await
            .unwrap();
        assert_eq!(resp["alias"], "alice");
        assert_eq!(resp["fingerprint"], "fp-alice");
        assert_eq!(resp["version"], "2.2");
    }

    a.shutdown().await;
}

// ---------------------------------------------------------------------------
// TLS (TOFU) scenarios
// ---------------------------------------------------------------------------

async fn make_tls_core(alias: &str, port: u16, store: &Path, identity: &Path) -> CoreHandle {
    let options = CoreOptions {
        enable_discovery: false,
        ..CoreOptions::default()
    };
    let mut config = test_config(port, store);
    config.identity_dir = Some(identity.to_string_lossy().to_string());
    let core = CoreHandle::with_options(test_device(alias, port), config, options);
    core.start().await;
    assert!(
        *core.server_state().await.borrow(),
        "server of {alias} failed to start"
    );
    core
}

#[tokio::test]
async fn tls_transfers_end_to_end_and_pins_peer() {
    let _ = env_logger::builder().is_test(true).try_init();
    let tmp = tempfile::tempdir().unwrap();
    let (dir_a, dir_b) = (tmp.path().join("a"), tmp.path().join("b"));
    let (id_a, id_b) = (tmp.path().join("id-a"), tmp.path().join("id-b"));
    for d in [&dir_a, &dir_b, &id_a, &id_b] {
        tokio::fs::create_dir_all(d).await.unwrap();
    }
    let (port_a, port_b) = (free_port(), free_port());
    let a = make_tls_core("alice", port_a, &dir_a, &id_a).await;
    let b = make_tls_core("bob", port_b, &dir_b, &id_b).await;

    let accept = auto_accept(b.clone());

    // First transfer: TOFU pins b's certificate under b's device id.
    let file = write_file(&dir_a, "secret.txt", b"tls payload").await;
    let id = a
        .send_files(
            NodeDevice::manual(&format!("127.0.0.1:{port_b}")).unwrap(),
            vec![file],
        )
        .await
        .unwrap();
    wait_session(&a, &id, |s| s.state == MissionState::Finished).await;
    assert!(tokio::fs::read(dir_b.join("secret.txt")).await.is_ok());

    // The pin must exist and match b's actual certificate fingerprint.
    let identity = localsend_core::relay::identity::DeviceIdentity::load_or_create(&id_b).unwrap();
    let _store =
        localsend_core::relay::tls::TofuStore::load(id_a.join("pinned-peers.json")).unwrap();
    // manual targets pin under `manual-<addr>`; resolve via any pin entry.
    let any_pin = std::fs::read_to_string(id_a.join("pinned-peers.json"))
        .unwrap()
        .contains(&identity.fingerprint);
    assert!(
        any_pin,
        "b's fingerprint must be pinned after first contact"
    );

    accept.abort();
    a.shutdown().await;
    b.shutdown().await;
}

#[tokio::test]
async fn tls_rejects_a_changed_certificate() {
    let tmp = tempfile::tempdir().unwrap();
    let (dir_a, dir_b) = (tmp.path().join("a"), tmp.path().join("b"));
    let (id_a, id_b) = (tmp.path().join("id-a"), tmp.path().join("id-b"));
    for d in [&dir_a, &dir_b, &id_a, &id_b] {
        tokio::fs::create_dir_all(d).await.unwrap();
    }
    let (port_a, port_b) = (free_port(), free_port());
    let a = make_tls_core("alice", port_a, &dir_a, &id_a).await;
    let b = make_tls_core("bob", port_b, &dir_b, &id_b).await;

    let accept = auto_accept(b.clone());

    // Pin b via one transfer.
    let file = write_file(&dir_a, "pin.txt", b"x").await;
    let id = a
        .send_files(
            NodeDevice::manual(&format!("127.0.0.1:{port_b}")).unwrap(),
            vec![file],
        )
        .await
        .unwrap();
    wait_session(&a, &id, |s| s.state == MissionState::Finished).await;

    // Swap b's identity (simulates a machine reinstall / MITM cert)
    // and restart its server.
    b.shutdown().await;
    std::fs::remove_file(id_b.join("tls-cert.pem")).unwrap();
    std::fs::remove_file(id_b.join("tls-key.pem")).unwrap();
    let b = make_tls_core("bob", port_b, &dir_b, &id_b).await;

    let file = write_file(&dir_a, "second.txt", b"y").await;
    let id = a
        .send_files(
            NodeDevice::manual(&format!("127.0.0.1:{port_b}")).unwrap(),
            vec![file],
        )
        .await
        .unwrap();
    let failed = tokio::time::timeout(TIMEOUT, async {
        let mut rx = a.session_index().await;
        loop {
            if let Some(s) = rx.borrow().iter().find(|s| s.id == id) {
                if matches!(s.state, MissionState::Failed | MissionState::Finished) {
                    return s.state;
                }
            }
            rx.changed().await.unwrap();
        }
    })
    .await
    .expect("session must reach a terminal state");
    assert_ne!(
        failed,
        MissionState::Finished,
        "transfer must fail when the pinned certificate changed"
    );

    accept.abort();
    a.shutdown().await;
    b.shutdown().await;
}

#[tokio::test]
async fn tls_handshake_smoke() {
    let tmp = tempfile::tempdir().unwrap();
    let (dir_b, id_b) = (tmp.path().join("b"), tmp.path().join("id-b"));
    let (dir_a, id_a) = (tmp.path().join("a"), tmp.path().join("id-a"));
    for d in [&dir_a, &dir_b, &id_a, &id_b] {
        tokio::fs::create_dir_all(d).await.unwrap();
    }
    let port_b = free_port();
    let b = make_tls_core("bob", port_b, &dir_b, &id_b).await;

    // plain HTTP must now be refused
    let plain = reqwest::Client::new()
        .get(format!("http://127.0.0.1:{port_b}/api/localsend/v2/info"))
        .send()
        .await;
    assert!(
        plain.is_err(),
        "plain request must not succeed against TLS server"
    );

    // TLS handshake + GET /info
    let tofu = localsend_core::relay::tls::TofuStore::load(id_a.join("pinned-peers.json")).unwrap();
    let cfg = localsend_core::relay::tls::tofu_client_config(
        std::sync::Arc::new(tofu),
        "manual-127.0.0.1",
        None,
    );
    let tcp = tokio::net::TcpStream::connect(("127.0.0.1", port_b))
        .await
        .unwrap();
    let connector = tokio_rustls::TlsConnector::from(cfg);
    let name = rustls::pki_types::ServerName::try_from("localsend").unwrap();
    let mut tls = connector.connect(name, tcp).await.expect("handshake");
    use tokio::io::{AsyncReadExt, AsyncWriteExt};
    tls.write_all(
        "GET /api/localsend/v2/info HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n".to_string()
        .as_bytes(),
    )
    .await
    .unwrap();
    let mut buf = Vec::new();
    tls.read_to_end(&mut buf).await.unwrap();
    let text = String::from_utf8_lossy(&buf);
    assert!(
        text.starts_with("HTTP/1.1 200"),
        "got: {}",
        &text[..text.len().min(200)]
    );

    b.shutdown().await;
}
