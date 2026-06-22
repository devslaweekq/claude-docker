# Changelog

## [1.0.1] - 2026-06-20

### Added

### `.github/workflows/deb-release.yml` — automated deb release
Builds and publishes the `.deb` as a GitHub Release, running in parallel with
`docker-publish.yml`. Triggers on push to `main`/`master` when deb-relevant
files change: `launcher`, `docker-compose.yml`, `.env.example`, `package.json`,
`scripts/deb/**`. Also available via `workflow_dispatch`.

Runs `npm run build:deb`, creates release `v<version>` with the `.deb` attached
via `softprops/action-gh-release`.
