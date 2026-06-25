# Changelog

## [1.3.5] - 2026-06-25

### Added

### Headroom proxy service (`ghcr.io/chopratejas/headroom:latest`)
Optional [Headroom](https://github.com/headroomlabs-ai/headroom) context-compression proxy
added to `docker-compose.yml` and `docker-compose.dev.yml` under the `headroom` profile.
Listens on `localhost:8787`; state persists in `~/claude-docker/headroom/.headroom/`.

### `launcher --headroom` flag
Starts Headroom before the Claude session and stops it on exit (same lifecycle as
`--comfyui`). Skips start if `/readyz` already responds. Flags can be combined
(`./launcher --headroom --comfyui`).

### Install layout — `headroom/.headroom`
`scripts/install.sh` and `scripts/deb/postinst` now create the Headroom data directory
on install.

### `PORTS.md` — service port reference
Documents which optional services listen on which host ports (`8188` ComfyUI,
`8787` Headroom) and why compose uses `network_mode: host` instead of `ports:`.

### `claude-mem` plugin — settings
Restored `claude-mem@thedotmack` in `claude-defaults/settings.json` with the
`thedotmack` marketplace (`github.com/thedotmack/claude-mem`). Worker web UI: `http://localhost:37777`.
