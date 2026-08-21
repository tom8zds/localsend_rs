# localsend TURN relay (coturn)

Self-hosted relay for transferring between localsend endpoints that
cannot reach each other directly (different NATs / networks). The
relay speaks standard STUN/TURN over TCP ([RFC
6062](https://www.rfc-editor.org/rfc/rfc6062)) and is a pure byte
pipe — it never sees file contents.

**Why coturn and not turn-rs**: turn-rs permissions only cover peers
that are themselves clients of the same server — it cannot relay to
an arbitrary peer address, which is exactly what localsend needs
(the receiving endpoint's own HTTP server). coturn implements the
full generic RFC 8656/6062 model.

## Admin panel (relay-panel)

`docker compose up -d` also starts **relay-panel** on
`127.0.0.1:8787` — the credential-issuing portal and monitoring
console:

- **签发凭据** (`/issue`): mint a client one-click config rendered as
  a `localsend-relay://configure?addr=…&secret=…` QR code + copyable
  link (scan/paste it into the app), plus a sample time-limited pair
- **概览** (`/`): live allocations, cumulative traffic, a 24h
  traffic trend (self-collected, minute granularity, 30-day
  retention in the panel's sqlite)
- **在线会话** (`/sessions`): live TURN sessions (user/peer/bytes,
  polled from coturn's CLI) with per-session kick

Env knobs (defaults fit the local test stack): `PANEL_ADMIN_PASSWORD`
(login), `RELAY_SECRET` (must match coturn's `static-auth-secret`),
`RELAY_PUBLIC_ADDR` (what issued configs advertise),
`COTURN_PROM_URL`/`COTURN_CLI_ADDR`/`COTURN_CLI_PASSWORD_PLAIN`
(coturn's metrics endpoint and admin CLI — the conf stores the
`turnadmin -P` hash, the panel sends the plain form),
`PANEL_BIND`/`PANEL_DB`.

The panel binds loopback by design; reach it over ssh port-forwarding
or an HTTPS reverse proxy. Data lives in the `panel-data` volume.

## Local testing / integration tests

```bash
docker compose up -d
cargo test -p localsend_core --test relay_integration -- --ignored   # from rust/
```

`turnserver.conf` here is the *testing* template: it allows loopback
peers and ships a well-known secret. The full cross-network scenario
(two isolated docker networks + fallback + checksums) runs as
scenario D in `docker/smoke.sh` via `docker/compose.relay.yaml`.

## Production deployment

1. Copy `turnserver.conf` to a private variant and change:
   - `external-ip` → the host's public IP (or `public/private` pair
     behind NAT)
   - `static-auth-secret` → a long random value; drop
     `allow-loopback-peers`
2. Expose 3478/udp + 3478/tcp to the internet. Relay data
   connections for TURN-over-TCP originate from arbitrary source
   ports, but everything clients dial stays on 3478.
3. Metrics: coturn can expose Prometheus via `prometheus-port`; the
   default conf keeps it off.

## Credentials

Time-limited REST credentials (draft-uberti), shared-secret based —
identical scheme on coturn (`use-auth-secret`) and the CLI:

```bash
localsend-cli relay-credential --secret <static-auth-secret> --ttl 86400 --suffix desk
# username: 1761234567:desk
# password: <base64 HMAC-SHA1>
```

Client config (`~/.config/localsend-cli/config.toml`):

```toml
[relay]
addr = "relay.example.com:3478"
secret = "<static-auth-secret>"
```

With this set, sends automatically fall back to the relay when a
direct connection fails; `--via-relay` forces the relay path.

## Notes

- Image tag pinned to coturn 4.17.2.
- coturn's loopback/self protections: `allow-loopback-peers` is
  required for local tests against 127.0.0.1, and the advertised
  `external-ip` must differ from the peer address or permission
  installs are rejected as a relay loop.
- End-to-end TLS between endpoints is the M2 hardening step; the
  relay itself stays a transparent pipe.
