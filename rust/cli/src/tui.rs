//! Interactive ratatui frontend.
//!
//! Layout: a device list pane (top left), a multi-session pane (right,
//! one card per concurrent send/receive session with per-file progress
//! bars) and a two-line status bar. The event loop multiplexes
//! crossterm input with the core's watch feeds; all state reduction
//! happens in [`crate::state::App`].

use std::io::{self, Stdout};
use std::path::PathBuf;
use std::time::Duration;

use anyhow::Result;
use crossterm::event::{
    DisableMouseCapture, Event, EventStream, KeyCode, KeyEvent, KeyModifiers,
};
use crossterm::terminal::{
    disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen,
};
use crossterm::{execute, queue};
use futures::StreamExt;
use localsend_core::{
    CoreHandle, FileState, MissionState, NodeDevice, SessionDirection, SessionEvent,
};
use ratatui::backend::CrosstermBackend;
use ratatui::layout::{Constraint, Direction, Layout};
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, Borders, List, ListItem, Paragraph, Wrap};
use ratatui::Terminal;
use tokio::sync::mpsc;
use tokio::sync::watch;

use crate::config::EffectiveConfig;
use crate::state::{App, InputMode, SessionView};

/// What to do right after startup (from CLI args).
pub struct StartupActions {
    pub pending_files: Vec<PathBuf>,
    /// Manual `--to ip:port` target: send staged files immediately,
    /// skipping device selection.
    pub direct_target: Option<NodeDevice>,
}

/// Restores the terminal on drop (including panic paths via the hook
/// installed in [`run`]).
struct TerminalGuard {
    terminal: Terminal<CrosstermBackend<Stdout>>,
}

impl TerminalGuard {
    fn new() -> Result<Self> {
        enable_raw_mode()?;
        let mut stdout = io::stdout();
        execute!(stdout, EnterAlternateScreen, DisableMouseCapture)?;
        let terminal = Terminal::new(CrosstermBackend::new(stdout))?;
        Ok(TerminalGuard { terminal })
    }

    fn restore() {
        let _ = disable_raw_mode();
        let _ = queue!(io::stdout(), LeaveAlternateScreen);
        let _ = io::Write::flush(&mut io::stdout());
    }
}

impl Drop for TerminalGuard {
    fn drop(&mut self) {
        Self::restore();
    }
}

const TICK: Duration = Duration::from_millis(250);

pub async fn run(core: CoreHandle, config: EffectiveConfig, startup: StartupActions) -> Result<()> {
    // Make sure a panic while the alternate screen is active still
    // leaves the user a usable terminal.
    let default_hook = std::panic::take_hook();
    std::panic::set_hook(Box::new(move |info| {
        TerminalGuard::restore();
        default_hook(info);
    }));
    let mut guard = TerminalGuard::new()?;

    let mut app = App::new(startup.pending_files);
    let mut devices_rx = core.device.listen().await;
    let mut index_rx = core.session_index().await;
    let mut server_rx = core.server_state().await;
    let server_err_rx = core.server_error();

    // Forward per-session events into one channel; a forwarder task is
    // spawned for every session that appears in the index.
    let (event_tx, mut event_rx) = mpsc::channel::<(String, SessionEvent)>(256);
    let mut watched: std::collections::HashSet<String> = std::collections::HashSet::new();

    core.announce().await;

    // Direct `--to` send: skip device selection entirely.
    if let Some(target) = startup.direct_target {
        let files = std::mem::take(&mut app.pending_files);
        if files.is_empty() {
            app.notice = Some("--to given without files; press 'a' to add some".into());
        } else {
            match core.send_files(target.clone(), files).await {
                Ok(id) => app.notice = Some(format!("sending to {} (session {id})", target.alias)),
                Err(e) => app.notice = Some(format!("send failed: {e}")),
            }
        }
    }

    let mut keys = EventStream::new();
    let mut tick = tokio::time::interval(TICK);
    let mut quit = false;

    while !quit {
        guard.terminal.draw(|f| draw(f, &app, &config, &server_rx, &server_err_rx))?;

        tokio::select! {
            maybe_key = keys.next() => {
                if let Some(Ok(Event::Key(key))) = maybe_key {
                    quit = handle_key(&core, &mut app, key).await?;
                }
            }
            changed = devices_rx.changed() => {
                if changed.is_ok() {
                    app.apply_devices(devices_rx.borrow_and_update().clone());
                }
            }
            changed = index_rx.changed() => {
                if changed.is_ok() {
                    let index = index_rx.borrow_and_update().clone();
                    spawn_watchers(&core, &index, &mut watched, &event_tx).await;
                    app.apply_index(index);
                }
            }
            Some((id, event)) = event_rx.recv() => {
                app.apply_event(&id, &event);
            }
            changed = server_rx.changed() => {
                let _ = changed; // status bar reads the watch directly
            }
            _ = tick.tick() => {}
        }
    }

    drop(guard);
    core.shutdown().await;
    Ok(())
}

