# Tinyproxy Add-on

A private HTTP/HTTPS **forward proxy** for Home Assistant OS, for clients on your
Tailscale tailnet that want selected traffic to egress via your home connection.

Built for small hardware: the image is **~4 MB** and Tinyproxy uses **under 2 MB
of RAM** at idle. It is safe on a 1 GB Raspberry Pi.

## What this is and is not

| Thing | This add-on? |
|---|---|
| **Forward proxy** — client explicitly set to `http://host:8888` | yes |
| **Reverse proxy** — public hostname in front of Home Assistant | no |
| **Tailscale exit node** — routes all of a device's traffic at the IP layer | no |
| **Transparent proxy** — intercepts traffic the client did not opt into | no |
| **Tailscale direct access** — reaching HA itself over the tailnet | different thing |
| SOCKS / generic TCP / UDP proxy | no |

Only applications you explicitly point at the proxy will use it.

## Installation

### As a remote repository (recommended)

1. Settings -> Add-ons -> Add-on Store -> three-dot menu -> **Repositories**.
2. Add `https://github.com/rymain/hassio-addon-tinyproxy`.
3. Refresh, then install **Tinyproxy**.

The Pi **pulls a prebuilt ~4 MB image** from ghcr.io rather than compiling
anything locally. On 1 GB hardware this matters: a local Docker build is the
single heaviest moment of an add-on's life.

### As a local add-on

1. Place the `tinyproxy/` folder at `/addons/local_tinyproxy/`, so that
   `/addons/local_tinyproxy/config.yaml` exists. Ways to get files there:
   - **Samba Share add-on** — mount the `addons` share and copy the folder.
   - **Advanced SSH & Web Terminal add-on** — `git clone` into `/addons`.
   - Do not try to `apt install` anything on the HA OS host; it is immutable.
2. Settings -> Add-ons -> Add-on Store -> three-dot menu -> **Check for updates**.
3. Refresh the browser; "Tinyproxy" appears under **Local add-ons**.
4. Install, configure, start.

Local installs **build on the Pi** (a few minutes, and the `image:` key is
ignored). The remote repository route is lighter.

## Recommended configuration

```yaml
port: 8888
allow:
  - 100.64.0.0/10
basic_auth_username: "proxyuser"
basic_auth_password: "replace-with-a-long-random-password"
connect_ports:
  - 443
  - 563
timeout: 600
log_level: "Info"
```

## Options

| Option | Type | Default | Notes |
|---|---|---|---|
| `port` | int 1024–65535 | `8888` | Port Tinyproxy listens on **inside the container**. See note below. |
| `allow` | list of CIDR/IP | `100.64.0.0/10` | One `Allow` directive per entry. Required, non-empty. `0.0.0.0/0` and `::/0` rejected at startup. |
| `basic_auth_username` | string | `""` | Optional. |
| `basic_auth_password` | password | `""` | Optional. Never written to the log. |
| `connect_ports` | list of int | `[443, 563]` | Ports allowed for HTTPS `CONNECT`. |
| `timeout` | int 1–86400 | `600` | Seconds of inactivity before a connection closes. |
| `log_level` | enum | `Info` | `Critical`, `Error`, `Warning`, `Notice`, `Connect`, `Info`. |

**Changing the port takes two edits.** `port` sets the container-internal
listener; the host-side published port is the separate `8888/tcp` field in the
add-on's **Network** panel. Home Assistant port mappings cannot be driven from
add-on options, so change both or neither.

`100.64.0.0/10` is the CGNAT range Tailscale allocates `100.x.y.z` addresses
from, so a tailnet peer's source address falls inside it.

### Credential validation

If exactly one of `basic_auth_username` / `basic_auth_password` is set, the
add-on **refuses to start** and logs why, rather than quietly running an
unauthenticated proxy. Set both, or neither.

### CONNECT port restriction

Only ports in `connect_ports` may be used for HTTPS `CONNECT`. HTTPS
destinations on unusual ports (e.g. `https://example.com:8443`) **will fail**
with `403 Access violation` until you deliberately add that port. An
unrestricted CONNECT list turns the proxy into a general-purpose TCP relay.

