# 2026-06-20 — deb release workflow fixes

## Fixed
- `.github/workflows/deb-release.yml` — changelog body was empty because
  `actions/checkout@v7` performs a shallow clone (depth 1) by default, making
  the `before` SHA unavailable for `git diff`. Fixed by setting `fetch-depth: 2`
  and using `HEAD~1 HEAD` instead of `github.event.before`.

## Changed
- `.github/workflows/deb-release.yml` — upgraded `softprops/action-gh-release`
  from `v2` to `v3` (Node.js 24). v2 used Node.js 20 which GitHub Actions
  deprecated in September 2025.
