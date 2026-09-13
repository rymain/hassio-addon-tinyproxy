# Tinyproxy Add-on

A private HTTP/HTTPS **forward proxy** for Home Assistant OS, intended for clients
on your Tailscale tailnet that want to send browser/CLI traffic out through your
home internet connection.

## What this is and is not

| Thing | This add-on? |
|---|---|
| **Forward proxy** — client explicitly configured with `http://host:8888` | ✅ yes |
| **Reverse proxy** — puts a public hostname in front of Home Assistant | ❌ no |
| **Tailscale exit node** — routes *all* of a device's traffic at the IP layer | ❌ no |
| **Transparent proxy** — intercepts traffic the client did not opt into | ❌ no |
| **Tailscale direct access** — reaching HA itself over the tailnet | ❌ different thing |
| SOCKS / generic TCP / UDP proxy | ❌ no |

Only applications you explicitly point at the proxy will use it.

## Installation

### A. As a local add-on

1. Put this repository's `tinyproxy/` folder on the HA OS `/addons` share as
   `/addons/local_tinyproxy/` — so `/addons/local_tinyproxy/config.yaml` exists.
   Practical ways to get files there:
   - **Samba Share add-on** — mount the `addons` share and copy the folder over.
   - **Advanced SSH & Web Terminal add-on** — `git clone` the repo into `/addons`
     and move `tinyproxy/` to `/addons/local_tinyproxy`.
   - Do **not** try to `apt install` anything on the HA OS host; it is immutable
     and has no apt.
2. Settings → Add-ons → Add-on Store → ⋮ → **Check for updates**.
3. Refresh the browser. "Tinyproxy" appears under **Local add-ons**.
4. Install → Configuration → Start.

### B. As a remote repository (preferred)

1. Settings → Add-ons → Add-on Store → ⋮ → **Repositories**.
2. Add `https://github.com/rymain/hassio-addon-tinyproxy`.
3. Refresh, then install **Tinyproxy** from the new repository section.

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
| `port` | int 1024–65535 | `8888` | Port Tinyproxy listens on **inside the container**. See the note below. |
| `allow` | list of CIDR/IP | `100.64.0.0/10` | One `Allow` directive per entry. Required and non-empty. `0.0.0.0/0` and `::/0` are rejected at startup. |
| `basic_auth_username` | string | `""` | Optional. |
| `basic_auth_password` | password | `""` | Optional. Never written to the log. |
| `connect_ports` | list of int | `[443, 563]` | Ports allowed for HTTPS `CONNECT`. |
| `timeout` | int 1–86400 | `600` | Seconds of inactivity before a connection is closed. |
| `log_level` | enum | `Info` | `Critical`, `Error`, `Warning`, `Notice`, `Connect`, `Info`. |

**Changing the port takes two edits.** `port` sets the container-internal listen
port; the host-side published port is the separate `8888/tcp` field in the
add-on's **Network** panel. Home Assistant port mappings cannot be driven from
add-on options, so if you change one you must change the other to match.

`100.64.0.0/10` is the CGNAT range Tailscale allocates its `100.x.y.z` addresses
from. It is the default because a tailnet peer's source address falls inside it.

### Credential validation

If exactly one of `basic_auth_username` / `basic_auth_password` is set, the
add-on **fails to start** with an explicit log message rather than quietly
running an unauthenticated proxy. Set both, or neither.

### CONNECT port restriction

Only ports in `connect_ports` may be used for HTTPS `CONNECT`. HTTPS destinations
on unusual ports (e.g. `https://example.com:8443`) **will fail** until you
deliberately add that port to `connect_ports`. This is intentional — an
unrestricted CONNECT list turns the proxy into a general-purpose TCP relay.

## Security

> **Do not forward TCP/8888 from the internet. Use Tailscale ACLs/grants and
> Tinyproxy's allow-list. Add BasicAuth as defense in depth.**

- No router changes, no UPnP, no port forwarding. Ever.
- Home Assistant publishes add-on ports on **all host interfaces**, so the proxy
  is also reachable from your LAN. The `Allow` list is the control that rejects
  non-permitted source IPs at the application layer — keep it tight.
- The add-on **cannot** bind specifically to your Tailscale IP. The Tailscale
  add-on runs in its own container with its own network namespace; this add-on
  does not see the `tailscale0` interface and cannot `Listen` on the 100.x
  address. Binding is all-interfaces plus allow-list filtering. That is an honest
  limitation, not a configuration you have missed.
- Tinyproxy drops privileges to the unprivileged `tinyproxy` account after
  binding. The add-on needs no `privileged`, `NET_ADMIN`, host PID, host
  networking, or Docker socket access.

## Does this actually work over Tailscale?

**Yes, with a caveat you should verify on your own install.** The Tailscale
add-on advertises the Home Assistant *host's* tailnet address, and add-on ports
are published on the host's network stack — so `http://<ha-tailscale-ip>:8888`
normally reaches this add-on even though the two containers are separate.

If it does not work on your setup, the supported fallbacks, best first:

1. **Tailscale add-on `subnet routes` / accept-routes** — reach the HA host's LAN
   IP over the tailnet and point the proxy at `http://<ha-lan-ip>:8888`. Smallest
   change that works.
2. **A separate Raspberry Pi OS / VM / Docker host** running Tailscale and
   Tinyproxy in one network namespace. This is the recommended architecture if
   you want the proxy bound strictly to the tailnet interface, because there it
   genuinely can be.
3. `tailscale serve` TCP forwarding — only forwards to the node's own localhost
   and is TLS-terminating; **not** a fit for a plain HTTP proxy port. Listed so
   you know it was considered and rejected.

A combined Tailscale+Tinyproxy add-on is *technically* possible but means
maintaining a fork of the community Tailscale add-on and running with the
elevated privileges Tailscale needs. Not worth it for this scope.

## Verifying it works

Allowed client, through the proxy:

```bash
curl -x http://proxyuser:PASSWORD@<ha-tailscale-ip>:8888 https://ifconfig.me
```

Expected: your **home** public IP, not the client's.

| Test | Expected |
|---|---|
| HTTPS `CONNECT` on 443 | succeeds (`curl -x ... https://...`) |
| Plain HTTP | succeeds |
| Source IP outside `allow` | `403 Access denied` from Tinyproxy |
| Wrong/missing BasicAuth when configured | `407 Proxy Authentication Required` |
| One credential field set, other empty | add-on refuses to start; error in log |
| `grep` the add-on log for the password | no match |
| `https://host:8443` with default `connect_ports` | fails (by design) |

WebSocket upgrades over HTTP work to the extent Tinyproxy passes `CONNECT` and
`Upgrade` through; `wss://` works because it is tunnelled inside `CONNECT 443`.
No claim is made about arbitrary non-HTTP protocols.
