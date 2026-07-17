#!/usr/bin/env bash
# Entrypoint for the `dashboard` compose service — validates config, then hands off
# to the Node gateway as the container's foreground process.
set -euo pipefail

if [ -z "${DASHBOARD_PASSWORD:-}" ]; then
  echo "ERROR: DASHBOARD_PASSWORD is not set. Refusing to start without authentication." >&2
  exit 1
fi

# exec replaces the shell so Docker's SIGTERM reaches Node directly.
exec node /usr/local/bin/claude-dashboard-gateway
