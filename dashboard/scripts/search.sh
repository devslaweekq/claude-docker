#!/usr/bin/env bash
# Full-text search across (or within one) Claude Code session transcript, backed
# by ripgrep. Query and scope always arrive as discrete argv elements (never a
# constructed shell string), so a query containing shell metacharacters is safe.
set -euo pipefail

PROJECTS_DIR="$HOME/.claude/projects"
RESULT_CAP=50

usage() {
  echo 'Usage: claude-dashboard-search --query "<text>" --scope all|session [--slug <slug>]' >&2
  exit 1
}

query="" scope="" slug=""
while [ $# -gt 0 ]; do
  case "$1" in
    --query) query="${2:-}"; shift 2 ;;
    --scope) scope="${2:-}"; shift 2 ;;
    --slug) slug="${2:-}"; shift 2 ;;
    *) usage ;;
  esac
done

[ -n "$query" ] || usage
case "$scope" in
  all) ;;
  session) [ -n "$slug" ] || usage ;;
  *) usage ;;
esac

if [ "$scope" = session ]; then
  case "$slug" in
    ""|*/*|*..*) echo "Invalid slug: $slug" >&2; exit 1 ;;
  esac
  search_root="$PROJECTS_DIR/$slug"
else
  search_root="$PROJECTS_DIR"
fi

[ -d "$search_root" ] || { echo '[]'; exit 0; }

# Same best-effort heuristic as sessions.sh: prefer a real cwd recorded inside
# the transcript, else naively reverse the slug's '/' -> '-' slugification.
reconstruct_cwd() {
  local slug="$1" jsonl="${2:-}" cwd=""
  if [ -n "$jsonl" ] && [ -f "$jsonl" ]; then
    cwd="$(jq -R -r 'fromjson? | select(.cwd != null and .cwd != "") | .cwd' "$jsonl" 2>/dev/null | head -1 || true)"
  fi
  [ -n "$cwd" ] || cwd="${slug//-//}"
  printf '%s' "$cwd"
}

declare -A name_cache=()
get_name_for_session() {
  local slug="$1" session_id="$2" cache_key="$slug/$session_id"
  if [ -n "${name_cache[$cache_key]:-}" ]; then
    printf '%s' "${name_cache[$cache_key]}"
    return 0
  fi
  local custom name
  custom="$(claude-dashboard-names get "$slug" "$session_id" 2>/dev/null || true)"
  if [ -n "$custom" ]; then
    name="$custom"
  else
    name="$(basename -- "$(reconstruct_cwd "$slug" "$PROJECTS_DIR/$slug/$session_id.jsonl")")"
  fi
  name_cache[$cache_key]="$name"
  printf '%s' "$name"
}

# The project a session belongs to, for "<project> › <session>" result labels —
# derived once per slug from whichever of its sessions is cheapest to read.
declare -A project_name_cache=()
get_project_name() {
  local slug="$1"
  if [ -n "${project_name_cache[$slug]:-}" ]; then
    printf '%s' "${project_name_cache[$slug]}"
    return 0
  fi
  local any_jsonl name
  any_jsonl="$(find "$PROJECTS_DIR/$slug" -maxdepth 1 -type f -name '*.jsonl' 2>/dev/null | head -1)"
  name="$(basename -- "$(reconstruct_cwd "$slug" "$any_jsonl")")"
  project_name_cache[$slug]="$name"
  printf '%s' "$name"
}

# Readable rendering of one matched JSONL line, same extraction heuristic as
# sessions.sh preview: message text if the line parses as message-shaped JSON,
# else a truncated raw fallback.
render_match() {
  local raw="$1" text=""
  if printf '%s' "$raw" | jq -e 'type == "object" and has("message") and (.message|type) == "object"' >/dev/null 2>&1; then
    text="$(printf '%s' "$raw" | jq -r '
        (.message.content) as $c
      | if ($c|type) == "string" then $c
        elif ($c|type) == "array" then ([$c[]? | select(.type == "text") | (.text // "")] | join(" "))
        else "" end' 2>/dev/null || true)"
  fi
  [ -n "${text// /}" ] || text="$raw"
  printf '%s' "$text" | tr '\n' ' ' | cut -c1-200
}

results=()
count=0
while IFS=: read -r fpath lno rest; do
  [ "$count" -lt "$RESULT_CAP" ] || break
  rel="${fpath#"$PROJECTS_DIR"/}"
  match_slug="${rel%%/*}"
  match_file="${rel#*/}"
  # Only match top-level <session-id>.jsonl files — skip a session's sidecar
  # subagent/sidechain directory and anything else nested under a project.
  case "$match_file" in
    */*) continue ;;
    *.jsonl) ;;
    *) continue ;;
  esac
  match_session="${match_file%.jsonl}"

  line_text="$(render_match "$rest")"
  [ -n "$line_text" ] || continue
  name="$(get_name_for_session "$match_slug" "$match_session")"
  project="$(get_project_name "$match_slug")"
  results+=("$(jq -n --arg slug "$match_slug" --arg sessionId "$match_session" --arg name "$name" --arg project "$project" --arg line "$line_text" --argjson lineNumber "$lno" \
    '{slug:$slug, sessionId:$sessionId, name:$name, project:$project, line:$line, lineNumber:$lineNumber}')")
  count=$((count + 1))
done < <(rg --line-number --no-heading --fixed-strings -i -- "$query" "$search_root" 2>/dev/null || true)

if [ "${#results[@]}" -eq 0 ]; then
  echo '[]'
else
  printf '%s\n' "${results[@]}" | jq -s '.'
fi
