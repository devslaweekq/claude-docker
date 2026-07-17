# dashboard

[![Dashboard Publish](https://github.com/devslaweekq/claude-docker/actions/workflows/dashboard-publish.yml/badge.svg)](https://github.com/devslaweekq/claude-docker/actions/workflows/dashboard-publish.yml)

Read-only session monitoring for [claude-docker](https://github.com/devslaweekq/claude-docker) — a browser dashboard that shows your active Claude Code sessions, their resource usage, and lets you rename or delete sessions. No interactive terminal, no shell access — just a live view of what's running.

## Features

- 📊 **Live resource view** — CPU, memory, and disk usage for the host and every running session container, refreshed continuously.
- 🗂️ **Session management** — rename or delete sessions from the browser; everything else is read-only.
- 🔒 **Basic auth + loopback by default** — no session data leaves the machine unless you deliberately expose the port.
- 🧩 **Two-container split by design** — the part that talks to the browser never touches `docker.sock`; see [Architecture](#architecture).

## Quick start

Requires `.env` to already be set up for the main [claude-docker](../claude-docker/README.md) service (`CLAUDE_HOME` in particular — the dashboard shares that volume to read session data).

```bash
./claude-docker/launcher --dashboard
```

which starts both `dashboard` and `dashboard-watcher` via the root `docker-compose.yml`, ref-counted just like `--comfyui`/`--headroom` (removed again once the last session using `--dashboard` exits). The launcher refuses to start the dashboard if `DASHBOARD_PASSWORD` is not set in `.env`.

Open `http://localhost:7900`. Log in with Basic auth using `DASHBOARD_USERNAME` / `DASHBOARD_PASSWORD`.

### `.env` variables

| Variable             | Required | Default | Notes                                                           |
| -------------------- | -------- | ------- | --------------------------------------------------------------- |
| `DASHBOARD_PASSWORD` | Yes      | —       | Basic auth password. The container refuses to start without it. |
| `DASHBOARD_USERNAME` | No       | `admin` | Basic auth username.                                            |
| `DASHBOARD_PORT`     | No       | `7900`  | Plain HTTP port.                                                |

See [`PORTS.md`](../PORTS.md) for the full port reference across all services.

## Architecture

This feature ships as **two containers built from one image** (`slaweekq/claude-docker-dashboard`), started as two compose services with different `entrypoint:` values:

- **`dashboard`** — the browser-facing gateway. Serves the frontend, handles Basic auth, and reads the stats file the watcher writes. Runs as an unprivileged user and never mounts `docker.sock`.
- **`dashboard-watcher`** — a headless polling loop. It's the only piece that mounts `/var/run/docker.sock` (read-only), which it needs to list session containers and pull their CPU/memory stats. It writes one JSON snapshot to the shared `CLAUDE_HOME` volume on an interval and never listens on any port or talks to the network at all.

The split exists so that a compromise of the browser-facing container (the one thing actually reachable over the network) can't reach the Docker socket — the only container that holds that socket is deliberately unreachable by design. `docker-compose.yml` and `docker-compose.dev.yml` in the repo root define both services under the `dashboard` compose profile.

## Security notes

- Basic auth is required — the gateway refuses to start without `DASHBOARD_PASSWORD` set.
- Binds to `127.0.0.1` by default (loopback-only); there is no built-in public tunnel.
- `dashboard-watcher` never listens on any port — it cannot be reached over the network under any configuration, by design.
- All actions other than rename/delete are read-only; there is no shell, terminal, or command execution surface exposed to the browser.
