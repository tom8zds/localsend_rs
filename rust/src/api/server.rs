use std::net::SocketAddr;

use axum::{http::StatusCode, Json, Router};
use log::debug;

use super::v2;

async fn api_fallback() -> (StatusCode, Json<serde_json::Value>) {
    (
        StatusCode::NOT_FOUND,
        Json(serde_json::json!({ "status": "Not Found" })),
    )
}

pub async fn serve(port: u16){
    debug!("api server listening on port {}", port);

    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    let listener = tokio::net::TcpListener::bind(addr)
        .await
        .expect("failed to listen to port");
    let api = Router::new().nest("/api/localsend/", v2::app());
    axum::serve(
        listener,
        api.into_make_service_with_connect_info::<SocketAddr>(),
    )
    .await
    .unwrap();
}
