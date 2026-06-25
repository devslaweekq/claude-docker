# Changelog

## [1.3.6] - 2026-06-25

### Fixed

### Plugin marketplace clone fails on SSH host key (GitHub)
Claude Code clones marketplaces via `git@github.com`, but the container has no
SSH keys and no `known_hosts` entry. `menu.sh` now sets
`git config url.https://github.com/.insteadOf git@github.com:` at startup so
public repos clone over HTTPS.

### `claude-defaults/settings.json` — HTTPS marketplace URLs
`claude-plugins-official` and `thedotmack` marketplaces use explicit HTTPS git
URLs instead of `source: github` (which prefers SSH).
