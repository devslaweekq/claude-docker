# Changelog

## [1.3.0] - 2026-06-23

### Added

#### Grafana MCP server in default MCP config

Added `grafana` entry to `claude-defaults/mcp.json` so Claude Code inside the
container can query Grafana dashboards, datasources, and alerts out of the box.

Uses the official `mcp-grafana` package from Grafana Labs via `uvx` with
environment variable placeholders for flexible auth — either service account
token or username/password:

```json
"grafana": {
  "args": [ "--disable-write", "mcp-grafana"],
  "command": "uvx",
  "env": {
    "GRAFANA_SERVICE_ACCOUNT_TOKEN": "${GRAFANA_SERVICE_ACCOUNT_TOKEN:-}",
    "GRAFANA_URL": "${GRAFANA_URL:-}",
  },
  "type": "stdio"
}
```

Set `GRAFANA_URL` and either `GRAFANA_SERVICE_ACCOUNT_TOKEN` in `.env` to activate.

#### `uv` / `uvx` in Docker image

Added `uv` binary via `COPY --from=ghcr.io/astral-sh/uv:latest` (same pattern
as Bun) — ~30 MB, no Python installation required. Enables `uvx`-based MCP
servers like Grafana out of the box.