## Security

> **Do not forward TCP/8888 from the internet. Use Tailscale ACLs/grants and
> Tinyproxy's allow-list. Add BasicAuth as defense in depth.**

- No router changes, no UPnP, no port forwarding. Ever.
- Home Assistant publishes add-on ports on **all host interfaces**, so the proxy
  is also reachable from your LAN. The `Allow` list is what rejects
  non-permitted source IPs at the application layer — keep it tight.
- The add-on **cannot** bind specifically to your Tailscale IP. The Tailscale
  add-on runs in a separate container with its own network namespace; this
  add-on never sees `tailscale0` and cannot `Listen` on the 100.x address.
  Binding is all-interfaces plus allow-list filtering. An honest limitation, not
  something you have misconfigured.
- Tinyproxy drops privileges to the unprivileged `tinyproxy` user after binding.
  No `privileged`, `NET_ADMIN`, host PID, host networking, or Docker socket.
- The generated config lives at `/tmp/tinyproxy.conf`, mode `0600`, root-owned,
  written before the privilege drop. `/data` can be mounted read-only.

## Does this work over Tailscale?

**Usually yes.** The Tailscale add-on advertises the Home Assistant *host's*
tailnet address, and add-on ports publish on the host's network stack — so
`http://<ha-tailscale-ip>:8888` normally reaches this add-on even though the two
containers are separate.

If it does not on your setup, supported fallbacks, best first:

1. **Tailscale subnet routes** — advertise your LAN, then use
   `http://<ha-lan-ip>:8888`. Smallest change that works.
2. **A separate Raspberry Pi OS / VM / Docker host** running Tailscale and
   Tinyproxy in one network namespace. Recommended if you want the proxy bound
   strictly to the tailnet interface, because there it genuinely can be.
3. `tailscale serve` TCP forwarding — only forwards to the node's own localhost
   and terminates TLS; **not** a fit for a plain HTTP proxy port. Listed so you
   know it was considered and rejected.

A combined Tailscale+Tinyproxy add-on is possible but means maintaining a fork
of the community Tailscale add-on and running with the elevated privileges
Tailscale needs. Not worth it at this scope.

## Verifying it works

```bash
curl -x http://proxyuser:PASSWORD@<ha-tailscale-ip>:8888 https://ifconfig.me
```

Expected: your **home** public IP, not the client's.

| Test | Expected |
|---|---|
| HTTPS `CONNECT` on 443 | `200` |
| Plain HTTP | `200` |
| No credentials when BasicAuth configured | `407` |
| Wrong password | `401` |
| Source IP outside `allow` | `403` |
| `https://host:8443` with default `connect_ports` | `403 Access violation` |
| One credential field set, other empty | add-on refuses to start, reason in log |
| `allow` containing `0.0.0.0/0` or `::/0`, or empty | add-on refuses to start |
| Password in the add-on log | never appears |

`wss://` WebSockets work because they tunnel inside `CONNECT 443`. No claim is
made about arbitrary non-HTTP protocols.

## Troubleshooting

**Add-on fails to start.** Open the add-on **Log** tab. Every refusal prints a
single `FATAL:` line naming the exact option at fault. The most common causes
are one-of-two BasicAuth fields, and an `allow` list that is empty or contains
`0.0.0.0/0`.

**`403` from the proxy.** Your client's source IP is not in `allow`. Check the
source address the HA host actually sees — over Tailscale this is the peer's
`100.x.y.z`, over LAN it is the LAN IP, and the two need different entries.

**`407` / `401`.** BasicAuth is on. Use `-x http://user:pass@host:8888`.

**Design note.** This add-on deliberately uses a plain Alpine base with a single
`/run.sh` entrypoint rather than the Home Assistant base image with bashio and
s6-overlay. That removes the Supervisor-API dependency and the s6 service
layering — fewer moving parts to fail at startup, and a ~4 MB image instead of
~80 MB. See the changelog for the 2.x failure this replaced.
