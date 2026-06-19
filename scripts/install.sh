#!/usr/bin/env bash
# Install claude-docker to ~/claude-docker
#   curl -fsSL https://raw.githubusercontent.com/devslaweekq/claude-docker/main/scripts/install.sh | bash

set -euo pipefail

RAW_BASE="https://raw.githubusercontent.com/devslaweekq/claude-docker/main"
INSTALL_DIR="$HOME/claude-docker"
LAUNCHER="$INSTALL_DIR/launcher"

download() {
  local rel="$1" dest="$2" mode="$3"
  curl -fsSL "$RAW_BASE/$rel" -o "$dest"
  chmod "$mode" "$dest"
}

echo "==> Installing claude-docker to $INSTALL_DIR"
mkdir -p "$INSTALL_DIR/home/scratch" "$INSTALL_DIR/certs"
chmod 700 "$INSTALL_DIR"

echo "==> Downloading launcher and config"
download launcher "$LAUNCHER" 755
download docker-compose.yml "$INSTALL_DIR/docker-compose.yml" 644
download .env.example "$INSTALL_DIR/.env.example" 644
if curl -fsSL "$RAW_BASE/certs/README.md" -o "$INSTALL_DIR/certs/README.md" 2>/dev/null; then
  chmod 644 "$INSTALL_DIR/certs/README.md"
fi

if [ ! -f "$INSTALL_DIR/.env" ]; then
  cp "$INSTALL_DIR/.env.example" "$INSTALL_DIR/.env"
  chmod 600 "$INSTALL_DIR/.env"
  echo "    Created $INSTALL_DIR/.env from .env.example"
else
  echo "    Keeping existing $INSTALL_DIR/.env"
fi

if command -v docker >/dev/null 2>&1; then
  echo "==> Pulling Docker image slaweekq/claude-docker:latest"
  if ! docker pull slaweekq/claude-docker:latest; then
    echo "Warning: docker pull failed — the image will be fetched on first launcher run." >&2
  fi
else
  echo "Warning: docker not found — install Docker before running launcher." >&2
fi

"$LAUNCHER" --install

cat <<EOF

✓ Installation complete

  Config directory:  $INSTALL_DIR
  Launcher:          $LAUNCHER
  Sessions / home:   $INSTALL_DIR/home
  TLS certs:         $INSTALL_DIR/certs/

Next step — edit $INSTALL_DIR/.env manually:
  • PROJECT_DIR              — host folder mounted as /workspace
  • CLAUDE_CODE_OAUTH_TOKEN  — from \`claude setup-token\`, or leave empty to /login inside

Then run: claude (e.g. cladock) or:  $LAUNCHER

EOF
