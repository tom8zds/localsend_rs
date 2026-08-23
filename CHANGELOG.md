# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] — 2026-08-23

First stable release: cross-platform file sharing with self-hosted relay, end-to-end encryption, and NAT traversal.

### ✨ Features

#### Core Protocol
- **LocalSend v2.2 protocol implementation** — multicast discovery, HTTP transfer, device registration
- **End-to-end TLS** — self-signed device certificates with TOFU trust (v2.2 fingerprint semantics, official app interop)
- **mTLS client certificate** — present device certificate to official app's HTTPS endpoints
- **Dual-protocol server** — single port (53317) serves plaintext (official app) and TLS (localsend_rs peers)

#### Routing & NAT Traversal
- **Automatic route selection** — direct → STUN hole punch (QUIC) → TURN relay (transparent fallback)
- **QUIC transport** — hole punch data plane with TLS 1.3, device certificate authentication
- **STUN hole punch** — candidate exchange, simultaneous UDP punching, stun route badge
- **Bidirectional relay bridge** — both peers connect outbound to the relay; works behind any NAT
- **Cross-network device discovery** — relay rendezvous registry with 30s heartbeat, 75s TTL

#### Relay Node (single binary)
- **Embedded TURN server** (RFC 6062 subset) — data plane for cross-NAT transfers
- **Embedded STUN server** — reflexive address discovery + connection test
- **Bidirectional bridge protocol** — BRIDGE LISTEN/CONNECT with splice confirmation
- **Device discovery registry** — cross-network device discovery via authenticated heartbeat
- **Admin panel** — credential issuing (QR code / deep link), live TURN sessions with kick, 24h traffic trends, 30-day retention
- **`diagnose` command** — 6-step relay link test (TCP → STUN → BRIDGE → handshake → discovery → data round-trip)

#### Flutter App
- **Material 3 UI** — spacing/color/typography/shape tokens, 600/840/1200 window classes
- **Route badges** — 直连 / 中继 / STUN per session and per device
- **Device-type icons** — mobile / desktop / web / headless
- **Relay settings** — server address + secret, connection test (RTT), QR code / deep link import
- **TLS toggle** — security settings group with plain-mode warning
- **Widget previews** — all core widgets have preview support
- **One-click config import** — `localsend-relay://configure` deep link on Android/iOS/macOS/Windows

#### Build & CI
- **Static musl binaries** — zero libc dependency, runs on any Linux distro
- **5-platform CI** — Android (3 ABI APKs), Windows (installer + CLI), Linux (desktop + CLI), relay panel
- **Fixed release signing** — stable APK signature via CI keystore secret
- **16-scenario docker smoke test** — discovery, multi-receiver, relay fallback, all-TLS verification
- **Docker compose** — local relay + panel deployment

### 🐞 Bug Fixes (since pre-release)

- **`announce()` wiped the device list** — periodic announce carried a stray `clear_devices()` that emptied peers every 5s
- **Hole punch exchange URL** — was posting to `127.0.0.1` instead of the peer address, causing self-loop transfers
- **Bridge handshake byte comparison** — `BRIDGE OK\n` (10 bytes) compared against `BRIDGE OK` (9 bytes), always failing
- **Bridge per-request fingerprint** — was passing the manual target's fabricated fingerprint instead of the real one
- **STUN probe registered local port instead of NAT-mapped port** — TURN Connect to wrong port always failed
- **Self-discovery** — relay-rendezvous merged the device's own entry back into the device list
- **Device list flicker** — register/announce payload field differences triggered unnecessary UI rebuilds
- **Certificate validity** — rcgen default (now → expiry) flunked official app's NotBefore/NotAfter check; aligned to 1975–4096
- **Fingerprint case** — official app uses uppercase hex; our lowercase was intermittently rejected
- **Same-host instances** — UDP port 53317 now binds with SO_REUSEADDR/REUSEPORT
- **Multi-interface multicast** — receiver joins on every IPv4 interface, announce sends per interface
- **Android Gradle** — AGP 8.11.1 + Gradle 8.14 + Kotlin 2.2.20; Windows installer Inno Setup quote fix

### ⚡ Performance

- Transfer throughput ~2x official app (Rust core vs Dart)
- TURN relay: <35μs forwarding latency
- Static CLI binary: 10MB, zero runtime dependencies

### 💥 Breaking Changes (from pre-release)

- `relay-panel` standalone binary removed — merged into `localsend-cli relay` + `localsend-cli panel`
- STUN/TURN from coturn replaced by embedded Rust implementation
- Gradle wrapper 7.5 → 8.14, AGP 7.3 → 8.11.1

## [0.1.0] — 2026-08-19

Initial pre-release.

### Features

- LocalSend v2 protocol core (Rust workspace: core/ffi/cli)
- Flutter app with riverpod 3.2.1
- Session-based provider layer, multi-target send
- ratatui TUI, headless send/receive
- Docker smoke test framework

## [0.0.1-alpha] — 2026-08-18

Initial project scaffold.

### Features

- Basic flutter + rust_skeleton project structure
- Android device-info plugin fix

### Bug Fixes

- const widget not respond to locale change
