# Changelog

## [1.0.3] - 2026-06-20

### Added

### `claude-defaults/commands/parallel.md` — bundled `/parallel` slash command
Fans a task out to independent parallel agents (uses the
`dispatching-parallel-agents` skill, caps at 6 concurrent agents). Shipped
inside the Docker image via the existing `COPY claude-defaults/ /opt/claude-defaults/`
step.

### `scripts/menu.sh` — seeds default commands on startup
New default commands are copied into `~/.claude/commands/` with `cp -n`
(copy-if-absent) on every container start — existing user edits are never
clobbered.
