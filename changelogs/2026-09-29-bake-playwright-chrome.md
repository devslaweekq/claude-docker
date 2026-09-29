# Changelog

## [1.4.14] - 2026-09-29

### Added

- **Playwright and Google Chrome are now baked into the image.** `@playwright/mcp`
  previously failed with `Chromium distribution 'chrome' is not found at
/opt/google/chrome/chrome` because no browser was installed. The `Dockerfile` now
  installs `playwright` globally and runs `playwright install --with-deps chrome`
  (amd64). Google publishes no Linux arm64 Chrome, so arm64 builds install
  Chromium instead. System libraries come from `--with-deps`; apt lists are cleaned
  in the same `RUN`. `PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright` keeps browser
  files outside the bind-mounted `/home/node`.

### Changed

- **Playwright MCP entry in `claude-defaults/mcp.json` now runs with `--headless
--no-sandbox`.** The container has no display and Chrome's sandbox cannot start
  in an unprivileged container. Image size grows by roughly 400-500 MB.
