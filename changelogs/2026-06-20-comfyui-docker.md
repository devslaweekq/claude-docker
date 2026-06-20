# 2026-06-20 — ComfyUI via Docker Compose

## Added
- `docker-compose.yml` — `comfyui` service using `yanwk/comfyui-boot:latest` with
  GPU passthrough (`nvidia` driver, `capabilities: [gpu]`). Activated via
  `profiles: [comfyui]` — not started by default. Mounts
  `~/claude-docker/comfyui/{models,output,user}` for persistent data.
- `launcher --comfyui` flag — starts the ComfyUI Docker service before the Claude
  session and stops it on exit via an EXIT trap. Skips start if ComfyUI is already
  reachable at `localhost:8188`. Exports `COMFYUI_HOME` (sibling of `CLAUDE_HOME`)
  so `docker-compose.yml` can reference the correct host paths.
- `claude-defaults/mcp.json` — ComfyUI MCP server (`comfyui-mcp` via npx) added as
  a default, pointing at `http://localhost:8188`.
- `scripts/install.sh` and `scripts/deb/postinst` — create
  `~/claude-docker/comfyui/{models,output,user/default/workflows}` on install and
  seed `z-image-turbo-txt2img.json` workflow so it appears in the ComfyUI web UI.
- `scripts/deb/build-deb.sh` — includes `workflows/` directory in the `.deb` package.

## Removed
- `COMFYUI_PATH` host-process approach (replaced by Docker Compose service).
