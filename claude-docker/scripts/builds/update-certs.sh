#!/usr/bin/env bash
# Entrypoint: optional TLS proxy CA from compose mount (./certs → /tmp/certs-input), then claude-launch as node.
set -euo pipefail

if [ -d /tmp/certs-input ]; then
  found=0
  for f in /tmp/certs-input/*.crt; do
    [ -f "$f" ] || continue
    cp "$f" /usr/local/share/ca-certificates/
    found=1
  done
  if [ "$found" = 1 ]; then
    # Debian update-ca-certificates is noisy (rehash warning on ca-certificates.crt bundle); suppress.
    update-ca-certificates >/dev/null 2>&1
  fi
fi

# -p keeps compose .env vars; force HOME so node never inherits /root from user: "0:0"
export HOME=/home/node
exec runuser -u node -g node -p -- /usr/local/bin/claude-launch "$@"
