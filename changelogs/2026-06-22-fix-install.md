# Changelog

## [1.2.4] - 2026-06-22

### Fixed

### `launcher --install` no longer asks to choose a name on re-install
`launcher --install` now scans `~/.local/bin/` before running the native-claude
detection. If any symlink there already resolves to `$LAUNCHER` (i.e. it is our
own symlink from a previous install), it refreshes the symlink silently and exits —
no "claude is already installed, choose a different name" prompt is shown.

Affected flows: `install.sh` re-run and `.deb` package upgrade.

### `postinst` — `sudo -H -u` instead of `sudo -u`
The `.deb` post-install hook invoked `launcher --install` via
`sudo -u "$REAL_USER"` without `-H`. This left `$HOME=/root` inside the
launcher process, so the symlink scan looked in `/root/.local/bin/` instead of
`/home/$REAL_USER/.local/bin/`, never found the existing symlink, and fell
through to the prompt. Fixed by adding `-H` so sudo sets `HOME` to the
target user's home directory.

### UTF-8 locale — Russian text no longer garbled on copy from terminal
The container now runs with `LANG=C.UTF-8` / `LC_ALL=C.UTF-8`. Without these
the `node:slim` base image defaults to the `C` (ASCII) locale, causing multi-byte
UTF-8 characters to be mishandled through the Docker PTY and arrive garbled in
the clipboard. Set in both `docker-compose.yml` (takes effect immediately, no
image rebuild) and `Dockerfile` (baked into future published images).
