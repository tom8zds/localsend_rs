use std::collections::HashMap;

use log::debug;
use tokio::sync::{mpsc, oneshot, watch};

use crate::{
    actor::model::{Mission, MissionState, NodeDevice, TaskState},
    api::model::FileInfo,
};

use super::{FileState, MissionFileInfo, MissionInfo, MISSION_NOTIFY};

enum Message {
    Add {
        mission: Mission,
        respond_to: oneshot::Sender<Result<(), MissionState>>,
    },
    ListenTask {
        token: String,
        respond_to: oneshot::Sender<Result<watch::Receiver<usize>, String>>,
    },
    StartTask {
        id: String,
        token: String,
        respond_to: oneshot::Sender<Result<(watch::Sender<usize>, FileInfo), String>>,
    },
    Finish {
        id: String,
        respond_to: oneshot::Sender<()>,
    },
    StateTask {
        id: String,
        token: String,
        state: FileState,
        respond_to: oneshot::Sender<()>,
    },
    Cancel {
        id: String,
        respond_to: oneshot::Sender<()>,
    },
}
#[derive(Debug, Clone)]
struct TransferMission {
    id: String,
    sender: NodeDevice,
    files: HashMap<String, MissionFileInfo>,
    state: MissionState,
}
struct MissionStore {
    mission: Option<TransferMission>,
    task: Option<TransferTask>,
}

struct Actor {
    receiver: mpsc::Receiver<Message>,
    store: MissionStore,
}

#[derive(Debug, Clone)]
struct TransferTask {
    token: String,
    state: TaskState,
    progress: watch::Receiver<usize>,
}

impl MissionInfo {
    fn from_transfer_mission(mission: TransferMission) -> Self {
        Self {
            id: mission.id,
            sender: mission.sender,
            files: mission
                .files
                .values()
                .map(|x| x.clone())
                .collect::<Vec<_>>(),
            state: mission.state,
        }
    }
}

impl Actor {
    fn new(receiver: mpsc::Receiver<Message>) -> Self {
        let store: MissionStore = MissionStore {
            mission: Option::None,
            task: Option::None,
        };
        Actor { receiver, store }
    }
    async fn handle_message(&mut self, msg: Message) {
        match msg {
            Message::Add {
                mission,
                respond_to,
            } => {
                debug!("mission added transfer: {:?}", mission);
                if self.store.mission.is_some() {
                    let _ = respond_to.send(Err(MissionState::Busy));
                    return;
                }

                let mut files = HashMap::new();
                let token_map = mission.token_map.clone();
                let info_map = mission.info_map.clone();
                for (k, v) in token_map {
                    let info = MissionFileInfo {
                        state: FileState::Pending,
                        info: info_map.get(&v).unwrap().clone(),
                    };
                    files.insert(k, info);
                }

                let transfer_mission = TransferMission {
                    id: mission.id,
                    sender: mission.sender,
                    state: MissionState::Transfering,
                    files: files,
                };

                self.store.mission.replace(transfer_mission.clone());
                MISSION_NOTIFY.notify(Some(MissionInfo::from_transfer_mission(transfer_mission)));
                let _ = respond_to.send(Ok(()));
            }
            Message::StartTask {
                id,
                token,
                respond_to,
            } => match &self.store.mission {
                Some(mission) => {
                    if mission.id != id {
                        let _ = respond_to.send(Err("mission not exist".to_string()));
                        return;
                    }
                    if !mission.files.contains_key(&token) {
                        let _ = respond_to.send(Err("task token not exist".to_string()));
                        return;
                    }

                    let file = mission.files.get(&token).unwrap();

                    let (tx, rx) = watch::channel(0);

                    let task = TransferTask {
                        token: token,
                        state: TaskState::Transfering,
                        progress: rx,
                    };

                    self.store.task.replace(task);
                    let _ = respond_to.send(Ok((tx, file.info.clone())));
                    return;
                }
                None => {
                    let _ = respond_to.send(Err("mission not exist".to_string()));
                }
            },
            Message::Finish { id, respond_to } => {
                match &self.store.mission {
                    Some(mission) => {
                        if mission.id == id {
                            let _ = self.store.mission.take();
                        }
                    }
                    None => {}
                }

                let _ = respond_to.send(());
            }
            Message::StateTask {
                id,
                token: _,
                state: _,
                respond_to,
            } => {
                match &self.store.mission {
                    Some(mission) => {
                        if mission.id == id {
                            let mut mission = self.store.mission.take().unwrap();
                            mission.state = MissionState::Canceled;
                            MISSION_NOTIFY
                                .notify(Some(MissionInfo::from_transfer_mission(mission)));
                        }
                    }
                    None => {}
                }

                let _ = respond_to.send(());
            }
            Message::Cancel { id, respond_to } => {
                match &self.store.mission {
                    Some(mission) => {
                        if mission.id == id {
                            let mut mission = self.store.mission.take().unwrap();
                            mission.state = MissionState::Canceled;
                            MISSION_NOTIFY
                                .notify(Some(MissionInfo::from_transfer_mission(mission)));
                        }
                    }
                    None => {}
                }

                let _ = respond_to.send(());
            }
            Message::ListenTask { token, respond_to } => match &self.store.mission {
                Some(_) => {
                    let task = self.store.task.clone();
                    match task {
                        Some(task) => {
                            if task.token == token {
                                let _ = respond_to.send(Ok(task.progress));
                                return;
                            }
                            let _ = respond_to.send(Err("task token not match".to_string()));
                        }
                        None => {
                            let _ = respond_to.send(Err("task not found".to_string()));
                        }
                    }
                }
                None => {
                    let _ = respond_to.send(Err("mission not found".to_string()));
                }
            },
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
    pub fn new() -> Self {
        let (sender, receiver) = mpsc::channel(8);
        let actor = Actor::new(receiver);
        tokio::spawn(run_mission_actor(actor));

        Self { sender }
    }

    pub async fn start_task(
        &self,
        id: String,
        token: String,
    ) -> Result<(watch::Sender<usize>, FileInfo), String> {
        let (send, recv) = oneshot::channel();
        let msg = Message::StartTask {
            id,
            token,
            respond_to: send,
        };

        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn listen_task_progress(
        &self,
        token: String,
    ) -> Result<watch::Receiver<usize>, String> {
        let (send, recv) = oneshot::channel();
        let msg = Message::ListenTask {
            token,
            respond_to: send,
        };

        let _ = self.sender.send(msg).await;

        recv.await.expect("Actor task has been killed")
    }

    pub async fn fail_file(&self, id: String, token: String, state: FileState) {
        let (send, recv) = oneshot::channel();
        let msg = Message::StateTask {
            id,
            token,
            state,
            respond_to: send,
        };
        let _ = self.sender.send(msg).await;

        recv.await.expect("Actor task has been killed");
    }

    pub async fn finish(&self, id: String) {
        let (send, recv) = oneshot::channel();
        let msg = Message::Finish {
            id: id,
            respond_to: send,
        };

        let _ = self.sender.send(msg).await;

        recv.await.expect("Actor task has been killed");
    }

    pub async fn add(&self, mission: Mission) -> Result<(), MissionState> {
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
}
