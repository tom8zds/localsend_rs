use std::collections::HashMap;
use std::net::{IpAddr, Ipv4Addr, SocketAddr};
use std::panic;
use std::sync::Arc;

use log::debug;
use tokio::net::UdpSocket;
use tokio::sync::watch;
use tokio::sync::Mutex;

use crate::discovery::model::Node;

use super::model::NodeAnnounce;

lazy_static::lazy_static! {
    static ref MULTICAST_ADDR: Arc<Mutex<Option<SocketAddr>>> = Arc::new(Mutex::new(None));
    static ref CURRENT_NODE: Arc<Mutex<Option<Node>>> = Arc::new(Mutex::new(None));
    static ref ANNOUCE_SOCKET: Arc<Mutex<Option<UdpSocket>>> = Arc::new(Mutex::new(None));
    static ref NODE_MAP: Arc<Mutex<HashMap<String, Node>>> = Arc::new(Mutex::new(HashMap::new()));
    static ref NODE_CHANNEL: (watch::Sender<HashMap<String, Node>>, watch::Receiver<HashMap<String, Node>>) = watch::channel(HashMap::new());
}

pub async fn stop() {
    let _ = ANNOUCE_SOCKET.lock().await.take();
}

pub async fn add_node(node: Node) {
    let mut node_map = NODE_MAP.lock().await;
    node_map.insert(node.fingerprint.clone(), node);
    let _ = NODE_CHANNEL.0.send(node_map.clone());
}

pub async fn remove_node(fingerprint: &str) {
    let mut node_map = NODE_MAP.lock().await;
    node_map.remove(fingerprint);
    let _ = NODE_CHANNEL.0.send(node_map.clone());
}

pub async fn get_node(fingerprint: &str) -> Option<Node> {
    let node_map = NODE_MAP.lock().await;
    node_map.get(fingerprint).cloned()
}

pub async fn get_nodes() -> HashMap<String, Node> {
    let node_map = NODE_MAP.lock().await;
    node_map.clone()
}

pub fn get_node_listener() -> watch::Receiver<HashMap<String, Node>> {
    NODE_CHANNEL.1.clone()
}

pub async fn serve(interface_addr: Ipv4Addr, multicast_addr: Ipv4Addr, multicast_port: u16) {
    debug!("discovery server listening on port {}", multicast_port);

    let socket = UdpSocket::bind((interface_addr, multicast_port))
        .await
        .expect("couldn't bind to address");

    socket
        .join_multicast_v4(multicast_addr, interface_addr)
        .expect("failed to join multicast");

    let _ = ANNOUCE_SOCKET.lock().await.replace(socket);

    if CURRENT_NODE.lock().await.is_none() {
        panic!("current node not initialized");
    }

    MULTICAST_ADDR.lock().await.replace(SocketAddr::new(
        IpAddr::from(multicast_addr),
        multicast_port,
    ));

    let fingerprint = CURRENT_NODE
        .lock()
        .await
        .as_ref()
        .unwrap()
        .fingerprint
        .clone();

    let mut buf = [0; 1024];

    while let Ok((size, addr)) = ANNOUCE_SOCKET
        .lock()
        .await
        .as_ref()
        .unwrap()
        .recv_from(&mut buf)
        .await
    {
        let message = String::from_utf8_lossy(&buf[..size]);
        let node_announce: NodeAnnounce = serde_json::from_str(&message).unwrap();
        let node = Node::from_announce(&node_announce, &addr.ip().to_string());

        debug!("node {:?}", node);

        if node.fingerprint != fingerprint {
            if !NODE_MAP.lock().await.contains_key(&node.fingerprint) {
                let registered = register(node.clone()).await;
                if registered {
                    add_node(node).await;
                }
                announce(1).await;
            } else {
                debug!("node already registered")
            }
        } else {
            debug!("node is self")
        }
    }
}

async fn register(target: Node) -> bool {
    let api = format!(
        "{}://{}:{}/api/localsend/v2/register",
        target.protocol,
        target.address,
        target.port.to_string()
    );
    let announce = CURRENT_NODE.lock().await.as_ref().unwrap().to_announce();

    let message = serde_json::to_string(&announce).unwrap();
    let resp = ureq::post(&api)
        .set("X-My-Header", "Secret")
        .send_string(&message);
    match resp {
        Ok(_) => {
            debug!("register success");
            true
        }
        Err(_) => {
            debug!("register failed");
            false
        }
    }
}

pub async fn discover() {
    announce(5).await;
}

async fn announce(repeat: u8) {
    let socket = ANNOUCE_SOCKET.lock().await;
    let socket = socket.as_ref().expect("failed to clone socket");
    let current_node = CURRENT_NODE.lock().await;
    let target = MULTICAST_ADDR.lock().await.unwrap().clone();

    if current_node.is_none() {
        drop(current_node);
        panic!("current node not initialized");
    }

    let current_node = current_node.as_ref().unwrap();

    let announce = current_node.to_announce();

    let message = serde_json::to_string(&announce).unwrap();

    let buf = message.as_bytes();

    for _ in 0..repeat {
        let _ = socket
            .send_to(buf, target)
            .await
            .expect("failed to send message");
        tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
    }
}

pub async fn set_current_node(node: Node) {
    let mut current_node = CURRENT_NODE.lock().await;
    current_node.replace(node);
}
