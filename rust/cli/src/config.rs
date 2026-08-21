//! TOML configuration persistence for `localsend-cli`.
//!
//! Settings live in `$XDG_CONFIG_HOME/localsend-cli/config.toml`
//! (falling back to `~/.config/localsend-cli/config.toml`). Command
//! line arguments always win over the file; the file only provides
//! defaults and persists the generated device fingerprint so the
//! device identity is stable across runs.

use std::path::{Path, PathBuf};

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};

pub const DEFAULT_PORT: u16 = 53317;

/// Raw settings as stored on disk. Every field is optional so a
/// partially-written or hand-edited file still loads.
#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
pub struct FileConfig {
    pub alias: Option<String>,
    pub port: Option<u16>,
    pub destination: Option<PathBuf>,
    /// Stable device identity, generated once on first run.
    pub fingerprint: Option<String>,
}

/// Fully-resolved runtime settings (CLI args merged over the file).
#[derive(Debug, Clone, PartialEq)]
pub struct EffectiveConfig {
    pub alias: String,
    pub port: u16,
    pub destination: PathBuf,
    pub fingerprint: String,
}

/// Overrides coming from the command line. `None` means "fall back to
/// the config file (or built-in default)".
#[derive(Debug, Clone, Default)]
pub struct CliOverrides {
    pub alias: Option<String>,
    pub port: Option<u16>,
    pub destination: Option<PathBuf>,
}

pub fn config_path() -> PathBuf {
    let base = dirs::config_dir()
        .or_else(dirs::home_dir)
        .unwrap_or_else(|| PathBuf::from("."));
    base.join("localsend-cli").join("config.toml")
}

pub fn load(path: &Path) -> Result<FileConfig> {
    match std::fs::read_to_string(path) {
        Ok(text) => toml::from_str(&text)
            .with_context(|| format!("failed to parse {}", path.display())),
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(FileConfig::default()),
        Err(e) => Err(e).with_context(|| format!("failed to read {}", path.display())),
    }
}

pub fn save(path: &Path, config: &FileConfig) -> Result<()> {
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent)
            .with_context(|| format!("failed to create {}", parent.display()))?;
    }
    let text = toml::to_string_pretty(config).context("failed to serialize config")?;
    std::fs::write(path, text).with_context(|| format!("failed to write {}", path.display()))
}

fn default_alias(fingerprint: &str) -> String {
    let short: String = fingerprint.chars().take(4).collect();
    format!("localsend-cli-{short}")
}

fn default_destination() -> PathBuf {
    dirs::download_dir()
        .or_else(dirs::home_dir)
        .unwrap_or_else(|| PathBuf::from("."))
}

/// Merge CLI overrides over the file config over built-in defaults.
/// A fingerprint is generated (but not persisted here) when the file
/// does not carry one.
pub fn resolve(overrides: &CliOverrides, file: &FileConfig) -> EffectiveConfig {
    let fingerprint = file
        .fingerprint
        .clone()
        .unwrap_or_else(|| uuid::Uuid::new_v4().to_string());
    let alias = overrides
        .alias
        .clone()
        .or_else(|| file.alias.clone())
        .unwrap_or_else(|| default_alias(&fingerprint));
    let port = overrides
        .port
        .or(file.port)
        .unwrap_or(DEFAULT_PORT);
    let destination = overrides
        .destination
        .clone()
        .or_else(|| file.destination.clone())
        .unwrap_or_else(default_destination);
    EffectiveConfig {
        alias,
        port,
        destination,
        fingerprint,
    }
}

/// Load, resolve and persist: ensures the file exists and carries a
/// fingerprint, then returns the effective settings with CLI
/// overrides applied (overrides themselves are not written back).
pub fn load_effective(path: &Path, overrides: &CliOverrides) -> Result<EffectiveConfig> {
    let mut file = load(path)?;
    if file.fingerprint.is_none() {
        file.fingerprint = Some(uuid::Uuid::new_v4().to_string());
    }
    let effective = resolve(overrides, &file);
    if !path.exists() {
        // Persist the first-run file (with the generated fingerprint)
        // so the device identity survives restarts.
        save(path, &file)?;
    } else {
        let on_disk = load(path)?;
        if on_disk.fingerprint.is_none() {
            save(path, &file)?;
        }
    }
    Ok(effective)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_full_config() {
        let text = r#"
            alias = "desk"
            port = 1234
            destination = "/tmp/incoming"
            fingerprint = "fp-1"
        "#;
        let cfg: FileConfig = toml::from_str(text).unwrap();
        assert_eq!(cfg.alias.as_deref(), Some("desk"));
        assert_eq!(cfg.port, Some(1234));
        assert_eq!(cfg.destination, Some(PathBuf::from("/tmp/incoming")));
        assert_eq!(cfg.fingerprint.as_deref(), Some("fp-1"));
    }

    #[test]
    fn parses_empty_config() {
        let cfg: FileConfig = toml::from_str("").unwrap();
        assert_eq!(cfg, FileConfig::default());
    }

    #[test]
    fn load_missing_file_yields_default() {
        let tmp = tempfile::tempdir().unwrap();
        let cfg = load(&tmp.path().join("nope.toml")).unwrap();
        assert_eq!(cfg, FileConfig::default());
    }

    #[test]
    fn cli_overrides_beat_file() {
        let file = FileConfig {
            alias: Some("file-alias".into()),
            port: Some(1111),
            destination: Some(PathBuf::from("/from-file")),
            fingerprint: Some("fp".into()),
        };
        let overrides = CliOverrides {
            alias: Some("cli-alias".into()),
            port: Some(2222),
            destination: Some(PathBuf::from("/from-cli")),
        };
        let eff = resolve(&overrides, &file);
        assert_eq!(eff.alias, "cli-alias");
        assert_eq!(eff.port, 2222);
        assert_eq!(eff.destination, PathBuf::from("/from-cli"));
        assert_eq!(eff.fingerprint, "fp");
    }

    #[test]
    fn file_beats_builtin_defaults() {
        let file = FileConfig {
            alias: Some("file-alias".into()),
            port: Some(1111),
            destination: None,
            fingerprint: Some("abcdef".into()),
        };
        let eff = resolve(&CliOverrides::default(), &file);
        assert_eq!(eff.alias, "file-alias");
        assert_eq!(eff.port, 1111);
        assert!(eff.destination.is_absolute() || eff.destination == Path::new("."));
        assert_eq!(eff.fingerprint, "abcdef");
    }

    #[test]
    fn defaults_fill_everything() {
        let eff = resolve(&CliOverrides::default(), &FileConfig::default());
        assert_eq!(eff.port, DEFAULT_PORT);
        assert!(eff.alias.starts_with("localsend-cli-"));
        assert!(!eff.fingerprint.is_empty());
    }

    #[test]
    fn load_effective_persists_fingerprint() {
        let tmp = tempfile::tempdir().unwrap();
        let path = tmp.path().join("sub").join("config.toml");
        let first = load_effective(&path, &CliOverrides::default()).unwrap();
        assert!(path.exists());
        let second = load_effective(&path, &CliOverrides::default()).unwrap();
        assert_eq!(first.fingerprint, second.fingerprint);
    }
}