/// Spawn one event forwarder per newly-seen session.
async fn spawn_watchers(
    core: &CoreHandle,
    index: &[localsend_core::SessionSummary],
    watched: &mut std::collections::HashSet<String>,
    event_tx: &mpsc::Sender<(String, SessionEvent)>,
) {
    for summary in index {
        if !watched.insert(summary.id.clone()) {
            continue;
        }
        if let Some(mut rx) = core.session_events(&summary.id).await {
            let id = summary.id.clone();
            let tx = event_tx.clone();
            tokio::spawn(async move {
                // Emit the current value first so late subscribers do
                // not miss the initial state.
                let initial = rx.borrow().clone();
                if tx.send((id.clone(), initial)).await.is_err() {
                    return;
                }
                while rx.changed().await.is_ok() {
                    let event = rx.borrow_and_update().clone();
                    if tx.send((id.clone(), event)).await.is_err() {
                        return;
                    }
                }
            });
        }
    }
}

async fn handle_key(core: &CoreHandle, app: &mut App, key: KeyEvent) -> Result<bool> {
    // Prompt line is modal: it swallows every key while active.
    if let InputMode::AddingFile { buffer } = &mut app.input {
        match key.code {
            KeyCode::Esc => app.input = InputMode::Normal,
            KeyCode::Enter => {
                let input = buffer.trim().to_string();
                app.input = InputMode::Normal;
                if !input.is_empty() {
                    let paths: Vec<PathBuf> =
                        input.split_whitespace().map(PathBuf::from).collect();
                    let missing = app.stage_files(paths);
                    app.notice = Some(if missing.is_empty() {
                        format!("{} file(s) staged", app.pending_files.len())
                    } else {
                        format!("not found: {}", missing[0].display())
                    });
                }
            }
            KeyCode::Backspace => {
                buffer.pop();
            }
            KeyCode::Char(c) => buffer.push(c),
            _ => {}
        }
        return Ok(false);
    }

    match key.code {
        KeyCode::Char('q') => return Ok(true),
        KeyCode::Char('c') if key.modifiers.contains(KeyModifiers::CONTROL) => return Ok(true),
        KeyCode::Char('d') => {
            core.announce().await;
            app.notice = Some("re-announced on the local network".into());
        }
        KeyCode::Tab | KeyCode::Down => app.cycle_focus(1),
        KeyCode::BackTab | KeyCode::Up => app.cycle_focus(-1),
        KeyCode::Char('a') => {
            app.input = InputMode::AddingFile {
                buffer: String::new(),
            };
        }
        KeyCode::Char('y') => {
            if let Some(s) = app.focused() {
                if s.is_pending_receive() {
                    let id = s.id.clone();
                    match core.accept(&id, None).await {
                        Ok(()) => app.notice = Some("accepted".into()),
                        Err(e) => app.notice = Some(format!("accept failed: {e}")),
                    }
                }
            }
        }
        KeyCode::Char('n') => {
            if let Some(s) = app.focused() {
                if s.is_pending_receive() {
                    let id = s.id.clone();
                    match core.decline(&id).await {
                        Ok(()) => app.notice = Some("declined".into()),
                        Err(e) => app.notice = Some(format!("decline failed: {e}")),
                    }
                }
            }
        }
        KeyCode::Char('c') => {
            if let Some(s) = app.focused() {
                if !s.is_terminal() {
                    core.cancel(&s.id.clone()).await;
                    app.notice = Some("session canceled".into());
                }
            }
        }
        KeyCode::Char('x') => {
            let n = app.clear_terminal();
            app.notice = Some(format!("cleared {n} finished session(s)"));
        }
        KeyCode::Char(d @ '1'..='9') => {
            let idx = (d as usize) - ('1' as usize);
            if app.pending_files.is_empty() {
                app.notice = Some("no files staged — press 'a' to add".into());
            } else if let Some(target) = app.devices.get(idx).cloned() {
                let files = std::mem::take(&mut app.pending_files);
                match core.send_files(target.clone(), files).await {
                    Ok(id) => {
                        app.notice = Some(format!("sending to {} (session {id})", target.alias))
                    }
                    Err(e) => app.notice = Some(format!("send failed: {e}")),
                }
            } else {
                app.notice = Some(format!("no device #{idx}"));
            }
        }
        _ => {}
    }
    Ok(false)
}

