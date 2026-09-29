# Changelog

## [1.4.15] - 2026-09-29

### Fixed

- **Reverted the baked-in Playwright + Chrome (1.4.14, +1.5 GB); the browser now runs on the host.**
  `@playwright/mcp` inside the container failed with `Chromium distribution 'chrome' is
  not found` because the image has no browser, and baking Chrome in would add ~1.5 GB.
  The launcher now starts `@playwright/mcp` on the host (`localhost:8931`, `--isolated`
  so no host cookies/logins are exposed) and `claude-defaults/mcp.json` points the
  `playwright` entry at `http://localhost:8931/mcp` (reachable via `network_mode: host`).
  Browser lookup order: `google-chrome(-stable)` → `chromium` → Playwright's Chromium,
  downloaded once to `~/.cache/ms-playwright` (no sudo). Headed when a display exists,
  headless otherwise. Requires `node`/`npx` on the host; without it (or a browser) the
  launcher prints a hint and continues. Sessions ref-count the server; the last one out
  stops it. Opt out with `--no-playwright`.

### Changed

- **Existing users are migrated automatically.** `menu.sh` rewrites an untouched old
  `playwright` entry (`npx -y @playwright/mcp@latest`) in `~/.claude.json` to the new HTTP
  entry; customized entries are left alone.
- **The launcher refreshes the image once per launcher version.** After `apt upgrade` the
  first launch runs `docker compose pull` (non-fatal, skipped with `--build`) so the image
  carries the migration above. Marker: `~/claude-docker/.pulled-launcher-version`.
