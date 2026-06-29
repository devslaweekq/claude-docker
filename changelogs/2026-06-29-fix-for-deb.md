# Changelog

## [1.3.9] - 2026-06-29

### Fixed

### `scripts/deb/postinst` — APT repository setup failed with permission errors

During post-install, importing the GPG key and writing the APT sources entry could
fail with `curl: Failed writing body` and `Permission denied` when
`/usr/share/keyrings/` was missing or the pipeline could not write to system paths.

- Create `/usr/share/keyrings/` with `mkdir -p` before dearmoring the key
- Run `gpg --dearmor` and `tee` through `sudo` so both steps can write to
  `/usr/share/keyrings/claude-docker.gpg` and `/etc/apt/sources.list.d/claude-docker.list`
- Replace shell redirect (`>`) with `sudo tee` for the sources list entry

After upgrading to this release, `sudo apt upgrade` can configure the repository
correctly on fresh installs and re-runs of the post-install hook.
