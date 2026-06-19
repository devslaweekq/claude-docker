FROM node:24.17.0-slim

# Base tools + git/PR + DB clients (psql, mysql, redis-cli) + GitHub CLI + Claude Code.
# User node (uid 1000) already exists in the image.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git git-lfs openssh-client ca-certificates curl less jq gnupg fzf \
      postgresql-client default-mysql-client redis-tools \
      ruby unzip

RUN install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
 && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update && apt-get install -y --no-install-recommends gh \
 && rm -rf /var/lib/apt/lists/*

# Claude Code in /usr/local — image seed; runtime prefers ~/.npm-global (writable, on volume).
RUN npm install -g @anthropic-ai/claude-code@latest \
 && npm cache clean --force \
 && mkdir -p /home/node/.claude /home/node/.npm-global /workspace \
 && chown -R node:node /home/node /workspace

# Bun — copy ready binary from official image (faster and more reliable than curl script)
COPY --from=oven/bun:latest /usr/local/bin/bun /usr/local/bin/bun
COPY --from=oven/bun:latest /usr/local/bin/bunx /usr/local/bin/bunx

# Startup: TLS proxy certs (compose mount) → menu as node
COPY scripts/update-certs.sh /usr/local/bin/update-certs.sh
COPY scripts/ensure-claude-cli.sh /usr/local/bin/ensure-claude-cli.sh
COPY scripts/menu.sh /usr/local/bin/claude-launch
COPY scripts/sessions.js /usr/local/bin/claude-sessions
RUN chmod +x /usr/local/bin/update-certs.sh /usr/local/bin/ensure-claude-cli.sh \
      /usr/local/bin/claude-launch /usr/local/bin/claude-sessions

# Common defaults (settings + MCP) — seeded into ~/.claude at startup (see menu.sh)
COPY claude-defaults/ /opt/claude-defaults/

WORKDIR /workspace
USER root
ENTRYPOINT ["/usr/local/bin/update-certs.sh"]
