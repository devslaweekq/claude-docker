#!/usr/bin/env bash
# Core data script for the dashboard: lists Claude Code session transcripts,
# previews a transcript's recent messages, and deletes one transcript.
#
# A "session" here is one <session-id>.jsonl file under a project directory —
# the same granularity claude-launch's own resume menu (sessions.js) uses.
# A project directory commonly holds several sessions, so listing/deleting
# operates per-file, never per-directory.
set -euo pipefail
shopt -s nullglob

PROJECTS_DIR="$HOME/.claude/projects"
STATS_FILE="$HOME/.claude/dashboard-stats.json"
CACHE_FILE="$HOME/.claude/dashboard-sessions-cache.json"
CACHE_LOCK="$HOME/.claude/dashboard-sessions-cache.json.lock"

usage() {
  echo "Usage: claude-dashboard-sessions <list|preview|delete> [slug] [sessionId]" >&2
  exit 1
}

# A slug/session id is one path segment — reject anything that could escape
# PROJECTS_DIR (path separators, "..") before it's used to build a path.
validate_id() {
  case "$1" in
    ""|*/*|*..*) echo "Invalid id: $1" >&2; exit 1 ;;
  esac
}

# Single defensive pass over a transcript: recovers its recorded cwd, its
# ai-generated title, and its first real user message (used as a title
# fallback before one exists). Malformed lines are skipped individually
# (fromjson?) rather than aborting the whole parse, since a transcript can
# end mid-write if the session was killed.
session_meta() {
  local file="$1"
  jq -R 'fromjson?' "$file" 2>/dev/null | jq -s -c '
    map(select(type == "object")) as $e
    | ($e | map(select(.cwd? and .cwd != "")) | (.[0].cwd // "")) as $cwd
    | ($e | map(select(.type == "ai-title" and .aiTitle != null and .aiTitle != "")) | (.[0].aiTitle // "")) as $aiTitle
    | ($e
        | map(select(.type == "user" and .message.role? == "user"))
        | map(
            (.message.content) as $c
            | (if ($c|type) == "string" then $c
               elif ($c|type) == "array" then ([$c[]? | select(.type == "text") | (.text // "")] | join(" "))
               else "" end)
            | gsub("\\s+"; " ")
          )
        | map(select(length > 0 and (startswith("<")|not) and (startswith("/")|not) and (startswith("Caveat:")|not)))
        | (.[0] // "")
      ) as $firstUser
    | {cwd: $cwd, aiTitle: $aiTitle, firstUser: $firstUser}
  ' 2>/dev/null
}

resolve_name() {
  local slug="$1" session_id="$2" cwd="$3" ai_title="$4" first_user="$5" custom
  custom="$(claude-dashboard-names get "$slug" "$session_id" 2>/dev/null || true)"
  if [ -n "$custom" ]; then
    printf '%s' "$custom"
  elif [ -n "$ai_title" ]; then
    printf '%.80s' "$ai_title"
  elif [ -n "$first_user" ]; then
    printf '%.80s' "$first_user"
  else
    basename -- "$cwd"
  fi
}

# `launcher` labels a session container with the matched PROJECT_DIRS subfolder
# name — the "/workspace/<name>" segment of the container-side cwd, however deep
# the session actually cd'd into it — or "scratch" for a scratch/root session
# (whose container-side cwd is always /home/node/scratch, regardless of the host
# directory bind-mounted there). Recover that same key from the transcript's cwd
# so a session correlates to its container even from a subdirectory. Note this
# is necessarily project-level, not session-level: several sessions in the same
# project directory share one container and therefore one status/usage reading.
project_key() {
  local cwd="$1"
  case "$cwd" in
    /workspace/*)
      cwd="${cwd#/workspace/}"
      printf '%s' "${cwd%%/*}"
      ;;
    *)
      printf 'scratch'
      ;;
  esac
}

container_status() {
  local project_key="$1" entry
  if [ -f "$STATS_FILE" ]; then
    entry="$(jq -c --arg k "$project_key" '.containers[$k] // empty' "$STATS_FILE" 2>/dev/null || true)"
  fi
  if [ -n "${entry:-}" ]; then
    local cpu mem
    cpu="$(printf '%s' "$entry" | jq -r '.cpuPercent // empty' 2>/dev/null || true)"
    mem="$(printf '%s' "$entry" | jq -r '.memUsedMb // empty' 2>/dev/null || true)"
    printf 'running\t%s\t%s' "${cpu:-null}" "${mem:-null}"
  else
    printf 'stopped\tnull\tnull'
  fi
}

# Prints "<branch>\t<dirty>"; both empty/false when cwd isn't a resolvable git repo.
git_info() {
  local cwd="$1" branch="" dirty=false
  if [ -n "$cwd" ] && [ -d "$cwd" ] && git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch="$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
    [ -z "$(git -C "$cwd" status --porcelain 2>/dev/null)" ] || dirty=true
  fi
  printf '%s\t%s' "$branch" "$dirty"
}

tokens_used() {
  jq -R 'fromjson?' "$1" 2>/dev/null \
    | jq -s '[.[] | select(.message.usage? != null)
              | (.message.usage.input_tokens // 0) + (.message.usage.output_tokens // 0)]
              | if length == 0 then null else add end' 2>/dev/null \
    || echo null
}

# session_meta + tokens_used each do a full-file jq parse — real cost for a
# multi-MB transcript. The dashboard polls this list every ~8s, and most
# sessions are idle history, not the one actively being appended to — without
# caching, EVERY session gets fully reparsed on EVERY poll forever, which is
# what actually drives sustained high CPU, not anything inherent to the task.
# Cache by the file's mtime+size; only recompute when a transcript actually
# grew since the last poll.
cached_session_data() {
  local key="$1" file="$2" mtime="$3" size="$4" entry
  if [ -f "$CACHE_FILE" ]; then
    entry="$(jq -c --arg k "$key" '.[$k] // empty' "$CACHE_FILE" 2>/dev/null || true)"
  fi
  if [ -n "${entry:-}" ] \
     && [ "$(printf '%s' "$entry" | jq -r '.mtime // empty' 2>/dev/null)" = "$mtime" ] \
     && [ "$(printf '%s' "$entry" | jq -r '.size // empty' 2>/dev/null)" = "$size" ]; then
    printf '%s' "$entry"
    return 0
  fi

  local meta cwd ai_title first_user tokens
  meta="$(session_meta "$file")"
  [ -n "$meta" ] || meta='{}'
  cwd="$(printf '%s' "$meta" | jq -r '.cwd // empty' 2>/dev/null || true)"
  ai_title="$(printf '%s' "$meta" | jq -r '.aiTitle // empty' 2>/dev/null || true)"
  first_user="$(printf '%s' "$meta" | jq -r '.firstUser // empty' 2>/dev/null || true)"
  tokens="$(tokens_used "$file")"
  [ -n "$tokens" ] || tokens=null

  entry="$(jq -n --arg mtime "$mtime" --arg size "$size" --arg cwd "$cwd" \
    --arg aiTitle "$ai_title" --arg firstUser "$first_user" --argjson tokensUsed "$tokens" \
    '{mtime:$mtime, size:$size, cwd:$cwd, aiTitle:$aiTitle, firstUser:$firstUser, tokensUsed:$tokensUsed}')"

  (
    flock 9
    local current tmp
    current="$([ -f "$CACHE_FILE" ] && cat "$CACHE_FILE" 2>/dev/null || echo '{}')"
    [ -n "$current" ] || current='{}'
    tmp="$(mktemp "${CACHE_FILE}.XXXXXX")"
    if jq --arg k "$key" --argjson v "$entry" '.[$k] = $v' <<< "$current" > "$tmp" 2>/dev/null; then
      mv "$tmp" "$CACHE_FILE"
    else
      rm -f "$tmp"
    fi
  ) 9>"$CACHE_LOCK"

  printf '%s' "$entry"
}

# Renders one raw JSONL line as short human text ("role: text"). The caller
# already filters to user/assistant-typed lines, so the "not message-shaped"
# branch below is a safety net, not the common case. Returns non-zero (caller
# must skip) when the line parses fine but carries no text (e.g. a tool-only
# assistant turn).
render_or_skip() {
  local raw="$1"
  if ! printf '%s' "$raw" | jq -e 'type == "object" and has("message") and (.message|type) == "object"' >/dev/null 2>&1; then
    printf '%s' "$raw" | tr '\n' ' ' | cut -c1-200
    return 0
  fi
  local text
  text="$(printf '%s' "$raw" | jq -r '
      (.message.content) as $c
    | if ($c|type) == "string" then $c
      elif ($c|type) == "array" then ([$c[]? | select(.type == "text") | (.text // "")] | join(" "))
      else "" end' 2>/dev/null || true)"
  text="$(printf '%s' "$text" | tr '\n' ' ')"
  [ -n "${text// /}" ] || return 1
  local role
  role="$(printf '%s' "$raw" | jq -r '.message.role // "?"' 2>/dev/null || echo "?")"
  printf '%.200s' "$role: $text"
}

list_cmd() {
  local -a objs=()
  local pdir jf

  for pdir in "$PROJECTS_DIR"/*/; do
    local slug
    slug="$(basename "$pdir")"

    for jf in "$pdir"*.jsonl; do
      [ -f "$jf" ] || continue
      local session_id
      session_id="$(basename "$jf" .jsonl)"

      # mtime/size are read exactly once per file per invocation and reused
      # everywhere below — for an actively-growing transcript (the session
      # you're using right now keeps appending to its own file), stat-ing
      # the same file twice in one run can return two different mtimes and
      # break any later exact-match comparison against it.
      local mtime size cache_entry cwd ai_title first_user tokens
      mtime="$(stat -c %Y "$jf" 2>/dev/null || echo 0)"
      size="$(stat -c %s "$jf" 2>/dev/null || echo 0)"
      cache_entry="$(cached_session_data "$slug/$session_id" "$jf" "$mtime" "$size")"
      cwd="$(printf '%s' "$cache_entry" | jq -r '.cwd // empty' 2>/dev/null || true)"
      [ -n "$cwd" ] || cwd="${slug//-//}"
      ai_title="$(printf '%s' "$cache_entry" | jq -r '.aiTitle // empty' 2>/dev/null || true)"
      first_user="$(printf '%s' "$cache_entry" | jq -r '.firstUser // empty' 2>/dev/null || true)"
      tokens="$(printf '%s' "$cache_entry" | jq -r '.tokensUsed // "null"' 2>/dev/null || echo null)"

      local pkey name
      pkey="$(project_key "$cwd")"
      name="$(resolve_name "$slug" "$session_id" "$cwd" "$ai_title" "$first_user")"

      local status cpu mem
      IFS=$'\t' read -r status cpu mem <<< "$(container_status "$pkey")"

      local gi branch dirty
      gi="$(git_info "$cwd")"
      branch="${gi%%$'\t'*}"
      dirty="${gi#*$'\t'}"

      # pkey rides along as an internal field for the post-processing pass
      # below (which session in a shared-container project is really live),
      # then gets stripped before the final response.
      objs+=("$(jq -n \
        --arg slug "$slug" --arg sessionId "$session_id" --arg name "$name" --arg cwd "$cwd" --arg status "$status" \
        --arg pkey "$pkey" \
        --argjson lastActivity "$mtime" --arg gitBranch "$branch" --argjson gitDirty "$dirty" \
        --argjson tokensUsed "$tokens" --argjson cpuPercent "$cpu" --argjson memUsedMb "$mem" \
        '{slug:$slug, sessionId:$sessionId, name:$name, cwd:$cwd, status:$status, pkey:$pkey, lastActivity:$lastActivity,
          gitBranch:$gitBranch, gitDirty:$gitDirty, tokensUsed:$tokensUsed,
          cpuPercent:$cpuPercent, memUsedMb:$memUsedMb}')")
    done
  done

  if [ "${#objs[@]}" -eq 0 ]; then
    echo '[]'
  else
    # A docker label only carries project-level identity, not which specific
    # session inside a project is being used — several sessions can share one
    # container, so container_status() above marks ALL of them "running"
    # whenever their shared project has a live container. Within each
    # project, keep "running" (and its live cpu/mem) on only the
    # most-recently-touched session — the one actually in use — and demote
    # every other session in that project back to stopped.
    printf '%s\n' "${objs[@]}" | jq -s '
      group_by(.pkey)
      | map(
          (map(select(.status == "running")) | max_by(.lastActivity)) as $active
          | map(
              if $active != null and .sessionId != $active.sessionId
              then .status = "stopped" | .cpuPercent = null | .memUsedMb = null
              else . end
            )
        )
      | flatten
      | map(del(.pkey))
      | sort_by(-.lastActivity)'
  fi
}

