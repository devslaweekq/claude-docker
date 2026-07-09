# Changelog

## [1.2.13] - 2026-06-23

### Fixed

#### Cyrillic (non-ASCII) text paste from container still garbled after v1.2.12

Text displayed correctly inside the cladock session but pasted as garbage
(mojibake such as `ÑÐµÐ¿ÐµÑÑ` instead of the original Cyrillic text) when
using VS Code integrated terminal.

Root cause: Claude Code selects its clipboard mechanism at startup based on
platform. Inside Docker it detects `linux`, finds no Wayland/X11 tools, and
falls back to **OSC 52**. VS Code's xterm.js decodes OSC 52 base64 payload as
Latin-1 bytes instead of UTF-8, corrupting multi-byte Cyrillic sequences in
the clipboard even though the terminal display was correct.

Fix: forward the compositor socket into the container so Claude Code can use
a native clipboard tool instead of OSC 52:
- **Wayland** (preferred): mount `$WAYLAND_DISPLAY` socket + pass
  `XDG_RUNTIME_DIR`; Claude Code uses `wl-copy`
- **X11 fallback**: mount `/tmp/.X11-unix` + `XAUTHORITY` cookie file;
  Claude Code uses `xclip`

Both tools write directly to the compositor clipboard which WSLg syncs to
Windows, bypassing the broken OSC 52 path entirely.

#### `.bashrc` UTF-8 sequence written as raw bytes instead of shell command

`Dockerfile` appended literal ESC bytes to `.bashrc` via `printf '\033%%G'`,
which bash silently ignores when sourcing the file. Changed to
`echo "printf '\\033%%G'"` so bash actually executes the sequence at
interactive session start.

### Added

#### `xclip` and `wl-clipboard` in Docker image

Installed so Claude Code's clipboard tool detection succeeds once `DISPLAY`
or `WAYLAND_DISPLAY` is forwarded from the host.

#### `scripts/utils/bump-version.sh`

Single command to bump the version across all files (`package.json`,
`package-lock.json`, `launcher`) and create a changelog template:

```bash
bash scripts/utils/bump-version.sh 1.2.14 my-feature-slug
```
