# Changelog

## [1.0.2] - 2026-06-20

### Changed

### Release body scoped to current push
`.github/workflows/deb-release.yml` — release body now includes only
`changelogs/*.md` files added or modified in the current push
(`git diff <before> HEAD`). Falls back to all files on the first push.
Shows "No changelog entries for this release." when none changed.
