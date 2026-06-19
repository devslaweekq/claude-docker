#!/usr/bin/env bash
# User-writable npm global prefix on $HOME (compose volume) so `claude update` persists.
set -euo pipefail

export NPM_CONFIG_PREFIX="${NPM_CONFIG_PREFIX:-$HOME/.npm-global}"
[ -d "$NPM_CONFIG_PREFIX"] || mkdir -p "$NPM_CONFIG_PREFIX"
export PATH="$NPM_CONFIG_PREFIX/bin${PATH:+:$PATH}"

if [ ! -x "$NPM_CONFIG_PREFIX/bin/claude" ]; then
  echo "==> Seeding Claude Code in $NPM_CONFIG_PREFIX …" >&2
  npm install -g @anthropic-ai/claude-code@latest
fi