preview_cmd() {
  local slug="$1" session_id="$2" file
  file="$PROJECTS_DIR/$slug/${session_id}.jsonl"
  if [ ! -f "$file" ]; then echo '{"lines":[]}'; return 0; fi

  local -a rendered=()
  local raw line
  while IFS= read -r raw; do
    if line="$(render_or_skip "$raw")"; then
      rendered+=("$line")
    fi
  done < <(jq -R -c 'fromjson? | select(. != null and type == "object" and (.type == "user" or .type == "assistant"))' "$file" 2>/dev/null | tail -n 15)

  if [ "${#rendered[@]}" -eq 0 ]; then
    echo '{"lines":[]}'
  else
    printf '%s\n' "${rendered[@]}" | jq -R -s '{lines: (split("\n") | map(select(length > 0)))}'
  fi
}

delete_cmd() {
  local slug="$1" session_id="$2" file
  file="$PROJECTS_DIR/$slug/${session_id}.jsonl"
  rm -f -- "$file"
  # Sidecar dir (subagent/sidechain transcripts) shares the session's UUID name.
  rm -rf -- "${PROJECTS_DIR:?}/${slug:?}/${session_id:?}"
  command -v claude-dashboard-names >/dev/null 2>&1 && claude-dashboard-names delete "$slug" "$session_id" || true
  if [ -f "$CACHE_FILE" ]; then
    (
      flock 9
      local tmp
      tmp="$(mktemp "${CACHE_FILE}.XXXXXX")"
      if jq --arg k "$slug/$session_id" 'del(.[$k])' "$CACHE_FILE" > "$tmp" 2>/dev/null; then
        mv "$tmp" "$CACHE_FILE"
      else
        rm -f "$tmp"
      fi
    ) 9>"$CACHE_LOCK"
  fi
  exit 0
}

sub="${1:-}"
case "$sub" in
  list)
    list_cmd
    ;;
  preview)
    slug="${2:-}"; session_id="${3:-}"
    [ -n "$slug" ] && [ -n "$session_id" ] || usage
    validate_id "$slug"; validate_id "$session_id"
    preview_cmd "$slug" "$session_id"
    ;;
  delete)
    slug="${2:-}"; session_id="${3:-}"
    [ -n "$slug" ] && [ -n "$session_id" ] || usage
    validate_id "$slug"; validate_id "$session_id"
    delete_cmd "$slug" "$session_id"
    ;;
  *)
    usage
    ;;
esac
