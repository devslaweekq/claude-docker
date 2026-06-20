#!/usr/bin/env bash
# Install claude-docker
#   curl -fsSL https://raw.githubusercontent.com/devslaweekq/claude-docker/main/scripts/install.sh | bash

set -euo pipefail

GITHUB_REPO="devslaweekq/claude-docker"
RAW_BASE="https://raw.githubusercontent.com/$GITHUB_REPO/main"
INSTALL_DIR="$HOME/claude-docker"
LAUNCHER="$INSTALL_DIR/launcher"

# ── Ensure curl is available ──────────────────────────────────────────────────
case "$(uname -s)" in
  Linux)
    command -v curl >/dev/null 2>&1 || {
      sudo apt-get update -qq && sudo apt-get install -y curl
    }
    ;;
  Darwin)
    command -v curl >/dev/null 2>&1 || {
      echo "Error: install Xcode Command Line Tools: xcode-select --install" >&2
      exit 1
    }
    ;;
  *)
    command -v curl >/dev/null 2>&1 || {
      echo "Error: curl not found, install it manually." >&2
      exit 1
    }
    ;;
esac

# ── Ubuntu/Debian: install via .deb from latest GitHub release ───────────────
if command -v dpkg >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
  echo "==> Fetching latest claude-docker release..."
  DEB_URL=$(curl -fsSL --connect-timeout 15 --max-time 30 \
    "https://api.github.com/repos/$GITHUB_REPO/releases/latest" \
    2>/dev/null \
    | grep '"browser_download_url"' | grep '\.deb"' | head -1 \
    | cut -d'"' -f4 || true)

  if [ -n "$DEB_URL" ]; then
    TMP=$(mktemp /tmp/claude-docker-XXXXXX.deb)
    trap 'rm -f "$TMP"' EXIT
    echo "==> Downloading $DEB_URL"
    curl -fL --connect-timeout 15 --max-time 300 --retry 3 --retry-delay 2 \
      "$DEB_URL" -o "$TMP"
    echo "==> Installing package..."
    sudo dpkg -i "$TMP"
    exit 0
  fi

  echo "    No release found, falling back to manual install..."
fi

# ── Ensure Docker is available ────────────────────────────────────────────────
case "$(uname -s)" in
  Linux)
    command -v docker >/dev/null 2>&1 || {
      curl -fsSL --connect-timeout 15 --max-time 300 --retry 3 --retry-delay 2 \
        https://get.docker.com | sh
      sudo systemctl enable --now docker || true
      sudo usermod -aG docker "${SUDO_USER:-$(whoami)}" || true
      echo "    Note: re-login or run 'newgrp docker'."
    }
    ;;
  Darwin)
    command -v docker >/dev/null 2>&1 || {
      echo "Error: install Docker Desktop: https://docs.docker.com/desktop/mac/install/" >&2
      exit 1
    }
    ;;
  *)
    command -v docker >/dev/null 2>&1 || {
      echo "Error: docker not found: https://docs.docker.com/engine/install/" >&2
      exit 1
    }
    ;;
esac

# ── Fallback: manual file download (macOS / non-Debian Linux) ────────────────
_curl() {
  curl -fsSL --connect-timeout 15 --max-time 120 --retry 3 --retry-delay 2 "$@"
}

download() {
  local rel="$1" dest="$2" mode="$3"
  _curl "$RAW_BASE/$rel" -o "$dest"
  chmod "$mode" "$dest"
}

echo "==> Installing claude-docker to $INSTALL_DIR"
[ -d "$INSTALL_DIR/home/scratch" ] || mkdir -p "$INSTALL_DIR/home/scratch"
[ -d "$INSTALL_DIR/certs" ] || mkdir -p "$INSTALL_DIR/certs"
[ -d "$INSTALL_DIR/comfyui/models" ] || mkdir -p "$INSTALL_DIR/comfyui/models"
[ -d "$INSTALL_DIR/comfyui/output" ] || mkdir -p "$INSTALL_DIR/comfyui/output"
[ -d "$INSTALL_DIR/comfyui/user/default/workflows" ] || \
  mkdir -p "$INSTALL_DIR/comfyui/user/default/workflows"
chmod 700 "$INSTALL_DIR"

echo "==> Downloading launcher and config"
download launcher "$LAUNCHER" 755
download docker-compose.yml "$INSTALL_DIR/docker-compose.yml" 644
download .env.example "$INSTALL_DIR/.env.example" 644

_curl "$RAW_BASE/certs/README.md" -o "$INSTALL_DIR/certs/README.md" 2>/dev/null \
  && chmod 644 "$INSTALL_DIR/certs/README.md" || true

if [ ! -f "$INSTALL_DIR/comfyui/user/default/workflows/default.json" ]; then
  _curl "$RAW_BASE/comfyui/workflows/default.json" \
    -o "$INSTALL_DIR/comfyui/user/default/workflows/default.json" 2>/dev/null || true
fi

if [ ! -f "$INSTALL_DIR/.env" ]; then
  cp "$INSTALL_DIR/.env.example" "$INSTALL_DIR/.env"
  chmod 600 "$INSTALL_DIR/.env"
  echo "    Created $INSTALL_DIR/.env from .env.example"
else
  echo "    Keeping existing $INSTALL_DIR/.env"
fi

command -v docker >/dev/null 2>&1 || \
  echo "Warning: docker not found — install Docker before running launcher." >&2

rm -f /tmp/claude-docker-chosen-cmd
if [ -e /dev/tty ]; then
  "$LAUNCHER" --install </dev/tty
else
  echo "    No interactive terminal — run '$LAUNCHER --install' to add a PATH command"
fi
chosen_cmd="$(cat /tmp/claude-docker-chosen-cmd 2>/dev/null || true)"
rm -f /tmp/claude-docker-chosen-cmd

cat <<EOF

✓ Installation complete

Next step — edit $INSTALL_DIR/.env:
  • PROJECT_DIRS             — comma-separated host folders, each mounted as /workspace/<name>
                               e.g. PROJECT_DIRS=/home/user/work,/home/user/personal
  • CLAUDE_CODE_OAUTH_TOKEN  — from \`claude setup-token\`, or leave empty to /login inside

Then run: ${chosen_cmd:-$LAUNCHER}

EOF
