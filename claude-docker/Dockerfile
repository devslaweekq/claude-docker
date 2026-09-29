FROM node:24.18.0-slim

# Base tools + git/PR + DB clients (psql, mysql, redis-cli) + GitHub CLI + Claude Code.
# User node (uid 1000) already exists in the image.
# One RUN for both apt-get passes (the second needs curl+gnupg from the first to add the
# GitHub CLI repo) so /var/lib/apt/lists is cleaned exactly once, at the end: cleaning it in
# an earlier, separate RUN wouldn't shrink that layer's diff, since Docker layers are
# immutable — a later layer's deletion only hides the files, it doesn't reclaim the space.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git git-lfs openssh-client ca-certificates curl less jq gnupg fzf \
      postgresql-client default-mysql-client redis-tools \
      unzip locales xclip wl-clipboard \
 && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
 && locale-gen \
 && install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
 && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update && apt-get install -y --no-install-recommends gh \
 && rm -rf /var/lib/apt/lists/*

# Claude Code is installed at runtime by ensure-claude-cli.sh into ~/.npm-global (on volume, node user).
# That script always runs before `claude` is invoked (menu.sh sources it under set -e), so a
# build-time copy here is never read: /home/node is entirely bind-mounted from the host at
# container start, and PATH always prefers ~/.npm-global — dead weight, not a fallback.
RUN npm install -g jimp \
 && npm cache clean --force \
 && mkdir -p /home/node/.claude /home/node/.npm-global /workspace \
 && chown -R node:node /home/node /workspace

# Playwright + Google Chrome, baked in so @playwright/mcp works out of the box (no runtime download).
# `install chrome` places Chrome at /opt/google/chrome/chrome — the path the MCP server's default
# `chrome` channel looks for. Google ships no Linux arm64 Chrome, so arm64 builds fall back to
# Chromium (browsers under /opt/ms-playwright, not /home/node, which is bind-mounted at runtime).
# --with-deps pulls the system libraries; lists are cleaned in the same RUN so the layer stays small.
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright
RUN npm install -g playwright \
 && if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
      playwright install --with-deps chrome; \
    else \
      playwright install --with-deps chromium; \
    fi \
 && chmod -R a+rX /opt/ms-playwright 2>/dev/null || true \
 && npm cache clean --force \
 && rm -rf /var/lib/apt/lists/*

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
