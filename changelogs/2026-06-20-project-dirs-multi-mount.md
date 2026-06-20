# Multi-directory workspace support (PROJECT_DIRS)

Replace `PROJECT_DIR` (single path) with `PROJECT_DIRS` (comma-separated list of parent directories).
Each entry is a projects root — its immediate subdirectories are mounted into the container as `/workspace/<name>`.

## Changes

- `launcher`: parse `PROJECT_DIRS`, scan immediate subdirs of each root, build dynamic `-v` flags,
  detect which project the caller cwd belongs to (otherwise the full menu, with the cwd bind-mounted as scratch)
- `docker-compose.yml`, `docker-compose.dev.yml`: remove static `${PROJECT_DIR}:/workspace`
  volume — mounts are now passed at runtime by the launcher
- `.env.example`, `README.md`, `INSTALL.md`, `scripts/install.sh`, `scripts/deb/postinst`:
  update docs to reference `PROJECT_DIRS`

## Migration

The semantics changed: `PROJECT_DIR` was mounted **as** `/workspace`, while each `PROJECT_DIRS`
entry is now a **parent** whose immediate subdirectories are each mounted as `/workspace/<name>`.
Point `PROJECT_DIRS` at the folder that *contains* your projects, not at a single project.

In `.env`, replace:
```
PROJECT_DIR=/home/user/work/my-app
```
with the parent that holds your projects:
```
PROJECT_DIRS=/home/user/work
```
Or list multiple parents:
```
PROJECT_DIRS=/home/user/work,/home/user/personal
```

Each project subdir (e.g. `work/my-app`) is then accessible in the container at `/workspace/my-app`.

## Behavior

- Caller cwd **inside a project** (subdir of a `PROJECT_DIRS` root) → session picker for that project
- Caller cwd **at a `PROJECT_DIRS` root** → full menu showing all projects
- Caller cwd **outside all `PROJECT_DIRS`** (or `PROJECT_DIRS` unset) → full menu, with the cwd bind-mounted so the scratch option opens it
