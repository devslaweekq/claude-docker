# Changelog

## [1.0.3] - 2026-06-20

### Fixed

### Changelog body was empty due to shallow clone
`.github/workflows/deb-release.yml` — `actions/checkout@v7` performs a shallow
clone (depth 1) by default, making the `before` SHA unavailable for `git diff`.
Fixed by setting `fetch-depth: 2` and using `HEAD~1 HEAD` instead of
`github.event.before`.

### Changed

### `softprops/action-gh-release` upgraded to `v3`
`.github/workflows/deb-release.yml` — upgraded from `v2` to `v3` (Node.js 24).
v2 used Node.js 20 which GitHub Actions deprecated in September 2025.
