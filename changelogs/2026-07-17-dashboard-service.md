# Changelog

## [1.5.3] - 2026-07-17

### Added

- New `dashboard/` service: a read-only, browser-based view of Claude Code sessions. Shows live CPU/memory/disk for the host and every running session container, git branch/dirty status, token usage, and a transcript preview per session; supports renaming and deleting sessions and full-text search across transcripts.
- Split into two containers built from one shared image (`slaweekq/claude-docker-dashboard`): the browser-facing `dashboard` service (Basic auth, loopback by default, no `docker.sock` access) and a headless `dashboard-watcher` collector (the only piece that mounts `docker.sock`, read-only, and never listens on any port). This keeps the only network-reachable container away from the Docker socket.
- `./claude-docker/launcher --dashboard` starts both services together, ref-counted the same way as `--comfyui`/`--headroom`, and stops them when the last session using the flag exits.
- Session containers are now labeled with `claude-docker.project=<name>` so the dashboard can correlate a transcript back to its live container without any session-side registration step.
- `dashboard-publish.yml` CI workflow builds/pushes the dashboard image and syncs its Docker Hub description from `dashboard/README.md`, mirroring the existing `comfyui-publish.yml` pattern.
- New `DASHBOARD_PASSWORD` (required), `DASHBOARD_USERNAME`, and `DASHBOARD_PORT` variables in `.env.example`.
