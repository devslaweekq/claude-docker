# 2026-06-20 — Paths filter for Docker publish workflow

## Changed
- `.github/workflows/docker-publish.yml` triggers only when files that affect
  the Docker image change: `Dockerfile`, `scripts/update-certs.sh`,
  `scripts/ensure-claude-cli.sh`, `scripts/menu.sh`, `scripts/sessions.js`,
  `claude-defaults/**`. Unrelated pushes (docs, install scripts, launcher) no
  longer trigger a rebuild. `workflow_dispatch` remains available for manual runs.
