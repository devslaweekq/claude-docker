# 2026-06-20 — ComfyUI via Docker Compose

Run ComfyUI locally alongside Claude Code via Docker Compose, with GPU passthrough
and MCP integration so Claude can generate images directly.

## Added

### ComfyUI Docker image (`comfyui/Dockerfile`)
Custom build recipe based on `nvidia/cuda:13.0.3-runtime-ubuntu22.04`:
- PyTorch installed from official CUDA 13.0 wheels (`--index-url .../whl/cu130`)
- ComfyUI cloned from `github.com/Comfy-Org/ComfyUI` during build
- Z-Image Turbo `txt2img` workflow baked into the image at
  `/opt/ComfyUI/user/default/workflows/` — appears in the ComfyUI web UI out of the box
- Published as `slaweekq/comfyui:latest` on Docker Hub

### `docker-compose.yml` — `comfyui` service
- Image: `slaweekq/comfyui:latest` (pulled from Docker Hub)
- Profile: `comfyui` — not started by default
- Network: `host` — both containers share `localhost`, so `localhost:8188` works inside Claude
- GPU: NVIDIA passthrough (`driver: nvidia`, `capabilities: [gpu]`)
- Volumes:
  - `~/claude-docker/comfyui/models` → `/opt/ComfyUI/models` (host-mounted, persistent)
  - `~/claude-docker/comfyui/output` → `/opt/ComfyUI/output` (host-mounted, generated images)
  - `comfyui_user` → `/opt/ComfyUI/user` (named Docker volume, preserves workflows/settings)

### `launcher --comfyui` flag
- Pulls `slaweekq/comfyui:latest` on first run if not cached locally
- Checks `localhost:8188` before starting — skips if ComfyUI is already running
- Starts the service via `docker compose --profile comfyui up -d`
- Registers an EXIT trap: stops the container when the Claude session ends
- Only active for interactive sessions — ignored for passthrough commands
- Exports `COMFYUI_HOME` (sibling of `CLAUDE_HOME`) for compose volume paths

### `claude-defaults/mcp.json` — ComfyUI MCP
`comfyui-mcp` server added as a default (via `npx`), pointing at `http://localhost:8188`.
Available in every Claude session; functional when ComfyUI is running.

### `scripts/docker/build.sh` and `scripts/docker/push.sh` — flag-based image selection
Both scripts now require an explicit target flag:
- `--claude` — build/push `slaweekq/claude-docker:latest`
- `--comfyui` — build/push `slaweekq/comfyui:latest`
- `--all` — both images

`npm run build:claude`, `npm run build:comfyui`, `npm run push:claude`, `npm run push:comfyui`
added to `package.json` for convenience.

### `.github/workflows/comfyui-publish.yml`
New CI workflow: rebuilds and pushes `slaweekq/comfyui:latest` when `comfyui/Dockerfile`
changes on `main`/`master`, or manually via `workflow_dispatch`. Uses the same Docker Hub
secrets as `docker-publish.yml` and calls `bash ./scripts/docker/push.sh --comfyui`.

### Install scripts (`scripts/install.sh`, `scripts/deb/postinst`)
- Create `~/claude-docker/comfyui/{models,output}` on install for host-mounted volumes
- No workflow files are copied to the host — they live inside the Docker image

## Removed

- `COMFYUI_PATH` env-var approach (host process, `scripts/menu.sh` conditional MCP sync)
- Workflow file seeding to host (`~/claude-docker/comfyui/user/default/workflows/`)
  replaced by baking the workflow into the Docker image
