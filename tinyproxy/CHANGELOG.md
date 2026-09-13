# Changelog

## 2.0.0

Rewrite of the original `niryeffet/hassio_addon_local_tinyproxy` (last touched
2024-05), which no longer installed cleanly on current Home Assistant OS.

### Breaking

- Default listen port is **8888** (was 3128, and was never published).
- Default `allow` is **`100.64.0.0/10`** only. The old hard-coded
  `192.168.0.0/16` + `10.0.0.0/8` + localhost rules are gone.
- `host_network: true` replaced with an explicit `ports:` declaration.

### Added

- Full add-on `options` + `schema`: `port`, `allow`, `basic_auth_username`,
  `basic_auth_password`, `connect_ports`, `timeout`, `log_level`.
- Config is generated at runtime; no editing files inside the image.
- `BasicAuth` support, with a hard startup failure if only one of the two
  credential fields is set.
- `ConnectPort 443` / `563` by default, configurable.
- Startup rejection of `0.0.0.0/0` and `::/0` in the allow list.
- `repository.yaml` so the add-on can be installed from a GitHub URL.
- `build.yaml` pinning the official Home Assistant Alpine 3.21 base images.
- `DOCS.md`, `CHANGELOG.md`, MIT `LICENSE`, CI (yamllint, shellcheck, arm64 build).

### Fixed

- s6-overlay **v3** service layout (`/etc/s6-overlay/s6-rc.d/`) instead of the v2
  `/etc/services.d/` layout.
- `startup: services`, `boot: auto` so the proxy comes back after an HA restart.
- Dropped `armhf` and `i386` from `arch`.
- Runs as the unprivileged `tinyproxy` user; no privileged/NET_ADMIN/host-PID.
