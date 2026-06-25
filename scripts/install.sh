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

# ── Ubuntu/Debian: configure APT repository for automatic updates ─────────────
if command -v dpkg >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
  if [ ! -f /usr/share/keyrings/claude-docker.gpg ] || [ ! -f /etc/apt/sources.list.d/claude-docker.list ]; then
    echo "==> Setting up claude-docker APT repository..."
    curl -fsSL --connect-timeout 15 --max-time 30 \
      "https://devslaweekq.github.io/claude-docker/KEY.gpg" \
      | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/claude-docker.gpg
    echo "deb [signed-by=/usr/share/keyrings/claude-docker.gpg] https://devslaweekq.github.io/claude-docker stable main" \
      | sudo tee /etc/apt/sources.list.d/claude-docker.list > /dev/null
  fi

  echo "==> Installing claude-docker..."
  sudo apt-get update -qq
  sudo apt-get install -y claude-docker
  exit 0
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

# ── WSL2: raise Docker Desktop VM limits ─────────────────────────────────────
if grep -qi microsoft /proc/version 2>/dev/null; then
  WIN_HOME="$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r\n')" 2>/dev/null || true)"
  if [ -n "$WIN_HOME" ] && [ -d "$WIN_HOME" ]; then
    WSLCONFIG="$WIN_HOME/.wslconfig"
    if [ ! -f "$WSLCONFIG" ]; then
      HOST_MEM_BYTES="$(powershell.exe -NoProfile -Command \
        '(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory' 2>/dev/null | tr -d '\r\n' || echo 0)"
      MEM_GB=$(( ${HOST_MEM_BYTES:-0} / 1024 / 1024 / 1024 * 3 / 4 ))
      [ "$MEM_GB" -lt 4 ] && MEM_GB=4
      PROCS="$(powershell.exe -NoProfile -Command \
        '(Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors' 2>/dev/null \
        | tr -d '\r\n' || nproc)"
      printf '[wsl2]\nmemory=%dGB\nprocessors=%s\n' "$MEM_GB" "$PROCS" > "$WSLCONFIG"
      echo "==> Created $WSLCONFIG (memory=${MEM_GB}GB, processors=${PROCS})"
      echo "    Run 'wsl --shutdown' and restart Docker Desktop to apply."
    else
      echo "    $WSLCONFIG already exists — skipping (edit manually to tune memory/processors)"
    fi
  fi
fi

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
[ -d "$INSTALL_DIR/headroom/.headroom" ] || mkdir -p "$INSTALL_DIR/headroom/.headroom"
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
