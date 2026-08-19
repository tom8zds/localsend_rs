use std::net::SocketAddr;

use axum::Router;
use log::info;

use tokio::sync::{mpsc, watch};

use crate::api::v2;

use super::{core::CoreActorHandle, discovery::DiscoverHandle};

enum ServerMessage {
    Shutdown,
}

struct HttpServerActor {
    core: CoreActorHandle,
    receiver: mpsc::Receiver<ServerMessage>,
}

async fn shutdown_signal(mut actor: HttpServerActor) {
    while let Some(msg) = actor.receiver.recv().await {
        if matches!(msg, ServerMessage::Shutdown) {
            break;
        };
        actor.handle_message(msg).await;
    }
}

async fn run_http_actor(actor: HttpServerActor, shutdown_callback: watch::Sender<bool>) {
    let config = actor.core.get_config().await;
    let n_port = config.port;

    let discover_handle = DiscoverHandle::new(actor.core.clone());

    let addr = SocketAddr::from(([0, 0, 0, 0], n_port));
    let listener = tokio::net::TcpListener::bind(addr)
        .await
        .expect("failed to listen to port");

    let app = Router::new().nest("/api/localsend/", v2::app(actor.core.clone()));

    info!("http service {} started", n_port);

    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal(actor))
        .await
        .unwrap();

    info!("http service {} shutdown", n_port);

    discover_handle.shutdown().await;

    let _ = shutdown_callback.send(true);
}

impl HttpServerActor {
    pub fn new(receiver: mpsc::Receiver<ServerMessage>, core: CoreActorHandle) -> Self {
        HttpServerActor { receiver, core }
    }
    async fn handle_message(&mut self, msg: ServerMessage) {
        match msg {
            ServerMessage::Shutdown => todo!(),
            _ => {}
        }
    }
}

pub struct HttpServerHandle {
    sender: mpsc::Sender<ServerMessage>,
    shutdown_receiver: watch::Receiver<bool>,
}

impl HttpServerHandle {
    pub fn new(core: CoreActorHandle) -> Self {
        let (sender, receiver) = mpsc::channel(8);
        let (s_sender, s_receiver) = watch::channel(true);

        let actor = HttpServerActor::new(receiver, core);

        tokio::spawn(run_http_actor(actor, s_sender));

        Self {
            sender,
            shutdown_receiver: s_receiver,
        }
    }

    pub async fn shutdown(mut self) {
        let msg = ServerMessage::Shutdown;

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
