use std::collections::HashMap;

use log::debug;
use tokio::sync::{mpsc, oneshot, watch};

use crate::actor::model::{Mission, MissionState};

struct MissionStore {
    mission_map: HashMap<String, Mission>,
}

struct MissionActor {
    receiver: mpsc::Receiver<MissionMessage>,
    store: MissionStore,
}

enum MissionMessage {
    StartMission {
        mission: Mission,
        respond_to: oneshot::Sender<()>,
    },
    GetMission {
        respond_to: oneshot::Sender<HashMap<String, Mission>>,
    },
}

impl MissionActor {
    fn new(receiver: mpsc::Receiver<MissionMessage>) -> Self {
        let store: MissionStore = MissionStore {
            mission_map: HashMap::new(),
        };
        MissionActor { receiver, store }
    }
    async fn handle_message(&mut self, msg: MissionMessage) {
        match msg {
            MissionMessage::StartMission {
                mission,
                respond_to,
            } => todo!(),
            MissionMessage::GetMission { respond_to } => {
                let result = self.store.mission_map.clone();
                let _ = respond_to.send(result);
            }
        }
    }
}

async fn run_mission_actor(mut actor: MissionActor) {
    while let Some(msg) = actor.receiver.recv().await {
        actor.handle_message(msg).await;
    }
}

#[derive(Clone)]
pub struct MissionActorHandle {
    sender: mpsc::Sender<MissionMessage>,
}

impl MissionActorHandle {
    pub fn new() -> Self {
        let (sender, receiver) = mpsc::channel(8);
        let actor = MissionActor::new(receiver);
        tokio::spawn(run_mission_actor(actor));

        Self { sender }
    }

    pub async fn get(&self) -> HashMap<String, Mission> {
        let (send, recv) = oneshot::channel();
        let msg = MissionMessage::GetMission { respond_to: send };

        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }
}
