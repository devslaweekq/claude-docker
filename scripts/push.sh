#!/usr/bin/env bash
# Local:
#   bash ./scripts/push.sh
#   echo YOUR_DOCKER_PASS | docker login -u YOUR_DOCKER_USERNAME --password-stdin
#
# CI (GitHub Actions): login is done by the workflow; set GITHUB_ACTIONS=true
# and DOCKER_USERNAME env var (no interactive prompt in CI).

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

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

IMAGE="$DOCKER_USERNAME/claude-docker:latest"
CACHE="$DOCKER_USERNAME/claude-docker:buildcache"
LOCAL="claude-docker"

if [ "$CI" != "true" ]; then
  echo "==> Stop running Claude Docker sessions (if any)"
  mapfile -t running < <(docker ps -q --filter label=claude-docker.role=session 2>/dev/null || true)
  if [ ${#running[@]} -gt 0 ]; then
    docker stop "${running[@]}"
  fi

  echo "==> Remove old local images: $LOCAL, $IMAGE"
  docker rmi -f "$LOCAL" "$IMAGE" 2>/dev/null || true
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

if [ "$CI" != "true" ]; then
  echo "==> Pull and tag for local compose: $LOCAL"
  docker pull "$IMAGE"
  docker tag "$IMAGE" "$LOCAL"
fi

echo
echo "Done."
echo "  Registry: $IMAGE"
echo "  Cache:    $CACHE"
if [ "$CI" != "true" ]; then
  echo "  Local:    $LOCAL"
fi

# docker compose -f ./docker-compose.dev.* stop || true
# docker compose -f ./docker-compose.dev.* down -v && docker compose -f ./docker-compose.dev.* rm -sfv
# docker rmi $(docker images -q --no-trunc) || true
# docker compose -f ./docker-compose.dev.* up -d
