# Changelog

## [1.4.17] - 2026-10-28

### Added

#### Outline MCP server in default MCP config

Added `outline` entry to `claude-defaults/mcp.json` so Claude Code inside the container can read and
edit documents in an Outline knowledge base out of the box.

Uses Outline's built-in remote MCP endpoint (`<OUTLINE_URL>/mcp`) over HTTP, authorised with an API
token via the `Authorization` header. Both values come from `.env`:

```json
"outline": {
  "type": "http",
  "url": "${OUTLINE_URL:-}/mcp",
  "headers": {
    "Authorization": "Bearer ${OUTLINE_API_TOKEN:-}"
  }
}
```

Set `OUTLINE_URL` (base address, no trailing slash and no `/mcp`) and `OUTLINE_API_TOKEN`
(Outline → Preferences → API) in `.env` to activate. The endpoint must be enabled on the Outline
instance; without the variables the server simply fails to connect and other MCP servers are
unaffected.

#### `.env.example`

Documented `OUTLINE_URL` and `OUTLINE_API_TOKEN`.
