# 2026-06-20 — Scope release notes to current push

## Changed
- `.github/workflows/deb-release.yml` — release body now includes only
  `changelog/*.md` files added or modified in the current push
  (`git diff <before> HEAD`). Falls back to all files on the first push.
  Shows "No changelog entries for this release." when none changed.
