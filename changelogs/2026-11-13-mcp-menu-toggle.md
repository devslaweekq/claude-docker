# Changelog

## [1.4.22] - 2026-11-13

### Changed

#### "Configure MCP servers" now switches servers on and off

- The menu entry lists every server from the shipped `mcp.json` with its current state: `●` connected (present
  in `~/.claude.json`), `○` off. Previously it showed a plain list and always re-added the whole selection, so
  adding one new server meant picking all the others again.
- Servers marked in the list (Tab, or Enter on the highlighted row) are switched to the opposite state:
  connected ones are removed from `~/.claude.json`, the others are added from the shipped `mcp.json`. Servers
  that are not in the shipped list (added by hand) are never touched, and untouched entries keep any local edits.
- The numeric fallback (no `fzf`) shows `[x]` / `[ ]` and takes the numbers to switch, or `A` to connect all.
- `~/.claude-docker-mcp-managed` is no longer used (the state is read from `~/.claude.json` instead); an existing
  file is simply ignored.

### Removed

#### Telegram MCP server

- The `telegram` entry (`@chaindead/telegram-mcp`) is removed from `claude-defaults/mcp.json`, together with its
  `TG_APP_ID` / `TG_API_HASH` block in `.env.example` and the README mentions. It cannot connect from networks
  where Telegram is blocked: the server has no MTProxy support and only honours a SOCKS5 `ALL_PROXY`.
- An already connected `telegram` entry stays in `~/.claude.json`; remove it with
  `claude mcp remove telegram -s user`.
