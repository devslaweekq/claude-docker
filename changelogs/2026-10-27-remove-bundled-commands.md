# Changelog

## [1.4.16] - 2026-10-27

### Added

- **`best-skills` and `pymobiledevice3` plugins enabled by default** (`claude-defaults/settings.json`).
  New marketplaces `devslaweekq-skills` (`devslaweekq/best-skills`) and `pymobiledevice3`
  (`doronz88/pymobiledevice3`), with `devslaweekq@devslaweekq-skills` and
  `pymobiledevice3-device-operator@pymobiledevice3` turned on in `enabledPlugins`.
- **New default settings:** `"editorMode": "normal"`, `"model": "sonnet"`, `"timeFormat": "24-hour"`.
- **"Native Ubuntu, NOT WSL" rule** in the seeded user-level `claude-defaults/CLAUDE.md`:
  `/mnt/...` paths are a second disk, so Claude must not assume WSL or suggest WSL-specific
  explanations.

### Changed

- **Seeded user-level `CLAUDE.md` reflowed** to ~140-column lines (wording unchanged).
- **ComfyUI base image** bumped `nvidia/cuda:13.3.0-base-ubuntu24.04` → `13.4.3-base-ubuntu24.04`.
- **Dev dependencies updated:** `prettier` `^3.9.5` → `^3.9.10`,
  `prettier-plugin-packagejson` `^3.0.2` → `^3.0.3`.

### Removed

- **Bundled `/parallel` and `/loki-report` slash commands** (`claude-defaults/commands/`).
  Both now ship as skills in the `devslaweekq` plugin above, so the seeded copies in
  `~/.claude/commands/` were duplicates. `menu.sh` already skips the seeding step when the
  `commands` directory is absent; commands already copied into an existing `~/.claude/commands/`
  are left untouched.
