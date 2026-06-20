# 2026-06-20 — Cleaner install output

## Changed
- `scripts/deb/postinst` and `scripts/install.sh` — simplified final message: removed
  the verbose block listing `Config directory`, `Launcher`, `Sessions / home`, and
  `TLS certs`; `Next step` section is now sufficient.
- `Then run:` line now shows the actual command chosen by the user (e.g. `cladock`)
  instead of the generic `claude (e.g. cladock) or: /path/to/launcher` string.
  Implemented via `launcher` writing the chosen command to `/tmp/claude-docker-chosen-cmd`
  after `--install`, which both scripts read and then clean up.
- `scripts/deb/postinst` — `re-login / newgrp docker` note is now shown only when the
  user is not already a member of the `docker` group (previously always printed).
