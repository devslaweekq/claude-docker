# Changelog

## [1.3.8] - 2026-06-25

### Fixed

- **Multi-session service lifecycle** — when multiple sessions are launched with `--headroom` or `--comfyui`,
  exiting one session no longer stops the service for the others. Each session now registers a PID file under
  `/tmp/claude-svc-sessions/<service>/`; on exit it unregisters itself and only stops the Docker service if
  no other live sessions are still holding the lock. Stale PID files from crashed sessions are auto-cleaned.
