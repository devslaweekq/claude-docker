# Changelog

## [1.4.10] - 2026-07-17

### Fixed

- **`certs/` mount path was broken on installed (`.deb`/`install.sh`) setups.**
  During the monorepo restructuring, `docker-compose.yml`/`docker-compose.dev.yml`
  were updated to mount `./claude-docker/certs:/tmp/certs-input:ro` — correct only
  for a git-clone layout, where `certs/` moved into `claude-docker/certs/` alongside
  `docker-compose.yml`'s own new sibling files. On an installed setup, `certs/`
  stays flat in `~/claude-docker/certs/` (unchanged by the restructuring) while
  `docker-compose.yml` is also flat in `~/claude-docker/` — so the relative path
  resolved to the nonexistent `~/claude-docker/claude-docker/certs`. Docker creates
  a missing bind-mount source directory automatically (owned by root, since the
  daemon runs as root), which is what produced the phantom, root-owned, seemingly
  "stuck" `claude-docker/` folder nested inside `~/claude-docker/` — not a bug in
  `install.sh`/`postinst` themselves, and not caused by `PROJECT_DIRS`.
- Moved `certs/` back to the repo root (it was never part of the Docker build
  context — only a runtime volume mount — so it never needed to live inside
  `claude-docker/` in the first place). `docker-compose.yml`,
  `docker-compose.dev.yml`, and `scripts/install.sh` now reference `./certs` /
  `certs/README.md`, matching both the git-clone layout (certs sits next to
  `docker-compose.yml` at repo root) and the installed layout (certs sits next to
  `docker-compose.yml` in `~/claude-docker/`) with the same relative path.
- `claude-docker/launcher`: when a `PROJECT_DIRS` root happens to be the install
  directory itself, its reserved runtime subfolders (`home/`, `comfyui/`,
  `headroom/`, `certs/`) are no longer offered up as mountable "projects" —
  they hold container state and credentials, never user code.
