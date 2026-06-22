# Changelog

## [1.2.2] - 2026-06-20

### Changed

### `scripts/install.sh` — prefer `.deb` on Ubuntu/Debian
On Debian/Ubuntu systems the script now fetches the latest `.deb` from GitHub
Releases (via the API) and installs it with `sudo dpkg -i` instead of
downloading individual files. Single download, no stdin issues, no partial state
on failure.

Fallback path (macOS / non-Debian Linux) is kept and all `curl` calls now use
`--connect-timeout 15 --max-time 120 --retry 3 --retry-delay 2` to prevent
indefinite hangs on TLS errors or flaky connections.

### `scripts/deb/build-deb.sh` — bundle default ComfyUI workflow
`comfyui/workflows/default.json` is now packaged into the `.deb` under
`/usr/share/claude-docker/workflows/`.

### `scripts/deb/postinst` — copy default workflow on install
After creating `~/claude-docker/comfyui/user/default/workflows/`, the postinst
script copies the bundled `default.json` there (skipped if the file already
exists, so user-modified workflows are never overwritten).
