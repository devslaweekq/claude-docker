# Changelog

## [1.2.5] - 2026-06-22

### Added

### Version flag — `claude -v` / `cladock --version`
The launcher now handles `-v` and `--version` flags before any other logic and
before Docker is even touched. Running `claude -v` (or `cladock --version`) prints
the launcher version and exits immediately:

```
claude-docker 1.2.5
```

The version is hardcoded as `LAUNCHER_VERSION` in the `launcher` script (kept in
sync with `package.json`). For `.deb` builds, `build-deb.sh` injects the version
from `package.json` via `sed` at package build time, so installed packages always
carry the exact release version even without `package.json` present on the host.

### Fixed

### UTF-8 locale — universal Unicode support (Cyrillic, Arabic, Kazakh, CJK, …)
The container now generates and activates the `en_US.UTF-8` locale. The
`node:24-slim` base image ships without any generated locale and defaults to the
`C` (ASCII) locale. With `C` or `C.UTF-8`, glibc and several tools fall back to
ASCII processing, causing multi-byte UTF-8 codepoints to be mishandled through the
Docker pseudo-TTY — non-ASCII text arrives garbled in the terminal and clipboard.

`en_US.UTF-8` is the standard UTF-8 locale on Debian/Ubuntu, recognised by all
Linux tooling. It governs character _encoding_ only, not the UI language — every
Unicode script is fully supported.

Changes:
- `Dockerfile`: adds `locales` to the base `apt-get install` layer, runs
  `locale-gen`, sets `ENV LANG=en_US.UTF-8` / `ENV LC_ALL=en_US.UTF-8`
  (baked into future published images; requires `--build` or `--pull`).
- `docker-compose.yml` + `docker-compose.dev.yml`: `LANG` / `LC_ALL` updated from
  `C.UTF-8` → `en_US.UTF-8` (takes effect immediately, no image rebuild needed).
