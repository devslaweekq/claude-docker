#!/usr/bin/env bash
# Maintainer only — local build before push.
#
# Usage:
#   bash scripts/docker/build.sh --claude    # build slaweekq/claude-docker:latest (local)
#   bash scripts/docker/build.sh --comfyui   # build slaweekq/comfyui:latest (local)
#   bash scripts/docker/build.sh --all       # build both

set -euo pipefail
cd "$(dirname "$0")/.."

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "Usage: build.sh --claude | --comfyui | --all" >&2
  exit 1
fi

read -rp "Docker Hub username: " DOCKER_USERNAME
if [ -z "$DOCKER_USERNAME" ]; then
  echo "Username cannot be empty." >&2
  exit 1
fi

build_claude() {
  local IMAGE="$DOCKER_USERNAME/claude-docker:latest"
  local CACHE="$DOCKER_USERNAME/claude-docker:buildcache"

  docker buildx build \
    --progress=plain \
    --build-arg HTTP_PROXY= --build-arg http_proxy= \
    --build-arg HTTPS_PROXY= --build-arg https_proxy= \
    --cache-from type=registry,ref="$CACHE" \
    --cache-to   type=registry,ref="$CACHE",mode=max \
    -t "$IMAGE" --load \
    .

  echo "OK: $IMAGE  (cache → $CACHE)"
}

build_comfyui() {
  local IMAGE="$DOCKER_USERNAME/comfyui:latest"
  local CACHE="$DOCKER_USERNAME/comfyui:buildcache"

  docker buildx build \
    --progress=plain \
    --cache-from type=registry,ref="$CACHE" \
    --cache-to   type=registry,ref="$CACHE",mode=max \
    -t "$IMAGE" --load \
    ./comfyui

  echo "OK: $IMAGE  (cache → $CACHE)"
}

case "$TARGET" in
  --claude)  build_claude ;;
  --comfyui) build_comfyui ;;
  --all)     build_claude; build_comfyui ;;
  *) echo "Unknown target: $TARGET. Use --claude, --comfyui, or --all." >&2; exit 1 ;;
esac
