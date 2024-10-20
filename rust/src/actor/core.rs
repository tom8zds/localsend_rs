use log::debug;
use tokio::sync::{mpsc, oneshot, watch};

use super::{device::DeviceActorHandle, http::HttpServerHandle, model::NodeDevice};

#[derive(Clone)]
pub struct CoreConfig {
    pub port: u16,
    pub interface_addr: String,
    pub multicast_addr: String,
    pub multicast_port: u16,
    pub store_path: String,
}

struct AppContext {
    config: CoreConfig,
}

impl CoreConfig {
    fn default() -> Self {
        CoreConfig {
            port: 8080,
            interface_addr: "0.0.0.0".to_string(),
            multicast_addr: "224.0.0.167".to_string(),
            multicast_port: 53317,
            store_path: "./".to_string(),
        }
    }
}

struct CoreActor {
    receiver: mpsc::Receiver<CoreMessage>,
    context: AppContext,
    server: Option<HttpServerHandle>,
    server_state_sender: watch::Sender<bool>,
    server_state_listener: watch::Receiver<bool>,
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
    Listen {
        respond_to: oneshot::Sender<watch::Receiver<bool>>,
    },
}

impl CoreActor {
    fn new(
        receiver: mpsc::Receiver<CoreMessage>,
        device: NodeDevice,
        mut config: CoreConfig,
    ) -> Self {
        let (tx, rx) = watch::channel(false);
        config.port = device.port;
        CoreActor {
            receiver,
            context: AppContext { config },
            server: None,
            server_state_sender: tx,
            server_state_listener: rx,
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
                let _ = self.server_state_sender.send(true);
            }
            CoreMessage::Shutdown { respond_to } => {
                let handler = self.server.take();
                if handler.is_some() {
                    handler.unwrap().shutdown().await;
                } else {
                    debug!("server not started")
                }
                _ = respond_to.send(());
                let _ = self.server_state_sender.send(false);
            }
            CoreMessage::Listen { respond_to } => {
                _ = respond_to.send(self.server_state_listener.clone())
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
}

impl CoreActorHandle {
    pub fn new(device: NodeDevice, config: CoreConfig) -> Self {
        let (sender, receiver) = mpsc::channel(8);
        let actor = CoreActor::new(receiver, device.clone(), config);
        tokio::spawn(run_context_actor(actor));

        let device = DeviceActorHandle::new(device);

        Self { sender, device }
    }
    pub async fn listen(&self) -> watch::Receiver<bool> {
        let (send, recv) = oneshot::channel();
        let msg = CoreMessage::Listen { respond_to: send };
        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn start(&self) {
        let (send, recv) = oneshot::channel();
        let msg = CoreMessage::Start {
            core: self.clone(),
            respond_to: send,
        };
        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed");
        self.device.clear_devices().await;
    }
    pub async fn shutdown(&self) {
        let (send, recv) = oneshot::channel();
        let msg = CoreMessage::Shutdown { respond_to: send };
        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed");
        self.device.clear_devices().await;
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

    pub async fn change_path(&self, path: String) {
        let mut value = self.get_config().await;
        value.store_path = path;
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
