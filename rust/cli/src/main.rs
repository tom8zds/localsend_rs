//! `localsend-cli` — interactive terminal frontend for the LocalSend
//! protocol, built on `localsend_core`.
//!
//! Default mode is a ratatui TUI (device discovery, multi-session
//! send/receive with per-file progress). `send` / `receive`
//! subcommands run non-interactively for scripting and smoke tests.

mod config;
mod headless;
mod state;
mod tui;

use std::path::PathBuf;

use anyhow::{Context, Result};
use clap::{Args, Parser, Subcommand};
use localsend_core::{CoreConfig, CoreHandle, CoreOptions, NodeDevice, PROTOCOL_VERSION};
use tracing_subscriber::prelude::*;

#[derive(Parser)]
#[command(
    name = "localsend-cli",
    version,
    about = "LocalSend in the terminal — interactive TUI by default"
)]
struct Cli {
    #[command(flatten)]
    common: CommonArgs,

    #[command(subcommand)]
    command: Option<Command>,
}

#[derive(Args, Clone, Default)]
struct CommonArgs {
    /// Device alias shown to peers (overrides config file).
    #[arg(long, global = true)]
    alias: Option<String>,

    /// HTTP listen port (overrides config file).
    #[arg(long, global = true)]
    port: Option<u16>,

    /// Directory where received files are saved (overrides config).
    #[arg(long, global = true)]
    destination: Option<PathBuf>,

    /// File(s) to send; may be repeated. In TUI mode they are staged
    /// for sending (press 1-9), in `send` mode they are the payload.
    #[arg(short = 'f', long = "file", global = true, value_name = "PATH")]
    files: Vec<PathBuf>,

    /// Manual target `ip:port`. TUI mode sends staged files to it
    /// immediately, skipping device selection.
    #[arg(long, global = true, value_name = "IP:PORT")]
    to: Option<String>,
}

#[derive(Subcommand)]
enum Command {
    /// Headless send: transfer files to a target and exit.
    Send,
    /// Headless receive: auto-accept incoming sessions.
    Receive {
        /// Exit after the first incoming session completes.
        #[arg(long)]
        once: bool,
    },
}

fn init_logging() -> Result<()> {
    // tracing_subscriber's global default installs a `log` bridge
    // (tracing-log feature), so core's `log` records land in the file.
    let log_path = std::env::var("LOCALSEND_CLI_LOG")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from("/tmp/localsend-cli.log"));
    let file = std::fs::File::create(&log_path)
        .with_context(|| format!("failed to create {}", log_path.display()))?;
    let layer = tracing_subscriber::fmt::layer()
        .with_writer(std::sync::Mutex::new(file))
        .with_ansi(false);
    tracing_subscriber::registry()
        .with(layer)
        .with(tracing_subscriber::filter::LevelFilter::DEBUG)
        .try_init()
        .context("failed to init tracing")?;
    tracing::debug!("logging to {}", log_path.display());
    Ok(())
}

fn build_device(config: &config::EffectiveConfig) -> NodeDevice {
    NodeDevice {
        alias: config.alias.clone(),
        version: PROTOCOL_VERSION.to_string(),
        device_model: "cli".to_string(),
        device_type: "headless".to_string(),
        fingerprint: config.fingerprint.clone(),
        address: "0.0.0.0".to_string(),
        port: config.port,
        protocol: "http".to_string(),
        download: true,
        announcement: true,
        announce: true,
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    init_logging()?;
    let cli = Cli::parse();

    let overrides = config::CliOverrides {
        alias: cli.common.alias.clone(),
        port: cli.common.port,
        destination: cli.common.destination.clone(),
    };
    let effective = config::load_effective(&config::config_path(), &overrides)?;
    tracing::info!(?effective, "effective configuration");

    std::fs::create_dir_all(&effective.destination).with_context(|| {
        format!(
            "failed to create destination {}",
            effective.destination.display()
        )
    })?;

    let core_config = CoreConfig {
        port: effective.port,
        store_path: effective.destination.to_string_lossy().to_string(),
        ..CoreConfig::default()
    };
    let core = CoreHandle::with_options(
        build_device(&effective),
        core_config,
        CoreOptions::default(),
    );
    core.start().await;
    if let Some(err) = core.server_error().borrow().clone() {
        anyhow::bail!("server failed to start: {err}");
    }

    let result = match (&cli.command, &cli.common.to) {
        (Some(Command::Send), _) => {
            let to = cli
                .common
                .to
                .as_deref()
                .context("`send` requires --to <ip:port>")?;
            let target = NodeDevice::manual(to)
                .with_context(|| format!("invalid --to target: {to}"))?;
            if cli.common.files.is_empty() {
                anyhow::bail!("`send` requires at least one -f/--file");
            }
            headless::send(&core, target, cli.common.files.clone()).await
        }
        (Some(Command::Receive { once }), _) => headless::receive(&core, *once).await,
        (None, to) => {
            let direct_target = match to {
                Some(t) => Some(
                    NodeDevice::manual(t)
                        .with_context(|| format!("invalid --to target: {t}"))?,
                ),
                None => None,
            };
            tui::run(
                core.clone(),
                effective.clone(),
                tui::StartupActions {
                    pending_files: cli.common.files.clone(),
                    direct_target,
                },
            )
            .await
        }
    };

    core.shutdown().await;
    result
}
