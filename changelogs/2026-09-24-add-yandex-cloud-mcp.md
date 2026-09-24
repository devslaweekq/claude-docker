# Changelog

## [1.4.13] - 2026-09-24

### Added

#### Yandex Cloud MCP server in default MCP config

Added `yandex-cloud` entry to `claude-defaults/mcp.json` so Claude Code inside
the container can inspect Yandex Cloud resources (compute, storage,
monitoring, etc.) out of the box.

Uses the official `@yandex-cloud/mcp` stdio client via `npx`, pinned to the
`toolkit` remote server:

```json
"yandex-cloud": {
  "args": ["-y", "@yandex-cloud/mcp", "-s", "toolkit"],
  "command": "npx",
  "type": "stdio"
}
```

No `.env` vars required — first use opens a browser for OAuth login (no
Yandex Cloud CLI install needed). Users who want CLI-profile auth instead can
override the args with `-p <profile>` themselves.
