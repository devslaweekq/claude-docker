#!/usr/bin/env bash
# Build and push Docker images to Docker Hub.
#
# Usage:
#   bash scripts/docker/push.sh --claude    # push slaweekq/claude-docker:latest
#   bash scripts/docker/push.sh --comfyui   # push slaweekq/comfyui:latest
#   bash scripts/docker/push.sh --all       # push both
#
# Local: log in first:
#   echo YOUR_DOCKER_PASS | docker login -u YOUR_DOCKER_USERNAME --password-stdin
#
# CI (GitHub Actions): login is done by the workflow; set GITHUB_ACTIONS=true
# and DOCKER_USERNAME env var.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "Usage: push.sh --claude | --comfyui | --all" >&2
  exit 1
fi

CI="${GITHUB_ACTIONS:-false}"

if [ "$CI" = "true" ]; then
  if [ -z "${DOCKER_USERNAME:-}" ]; then
    echo "CI mode: set DOCKER_USERNAME env var." >&2
    exit 1
  fi
else
  read -rp "Docker Hub username: " DOCKER_USERNAME
  if [ -z "$DOCKER_USERNAME" ]; then
    echo "Username cannot be empty." >&2
    exit 1
  fi
fi

push_claude() {
  local IMAGE="$DOCKER_USERNAME/claude-docker:latest"
  local CACHE="$DOCKER_USERNAME/claude-docker:buildcache"

  if [ "$CI" != "true" ]; then
    echo "==> Stop running Claude Docker sessions (if any)"
    mapfile -t running < <(docker ps -q --filter label=claude-docker.role=session 2>/dev/null || true)
    [ ${#running[@]} -gt 0 ] && docker stop "${running[@]}"

    echo "==> Remove old local image: $IMAGE"
    docker rmi -f "$IMAGE" 2>/dev/null || true
  fi

  echo "==> Build and push: $IMAGE"
  docker buildx build \
    --progress=plain \
    --build-arg HTTP_PROXY= --build-arg http_proxy= \
    --build-arg HTTPS_PROXY= --build-arg https_proxy= \
    --cache-from type=registry,ref="$CACHE" \
    --cache-to   type=registry,ref="$CACHE",mode=max \
    -t "$IMAGE" --push \
    .

  [ "$CI" != "true" ] && docker pull "$IMAGE"

  echo "  Registry: $IMAGE"
  echo "  Cache:    $CACHE"
}

push_comfyui() {
  local IMAGE="$DOCKER_USERNAME/comfyui:latest"
  local CACHE="$DOCKER_USERNAME/comfyui:buildcache"

  echo "==> Build and push: $IMAGE"
  docker buildx build \
    --progress=plain \
    --cache-from type=registry,ref="$CACHE" \
    --cache-to   type=registry,ref="$CACHE",mode=max \
    -t "$IMAGE" --push \
    ./comfyui

  [ "$CI" != "true" ] && docker pull "$IMAGE"

  echo "  Registry: $IMAGE"
  echo "  Cache:    $CACHE"
}

case "$TARGET" in
  --claude)  push_claude ;;
  --comfyui) push_comfyui ;;
  --all)     push_claude; push_comfyui ;;
  *) echo "Unknown target: $TARGET. Use --claude, --comfyui, or --all." >&2; exit 1 ;;
esac

echo
echo "Done."

# docker compose -f ./docker-compose.dev.* stop || true
# docker compose -f ./docker-compose.dev.* down -v && docker compose -f ./docker-compose.dev.* rm -sfv
# docker rmi $(docker images -q --no-trunc) || true
# docker compose -f ./docker-compose.dev.* up -d
