# Changelog

## [1.4.18] - 2026-11-11

### Changed

#### Plugin defaults in `claude-defaults/settings.json`

- Enabled the `figma@claude-plugins-official` plugin by default (was `false`).
- Enabled the built-in `cc-plugin-you-should-know@builtin` plugin.
- Turned on `autoUpdate` for the `devslaweekq/best-skills`, `pymobiledevice3` and `thedotmack`
  marketplaces so their plugins stay current without manual updates.

### Added

#### Settings

- `pluginConfigs` for `cc-plugin-agents-md@builtin` with `instructionFiles` set to
  `claude-md-or-agents-md`, so both `CLAUDE.md` and `AGENTS.md` are picked up as instruction files.
- `switchModelsOnFlag: false` — do not switch models automatically when a model flag is hit.

### Internal

- `claude-defaults/mcp.json`: the `outline` server keys were re-sorted alphabetically
  (`headers`, `type`, `url`). No functional change.
