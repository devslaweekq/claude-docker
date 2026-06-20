# 2026-06-20 — GitHub Actions workflow for deb release

## Added
- `.github/workflows/deb-release.yml` — builds and publishes the `.deb` package
  as a GitHub Release. Runs in parallel with `docker-publish.yml`, each workflow
  owns its own `paths` filter.

  Triggers on push to `main`/`master` when deb-relevant files change:
  `launcher`, `docker-compose.yml`, `.env.example`, `package.json`,
  `scripts/deb/**`. Also available via `workflow_dispatch` for manual runs.

  Steps:
  1. Read version from `package.json`.
  2. Run `npm run build:deb` → `dist/claude-docker_<version>_all.deb`.
  3. Concatenate all `changelog/*.md` files (sorted by name, excluding README)
     into the release body.
  4. Create or update GitHub Release `v<version>` with the `.deb` attached
     (`softprops/action-gh-release@v2`, `permissions: contents: write`).
