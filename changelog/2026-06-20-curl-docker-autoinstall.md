# 2026-06-20 — Auto-install curl and Docker in install.sh

## Added
- `scripts/install.sh` checks for `curl` and `docker` at startup and installs
  them automatically when missing:
  - **Linux** — `curl` via `apt-get`; `docker` via the official `get.docker.com`
    script, daemon enabled with `systemctl`, user added to the `docker` group.
  - **macOS** — exits with a human-readable hint for each missing tool.
  - **Other OS** — exits with an error.
