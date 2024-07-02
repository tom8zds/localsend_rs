use std::{collections::HashMap, net::Ipv4Addr};

use log::debug;
use tokio::sync::{mpsc, oneshot};

use super::{
    device::DeviceActorHandle,
    http::HttpServerHandle,
    mission::MissionHandle,
    model::{Mission, NodeDevice},
};

#[derive(Clone)]
pub struct CoreConfig {
    pub port: u16,
    pub interface_addr: Ipv4Addr,
    pub multicast_addr: Ipv4Addr,
    pub multicast_port: u16,
}

struct AppContext {
    config: CoreConfig,
}

impl CoreConfig {
    fn default() -> Self {
        CoreConfig {
            port: 8080,
            interface_addr: Ipv4Addr::new(0, 0, 0, 0),
            multicast_addr: Ipv4Addr::new(224, 0, 0, 167),
            multicast_port: 53317,
        }
    }
}

struct CoreActor {
    receiver: mpsc::Receiver<CoreMessage>,
    context: AppContext,
    server: Option<HttpServerHandle>,
}
enum CoreMessage {
    GetConfig {
        respond_to: oneshot::Sender<CoreConfig>,
    },
    ChangeConfig {
        new_config: CoreConfig,
        respond_to: oneshot::Sender<()>,
    },
    Start {
        core: CoreActorHandle,
        respond_to: oneshot::Sender<()>,
    },
    Shutdown {
        respond_to: oneshot::Sender<()>,
    },
}

impl CoreActor {
    fn new(receiver: mpsc::Receiver<CoreMessage>) -> Self {
        CoreActor {
            receiver,
            context: AppContext {
                config: CoreConfig::default(),
            },
            server: None,
        }
    }
    async fn handle_message(&mut self, msg: CoreMessage) {
        match msg {
            CoreMessage::GetConfig { respond_to } => {
                let config = self.context.config.clone();
                _ = respond_to.send(config);
            }
            CoreMessage::ChangeConfig {
                new_config,
                respond_to,
            } => {
                self.context.config = new_config;
                _ = respond_to.send(());
            }
            CoreMessage::Start { core, respond_to } => {
                if self.server.is_some() {
                    self.server.take().unwrap().shutdown().await;
                }

                let handler = HttpServerHandle::new(core);
                self.server.replace(handler);
                _ = respond_to.send(());
            }
            CoreMessage::Shutdown { respond_to } => {
                let handler = self.server.take();
                if handler.is_some() {
                    handler.unwrap().shutdown().await;
                } else {
                    debug!("server not started")
                }
                _ = respond_to.send(());
            }
        }
    }
}

async fn run_context_actor(mut actor: CoreActor) {
    while let Some(msg) = actor.receiver.recv().await {
        actor.handle_message(msg).await;
    }
}

#[derive(Clone)]
pub struct CoreActorHandle {
    sender: mpsc::Sender<CoreMessage>,
    pub device: DeviceActorHandle,
    pub mission: MissionHandle,
}

impl CoreActorHandle {
    pub fn new() -> Self {
        let (sender, receiver) = mpsc::channel(8);
        let actor = CoreActor::new(receiver);
        tokio::spawn(run_context_actor(actor));

        let fingerprint: String = uuid::Uuid::new_v4().to_string();
        let device = DeviceActorHandle::new(NodeDevice {
            alias: String::from("test"),
            version: String::from("2.0"),
            device_model: String::from("rust"),
            device_type: String::from("mobile"),
            fingerprint: fingerprint.clone(),
            address: String::from("192.168.3.2"),
            port: 9000,
            protocol: String::from("http"),
            download: false,
            announcement: true,
            announce: true,
        });
        let mission = MissionHandle::new();

        Self {
            sender,
            device,
            mission,
        }
    }

    pub async fn start(&self) {
        let (send, recv) = oneshot::channel();
        let msg = CoreMessage::Start {
            core: self.clone(),
            respond_to: send,
        };
        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }
    pub async fn shutdown(&self) {
        let (send, recv) = oneshot::channel();
        let msg = CoreMessage::Shutdown { respond_to: send };
        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn get_config(&self) -> CoreConfig {
        let (send, recv) = oneshot::channel();
        let msg = CoreMessage::GetConfig { respond_to: send };
        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn change_port(&self, port: u16) {
        let mut value = self.get_config().await;
        value.port = port;
        self.change_config(value).await;
    }

    pub async fn change_config(&self, config: CoreConfig) {
        let (send, recv) = oneshot::channel();
        let msg = CoreMessage::ChangeConfig {
            new_config: config.clone(),
            respond_to: send,
        };

        let mut current = self.device.get_current_device().await;
        current.port = config.port;
        self.device.set_current_device(current).await;

        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }
}
