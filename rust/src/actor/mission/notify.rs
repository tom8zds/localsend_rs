use log::trace;
use tokio::sync::{mpsc, oneshot, watch};

use super::MissionInfo;

enum Message {
    Notify {
        mission: Option<MissionInfo>,
    },
    Listen {
        respond_to: oneshot::Sender<watch::Receiver<Option<MissionInfo>>>,
    },
    Clear {
        respond_to: oneshot::Sender<()>,
    },
}

struct Actor {
    receiver: mpsc::Receiver<Message>,
    notify: watch::Sender<Option<MissionInfo>>,
    listener: watch::Receiver<Option<MissionInfo>>,
}

impl Actor {
    fn new(receiver: mpsc::Receiver<Message>) -> Self {
        let (tx, rx) = watch::channel(None);

        Actor {
            receiver,
            notify: tx,
            listener: rx,
        }
    }
    async fn handle_message(&mut self, msg: Message) {
        match msg {
            Message::Notify { mission } => {
                trace!("mission changed");
                let _ = self.notify.send(mission);
            }
            Message::Listen { respond_to } => {
                let rx = self.listener.clone();
                let _ = respond_to.send(rx);
            }
            Message::Clear { respond_to } => {
                let _ = self.notify.send(None);
                let _ = respond_to.send(());
            }
        }
    }
}

async fn run_notify_actor(mut actor: Actor) {
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
        tokio::spawn(run_notify_actor(actor));

        Self { sender }
    }

    pub async fn listen(&self) -> watch::Receiver<Option<MissionInfo>> {
        let (send, recv) = oneshot::channel();
        let msg = Message::Listen { respond_to: send };

        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }

    pub async fn notify(&self, mission: Option<MissionInfo>) {
        let msg = Message::Notify { mission };
        let _ = self.sender.send(msg).await;
    }
    pub async fn clear(&self) {
        let (send, recv) = oneshot::channel();
        let msg = Message::Clear { respond_to: send };

        let _ = self.sender.send(msg).await;
        recv.await.expect("Actor task has been killed")
    }
}
