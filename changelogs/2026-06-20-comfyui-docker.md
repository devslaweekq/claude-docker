# Changelog

## [1.1.3] - 2026-06-20

### Added

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
  - `~/claude-docker/comfyui/models` → `/opt/ComfyUI/models`
  - `~/claude-docker/comfyui/output` → `/opt/ComfyUI/output`
  - `~/claude-docker/comfyui/user` → `/opt/ComfyUI/user`

### `launcher --comfyui` flag
Starts ComfyUI before the Claude session and stops it on exit:
- Pulls `slaweekq/comfyui:latest` on first run if not cached locally
- Checks `localhost:8188` before starting — skips if ComfyUI is already running
- Starts the service via `docker compose --profile comfyui up -d`
- Registers an EXIT trap: stops the container when the Claude session ends
- Only active for interactive sessions — ignored for passthrough commands
- Exports `COMFYUI_HOME` (sibling of `CLAUDE_HOME`) for compose volume paths

### `claude-defaults/mcp.json` — ComfyUI MCP
`comfyui-mcp` server added as a default (via `npx`), pointing at
`http://localhost:8188`. Available in every Claude session; functional when
ComfyUI is running.

### `scripts/docker/build.sh` and `scripts/docker/push.sh` — flag-based image selection
Both scripts now require an explicit target flag:
- `--claude` — build/push `slaweekq/claude-docker:latest`
- `--comfyui` — build/push `slaweekq/comfyui:latest`
- `--all` — both images

`npm run build:claude`, `npm run build:comfyui`, `npm run push:claude`,
`npm run push:comfyui` added to `package.json` for convenience.

### `.github/workflows/comfyui-publish.yml`
New CI workflow: rebuilds and pushes `slaweekq/comfyui:latest` when
`comfyui/Dockerfile` changes on `main`/`master`, or manually via
`workflow_dispatch`.

### Install scripts (`scripts/install.sh`, `scripts/deb/postinst`)
Create `~/claude-docker/comfyui/{models,output,user/default/workflows}` on
install; seed `default.json` (Z-Image Turbo workflow) into
`comfyui/user/default/workflows/` on first install.

### Changed

### `comfyui_user` volume → host-mount
`docker-compose.yml`, `docker-compose.dev.yml` — `comfyui_user:/opt/ComfyUI/user`
named volume replaced with `${COMFYUI_HOME}/user:/opt/ComfyUI/user` bind-mount.
Workflow files placed in `~/claude-docker/comfyui/user/default/workflows/` are
visible in the ComfyUI web UI immediately without restarting the container.

> **Migration:** `docker volume rm claude-docker_comfyui_user && mkdir -p ~/claude-docker/comfyui/user/default/workflows`

### Removed

### COMFYUI_PATH env-var approach
Host-process ComfyUI start and `scripts/menu.sh` conditional MCP sync removed;
replaced by the Docker Compose service and `--comfyui` launcher flag.
