use log::debug;
use tokio::sync::{mpsc, oneshot, watch};

use crate::actor::model::{Mission, MissionState};

use super::transfer;

enum Message {
    Add {
        mission: Mission,
        respond_to: oneshot::Sender<watch::Receiver<MissionState>>,
    },
    Cancel {
        id: String,
        respond_to: oneshot::Sender<()>,
    },
    Accept {
        id: String,
        respond_to: oneshot::Sender<()>,
    },
}

pub struct PendingMission {
    pub mission: Mission,
    pub notify: watch::Sender<MissionState>,
}

struct MissionStore {
    mission: Option<PendingMission>,
}

struct Actor {
    transfer: transfer::Handle,
    receiver: mpsc::Receiver<Message>,
    store: MissionStore,
}

impl Actor {
    fn new(receiver: mpsc::Receiver<Message>, transfer: transfer::Handle) -> Self {
        let store: MissionStore = MissionStore {
            mission: Option::None,
        };
        Actor {
            receiver,
            store,
            transfer,
        }
    }
    async fn handle_message(&mut self, msg: Message) {
        match msg {
            Message::Add {
                mission,
                respond_to,
            } => {
                debug!("mission added pending: {:?}", mission);

                let (tx, rx) = watch::channel(MissionState::Pending);

                if self.store.mission.is_some() {
                    let _ = respond_to.send(rx);
                    let _ = tx.send(MissionState::Busy);
                    return;
                }

                let pending_mission = PendingMission {
                    mission,
                    notify: tx,
                };

                self.store.mission.replace(pending_mission);
                let _ = respond_to.send(rx);
            }
            Message::Cancel { id, respond_to } => {
                match &self.store.mission {
                    Some(mission) => {
                        if mission.mission.id == id {
                            let mission = self.store.mission.take().unwrap();
                            let _ = mission.notify.send(MissionState::Canceled);
                        }
                    }
                    None => {}
                }

                let _ = respond_to.send(());
            }
            Message::Accept { id, respond_to } => {
                match &self.store.mission {
                    Some(mission) => {
                        if mission.mission.id == id {
                            let mission = self.store.mission.take().unwrap();
                            let _ = mission.notify.send(MissionState::Transfering);
                            let _ = self.transfer.add(mission.mission).await;
                        }
                    }
                    None => {}
                }

                let _ = respond_to.send(());
            }
        }
    }
}

async fn run_mission_actor(mut actor: Actor) {
    while let Some(msg) = actor.receiver.recv().await {
        actor.handle_message(msg).await;
    }
}

#[derive(Clone)]
pub struct Handle {
    sender: mpsc::Sender<Message>,
}

impl Handle {
    pub fn new(transfer: transfer::Handle) -> Self {
        let (sender, receiver) = mpsc::channel(8);
        let actor = Actor::new(receiver, transfer);
        tokio::spawn(run_mission_actor(actor));

        Self { sender }
    }

    pub async fn add(&self, mission: Mission) -> watch::Receiver<MissionState> {
        let (send, recv) = oneshot::channel();
        let msg = Message::Add {
            mission,
            respond_to: send,
        };

        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn cancel(&self, id: String) {
        let (send, recv) = oneshot::channel();
        debug!("cancel mission {}", id);
        let msg = Message::Cancel {
            id,
            respond_to: send,
        };

        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn accept(&self, id: String) {
        let (send, recv) = oneshot::channel();
        debug!("accept mission {}", id);
        let msg = Message::Accept {
            id,
            respond_to: send,
        };

        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }
}
