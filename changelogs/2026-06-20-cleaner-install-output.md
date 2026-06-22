# Changelog

## [1.1.0] - 2026-06-20

### Changed

### Simplified final install message
`scripts/deb/postinst` and `scripts/install.sh` — removed the verbose block
listing `Config directory`, `Launcher`, `Sessions / home`, and `TLS certs`;
the `Next step` section is now sufficient.

### `Then run:` shows the chosen command
The `Then run:` line now shows the actual command chosen by the user (e.g.
`cladock`) instead of the generic `claude (e.g. cladock) or: /path/to/launcher`
string. Implemented via `launcher` writing the chosen command to
`/tmp/claude-docker-chosen-cmd` after `--install`, which both scripts read and
then clean up.

### `re-login / newgrp docker` note shown only when needed
`scripts/deb/postinst` — the note is now printed only when the user is not
already a member of the `docker` group (previously always printed).
