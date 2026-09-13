# Changelog

## 3.0.0

Rebuilt on a plain Alpine base. 2.x installed but **failed to start**; this
release removes the machinery that failure depended on.

### Changed

- **Base image is now `alpine:3.21`**, not the Home Assistant base image.
  Image size drops from roughly 80 MB to **~4 MB**; runtime RSS is under 2 MB.
  This matters on a 1 GB Raspberry Pi.
- **No bashio.** Options are read straight from `/data/options.json` with `jq`.
  2.x used `bashio::config`, which queries the Supervisor API over HTTP at
  startup — a dependency that can fail before the proxy ever binds.
- **No s6-overlay.** A single `/run.sh` entrypoint execs Tinyproxy as PID 1,
  instead of an s6-rc service directory (`type`, `run`, `finish`,
  `user/contents.d/`). Restarts are handled by the Supervisor's container
  restart policy.
- **Prebuilt images.** `config.yaml` declares
  `image: ghcr.io/rymain/{arch}-addon-tinyproxy`, so the Pi pulls rather than
  builds. GitHub Actions publishes aarch64, armv7 and amd64 on every push to
  `main`. Local `/addons` installs still build from the Dockerfile.
- Generated config moved to `/tmp/tinyproxy.conf`, so `/data` may be read-only.
- `MaxClients` lowered from 100 to 50, sized for small hardware.

### Unchanged

Options, schema, defaults and every security guard are identical to 2.0.0:
default `allow` of `100.64.0.0/10`, `ConnectPort 443`/`563`, rejection of
`0.0.0.0/0` and `::/0` and of empty allow lists, startup failure when only one
BasicAuth credential is set, credentials never logged, unprivileged `tinyproxy`
user, no privileged/NET_ADMIN/host-PID/host-networking.

## 2.0.0

Rewrite of `niryeffet/hassio_addon_local_tinyproxy` (last touched 2024-05).
Installed on current Home Assistant OS but failed to start — superseded by 3.0.0.

### Breaking

- Default listen port 8888 (was 3128, and was never published).
- Default `allow` is `100.64.0.0/10` only; the hard-coded `192.168.0.0/16`,
  `10.0.0.0/8` and localhost rules are gone.
- `host_network: true` replaced with an explicit `ports:` declaration.

### Added

- Full `options` + `schema`; config generated at runtime, nothing baked in.
- BasicAuth, `ConnectPort` restriction, allow-list validation.
- `repository.yaml`, `build.yaml`, docs, changelog, MIT license, CI.

### Fixed

- s6-overlay v3 service layout instead of the v2 `/etc/services.d/` layout.
- `startup: services`, `boot: auto`. Dropped `armhf` and `i386`.
- Runs as the unprivileged `tinyproxy` user.
