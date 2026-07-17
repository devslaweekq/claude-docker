#!/usr/bin/env bash
# Manages the custom display-name store for dashboard sessions: a flat JSON map
# of "slug/sessionId" -> user-chosen name at $HOME/.claude/dashboard-names.json,
# guarded by flock since the gateway can process concurrent rename requests.
set -euo pipefail

STORE="$HOME/.claude/dashboard-names.json"
LOCK="$HOME/.claude/dashboard-names.json.lock"

usage() {
  echo "Usage: claude-dashboard-names <get|set|delete> <slug> <sessionId> [name]" >&2
  exit 1
}

cmd="${1:-}"
slug="${2:-}"
session_id="${3:-}"
[ -n "$cmd" ] && [ -n "$slug" ] && [ -n "$session_id" ] || usage
key="$slug/$session_id"

mkdir -p "$(dirname "$STORE")"

case "$cmd" in
  get)
    # Absent store or absent key are both "no custom name" — empty stdout, exit 0.
    [ -f "$STORE" ] || exit 0
    jq -r --arg k "$key" '.[$k] // empty' "$STORE" 2>/dev/null || true
    ;;
  set)
    shift 3
    name="$*"
    [ -n "$name" ] || usage
    (
      flock 9
      [ -f "$STORE" ] || echo '{}' > "$STORE"
      tmp="$(mktemp "${STORE}.XXXXXX")"
      jq --arg k "$key" --arg v "$name" '.[$k] = $v' "$STORE" > "$tmp"
      mv "$tmp" "$STORE"
    ) 9>"$LOCK"
    ;;
  delete)
    (
      flock 9
      if [ -f "$STORE" ]; then
        tmp="$(mktemp "${STORE}.XXXXXX")"
        jq --arg k "$key" 'del(.[$k])' "$STORE" > "$tmp"
        mv "$tmp" "$STORE"
      fi
    ) 9>"$LOCK"
    ;;
  *)
    usage
    ;;
esac
