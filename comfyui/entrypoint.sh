#!/usr/bin/env bash
# Installs torch + ComfyUI's Python deps into /opt/venv (mounted from the
# host at ~/claude-docker/comfyui/venv) the first time, and automatically
# again whenever requirements.txt or the torch pin below changes — keyed off
# a content hash, not a bare "did we ever run" marker. Keeps the pushed image
# thin — these deps never live in an image layer.
set -euo pipefail

VENV=/opt/venv
mkdir -p "$VENV"
STATE_FILE="$VENV/.install-hash"
TORCH_SPEC=(torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130)

CURRENT_HASH="$(cat /opt/ComfyUI/requirements.txt <(printf '%s\n' "${TORCH_SPEC[@]}") | sha256sum | cut -d' ' -f1)"

if [ ! -f "$STATE_FILE" ] || [ "$(cat "$STATE_FILE")" != "$CURRENT_HASH" ]; then
  echo "==> Installing torch + ComfyUI dependencies into $VENV"
  echo "    (requirements.txt or the torch pin changed, or this is the first run)"
  find "$VENV" -mindepth 1 -delete
  uv venv "$VENV" --python python3
  uv pip install --python "$VENV/bin/python3" --no-cache "${TORCH_SPEC[@]}"
  uv pip install --python "$VENV/bin/python3" --no-cache -r /opt/ComfyUI/requirements.txt
  echo "$CURRENT_HASH" > "$STATE_FILE"
  echo "==> Dependencies installed."
fi

exec "$VENV/bin/python3" /opt/ComfyUI/main.py "$@"
