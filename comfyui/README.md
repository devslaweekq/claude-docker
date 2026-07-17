# comfyui

[![ComfyUI Publish](https://github.com/devslaweekq/claude-docker/actions/workflows/comfyui-publish.yml/badge.svg)](https://github.com/devslaweekq/claude-docker/actions/workflows/comfyui-publish.yml)

GPU-accelerated [ComfyUI](https://github.com/Comfy-Org/ComfyUI) in a thin Docker image — part of the [claude-docker](https://github.com/devslaweekq/claude-docker) project, where it runs alongside Claude Code with a pre-configured `comfyui-mcp` server so Claude can generate images directly. Works standalone too.

## Features

- 🪶 **Thin image** — torch/torchvision/torchaudio and ComfyUI's Python deps are **not** baked into the image (that's multi-GB). They install once into a mounted volume on first container start.
- 🔁 **Auto-reinstall on dependency change, not on every restart** — the install is keyed off a hash of `requirements.txt` + the torch pin, not a bare "did we ever run" marker. Change either and it reinstalls automatically; otherwise every start reuses the existing install.
- 🎮 **GPU passthrough** — built on `nvidia/cuda`, requires `nvidia-container-toolkit` on the host.
- 🧩 **Z-Image Turbo workflow included** — a working txt2img workflow ships in `user/default/workflows/` out of the box.

## Quick start

Requires an NVIDIA GPU and [`nvidia-container-toolkit`](https://github.com/NVIDIA/nvidia-container-toolkit) configured for Docker.

```bash
mkdir -p ~/claude-docker/comfyui/{models,output,user,venv}

docker run -d --gpus all \
  -p 8188:8188 \
  -v ~/claude-docker/comfyui/models:/opt/ComfyUI/models \
  -v ~/claude-docker/comfyui/output:/opt/ComfyUI/output \
  -v ~/claude-docker/comfyui/user:/opt/ComfyUI/user \
  -v ~/claude-docker/comfyui/venv:/opt/venv \
  slaweekq/comfyui:latest
```

**First run installs torch + ComfyUI's Python deps** into the mounted `venv/` (a few GB,
takes a few minutes). Every start after that reuses the same install and skips straight to
launching. The web UI is at `http://localhost:8188`.

Every build also pushes a `:<version>` tag matching the
[claude-docker release](https://github.com/devslaweekq/claude-docker/releases) it shipped
with, if you'd rather pin to a specific version than track `latest`.

## Models

Subdirectories mirror ComfyUI's own layout:

```
~/claude-docker/comfyui/
├── models/
│   ├── checkpoints/
│   ├── clip/           # e.g. qwen_3_4b.safetensors
│   ├── unet/            # e.g. z_image_turbo_bf16.safetensors
│   └── vae/            # e.g. ae.safetensors
├── output/              # generated images
├── venv/                # torch + ComfyUI deps, installed on first run — not model files
└── user/
    └── default/
        └── workflows/   # drop .json workflow files here — they appear in the UI instantly
```

## Using it with claude-docker

If you're running the full [claude-docker](https://github.com/devslaweekq/claude-docker)
stack instead of this image standalone, just use:

```bash
./claude-docker/launcher --comfyui
```

which starts this container via `docker-compose.yml` (same volumes as above) before the
Claude session, and pre-configures the `comfyui-mcp` MCP server so Claude can generate
images directly.

## Force a dependency reinstall

Delete `~/claude-docker/comfyui/venv/.install-hash` (or the whole `venv/` folder) and
restart the container.
