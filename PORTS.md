# Ports

All services in this project use **`network_mode: host`**. Containers bind ports directly on the host — there is no Docker `ports:` mapping. What you see in `docker compose` is the real listening address.

## Optional services (launcher flags)

| Service  | Port | URL                   | Launcher flag | Compose profile | Health / ready check |
| -------- | ---- | --------------------- | ------------- | --------------- | -------------------- |
| ComfyUI  | 8188 | http://localhost:8188 | `--comfyui`   | `comfyui`       | `GET /system_stats`  |
| Headroom | 8787 | http://localhost:8787 | `--headroom`  | `headroom`      | `GET /readyz`        |

Start examples:

```bash
./claude-docker/launcher --comfyui
./claude-docker/launcher --headroom
./claude-docker/launcher --comfyui --headroom
```

## Claude session container

The `claude` service does not expose a fixed HTTP port. It is an interactive shell (`claude-launch` / Claude Code). MCP servers and tools inside the session reach optional services via `localhost` because every service shares the host network stack.

| Consumer              | Target                         | Notes                                           |
| --------------------- | ------------------------------ | ----------------------------------------------- |
| `claude-mem` plugin   | `http://localhost:37777`       | Worker + web viewer (plugin hooks, not compose) |
| `comfyui-mcp` (MCP)   | `http://localhost:8188`        | Set in `claude-docker/claude-defaults/mcp.json` |
| Headroom proxy client | `http://localhost:8787`        | e.g. `ANTHROPIC_BASE_URL` when using proxy      |
| Anthropic API         | `api.anthropic.com` (outbound) | Direct or via `HTTP_PROXY` in `.env`            |

## Why not `ports:` in compose?

With `network_mode: host`, Docker **ignores** `ports:` entries. Listing them in `docker-compose.yml` would suggest bridge networking and port forwarding, which is not how this stack runs. Host mode is intentional: Tailscale/private DB access, MCP to localhost services, and clipboard forwarding all rely on the container sharing the host network namespace.

See `docker-compose.yml` service comments for quick port hints; this file is the canonical reference.
