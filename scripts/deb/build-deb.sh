#!/usr/bin/env bash
# Build the claude-docker .deb package.
# Usage: bash scripts/deb/build-deb.sh
# Output: dist/claude-docker_<version>_all.deb

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO"

VERSION="$(grep '"version"' package.json | head -1 | sed 's/.*"version": "\(.*\)".*/\1/')"
PKG="claude-docker_${VERSION}_all"
BUILD="$REPO/dist/deb-build/$PKG"
OUT="$REPO/dist"

echo "==> Building $PKG.deb"

rm -rf "$BUILD"
mkdir -p "$BUILD/DEBIAN" "$BUILD/usr/share/claude-docker"

# Control files
sed "s/VERSION_PLACEHOLDER/$VERSION/" scripts/deb/control > "$BUILD/DEBIAN/control"
install -m 755 scripts/deb/postinst "$BUILD/DEBIAN/postinst"
install -m 755 scripts/deb/postrm   "$BUILD/DEBIAN/postrm"

# Data files — taken directly from repo root, no duplication
install -m 755 launcher           "$BUILD/usr/share/claude-docker/launcher"
install -m 644 docker-compose.yml "$BUILD/usr/share/claude-docker/docker-compose.yml"
install -m 644 .env.example       "$BUILD/usr/share/claude-docker/.env.example"
mkdir -p "$BUILD/usr/share/claude-docker/workflows"
install -m 644 workflows/z-image-turbo-txt2img.json \
  "$BUILD/usr/share/claude-docker/workflows/z-image-turbo-txt2img.json"

mkdir -p "$OUT"
dpkg-deb --root-owner-group --build "$BUILD" "$OUT/${PKG}.deb"

echo "==> Done: $OUT/${PKG}.deb"
