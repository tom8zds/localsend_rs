//! Thin CLI entry for the relay panel. The panel logic lives in the
//! library so `localsend-cli` can embed it (auto-started when relay
//! is configured).

use clap::Parser;
use localsend_panel::{serve, PanelArgs};

#[tokio::main]
async fn main() {
    let args = PanelArgs::parse();
    let cfg = localsend_panel::state::PanelConfig::from_args_struct(args);
    let db = std::env::var("PANEL_DB").unwrap_or_else(|_| "panel.db".into());
    if let Err(e) = serve(cfg, db).await {
        eprintln!("relay-panel: {e}");
        std::process::exit(1);
    }
}