// ---------------------------------------------------------------------------
// Rendering
// ---------------------------------------------------------------------------

fn draw(
    frame: &mut ratatui::Frame,
    app: &App,
    config: &EffectiveConfig,
    server_rx: &watch::Receiver<bool>,
    server_err_rx: &watch::Receiver<Option<String>>,
) {
    let area = frame.area();
    let outer = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(5), Constraint::Length(3)])
        .split(area);
    let panes = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(38), Constraint::Percentage(62)])
        .split(outer[0]);

    draw_devices(frame, app, panes[0]);
    draw_sessions(frame, app, panes[1]);
    draw_status(frame, app, config, server_rx, server_err_rx, outer[1]);
}

fn draw_devices(frame: &mut ratatui::Frame, app: &App, area: ratatui::layout::Rect) {
    let items: Vec<ListItem> = if app.devices.is_empty() {
        vec![ListItem::new(Line::from(Span::styled(
            "  (no devices discovered — press 'd' to announce)",
            Style::default().fg(Color::DarkGray),
        )))]
    } else {
        app.devices
            .iter()
            .take(9)
            .enumerate()
            .map(|(i, d)| {
                let fp: String = d.fingerprint.chars().take(8).collect();
                ListItem::new(Line::from(vec![
                    Span::styled(
                        format!("[{}] ", i + 1),
                        Style::default()
                            .fg(Color::Yellow)
                            .add_modifier(Modifier::BOLD),
                    ),
                    Span::raw(&d.alias),
                    Span::styled(
                        format!("  {}:{}  {}", d.address, d.port, fp),
                        Style::default().fg(Color::DarkGray),
                    ),
                ]))
            })
            .collect()
    };
    let title = if app.pending_files.is_empty() {
        "Devices".to_string()
    } else {
        format!("Devices — {} file(s) staged, press 1-9 to send", app.pending_files.len())
    };
    let block = Block::default().borders(Borders::ALL).title(title);
    frame.render_widget(List::new(items).block(block), area);
}

fn state_style(state: MissionState) -> (&'static str, Color) {
    match state {
        MissionState::Idle => ("idle", Color::DarkGray),
        MissionState::Pending => ("pending", Color::Yellow),
        MissionState::Transfering => ("transferring", Color::Cyan),
        MissionState::Finished => ("finished", Color::Green),
        MissionState::Failed => ("failed", Color::Red),
        MissionState::Canceled => ("canceled", Color::Magenta),
        MissionState::Busy => ("busy", Color::Magenta),
    }
}

fn file_state_label(state: &FileState) -> String {
    match state {
        FileState::Pending => "waiting".into(),
        FileState::Transfer => "sending".into(),
        FileState::Finish => "done".into(),
        FileState::Skip => "skipped".into(),
        FileState::Fail { msg } => format!("failed: {msg}"),
    }
}

fn human_size(bytes: i64) -> String {
    let b = bytes.max(0) as f64;
    if b >= 1_048_576.0 {
        format!("{:.1} MiB", b / 1_048_576.0)
    } else if b >= 1024.0 {
        format!("{:.1} KiB", b / 1024.0)
    } else {
        format!("{bytes} B")
    }
}

fn progress_bar(f: &crate::state::FileView, width: usize) -> String {
    let width = width.max(4);
    // A finished file may have skipped progress events entirely (tiny
    // files, fast links); render it as a full bar.
    let ratio = if matches!(f.state, FileState::Finish) {
        Some(1.0)
    } else {
        f.progress_ratio()
    };
    match ratio {
        Some(ratio) if matches!(f.state, FileState::Transfer | FileState::Finish) => {
            let filled = (ratio * width as f64).round() as usize;
            let pct = (ratio * 100.0).round() as i64;
            format!(
                "[{}{}] {:>3}% {}/{}",
                "#".repeat(filled.min(width)),
                "-".repeat(width - filled.min(width)),
                pct,
                human_size(f.transferred as i64),
                human_size(f.size),
            )
        }
        _ => format!("[{}] {}", "-".repeat(width), file_state_label(&f.state)),
    }
}

