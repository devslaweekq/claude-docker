# Changelog

## [1.4.3] - 2026-07-15

### Added

### Docker images tag and push `:<version>` alongside `:latest`
`scripts/docker/build.sh` and `scripts/docker/push.sh` now read the project version from
`package.json` and tag/push both `slaweekq/claude-docker:<version>` and
`slaweekq/comfyui:<version>` alongside `:latest`, for both images (`--claude`, `--comfyui`,
`--all`). Same scheme as `nx-cache-s3-remote`. No extra build cost — just an extra `-t` on
the existing `docker buildx build` call.

### Docker Hub overview syncs automatically from README
`docker-publish.yml` pushes the root `README.md` as `slaweekq/claude-docker`'s Docker Hub
description via `peter-evans/dockerhub-description@v5`, right after the image push.
`comfyui-publish.yml` does the same for `slaweekq/comfyui`, but from a new dedicated
`comfyui/README.md` — the root README is claude-docker-session-focused and isn't a good fit
for someone landing on the `comfyui` image's own Docker Hub page. Both workflows also
trigger on README-only changes now. Needs `DOCKER_PASSWORD` to be a "Read, Write, Delete"
scoped token — same requirement discovered debugging this exact setup in
`nx-cache-s3-remote` (a lower scope 403s on the Hub API even though it pushes images fine).

### Changed

### Root README restyled: badges + `## Features`
Banner switched to an absolute `raw.githubusercontent.com` URL (relative paths don't
resolve once the same markdown is pushed to Docker Hub via the API — no repo filesystem
context there). Added `Docker Publish` and `ComfyUI Publish` status badges alongside the
existing `Release` badge, and a `## Features` section up front (persistent sessions,
pre-configured MCP servers, optional GPU image generation, corporate proxy support,
user-level `CLAUDE.md` seeding, three install paths) before the prerequisites/install detail.
