# Changelog

## [1.0.1] - 2026-06-20

### Changed

### `docker-publish.yml` — trigger only on image-affecting files
`.github/workflows/docker-publish.yml` now triggers only when files that affect
the Docker image change: `Dockerfile`, `scripts/update-certs.sh`,
`scripts/ensure-claude-cli.sh`, `scripts/menu.sh`, `scripts/sessions.js`,
`claude-defaults/**`. Unrelated pushes (docs, install scripts, launcher) no
longer trigger a rebuild. `workflow_dispatch` remains available for manual runs.
