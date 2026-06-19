#!/usr/bin/env bash
# Maintainer only — local build before push.
set -euo pipefail
cd "$(dirname "$0")/.."

read -rp "Docker Hub username: " DOCKER_USERNAME
if [ -z "$DOCKER_USERNAME" ]; then
  echo "Username cannot be empty." >&2
  exit 1
fi

IMAGE="$DOCKER_USERNAME/claude-docker:latest"
CACHE="$DOCKER_USERNAME/claude-docker:buildcache"

# Build directly, bypassing proxy: host daemon may have HTTPS_PROXY set
# (needed only for Claude→Anthropic INSIDE the container, see .env); GitHub releases
# and cli.github.com time out through it. Empty *_PROXY disables BuildKit auto-proxying.
docker buildx build \
  --progress=plain \
  --build-arg HTTP_PROXY= --build-arg http_proxy= \
  --build-arg HTTPS_PROXY= --build-arg https_proxy= \
  --cache-from type=registry,ref="$CACHE" \
  --cache-to   type=registry,ref="$CACHE",mode=max \
  -t "$IMAGE" --load \
  .

echo
echo "OK: $IMAGE  (cache → $CACHE)"
