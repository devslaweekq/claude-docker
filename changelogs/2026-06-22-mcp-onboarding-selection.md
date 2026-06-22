# 2026-06-22 — MCP server selection onboarding

## Added

### `scripts/menu.sh` — interactive MCP server selection

Instead of blindly merging all MCP servers from `claude-defaults/mcp.json` into
`~/.claude.json` on every start, the menu now asks the user once which servers
to enable.

**First-run onboarding** (triggered when `~/.claude-docker-mcp-configured` does
not exist):

- Displays a dedicated "MCP Server Setup" screen before the session picker.
- **fzf** (default): multi-select list — Tab to toggle, Ctrl+A for all, Enter to
  confirm, Esc to skip.
- **Numeric fallback** (no fzf): numbered list, space-separated input or `A` for
  all, Enter to skip.
- Only the selected servers are written to `~/.claude.json`.

**Reconfigure at any time** via the new "⚙  Configure MCP servers" entry in the
main menu (both fzf and numeric variants). Re-running the selection first removes
the previously managed servers, then applies the new choice — user-added servers
are never touched.

**State files:**

| File                              | Purpose                                                       |
| --------------------------------- | ------------------------------------------------------------- |
| `~/.claude-docker-mcp-configured` | Flag: onboarding completed (existence check)                  |
| `~/.claude-docker-mcp-managed`    | JSON array of server names currently managed by claude-docker |
