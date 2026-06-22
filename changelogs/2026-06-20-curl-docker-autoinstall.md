# Changelog

## [1.0.1] - 2026-06-20

### Added

### `scripts/install.sh` — auto-install curl and Docker when missing
- **Linux** — `curl` via `apt-get`; `docker` via the official `get.docker.com`
  script, daemon enabled with `systemctl`, user added to the `docker` group.
- **macOS** — exits with a human-readable hint for each missing tool.
- **Other OS** — exits with an error.
