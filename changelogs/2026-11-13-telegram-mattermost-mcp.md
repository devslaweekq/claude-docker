# Changelog

## [1.4.20] - 2026-11-13

### Added

#### Telegram MCP server

- New `telegram` entry in `claude-defaults/mcp.json`, running
  [`@chaindead/telegram-mcp`](https://github.com/chaindead/telegram-mcp) via `npx`.
- Reads `TG_APP_ID` and `TG_API_HASH` (get them at <https://my.telegram.org/apps>); both are added to
  `.env.example`.
- The server acts as your personal Telegram account and needs a one-time login with a code from Telegram.

### Changed

#### Documentation

- `claude-docker/README.md`: the MCP server table and the configuration reference now list every server
  from `mcp.json` (added Grafana, Outline, Telegram, Yandex Cloud) with their environment
  variables, plus short setup notes for Telegram.

### Internal

- `.prettierrc`: `https` schema URL, Markdown excluded from the formatting overrides, and
  `prettier-plugin-sort-json` limited to `*.json` files other than `tsconfig*.json`.
