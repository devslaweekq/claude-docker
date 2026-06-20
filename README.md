# Claude Docker

Run [Claude Code](https://docs.anthropic.com/en/docs/claude-code) in an isolated Docker container — your workspace mounted inside, persistent sessions, an fzf menu with resume, and optional corporate proxy support.

**Docker image:** [`slaweekq/claude-docker:latest`](https://hub.docker.com/r/slaweekq/claude-docker)

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (Compose v2 if you use method A)
- Bash — Linux, macOS, or WSL2 on Windows
- A Claude account: OAuth token via `claude setup-token`, or log in interactively inside the container

---

## Three ways to install

|                             | **A. Clone the repo**           | **B. Install script**     | **C. Docker image only**        |
| --------------------------- | ------------------------------- | ------------------------- | ------------------------------- |
| Best for                    | Development, Dockerfile changes | `bash scripts/install.sh` | Minimal setup, raw `docker run` |
| Config lives in             | in repo; `~/claude-docker/`     | `~/claude-docker/`        | `~/claude-docker/`              |
| Start command (e.g. claude) | `./launcher`                    | `claude`                  | `docker run …`                  |
| Smart cwd launch            | Yes — run from any project      | Yes                       | Pass your project path manually |

---

## A. Clone the repository

### 1. Clone and configure

```bash
git clone https://github.com/devslaweekq/claude-docker.git
cd claude-docker
cp .env.example .env
chmod 600 .env
```

Open `.env` and set two values:

```env
PROJECT_DIRS=/home/you/projects         # comma-separated folders → each mounted as /workspace/<name>
CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-…  # from `claude setup-token`, or leave empty to /login inside
```

> **WSL users:** use Linux paths (`/home/you/...` or `/mnt/c/Users/you/...`), not `C:\...`

### 2. Start

```bash
./launcher
```

First run pulls the image from Docker Hub automatically.

### 3. Optional: add to PATH

```bash
./launcher --install   # interactive: pick PATH command or skip
```

### Commands

| Command                     | Action                                                          |
| --------------------------- | --------------------------------------------------------------- |
| `./launcher`                | Start a session                                                 |
| `./launcher --pull`         | Pull the latest image, then start                               |
| `./launcher --build`        | Build the image locally (maintainers)                           |
| `./launcher --comfyui`      | Start ComfyUI (Docker, GPU) before the session, stop it on exit |
| `./launcher --install`      | Add a command to your PATH                                      |
| `./launcher <claude args…>` | Passthrough — run `claude <args…>` in the container, then exit  |

#### Passthrough

Any arguments that aren't launcher flags (`--install`, `--pull`, `--build`) are
forwarded straight to `claude` inside a throwaway container, which runs the
command and exits. With a PATH command from `--install`, the full claude CLI is
available natively:

```bash
claude setup-token     # print a token to paste into .env
claude login           # interactive OAuth; credentials persist in ~/claude-docker/home
claude auth status     # check current auth
claude --version
```

Output is pipeable (`claude auth status | grep …`) and the exit code is
propagated, so passthrough works in scripts. Bare `claude` still opens the
menu/session.

### Smart launch from any folder

You can run `./launcher` (or your PATH command from `--install`) from any directory:

| Where you run it                            | What opens                                |
| ------------------------------------------- | ----------------------------------------- |
| Inside a project (subdir of `PROJECT_DIRS`) | Session picker for that project           |
| At a `PROJECT_DIRS` root                    | Full menu — all projects, scratch, bash   |
| Outside all `PROJECT_DIRS` (or unset)       | Full menu — your cwd available as scratch |

---

## B. Install script (no clone)

```bash
curl -fsSL https://raw.githubusercontent.com/devslaweekq/claude-docker/main/scripts/install.sh | bash
```

Then edit `~/claude-docker/.env` and run your PATH command (e.g. `claude`) or `~/claude-docker/launcher`. Re-run `bash scripts/install.sh` from a newer checkout to update the launcher and compose file (your `.env` and `home/` are preserved).

---

## C. Docker image only (no clone)

No repo needed. Everything lives in `~/claude-docker/` on your machine.

### 1. Create the config folder

```bash
mkdir -p ~/claude-docker/home ~/claude-docker/certs
chmod 700 ~/claude-docker

cat > ~/claude-docker/.env <<'EOF'
CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-...

# Optional — only if Anthropic is not reachable directly:
# HTTP_PROXY=http://USER:PASSWORD@proxy.example.com:8888
# HTTPS_PROXY=http://USER:PASSWORD@proxy.example.com:8888
NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16

# Optional integrations:
# GH_TOKEN=
# CONTEXT7_API_KEY=
# JIRA_URL=https://your-org.atlassian.net/
# JIRA_USERNAME=
# JIRA_API_TOKEN=
EOF

chmod 600 ~/claude-docker/.env
```

### 2. Pull the image

```bash
docker pull slaweekq/claude-docker:latest
```

### 3. Run

Replace `/home/you/projects` with your actual workspace path:

```bash
docker run --rm -it \
  --network host \
  --user 0:0 \
  --env-file ~/claude-docker/.env \
  -v /home/you/projects:/workspace \
  -v ~/claude-docker/home:/home/node \
  slaweekq/claude-docker:latest
```

If you use a **TLS proxy with a self-signed certificate**, add the certs volume:

```bash
  -v ~/claude-docker/certs:/tmp/certs-input:ro \
```

---

## ComfyUI — AI image generation

Run [ComfyUI](https://github.com/Comfy-Org/ComfyUI) locally in Docker with GPU acceleration alongside Claude Code. The `comfyui-mcp` server is pre-configured in every session so Claude can generate images directly.

### Requirements

- NVIDIA GPU + [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
- `slaweekq/comfyui:latest` image (pulled automatically on first `--comfyui` run)

### Start

```bash
./launcher --comfyui
```

Claude will have access to ComfyUI at `http://localhost:8188` via MCP. The web UI is also available in your browser.

### Models

Place model files in `~/claude-docker/comfyui/models/` — subdirectories mirror the ComfyUI layout:

```
~/claude-docker/comfyui/
├── models/
│   ├── checkpoints/
│   ├── clip/           # e.g. qwen_3_4b.safetensors
│   ├── unet/           # e.g. z_image_turbo_bf16.safetensors
│   └── vae/            # e.g. ae.safetensors
└── output/             # generated images
```

Generated images are saved to `~/claude-docker/comfyui/output/`.

A bundled **Z-Image Turbo** txt2img workflow is available in the ComfyUI web UI out of the box (baked into the image).

---

## Authentication

| Method                              | When to use                                          |
| ----------------------------------- | ---------------------------------------------------- |
| `CLAUDE_CODE_OAUTH_TOKEN` in `.env` | Recommended — works headless, skips the login wizard |
| `/login` inside the container       | Personal Pro/Max account or first-time setup         |

**Corporate token:** get it from your admin and put it in `CLAUDE_CODE_OAUTH_TOKEN`. You don't need access to the corporate Claude.ai web interface.

To generate a token using the container itself — no second terminal, no
shelling into a running session — use [passthrough](#passthrough):

```bash
claude setup-token     # paste the result into CLAUDE_CODE_OAUTH_TOKEN in .env
# or, with a clone:
./launcher setup-token
```

`claude login` works the same way; credentials are written to the persistent
`~/claude-docker/home` volume and picked up by your next session.

Tokens last about one year.

---

## What's included

Claude Code, `git`, `gh` (GitHub CLI), `fzf`, `bun`, DB clients (`psql`, `mysql`, `redis-cli`), and these MCP servers pre-configured:

| MCP server | What it connects to                                       |
| ---------- | --------------------------------------------------------- |
| comfyui    | Local ComfyUI server at localhost:8188 (`--comfyui` flag) |
| github     | GitHub (requires `GH_TOKEN`)                              |
| playwright | Browser automation                                        |
| context7   | Library docs (requires `CONTEXT7_API_KEY`)                |
| figma      | Figma designs                                             |
| atlassian  | Jira (requires `JIRA_*` vars)                             |
| kubernetes | Kubernetes cluster (read-only)                            |
| sentry     | Sentry error tracking                                     |

Plugins pre-installed: [superpowers](https://github.com/anthropics/claude-code-superpowers), [claude-mem](https://github.com/thedotmack/claude-mem).

---

## Configuration reference

| Variable                                        | Required        | Description                                                       |
| ----------------------------------------------- | --------------- | ----------------------------------------------------------------- |
| `PROJECT_DIRS`                                  | Clone path only | Comma-separated host folders; each mounted as `/workspace/<name>` |
| `CLAUDE_CODE_OAUTH_TOKEN`                       | Recommended     | OAuth token (`sk-ant-oat01-…`)                                    |
| `HTTP_PROXY` / `HTTPS_PROXY`                    | No              | Outbound proxy for Anthropic API                                  |
| `NO_PROXY` / `no_proxy`                         | No              | Hosts that bypass the proxy                                       |
| `GH_TOKEN`                                      | No              | GitHub CLI + GitHub MCP                                           |
| `CONTEXT7_API_KEY`                              | No              | Context7 MCP                                                      |
| `JIRA_URL` / `JIRA_USERNAME` / `JIRA_API_TOKEN` | No              | Jira MCP                                                          |

See [`.env.example`](.env.example) for the full template.

---

## Proxy (optional)

Skip this if Anthropic is reachable directly from your machine.

| Setup                        | `HTTP_PROXY` / `HTTPS_PROXY`  | `certs/` folder        |
| ---------------------------- | ----------------------------- | ---------------------- |
| No proxy                     | leave commented               | empty                  |
| HTTP proxy with auth         | `http://USER:PASS@HOST:PORT`  | not needed             |
| TLS proxy (self-signed cert) | `https://USER:PASS@HOST:PORT` | put `*.crt` files here |

TLS certificates are picked up at container start — no image rebuild needed.

---

## Troubleshooting

| Problem                                    | Fix                                                                                    |
| ------------------------------------------ | -------------------------------------------------------------------------------------- |
| `401` from Claude                          | Check `CLAUDE_CODE_OAUTH_TOKEN` or run `/login` inside the container                   |
| First-run login screen even with token set | Make sure the token is in `--env-file` or use method A (`./launcher`)                  |
| `Settings Error` / invalid `settings.json` | Delete `~/claude-docker/home/.claude/settings.json` and restart — it will be recreated |
| `cannot connect to Docker daemon`          | Start Docker Desktop / enable WSL integration                                          |

---

## Windows

Use WSL2 + [Docker Desktop](https://www.docker.com/products/docker-desktop/) with WSL integration enabled, then follow method **A** or **B** inside your Ubuntu terminal.

Alternatively, double-click [`launcher.bat`](launcher.bat) from the cloned repo (edit the WSL distro name in the file if yours isn't `Ubuntu`).

---

<details>
<summary>For maintainers</summary>

```bash
# Build locally (--load into local daemon)
npm run build:claude    # claude-docker image
npm run build:comfyui   # comfyui image
npm run build           # both

# Build and push to Docker Hub
npm run push:claude     # slaweekq/claude-docker:latest
npm run push:comfyui    # slaweekq/comfyui:latest
npm run push            # both

npm run build:deb       # build .deb package
npm run launcher        # ./launcher
```

See [`scripts/docker/build.sh`](scripts/docker/build.sh) and [`scripts/docker/push.sh`](scripts/docker/push.sh).

</details>
