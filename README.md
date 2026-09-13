# Home Assistant add-on: Tinyproxy

A private HTTP/HTTPS **forward proxy** for Home Assistant OS. Point a
Tailscale-connected laptop or phone at it and selected apps egress via your home
connection.

**~4 MB image, under 2 MB RAM.** Fine on a 1 GB Raspberry Pi. Prebuilt for
aarch64, armv7 and amd64 — the Pi pulls an image instead of compiling one.

This is **not** a reverse proxy, **not** a Tailscale exit node, **not** a
transparent proxy, and **not** an open proxy.

## Install

Settings -> Add-ons -> Add-on Store -> three-dot menu -> **Repositories** ->
`https://github.com/rymain/hassio-addon-tinyproxy`

Then install **Tinyproxy**, set `allow` and a BasicAuth password, and start it.

Full options, security notes and troubleshooting:
**[tinyproxy/DOCS.md](tinyproxy/DOCS.md)**.

> **Do not forward TCP/8888 from the internet. Use Tailscale ACLs/grants and
> Tinyproxy's allow-list. Add BasicAuth as defense in depth.**

Originally a modernization of
[niryeffet/hassio_addon_local_tinyproxy](https://github.com/niryeffet/hassio_addon_local_tinyproxy).
MIT licensed.
