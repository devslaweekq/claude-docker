# 2026-06-20 — Bundled `/parallel` slash command

## Added
- `claude-defaults/commands/parallel.md` — a slash command that fans a task out
  to independent parallel agents (uses the `dispatching-parallel-agents` skill,
  caps at 6 concurrent agents). Shipped inside the Docker image via the existing
  `COPY claude-defaults/ /opt/claude-defaults/` step.
- `scripts/menu.sh` seeds shipped commands into `~/.claude/commands/` on startup
  with `cp -n` (copy-if-absent) — new defaults appear for every user, existing
  user edits are never clobbered.

## Notes
- Reaches all install paths automatically: clone, `install.sh`, and the `.deb`
  package all pull the prebuilt image, which now carries the command.
- `docker-publish.yml` already triggers on `claude-defaults/**` and
  `scripts/menu.sh`, so merging to `main` rebuilds and republishes the image.
