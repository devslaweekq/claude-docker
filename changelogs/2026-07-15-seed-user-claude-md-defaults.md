# Changelog

## [1.4.2] - 2026-07-15

### Added

### User-level `CLAUDE.md` seeding (`claude-defaults/CLAUDE.md`)
`menu.sh` now seeds `~/.claude/CLAUDE.md` from `claude-defaults/CLAUDE.md` on first session
start — same non-clobbering pattern as `settings.json` (only copied if the user doesn't
already have one, never overwrites edits). This is where standing behavioral rules that
should apply across every project live, as opposed to `settings.json` (permissions/config)
or `commands/` (slash commands).

First rule shipped this way: when generating an image via the `comfyui` MCP for
preview/validation (banner, logo, icon — anything not locked in yet), draft 3-5 low-res
variants first, then re-render only the chosen one at full quality. Avoids burning
full-quality renders on directions that get discarded.

Second rule: always give commit text (single line, under 100 chars, no bulleted body) at
the end of any turn that leaves uncommitted changes, without waiting to be asked.
