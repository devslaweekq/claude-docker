FROM node:24.18.0-slim

# Base tools for the gateway + watcher scripts (built by other agents, but their
# dependencies are fixed by contract): jq (JSON), ripgrep (transcript search),
# git (branch/dirty lookups), curl (health checks), bash (script interpreter).
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash git jq ripgrep curl ca-certificates locales \
 && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
 && locale-gen \
 && rm -rf /var/lib/apt/lists/*

# Docker CLI only (no daemon) — copied from the official docker:cli image rather than
# pulling in docker-ce-cli's apt repo, which is heavy for a slim base.
COPY --from=docker:cli /usr/local/bin/docker /usr/local/bin/docker

WORKDIR /opt/dashboard

COPY scripts/gateway-entrypoint.sh /usr/local/bin/claude-dashboard-serve
COPY scripts/gateway.js /usr/local/bin/claude-dashboard-gateway
COPY scripts/sessions.sh /usr/local/bin/claude-dashboard-sessions
COPY scripts/search.sh /usr/local/bin/claude-dashboard-search
COPY scripts/names.sh /usr/local/bin/claude-dashboard-names
COPY scripts/watcher-entrypoint.sh /usr/local/bin/claude-dashboard-watcher-serve
RUN chmod +x /usr/local/bin/claude-dashboard-serve /usr/local/bin/claude-dashboard-gateway \
      /usr/local/bin/claude-dashboard-sessions /usr/local/bin/claude-dashboard-search \
      /usr/local/bin/claude-dashboard-names /usr/local/bin/claude-dashboard-watcher-serve

COPY frontend/dashboard.html /opt/dashboard/dashboard.html

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Deliberate tradeoff: this image is shared by two compose services with different
# entrypoints. The `dashboard-watcher` service needs to read /var/run/docker.sock,
# whose host-side GID varies per host and can't be baked in at build time — so it
# runs as root. This is acceptable specifically for the watcher because it never
# listens on any port (no network-facing attack surface); the `dashboard` gateway
# service, which does listen, should be run as a non-root user via its compose
# `user:` override instead of relying on the image default.
USER root
