//! Multicast UDP discovery.
//!
//! All socket failures degrade gracefully (log + actor exit) instead of
//! panicking: discovery is best-effort, the HTTP server keeps working
//! and peers can still be reached via manual IP or `/register`.

use std::net::IpAddr;
use std::net::Ipv4Addr;
use std::net::SocketAddr;
use std::str::FromStr;

use log::{debug, error, info, warn};
use tokio::sync::{mpsc, watch};

use tokio::net::UdpSocket;

use crate::client::Client;
use crate::handle::CoreHandle;
use crate::model::NodeDevice;

enum DiscoverMessage {
    Shutdown,
}

struct DiscoverActor {
    receiver: mpsc::Receiver<DiscoverMessage>,
    core: CoreHandle,
    config: crate::config::CoreConfig,
}

async fn register(client: Client, current: NodeDevice, target: NodeDevice) {
    match client.register(&target, &current).await {
        Ok(_) => debug!("register to {} success", target.address),
        Err(e) => debug!("register to {} failed: {e}", target.address),
    }
}

/// Send this device's announcement to the multicast group a few times.
pub async fn announce(config: &crate::config::CoreConfig, message: &str) {
    let (interface_addr, multicast_addr) = match (
        Ipv4Addr::from_str(&config.interface_addr),
        Ipv4Addr::from_str(&config.multicast_addr),
    ) {
        (Ok(i), Ok(m)) => (i, m),
        _ => {
            error!("invalid interface/multicast address in config");
            return;
        }
    };
    let multicast_port = config.multicast_port;

    let send_socket = match UdpSocket::bind((interface_addr, 0)).await {
        Ok(s) => s,
        Err(e) => {
            error!("announce: couldn't bind socket: {e}");
            return;
        }
    };

    if let Err(e) = send_socket.join_multicast_v4(multicast_addr, interface_addr) {
        error!("announce: failed to join multicast group: {e}");
        return;
    }

    let buf = message.as_bytes();
    for _ in 1..3 {
        let _ = send_socket
            .send_to(
                buf,
                SocketAddr::new(IpAddr::from(multicast_addr), multicast_port),
            )
            .await;
    }
}

async fn run_udp_actor(mut actor: DiscoverActor, shutdown_callback: watch::Sender<bool>) {
    let config = actor.config.clone();
    let (interface_addr, multicast_addr) = match (
        Ipv4Addr::from_str(&config.interface_addr),
        Ipv4Addr::from_str(&config.multicast_addr),
    ) {
        (Ok(i), Ok(m)) => (i, m),
        _ => {
            error!("invalid interface/multicast address in config, discovery disabled");
            let _ = shutdown_callback.send(true);
            return;
        }
    };
    let multicast_port = config.multicast_port;

    let rec_socket = match UdpSocket::bind((interface_addr, multicast_port)).await {
        Ok(s) => s,
        Err(e) => {
            error!("udp service couldn't bind port {multicast_port}: {e}, discovery disabled");
            let _ = shutdown_callback.send(true);
            return;
        }
    };

    let send_socket = match UdpSocket::bind((interface_addr, 0)).await {
        Ok(s) => s,
        Err(e) => {
            error!("udp service couldn't bind send socket: {e}, discovery disabled");
            let _ = shutdown_callback.send(true);
            return;
        }
    };

    if let Err(e) = rec_socket.join_multicast_v4(multicast_addr, interface_addr) {
        error!("failed to join multicast group: {e}, discovery disabled");
        let _ = shutdown_callback.send(true);
        return;
    }
    if let Err(e) = send_socket.join_multicast_v4(multicast_addr, interface_addr) {
        warn!("send socket failed to join multicast group: {e}");
    }

    info!("udp service {multicast_port} started");

    let mut buf: [u8; 2048] = [0; 2048];

    let device_handle = actor.core.device.clone();
    let client = Client::new();

    loop {
        let current = device_handle.get_current_device().await;
        let s_message = serde_json::to_string(&current.to_announce()).unwrap_or_default();
        let core_config = config.clone();

        tokio::select! {
            recv = rec_socket.recv_from(&mut buf) => {
                let (size, addr) = match recv {
                    Ok(v) => v,
                    Err(e) => {
                        warn!("udp recv failed: {e}");
                        continue;
                    }
                };
                if addr.ip().to_string() == current.address {
                    debug!("self loop");
                    continue;
                }
                let message = String::from_utf8_lossy(&buf[..size]);
                let node_announce = match serde_json::from_str(&message) {
                    Ok(a) => a,
                    Err(e) => {
                        // Foreign/garbage datagrams are normal on a
                        // shared multicast group; ignore them.
                        debug!("ignoring undecodable announcement from {addr}: {e}");
                        continue;
                    }
                };

                let device = NodeDevice::from_announce(&node_announce, &addr.ip().to_string());
                let exist = device_handle.check_device_exist(device.fingerprint.clone()).await;

                if current.fingerprint == device.fingerprint {
                    debug!("self loop");
                } else if exist {
                    let client = client.clone();
                    let current = current.clone();
                    tokio::spawn(async move {
                        register(client, current, device).await;
                    });
                } else {
                    debug!("node discovered {:?}", device);

                    device_handle.add_node_device(device.clone()).await;

                    let config = core_config.clone();
                    let current_s = s_message.clone();
                    tokio::spawn(async move {
                        announce(&config, &current_s).await;
                    });
                }
            }
            Some(_) = actor.receiver.recv() => {
                debug!("discovery shutdown by signal");
                break;
            }
        }
    }

    drop(rec_socket);

    info!("udp service {multicast_port} shutdown");

    let _ = shutdown_callback.send(true);
}

#[derive(Clone)]
pub struct DiscoverHandle {
    sender: mpsc::Sender<DiscoverMessage>,
    shutdown_receiver: watch::Receiver<bool>,
}

impl DiscoverHandle {
    /// `config` is passed in for the same reason as
    /// [`crate::server::HttpServerHandle::new`]: callers may be the core
    /// actor itself.
    pub fn new(core: CoreHandle, config: crate::config::CoreConfig) -> Self {
        let (sender, receiver) = mpsc::channel(8);
        let (s_sender, s_receiver) = watch::channel(true);

        let actor = DiscoverActor {
            receiver,
            core,
            config,
        };

        tokio::spawn(run_udp_actor(actor, s_sender));
        Self {
            sender,
            shutdown_receiver: s_receiver,
        }
    }

    pub async fn shutdown(mut self) {
        let _ = self.sender.send(DiscoverMessage::Shutdown).await;
        let _ = self.shutdown_receiver.changed().await;
    }
}
