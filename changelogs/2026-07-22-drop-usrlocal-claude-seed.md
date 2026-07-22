# Changelog

## [1.4.11] - 2026-07-22

### Fixed

- **Dropped the redundant `@anthropic-ai/claude-code` install from the image build.**
  `Dockerfile` baked a root-owned copy into `/usr/local` at build time, commented as
  an "image seed" fallback for the real, volume-backed copy that
  `ensure-claude-cli.sh` installs into `~/.npm-global` at container start. That
  fallback never engages: `docker-compose.yml` bind-mounts the entire `/home/node`
  from `${CLAUDE_HOME}`, so nothing baked under `/home/node` at build time survives
  container start anyway, and `~/.npm-global/bin` is always first in `PATH`. Worse,
  `menu.sh` sources `ensure-claude-cli.sh` under `set -euo pipefail` before ever
  calling `claude` — if that install fails (e.g. no network on a brand-new
  `${CLAUDE_HOME}`), the entrypoint aborts before `claude` would run from anywhere,
  seeded copy or not. The `/usr/local` copy was never read in any real path, just
  extra image weight and a stale version number that drifted from the running one.
  `Dockerfile` now installs only `jimp` at build time; `claude` continues to come
  solely from `ensure-claude-cli.sh` at runtime, as it already did in practice.
