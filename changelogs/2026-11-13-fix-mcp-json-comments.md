# Changelog

## [1.4.21] - 2026-11-13

### Fixed

#### MCP selection screen not showing

- `claude-defaults/mcp.json` contained `//` comments (the disabled `headers` block of `mattermost`).
  `menu.sh` reads the file with `jq`, which rejects comments, so the list of servers came out empty and the
  first-start MCP selection screen was silently skipped (the Playwright entry migration failed the same way).
- The commented block is now a top-level `_mattermost_headers_example` key, so `mcp.json` is valid JSON again.
  It sits outside `mcpServers`, so it never reaches the Claude Code config.
- To authenticate Mattermost with a personal access token, copy that `headers` block into the `mattermost`
  entry and set `MATTERMOST_TOKEN`. The README is updated accordingly.
- To see the selection screen again on an existing install, rebuild or re-pull the image and delete
  `~/.claude-docker-mcp-configured`.
