use std::net::IpAddr;
use std::net::Ipv4Addr;
use std::net::SocketAddr;
use std::str::FromStr;

use log::{debug, info};
use tokio::sync::mpsc;
use tokio::sync::watch;

use tokio::net::UdpSocket;

use crate::actor::model::NodeDevice;

use super::core::CoreActorHandle;
use super::core::CoreConfig;

enum DiscoverMessage {
    Shutdown,
}

struct DiscoverActor {
    receiver: mpsc::Receiver<DiscoverMessage>,
    core: CoreActorHandle,
}

async fn register(current: NodeDevice, target: NodeDevice) -> bool {
    let api = format!(
        "{}://{}:{}/api/localsend/v2/register",
        target.protocol,
        target.address,
        target.port.to_string()
    );
    let announce = current.to_announce();

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

async fn announce(config: CoreConfig, current: String) {
    let interface_addr = Ipv4Addr::from_str(&config.interface_addr).unwrap();
    let multicast_addr = Ipv4Addr::from_str(&config.multicast_addr).unwrap();
    let multicast_port = config.multicast_port;

    let send_socket: UdpSocket = UdpSocket::bind((interface_addr, multicast_port + 2))
        .await
        .expect("couldn't bind to address");

    send_socket
        .join_multicast_v4(multicast_addr, interface_addr)
        .expect("failed to join multicast");

    let buf = current.as_bytes();
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
    let config = actor.core.get_config().await;
    let interface_addr = Ipv4Addr::from_str(&config.interface_addr).unwrap();
    let multicast_addr = Ipv4Addr::from_str(&config.multicast_addr).unwrap();
    let multicast_port = config.multicast_port;

    info!("udp service {} started", multicast_port);

    let rec_socket = UdpSocket::bind((interface_addr, multicast_port))
        .await
        .expect("couldn't bind to address");

    let send_socket: UdpSocket = UdpSocket::bind((interface_addr, multicast_port + 1))
        .await
        .expect("couldn't bind to address");

    rec_socket
        .join_multicast_v4(multicast_addr, interface_addr)
        .expect("failed to join multicast");

    send_socket
        .join_multicast_v4(multicast_addr, interface_addr)
        .expect("failed to join multicast");

    let mut buf: [u8; 1024] = [0; 1024];

    let device_handle = actor.core.device.clone();

    loop {
        let current = device_handle.get_current_device().await;
        let s_message = serde_json::to_string(&current).unwrap();
        let core_config = config.clone();

        tokio::select! {
            Ok((size, addr)) = rec_socket.recv_from(&mut buf) => {
                if current.address == addr.to_string() {
                    debug!("self loop");
                    continue
                }
                debug!("recv msg");
                let message = String::from_utf8_lossy(&buf[..size]);
                match serde_json::from_str(&message) {
                    Ok(node_announce) => {


                        let device = NodeDevice::from_announce(&node_announce, &addr.ip().to_string());
                        let exist = device_handle.check_device_exist(device.fingerprint.clone()).await;


                        if current.fingerprint == device.fingerprint {
                            debug!("self loop");
                        } else if exist {
                            tokio::spawn(
                                async {
                                    register(current, device).await;
                                }
                            );
                        } else {
                            debug!("node {:?}", device);

                            device_handle.add_node_device(device.clone()).await;

                            let current_s = s_message.clone();
                            let config = core_config.clone();

                            tokio::spawn(
                                async {
                                   announce(config, current_s).await;
                                }
                            );
                        }

                    },
                    Err(_) => todo!(),
                }
            }
            Some(_) = actor.receiver.recv() => {
            //    let flag = actor.handle_message(msg);
            //    if flag {
            //     break;
            //    }
                debug!("shutdown by signal");
                break;
            }
        }
    }

    drop(rec_socket);

    info!("udp service {} shutdown", multicast_port);

    let _ = shutdown_callback.send(true);
}

impl DiscoverActor {
    pub fn new(receiver: mpsc::Receiver<DiscoverMessage>, core: CoreActorHandle) -> Self {
        DiscoverActor { receiver, core }
    }

    pub fn handle_message(&mut self, msg: DiscoverMessage) -> bool {
        match msg {
            DiscoverMessage::Shutdown => {
                return true;
            }
            _ => {
                return false;
            }
        }
    }
}

#[derive(Clone)]
pub struct DiscoverHandle {
    sender: mpsc::Sender<DiscoverMessage>,
    shutdown_receiver: watch::Receiver<bool>,
}

impl DiscoverHandle {
    pub fn new(core: CoreActorHandle) -> Self {
        let (sender, receiver) = mpsc::channel(8);
        let (s_sender, s_receiver) = watch::channel(true);

        let actor = DiscoverActor::new(receiver, core);

        tokio::spawn(run_udp_actor(actor, s_sender));
        Self {
            sender,
            shutdown_receiver: s_receiver,
        }
    }

    pub async fn shutdown(mut self) {
        let msg = DiscoverMessage::Shutdown;

        // Ignore send errors. If this send fails, so does the
        // recv.await below. There's no reason to check the
        // failure twice.
        let _ = self.sender.send(msg).await;
        self.shutdown_receiver
            .changed()
            .await
            .expect("Actor task has been killed")
    }
}
