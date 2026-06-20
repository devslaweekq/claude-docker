# 2026-06-20 — Auto-install curl and Docker in install.sh

## Added
- `scripts/install.sh` now checks for `curl` and `docker` at startup and
  installs them automatically if missing:
  - **Linux** — `curl` is installed via `apt-get`; `docker` is installed via
    the official `get.docker.com` script, the daemon is enabled with
    `systemctl`, and the current user is added to the `docker` group.
  - **macOS** — exits with a human-readable hint if either tool is absent.
  - **Other OS** — exits with an error.
