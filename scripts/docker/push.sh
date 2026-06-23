#!/usr/bin/env bash
# Push locally built Docker images to Docker Hub.
# Run build.sh first to build and load the image.
#
# Usage:
#   bash scripts/docker/push.sh --claude    # push slaweekq/claude-docker:latest
#   bash scripts/docker/push.sh --comfyui   # push slaweekq/comfyui:latest
#   bash scripts/docker/push.sh --all       # push both
#
# Local: log in first:
#   echo YOUR_DOCKER_PASS | docker login -u YOUR_DOCKER_USERNAME --password-stdin
#
# CI (GitHub Actions): login is done by the workflow; set DOCKER_USERNAME env var.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
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

  [ "$CI" != "true" ] && DOCKER_USERNAME="$DOCKER_USERNAME" bash "$REPO/scripts/docker/build.sh" --claude

  echo "==> Push: $IMAGE"
  docker push "$IMAGE"
  [ "$CI" != "true" ] && docker pull "$IMAGE"

  echo "  Registry: $IMAGE"
}

push_comfyui() {
  local IMAGE="$DOCKER_USERNAME/comfyui:latest"

  [ "$CI" != "true" ] && DOCKER_USERNAME="$DOCKER_USERNAME" bash "$REPO/scripts/docker/build.sh" --comfyui

  echo "==> Push: $IMAGE"
  docker push "$IMAGE"
  [ "$CI" != "true" ] && docker pull "$IMAGE"

  echo "  Registry: $IMAGE"
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