fn session_lines(s: &SessionView, focused: bool, width: usize) -> Vec<Line<'static>> {
    let (label, color) = state_style(s.state);
    let arrow = match s.direction {
        SessionDirection::Send => "↑ send",
        SessionDirection::Receive => "↓ recv",
    };
    let marker = if focused { "▶" } else { " " };
    let mut head = vec![
        Span::raw(format!("{marker} ")),
        Span::styled(
            arrow,
            Style::default()
                .fg(match s.direction {
                    SessionDirection::Send => Color::Blue,
                    SessionDirection::Receive => Color::Green,
                })
                .add_modifier(Modifier::BOLD),
        ),
        Span::raw(format!(" {} ({}) ", s.peer_alias, s.peer_addr)),
        Span::styled(label, Style::default().fg(color).add_modifier(Modifier::BOLD)),
    ];
    if s.is_pending_receive() {
        head.push(Span::styled(
            "  [y] accept  [n] decline",
            Style::default().fg(Color::Yellow),
        ));
    }
    let mut lines = vec![Line::from(head)];

    let bar_width = width.saturating_sub(38).clamp(8, 40);
    for f in &s.files {
        lines.push(Line::from(vec![
            Span::raw("    "),
            Span::raw(truncate(&f.name, 24)),
            Span::raw(" "),
            Span::styled(
                progress_bar(f, bar_width),
                Style::default().fg(match f.state {
                    FileState::Finish => Color::Green,
                    FileState::Fail { .. } => Color::Red,
                    FileState::Skip => Color::DarkGray,
                    _ => Color::Cyan,
                }),
            ),
        ]));
    }
    if let Some(reason) = &s.fail_reason {
        lines.push(Line::from(vec![
            Span::raw("    "),
            Span::styled(format!("reason: {reason}"), Style::default().fg(Color::Red)),
        ]));
    }
    lines
}

fn truncate(s: &str, max: usize) -> String {
    if s.chars().count() <= max {
        s.to_string()
    } else {
        let mut out: String = s.chars().take(max.saturating_sub(1)).collect();
        out.push('…');
        out
    }
}

fn draw_sessions(frame: &mut ratatui::Frame, app: &App, area: ratatui::layout::Rect) {
    let inner_width = area.width.saturating_sub(2) as usize;
    let mut lines: Vec<Line> = Vec::new();
    if app.sessions.is_empty() {
        lines.push(Line::from(Span::styled(
            "  (no sessions yet)",
            Style::default().fg(Color::DarkGray),
        )));
    } else {
        for (i, s) in app.sessions.iter().enumerate() {
            if i > 0 {
                lines.push(Line::from(""));
            }
            lines.extend(session_lines(s, i == app.focus, inner_width));
        }
    }
    let pending = app.pending_receive_count();
    let title = if pending > 0 {
        format!("Sessions — {pending} incoming request(s) waiting (Tab to focus)")
    } else {
        "Sessions".to_string()
    };
    let block = Block::default().borders(Borders::ALL).title(title);
    frame.render_widget(
        Paragraph::new(lines).block(block).wrap(Wrap { trim: false }),
        area,
    );
}

fn draw_status(
    frame: &mut ratatui::Frame,
    app: &App,
    config: &EffectiveConfig,
    server_rx: &watch::Receiver<bool>,
    server_err_rx: &watch::Receiver<Option<String>>,
    area: ratatui::layout::Rect,
) {
    let (server_label, server_color) = if *server_rx.borrow() {
        (format!("listening on :{}", config.port), Color::Green)
    } else if let Some(err) = server_err_rx.borrow().clone() {
        (format!("server error: {err}"), Color::Red)
    } else {
        ("starting…".to_string(), Color::Yellow)
    };

    let notice = app.notice.clone().unwrap_or_default();
    let line1 = Line::from(vec![
        Span::styled(
            format!(" {} ", config.alias),
            Style::default().add_modifier(Modifier::BOLD),
        ),
        Span::raw("| "),
        Span::styled(server_label, Style::default().fg(server_color)),
        Span::raw(format!(" | save to {} | {notice}", config.destination.display())),
    ]);

    let line2 = if let InputMode::AddingFile { buffer } = &app.input {
        Line::from(vec![
            Span::styled(" add file path(s): ", Style::default().fg(Color::Yellow)),
            Span::raw(buffer.clone()),
            Span::styled("▌ (Enter=stage, Esc=cancel)", Style::default().fg(Color::DarkGray)),
        ])
    } else {
        Line::from(Span::styled(
            " [1-9] send to device  [a] add file  [y/n] accept/decline  [Tab/↑/↓] focus  [c] cancel  [x] clear done  [d] rediscover  [q] quit",
            Style::default().fg(Color::DarkGray),
        ))
    };

    frame.render_widget(
        Paragraph::new(vec![line1, line2]).block(Block::default().borders(Borders::ALL)),
        area,
    );
}
