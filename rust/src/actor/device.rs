use std::collections::HashMap;

use log::debug;
use tokio::sync::{mpsc, oneshot, watch};

use super::model::NodeDevice;

struct DeviceActor {
    receiver: mpsc::Receiver<DeviceMessage>,
    current: NodeDevice,
    device_map: HashMap<String, NodeDevice>,
    listener: watch::Receiver<Vec<NodeDevice>>,
    notify: watch::Sender<Vec<NodeDevice>>,
}

enum DeviceMessage {
    Listen {
        respond_to: oneshot::Sender<watch::Receiver<Vec<NodeDevice>>>,
    },
    Add {
        device: NodeDevice,
        respond_to: oneshot::Sender<()>,
    },
    GetAll {
        respond_to: oneshot::Sender<HashMap<String, NodeDevice>>,
    },
    Get {
        fingerprint: String,
        respond_to: oneshot::Sender<Option<NodeDevice>>,
    },
    Clear {
        respond_to: oneshot::Sender<()>,
    },
    CheckExist {
        fingerprint: String,
        respond_to: oneshot::Sender<bool>,
    },
    GetCurrent {
        respond_to: oneshot::Sender<NodeDevice>,
    },
    SetCurrent {
        device: NodeDevice,
        respond_to: oneshot::Sender<()>,
    },
}

impl DeviceActor {
    fn new(receiver: mpsc::Receiver<DeviceMessage>, current: NodeDevice) -> Self {
        let device_map: HashMap<String, NodeDevice> = HashMap::new();
        let (tx, rx) = watch::channel(Vec::new());
        DeviceActor {
            receiver,
            current,
            device_map,
            listener: rx,
            notify: tx,
        }
    }
    async fn notify_change(&self) {
        let data = self
            .device_map
            .clone()
            .values()
            .map(|x| x.clone())
            .collect::<Vec<_>>();
        let _ = self.notify.send(data);
    }
    async fn handle_message(&mut self, msg: DeviceMessage) {
        match msg {
            DeviceMessage::Add { device, respond_to } => {
                self.device_map.insert(device.fingerprint.clone(), device);
                debug!("device added");
                let _ = respond_to.send(());
                self.notify_change().await;
            }
            DeviceMessage::Get {
                fingerprint,
                respond_to,
            } => {
                if self.current.fingerprint == fingerprint {
                    let _ = respond_to.send(Some(self.current.clone()));
                    return;
                }
                if self.device_map.contains_key(&fingerprint) {
                    let _ =
                        respond_to.send(Some(self.device_map.get(&fingerprint).unwrap().clone()));
                    return;
                }
                let _ = respond_to.send(None);
            }
            DeviceMessage::GetAll { respond_to } => {
                let id_map = self.device_map.clone();
                let _ = respond_to.send(id_map);
            }
            DeviceMessage::CheckExist {
                fingerprint,
                respond_to,
            } => {
                let _ = respond_to.send(
                    self.current.fingerprint == fingerprint
                        || self.device_map.contains_key(&fingerprint),
                );
            }
            DeviceMessage::GetCurrent { respond_to } => {
                let _ = respond_to.send(self.current.clone());
            }
            DeviceMessage::SetCurrent { device, respond_to } => {
                self.current = device;
                debug!("current device updated");
                let _ = respond_to.send(());
            }
            DeviceMessage::Listen { respond_to } => {
                let _ = respond_to.send(self.listener.clone());
            }
            DeviceMessage::Clear { respond_to } => {
                self.device_map.clear();
                self.notify_change().await;
                let _ = respond_to.send(());
            }
        }
    }
}

async fn run_device_actor(mut actor: DeviceActor) {
    while let Some(msg) = actor.receiver.recv().await {
        actor.handle_message(msg).await;
    }
}

#[derive(Clone)]
pub struct DeviceActorHandle {
    sender: mpsc::Sender<DeviceMessage>,
}

impl DeviceActorHandle {
    pub fn new(current: NodeDevice) -> Self {
        let (sender, receiver) = mpsc::channel(8);
        let actor = DeviceActor::new(receiver, current);
        tokio::spawn(run_device_actor(actor));

        Self { sender }
    }

    pub async fn listen(&self) -> watch::Receiver<Vec<NodeDevice>> {
        let (send, recv) = oneshot::channel();
        let msg = DeviceMessage::Listen { respond_to: send };

        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn clear_devices(&self) {
        let (send, recv) = oneshot::channel();
        let msg = DeviceMessage::Clear { respond_to: send };

        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn add_node_device(&self, device: NodeDevice) {
        let (send, recv) = oneshot::channel();
        let msg = DeviceMessage::Add {
            device,
            respond_to: send,
        };

        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn get_device_map(&self) -> HashMap<String, NodeDevice> {
        let (send, recv) = oneshot::channel();
        let msg = DeviceMessage::GetAll { respond_to: send };

        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn get_device(&self, fingerprint: String) -> Option<NodeDevice> {
        let (send, recv) = oneshot::channel();
        let msg = DeviceMessage::Get {
            fingerprint,
            respond_to: send,
        };

        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn check_device_exist(&self, fingerprint: String) -> bool {
        let (send, recv) = oneshot::channel();
        let msg = DeviceMessage::CheckExist {
            fingerprint: fingerprint,
            respond_to: send,
        };

        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn set_current_device(&self, device: NodeDevice) {
        let (send, recv) = oneshot::channel();
        let msg = DeviceMessage::SetCurrent {
            device,
            respond_to: send,
        };

        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn get_current_device(&self) -> NodeDevice {
        let (send, recv) = oneshot::channel();
        let msg = DeviceMessage::GetCurrent { respond_to: send };

        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }
}
