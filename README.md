# Home Assistant add-on: Tinyproxy

A private HTTP/HTTPS **forward proxy** for Home Assistant OS (Raspberry Pi
aarch64/armv7, plus amd64). Point a Tailscale-connected laptop or phone at it and
selected apps egress via your home connection.

This is **not** a reverse proxy, **not** a Tailscale exit node, **not** a
transparent proxy, and **not** an open proxy.

## Install

Add this repository in Home Assistant:
Settings → Add-ons → Add-on Store → ⋮ → **Repositories** →
`https://github.com/rymain/hassio-addon-tinyproxy`

Or drop the `tinyproxy/` folder at `/addons/local_tinyproxy/` for a local add-on.

Full instructions, options, and security notes: **[tinyproxy/DOCS.md](tinyproxy/DOCS.md)**.

> **Do not forward TCP/8888 from the internet. Use Tailscale ACLs/grants and
> Tinyproxy's allow-list. Add BasicAuth as defense in depth.**

Origin: a modernized replacement for
[niryeffet/hassio_addon_local_tinyproxy](https://github.com/niryeffet/hassio_addon_local_tinyproxy).
MIT licensed.
