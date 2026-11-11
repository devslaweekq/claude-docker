# Changelog

## [1.4.19] - 2026-11-11

### Fixed

#### Host Playwright MCP failing on Ubuntu 23.10+

- On hosts where AppArmor restricts unprivileged user namespaces
  (`kernel.apparmor_restrict_unprivileged_userns=1`, the default since Ubuntu 23.10), the Chromium
  downloaded by Playwright (or a system Chromium) crashed on start with `No usable sandbox!`, so the
  `playwright` MCP server never came up.
- The launcher now checks that sysctl and, when a browser is started via `--executable-path`, passes
  `--no-sandbox` to `@playwright/mcp`. Google Chrome (`--browser chrome`) is unaffected: it ships its
  own AppArmor profile and keeps its sandbox.
- Works on a clean install with no manual AppArmor or `sysctl` changes.

### Internal

- Added a root `AGENTS.md` that points agents to `.claude/CLAUDE.md` and repeats the per-commit release
  checklist (git state check, one version bump per commit batch, changelog, no commit/push).
