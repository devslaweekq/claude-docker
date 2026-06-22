# Changelog

## [1.0.3] - 2026-06-20

### Changed

### `PROJECT_DIR` → `PROJECT_DIRS` — multi-directory workspace support
`PROJECT_DIR` (single path) replaced with `PROJECT_DIRS` (comma-separated list
of parent directories). Each entry is a projects root — its immediate
subdirectories are mounted into the container as `/workspace/<name>`.

**`launcher`** — parses `PROJECT_DIRS`, scans immediate subdirs of each root,
builds dynamic `-v` flags, detects which project the caller cwd belongs to
(otherwise shows the full menu, with the cwd bind-mounted as scratch).

**`docker-compose.yml`, `docker-compose.dev.yml`** — static
`${PROJECT_DIR}:/workspace` volume removed; mounts are now passed at runtime by
the launcher.

**`.env.example`, `README.md`, `INSTALL.md`, `scripts/install.sh`,
`scripts/deb/postinst`** — updated to reference `PROJECT_DIRS`.

**Caller cwd behaviour:**
- Inside a project (subdir of a `PROJECT_DIRS` root) → session picker for that project
- At a `PROJECT_DIRS` root → full menu showing all projects
- Outside all `PROJECT_DIRS` (or `PROJECT_DIRS` unset) → full menu, cwd bind-mounted as scratch

**Migration** — in `.env`, replace:
```
PROJECT_DIR=/home/user/work/my-app
```
with the parent that holds your projects:
```
PROJECT_DIRS=/home/user/work
```
Each project subdir (e.g. `work/my-app`) is then accessible at `/workspace/my-app`.
