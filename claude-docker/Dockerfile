FROM node:24.18.0-slim

# Base tools + git/PR + DB clients (psql, mysql, redis-cli) + GitHub CLI + Claude Code.
# Also: fonts and the shared libraries headless Chromium needs (libnss3, libgbm1, libasound2, ...), so
# an already-installed Playwright/Chrome in ~/.cache/ms-playwright can start inside the container (jpg/png/pdf
# rendering). The browser itself is NOT baked in, and neither is ffmpeg: Debian's ffmpeg drags in ~450 MB of
# dependencies (llvm, mesa, codecs), so video work must bring its own static ffmpeg. Packages renamed to *t64
# on newer Debian/Ubuntu are resolved in the loop below, so the same Dockerfile works with both naming schemes.
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
 && apt-get install -y --no-install-recommends \
      fonts-liberation fonts-noto-color-emoji fonts-dejavu-core \
      libnss3 libnspr4 libdbus-1-3 libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 \
      libxrender1 libxi6 libdrm2 libgbm1 libpango-1.0-0 libcairo2 libx11-6 libxext6 libxcb1 \
 && for group in "libasound2t64 libasound2" "libatk1.0-0t64 libatk1.0-0" "libatk-bridge2.0-0t64 libatk-bridge2.0-0" \
      "libatspi2.0-0t64 libatspi2.0-0" "libglib2.0-0t64 libglib2.0-0" "libcups2t64 libcups2"; do \
      for pkg in $group; do \
        if apt-cache show "$pkg" >/dev/null 2>&1; then apt-get install -y --no-install-recommends "$pkg"; break; fi; \
      done; \
    done \
 && rm -rf /var/lib/apt/lists/*

# Claude Code is installed at runtime by ensure-claude-cli.sh into ~/.npm-global (on volume, node user).
# That script always runs before `claude` is invoked (menu.sh sources it under set -e), so a
# build-time copy here is never read: /home/node is entirely bind-mounted from the host at
# container start, and PATH always prefers ~/.npm-global — dead weight, not a fallback.
RUN npm install -g jimp \
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
