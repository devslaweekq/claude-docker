#!/usr/bin/env bash
# Build Docker images locally (--load) and write cache to registry.
#
# Usage:
#   bash scripts/docker/build.sh --claude    # build slaweekq/claude-docker:latest (local)
#   bash scripts/docker/build.sh --comfyui   # build slaweekq/comfyui:latest (local)
#   bash scripts/docker/build.sh --all       # build both
#
# CI (GitHub Actions): set DOCKER_USERNAME env var; login is done by the workflow.

set -euo pipefail
cd "$(dirname "$0")/../.."

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "Usage: build.sh --claude | --comfyui | --all" >&2
  exit 1
fi

CI="${GITHUB_ACTIONS:-false}"

if [ "$CI" = "true" ]; then
  if [ -z "${DOCKER_USERNAME:-}" ]; then
    echo "CI mode: set DOCKER_USERNAME env var." >&2
    exit 1
  fi
elif [ -z "${DOCKER_USERNAME:-}" ]; then
  read -rp "Docker Hub username: " DOCKER_USERNAME
  if [ -z "$DOCKER_USERNAME" ]; then
    echo "Username cannot be empty." >&2
    exit 1
  fi
fi

build_claude() {
  local IMAGE="$DOCKER_USERNAME/claude-docker:latest"
  local CACHE="$DOCKER_USERNAME/claude-docker:buildcache"

  if [ "$CI" != "true" ]; then
    echo "==> Stop running Claude Docker sessions (if any)"
    mapfile -t running < <(docker ps -q --filter label=claude-docker.role=session 2>/dev/null || true)
    [ ${#running[@]} -gt 0 ] && docker stop "${running[@]}"

    echo "==> Remove old local image: $IMAGE"
    docker rmi -f "$IMAGE" 2>/dev/null || true
  fi

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
    --build-arg HTTP_PROXY= --build-arg http_proxy= \
    --build-arg HTTPS_PROXY= --build-arg https_proxy= \
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
