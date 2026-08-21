//! Non-interactive `send` / `receive` subcommands.
//!
//! These exist for scripting and smoke-testing the transfer path
//! without driving the TUI. `send` transmits the given files to a
//! target (`ip:port`) and exits with the session outcome; `receive`
//! auto-accepts every incoming session until interrupted (or once,
//! with `--once`).

use std::path::PathBuf;

use anyhow::{Context, Result};
use localsend_core::{CoreHandle, MissionState, NodeDevice, SessionDirection, SessionEvent};

/// Send `files` to `target`, printing progress lines to stdout.
/// Returns `Ok(())` only when the session finishes cleanly.
pub async fn send(core: &CoreHandle, target: NodeDevice, files: Vec<PathBuf>) -> Result<()> {
    for f in &files {
        if !f.exists() {
            anyhow::bail!("file not found: {}", f.display());
        }
    }
    println!("Sending {} file(s) to {}", files.len(), target.alias);
    let session_id = core
        .send_files(target, files)
        .await
        .context("failed to start send session")?;
    println!("session {session_id}");

    let mut index = core.session_index().await;
    let mut events = core
        .session_events(&session_id)
        .await
        .context("session disappeared")?;
    let mut progress: std::collections::HashMap<String, usize> = std::collections::HashMap::new();
    let mut last_percent = -1i64;
    loop {
        let summary = index.borrow().iter().find(|s| s.id == session_id).cloned();
        if let Some(s) = summary {
            match s.state {
                MissionState::Finished => {
                    println!("100% — finished");
                    return Ok(());
                }
                MissionState::Failed => {
                    let reason = match events.borrow().clone() {
                        SessionEvent::Failed { reason } => reason,
                        other => format!("{other:?}"),
                    };
                    anyhow::bail!("send failed: {reason}");
                }
                MissionState::Canceled => anyhow::bail!("send canceled"),
                _ => {
                    let total: i64 = s.files.iter().map(|f| f.info.size.max(0)).sum();
                    let done: u64 = s
                        .files
                        .iter()
                        .map(|f| {
                            let live = progress
                                .get(&f.info.id)
                                .copied()
                                .unwrap_or(0) as u64;
                            let size = f.info.size.max(0) as u64;
                            match f.state {
                                localsend_core::FileState::Finish => size,
                                _ => live.min(size),
                            }
                        })
                        .sum();
                    if total > 0 {
                        let percent = (done * 100 / total as u64) as i64;
                        if percent != last_percent {
                            last_percent = percent;
                            println!("{:?} — {percent}%", s.state);
                        }
                    }
                }
            }
        }
        tokio::select! {
            changed = index.changed() => {
                if changed.is_err() {
                    anyhow::bail!("session index closed");
                }
            }
            changed = events.changed() => {
                if changed.is_err() {
                    anyhow::bail!("session events closed");
                }
                if let SessionEvent::Progress { file_id, bytes } = events.borrow_and_update().clone() {
                    progress.insert(file_id, bytes);
                }
            }
        }
    }
}

/// Receive mode: auto-accept every pending session. With `once`,
/// return after the first session reaches a terminal state.
pub async fn receive(core: &CoreHandle, once: bool) -> Result<()> {
    let device = core.device.get_current_device().await;
    let config = core.get_config().await;
    println!(
        "Receiving as \"{}\" on {}:{}, saving to {}",
        device.alias, config.interface_addr, device.port, config.store_path
    );
    println!("auto-accepting all incoming sessions{}", if once { " (exits after the first)" } else { "" });

    let mut index = core.session_index().await;
    loop {
        let (pending, terminal_recv): (Vec<String>, Vec<(String, MissionState)>) = {
            let list = index.borrow();
            (
                list.iter()
                    .filter(|s| {
                        s.direction == SessionDirection::Receive
                            && s.state == MissionState::Pending
                    })
                    .map(|s| s.id.clone())
                    .collect(),
                list.iter()
                    .filter(|s| s.direction == SessionDirection::Receive && {
                        matches!(
                            s.state,
                            MissionState::Finished | MissionState::Failed | MissionState::Canceled
                        )
                    })
                    .map(|s| (s.id.clone(), s.state))
                    .collect(),
            )
        };
        for id in pending {
            println!("accepting session {id}");
            if let Err(e) = core.accept(&id, None).await {
                eprintln!("accept failed for {id}: {e}");
            }
        }
        if once {
            if let Some((id, state)) = terminal_recv.into_iter().next() {
                println!("session {id} reached {state:?}");
                return if state == MissionState::Finished {
                    Ok(())
                } else {
                    anyhow::bail!("session ended with {state:?}")
                };
            }
        }
        tokio::select! {
            changed = index.changed() => {
                if changed.is_err() {
                    anyhow::bail!("session index closed");
                }
            }
            _ = tokio::signal::ctrl_c() => {
                println!("interrupted");
                return Ok(());
            }
        }
    }
}
