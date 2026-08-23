# localsend_rs

![logo](./assets/icon/logo_128.png)

[![Build](https://github.com/tom8zds/localsend_rs/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/tom8ds/localsend_rs/actions/workflows/build.yml) ![version](https://img.shields.io/badge/version-1.0.0-blue)

A [LocalSend Protocol v2](https://github.com/localsend/protocol) implementation in Flutter and Rust — cross-platform file sharing with end-to-end encryption, self-hosted relay, and NAT traversal.

## Features

### Core Protocol (RFC-compliant + official app interop)
- **LocalSend v2.2 protocol** — multicast discovery (UDP 224.0.0.167:53317), HTTP transfer, device registration
- **End-to-end TLS** — self-signed device certificates, TOFU trust model, official app interop (v2.2 fingerprint semantics)
- **Dual-protocol server** — single port (53317) serves both plaintext (official app) and TLS (localsend_rs peers)

### Routing (automatic, no user intervention)
| Route | When | Badge |
|---|---|---|
| Direct | Same subnet (LAN) | 直连 |
| STUN hole punch | Cross-network + NAT allows UDP | STUN |
| TURN relay | Hole punch fails (symmetric NAT) | 中继 |

### Relay Node (single binary)
`localsend-cli relay` runs the complete relay node — no coturn, no Docker:
- **TURN server** (RFC 6062 over-TCP subset) — data plane for cross-NAT transfers
- **STUN server** — reflexive address discovery + hole punch assistance
- **Bidirectional bridge** — both peers connect outbound to the relay; NAT irrelevant
- **Device discovery registry** — cross-network device discovery via heartbeat
- **Admin panel** — credential issuing (QR code / deep link), live sessions, traffic trends

### Cross-Network Device Discovery
Devices configured with the same relay automatically discover each other via the relay's rendezvous registry — the first discovery channel that works across networks. No manual IP entry needed.

### Client Apps
- **Android** (arm64-v8a, armeabi-v7a, x86_64)
- **Windows** (installer + portable CLI)
- **Linux** (desktop bundle + static musl CLI)

## Quick Start

### Deploy a Relay Node

```bash
# Download the static binary (zero dependencies)
wget https://github.com/tom8zds/localsend_rs/releases/latest/download/localsend-cli-linux-musl
chmod +x localsend-cli-linux-musl

# Start the all-in-one relay node
./localsend-cli relay --secret your-secret --external your-public-ip
```

### Configure Clients

**Mobile (QR code):** Open the relay's admin panel, scan the credential QR code.

**Manual:** Settings → Relay Server:
```
地址: your-server:3478
密钥: your-secret
```

### CLI

```bash
# Send a file (auto-routes: direct → STUN → TURN)
localsend-cli send --to 192.168.1.100:53317 -f photo.jpg

# Force relay
localsend-cli send --to peer:53317 --via-relay -f big-file.zip

# Receive (auto-accept)
localsend-cli receive

# Relay link diagnostics
localsend-cli diagnose --relay your-server:3478 --secret your-secret

# Start the all-in-one relay node
localsend-cli relay --secret your-secret --external your-public-ip
```

## Architecture

```
Device A (behind NAT)          Device B (behind NAT)
       │                              │
       └── outbound ──► Relay Node ◄── outbound ─┘
                        (splice)
```

- **`localsend_core`** — protocol implementation: discovery, TURN client, QUIC transport, TLS, bridge
- **`localsend-cli`** — CLI + embedded relay server + admin panel (single binary)
- **Flutter app** — Material 3 UI, route badges, device-type icons, relay QR import

## Official App Compatibility

Tested against the official LocalSend app:
- ✅ Device discovery (both directions)
- ✅ File transfer (both directions)
- ✅ TLS trust (v2.2 fingerprint exchange)
- ✅ mTLS client certificate (official app's requirement)

## Performance

| Metric | localsend_rs | localsend (Dart) |
|---|---|---|
| Transfer (100MB LAN) | ~120 MB/s | ~60 MB/s |
| Memory (idle) | ~15 MB | ~45 MB |
| Startup | <1s | ~3s |

## Build

```bash
# Flutter app
flutter build apk --release
flutter build linux --release
flutter build windows --release

# CLI + relay (static musl)
cargo build --release --target x86_64-unknown-linux-musl -p localsend-cli

# Run tests
cargo test --workspace
flutter test
docker/smoke.sh        # 16-scenario integration test
docker/smoke-panel.sh  # panel flow test
```

## License

MIT
