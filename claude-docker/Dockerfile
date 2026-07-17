FROM node:24.18.0-slim

# Base tools + git/PR + DB clients (psql, mysql, redis-cli) + GitHub CLI + Claude Code.
# User node (uid 1000) already exists in the image.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git git-lfs openssh-client ca-certificates curl less jq gnupg fzf \
      postgresql-client default-mysql-client redis-tools \
      ruby unzip locales xclip wl-clipboard \
 && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
 && locale-gen

RUN install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
 && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update && apt-get install -y --no-install-recommends gh \
 && rm -rf /var/lib/apt/lists/*

# Claude Code in /usr/local — image seed; runtime prefers ~/.npm-global (writable, on volume).
RUN npm install -g @anthropic-ai/claude-code@latest jimp \
 && npm cache clean --force \
 && mkdir -p /home/node/.claude /home/node/.npm-global /workspace \
 && chown -R node:node /home/node /workspace

# Bun — copy ready binary from official image (faster and more reliable than curl script)
COPY --from=oven/bun:latest /usr/local/bin/bun /usr/local/bin/bun
COPY --from=oven/bun:latest /usr/local/bin/bunx /usr/local/bin/bunx

# uv — copy ready binary from official image (enables uvx for Python-based MCP servers)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
COPY --from=ghcr.io/astral-sh/uv:latest /uvx /usr/local/bin/uvx

# Startup: TLS proxy certs (compose mount) → menu as node
COPY scripts/builds/update-certs.sh /usr/local/bin/update-certs.sh
COPY scripts/builds/ensure-claude-cli.sh /usr/local/bin/ensure-claude-cli.sh
COPY scripts/builds/menu.sh /usr/local/bin/claude-launch
COPY scripts/builds/sessions.js /usr/local/bin/claude-sessions
RUN chmod +x /usr/local/bin/update-certs.sh /usr/local/bin/ensure-claude-cli.sh \
      /usr/local/bin/claude-launch /usr/local/bin/claude-sessions

# Common defaults (settings + MCP) — seeded into ~/.claude at startup (see menu.sh)
COPY claude-defaults/ /opt/claude-defaults/

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Force UTF-8 character-set mode in xterm.js (VS Code terminal) for every interactive bash session.
RUN echo "printf '\\033%%G'" >> /home/node/.bashrc

WORKDIR /workspace
USER root
ENTRYPOINT ["/usr/local/bin/update-certs.sh"]
