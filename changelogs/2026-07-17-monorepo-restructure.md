# Changelog

## [1.4.9] - 2026-07-17

### Changed

- Restructured the repo into a per-service monorepo layout, mirroring the
  existing `comfyui/` folder pattern. Everything specific to the main Claude
  session service now lives under `claude-docker/`: `Dockerfile`,
  `.dockerignore`, `launcher`, `launcher.bat`, `claude-defaults/`, `certs/`,
  `scripts/builds/` (menu.sh, sessions.js, update-certs.sh,
  ensure-claude-cli.sh), and the detailed service `README.md`.
- Cross-service tooling stays at the true repo root, since it already
  operates across every service in the monorepo: `scripts/docker/`
  (build/push), `scripts/utils/` (version bump), `scripts/deb/` (`.deb`
  packaging), `scripts/install.sh`, `docker-compose.yml`,
  `docker-compose.dev.yml`, `.env`/`.env.example`.
- Root `README.md` is now a short overview linking to each service's own
  README (`claude-docker/README.md`, `comfyui/README.md`); `INSTALL.md`,
  `PORTS.md`, and `CONTRIBUTING.md` stay at root as project-wide docs.
- `claude-docker/launcher` now auto-detects whether it's running from the
  flat installed layout (`~/claude-docker/launcher` next to
  `~/claude-docker/docker-compose.yml`) or a git-clone dev layout
  (`docker-compose.yml` one directory above `claude-docker/launcher`), so
  both continue to work without configuration.
- `comfyui/` is untouched by this restructuring.

### Breaking

- The entry point for git-clone users moves from `./launcher` to
  `./claude-docker/launcher`. No backward-compat shim is provided at the old
  path. The installed layout (curl installer / `.deb`, `~/claude-docker/`)
  is unaffected — it stays exactly as flat as before.
