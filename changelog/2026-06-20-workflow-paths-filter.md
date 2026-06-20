# 2026-06-20 — Workflow paths filter for Docker publish

## Changed
- `.github/workflows/docker-publish.yml` now triggers only when files that
  actually affect the Docker image are changed:
  - `Dockerfile`
  - `scripts/update-certs.sh`
  - `scripts/ensure-claude-cli.sh`
  - `scripts/menu.sh`
  - `scripts/sessions.js`
  - `claude-defaults/**`

  Pushes to `main`/`master` that only touch docs, install scripts, launcher,
  or other unrelated files no longer trigger an image rebuild.
  `workflow_dispatch` remains available for manual runs at any time.
