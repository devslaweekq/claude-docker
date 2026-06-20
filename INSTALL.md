# Installation

Full guide: **[README.md](README.md)**

Quick links:

- [A. Clone the repository](README.md#a-clone-the-repository)
- [B. Docker image only](README.md#b-docker-image-only-no-clone)
- [Add to PATH](README.md#3-optional-add-to-path)
- [Authentication](README.md#authentication)
- [Proxy (optional)](README.md#proxy-optional)
- [Troubleshooting](README.md#troubleshooting)
- [Windows](README.md#windows)

---

## Quickstart — install script (no clone)

One-liner — creates `~/claude-docker/`, downloads required files from GitHub

```bash
curl -fsSL https://raw.githubusercontent.com/devslaweekq/claude-docker/main/scripts/install.sh | bash
```

Installs to `~/claude-docker/` (launcher, compose file, `.env`, `home/`, `certs/`), pulls the Docker image, and offers to add a PATH command. Then edit `~/claude-docker/.env` and run `claude` (or your chosen command).

## Quickstart — clone

```bash
git clone https://github.com/devslaweekq/claude-docker.git
cd claude-docker
cp .env.example .env && chmod 600 .env
# set PROJECT_DIRS and CLAUDE_CODE_OAUTH_TOKEN in .env, then:
./launcher
```

## Quickstart — image only

```bash
mkdir -p ~/claude-docker/{home,certs}
chmod 700 ~/claude-docker

cat > ~/claude-docker/.env <<'EOF'
CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-...

# Optional proxy:
# HTTP_PROXY=http://USER:PASSWORD@proxy.example.com:8888
# HTTPS_PROXY=http://USER:PASSWORD@proxy.example.com:8888
NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16

# Optional integrations:
# GH_TOKEN=
# CONTEXT7_API_KEY=
EOF

chmod 600 ~/claude-docker/.env
docker pull slaweekq/claude-docker:latest
docker run --rm -it --network host --user 0:0 \
  --env-file ~/claude-docker/.env \
  -v "$HOME/projects:/workspace" \
  -v ~/claude-docker/home:/home/node \
  slaweekq/claude-docker:latest
```
