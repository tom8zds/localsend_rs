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

/// All IPv4 interface addresses on this host (loopback included) —
/// machines routinely carry VPNs, docker bridges and WLN adapters
/// next to the real LAN NIC, and a single membership on the
/// default-route interface misses the actual network.
fn all_ipv4_interfaces() -> Vec<Ipv4Addr> {
    let mut list: Vec<Ipv4Addr> = if_addrs::get_if_addrs()
        .map(|ifs| {
            ifs.into_iter()
                .filter_map(|i| match i.ip() {
                    std::net::IpAddr::V4(v4) if !i.is_loopback() => Some(v4),
                    _ => None,
                })
                .collect()
        })
        .unwrap_or_default();
    if list.is_empty() {
        // Fall back to whatever the caller configured (0.0.0.0 lets
        // the kernel pick the default-route interface).
        if let Ok(v4) = Ipv4Addr::from_str("0.0.0.0") {
            list.push(v4);
        }
    }
    list
}

/// Send this device's announcement to the multicast group a few
/// times, once per interface, so peers on any attached network hear
/// it regardless of the host's default route.
pub async fn announce(config: &crate::config::CoreConfig, message: &str) {
    let Ok(multicast_addr) = Ipv4Addr::from_str(&config.multicast_addr) else {
        error!("invalid multicast address in config");
        return;
    };
    let multicast_port = config.multicast_port;
    let target = SocketAddr::new(IpAddr::from(multicast_addr), multicast_port);
    let buf = message.as_bytes();

    for if_addr in all_ipv4_interfaces() {
        let Ok(send_socket) = UdpSocket::bind((if_addr, 0)).await else {
            continue;
        };
        let _ = send_socket.join_multicast_v4(multicast_addr, if_addr);
        for _ in 1..3 {
            let _ = send_socket.send_to(buf, target).await;
        }
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

    // Multiple instances on one host (our own binaries and the
    // official app) all listen on the multicast port — bind with
    // SO_REUSEADDR/SO_REUSEPORT or the second instance silently
    // loses discovery entirely.
    let rec_socket = {
        let sockaddr = socket2::SockAddr::from(std::net::SocketAddr::new(
            std::net::IpAddr::V4(interface_addr),
            multicast_port,
        ));
        let sock = match socket2::Socket::new(socket2::Domain::IPV4, socket2::Type::DGRAM, None) {
            Ok(s) => s,
            Err(e) => {
                error!("udp socket create failed: {e}, discovery disabled");
                let _ = shutdown_callback.send(true);
                return;
            }
        };
        let _ = sock.set_reuse_address(true);
        #[cfg(unix)]
        let _ = sock.set_reuse_port(true);
        if let Err(e) = sock.bind(&sockaddr) {
            error!("udp service couldn't bind port {multicast_port}: {e}, discovery disabled");
            let _ = shutdown_callback.send(true);
            return;
        }
        match UdpSocket::from_std(sock.into()) {
            Ok(s) => s,
            Err(e) => {
                error!("udp socket register failed: {e}, discovery disabled");
                let _ = shutdown_callback.send(true);
                return;
            }
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

    // Join the group on every interface — receiving only on the
    // default-route one misses peers when a VPN/bridge/VM adapter
    // grabbed that route.
    let mut joined = 0usize;
    for if_addr in all_ipv4_interfaces() {
        match rec_socket.join_multicast_v4(multicast_addr, if_addr) {
            Ok(()) => {
                joined += 1;
                debug!("multicast group joined on {if_addr}");
            }
            Err(e) => debug!("join on {if_addr} failed: {e}"),
        }
        let _ = send_socket.join_multicast_v4(multicast_addr, if_addr);
    }
    if joined == 0 {
        // Fall back to the legacy wildcard join (kernel picks the
        // default route interface).
        match rec_socket.join_multicast_v4(multicast_addr, interface_addr) {
            Ok(()) => {}
            Err(e) => {
                error!("failed to join multicast group: {e}, discovery disabled");
                let _ = shutdown_callback.send(true);
                return;
            }
        }
    } else {
        debug!("joined multicast group on {joined} interface(s)");
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

                let mut device = NodeDevice::from_announce(&node_announce, &addr.ip().to_string());
            device.discovery_source = "lan".to_string();
                let exist = device_handle.check_device_exist(device.fingerprint.clone()).await;

                if current.fingerprint == device.fingerprint {
                    // our own announce looping back on N interfaces
                } else if exist {
                    // HTTPS peers: the announce already carries the
                    // full identity; skip the legacy register (it
                    // would need TOFU validation reqwest cannot do).
                    if device.protocol.eq_ignore_ascii_case("https") {
                        debug!("skip register toward https peer {}", device.alias);
                    } else {
                        let client = client.clone();
                        let current = current.clone();
                        tokio::spawn(async move {
                            register(client, current, device).await;
                        });
                    }
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
