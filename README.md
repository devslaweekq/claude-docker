<p align="center">
  <img src="https://raw.githubusercontent.com/devslaweekq/claude-docker/main/assets/banner.png" alt="claude-docker" width="100%"/>
</p>

[![Release](https://github.com/devslaweekq/claude-docker/actions/workflows/deb-release.yml/badge.svg)](https://github.com/devslaweekq/claude-docker/actions/workflows/deb-release.yml)
[![Docker Publish](https://github.com/devslaweekq/claude-docker/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/devslaweekq/claude-docker/actions/workflows/docker-publish.yml)
[![ComfyUI Publish](https://github.com/devslaweekq/claude-docker/actions/workflows/comfyui-publish.yml/badge.svg)](https://github.com/devslaweekq/claude-docker/actions/workflows/comfyui-publish.yml)
[![Dashboard Publish](https://github.com/devslaweekq/claude-docker/actions/workflows/dashboard-publish.yml/badge.svg)](https://github.com/devslaweekq/claude-docker/actions/workflows/dashboard-publish.yml)

Run [Claude Code](https://docs.anthropic.com/en/docs/claude-code) in an isolated Docker container, with a set of optional companion services. This repo is a monorepo — each service lives in its own folder with its own Dockerfile and README.

## Services

| Folder                                      | What it is                                                                                                                             |
| ------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| [`claude-docker/`](claude-docker/README.md) | The main service — Claude Code in an isolated container, persistent sessions, fzf resume menu, pre-configured MCP servers. Start here. |
| [`comfyui/`](comfyui/README.md)             | Optional GPU image-generation service (`--comfyui`), driven via MCP.                                                                   |
| [`dashboard/`](dashboard/README.md)         | Optional read-only session monitoring dashboard (`--dashboard`), viewed in the browser.                                                |

All are orchestrated together from the root [`docker-compose.yml`](docker-compose.yml) / [`docker-compose.dev.yml`](docker-compose.dev.yml) and started via [`claude-docker/launcher`](claude-docker/launcher).

## Quick start

```bash
git clone https://github.com/devslaweekq/claude-docker.git
cd claude-docker
cp .env.example .env && chmod 600 .env
# set PROJECT_DIRS and CLAUDE_CODE_OAUTH_TOKEN in .env, then:
./claude-docker/launcher
```

Full install instructions (clone, one-line install script, or Docker image only): [`INSTALL.md`](INSTALL.md). Detailed features, configuration, and troubleshooting: [`claude-docker/README.md`](claude-docker/README.md).


## More docs

- [`INSTALL.md`](INSTALL.md) — the three install methods
- [`PORTS.md`](PORTS.md) — port reference across all services
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — contribution guidelines
- [`claude-docker/README.md`](claude-docker/README.md) — main service docs (features, MCP servers, proxy, Windows, troubleshooting)
- [`comfyui/README.md`](comfyui/README.md) — ComfyUI service docs
- [`dashboard/README.md`](dashboard/README.md) — dashboard service docs
