# Changelog

## [1.4.0] - 2026-07-14

### Added

### `scripts/builds/menu.sh`, `scripts/builds/sessions.js` — session cleanup

The per-folder session picker (shown either when launching `claude` directly
inside a project directory, or after picking a workspace from the main menu)
now lets you delete old saved sessions instead of only resuming them.

- New **"🧹 Clean up old sessions…"** entry at the bottom of the session list
  (only shown when the folder has at least one saved session).
- Selecting it opens an **fzf multi-select** picker over that folder's
  sessions only — same interaction as the existing MCP server picker: `Tab`
  to mark, `Ctrl+A` for all, `Enter` to confirm, `Esc` to cancel. The live
  preview pane still shows each session's conversation before you decide.
- Since deletion is irreversible, confirming the selection asks
  `Delete N session(s)? [y/N]` before anything is removed.
- After cleanup, the session list refreshes in place instead of exiting.
- `sessions.js` gained a `--delete <cwd> <id...>` mode that removes the
  matching `.jsonl` files, reusing the existing path-traversal-safe
  `sessionFile()` lookup.

Scope: only sessions belonging to the folder currently open in the picker are
ever affected — there is no "clean up everything" action.
