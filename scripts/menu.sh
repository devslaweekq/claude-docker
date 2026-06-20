#!/usr/bin/env bash
# Container startup menu: banner + fzf picker (type to filter, ↑↓ to select, Enter)
# over /workspace subdirs (newest first) + scratch / new folder / bash.
# Falls back to numeric menu (read) when fzf is unavailable.
set -euo pipefail

# shellcheck disable=SC1091
source /usr/local/bin/ensure-claude-cli.sh

WS="${WORKSPACE_DIR:-/workspace}"

# empty proxy vars from .env must not override direct mode
for _p in HTTP_PROXY HTTPS_PROXY http_proxy https_proxy; do
  [ -z "${!_p:-}" ] && unset "$_p"
done

# --- seed shared defaults: settings (once), mcpServers (sync from repo) ---
DEF="${CLAUDE_DEFAULTS:-/opt/claude-defaults}"
[ -d "$HOME/.claude" ] || mkdir -p "$HOME/.claude"
if [ ! -f "$HOME/.claude/settings.json" ] && [ -f "$DEF/settings.json" ]; then
  cp "$DEF/settings.json" "$HOME/.claude/settings.json"
fi

# slash commands: copy any shipped command not already present (never clobber user edits)
if [ -d "$DEF/commands" ]; then
[ -d "$HOME/.claude/commands" ] || mkdir -p "$HOME/.claude/commands"
  cp -n "$DEF/commands/"*.md "$HOME/.claude/commands/" 2>/dev/null || true
fi

if [ -f "$DEF/mcp.json" ]; then
  [ -f "$HOME/.claude.json" ] || echo '{}' > "$HOME/.claude.json"
  tmp="$(mktemp)"
  jq --slurpfile d "$DEF/mcp.json" '.mcpServers = ($d[0].mcpServers + (.mcpServers // {}))' "$HOME/.claude.json" > "$tmp" && mv "$tmp" "$HOME/.claude.json"
fi

# OAuth token in .env: skip first-run login wizard (Claude Code ignores env token in onboarding)
if [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
  [ -f "$HOME/.claude.json" ] || echo '{}' > "$HOME/.claude.json"
  tmp="$(mktemp)"
  jq '.hasCompletedOnboarding = true' "$HOME/.claude.json" > "$tmp" && mv "$tmp" "$HOME/.claude.json"
fi

# workspace subdirs, newest (by mtime) first
mapfile -t dirs < <(find "$WS" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -printf '%T@\t%p\n' 2>/dev/null | sort -rn | cut -f2-)

SCRATCH="•  Temporary session (scratch, not saved)"
NEWDIR="•  Create new folder in /workspace…"
BASHC="•  bash in container"
SCRATCH_DIR="$HOME/scratch"

O=$'\033[38;5;208m'; B=$'\033[1m'; D=$'\033[2m'; R=$'\033[0m'   # orange / bold / dim / reset

print_header() {
  printf '\033c\n'
  printf '   %s╭────────────────────────────────╮%s\n' "$O" "$R"
  printf '   %s│ %sClaude Docker%s                  │%s\n' "$O" "$B" "$O" "$R"
  printf '   %s│ %sisolated Claude Code in Docker%s%s │%s\n' "$O" "$D" "$R" "$O" "$R"
  printf '   %s│ %st.me/slaweekq%s%s                  │%s\n' "$O" "$D" "$R" "$O" "$R"
  printf '   %s╰────────────────────────────────╯%s\n\n' "$O" "$R"
}

# Shown in the menu when /workspace has no project dirs (PROJECT_DIRS unset, or its parents have no subdirs).
no_projects_hint() {
  [ ${#dirs[@]} -eq 0 ] || return 0
  printf '   %sNo projects in /workspace — set PROJECT_DIRS in .env to mount them.%s\n' "$D" "$R"
  printf '   %sScratch and bash still work below.%s\n\n' "$D" "$R"
}

# full terminal reset before/after claude (RIS — no ncurses/reset dependency)
run_claude() {
  printf '\033c'
  claude "$@"
  local rc=$?
  printf '\033c'
  exit "$rc"
}

prepare_scratch() {
  [ -d "$SCRATCH_DIR" ] || mkdir -p "$SCRATCH_DIR"
  if [ -z "${SCRATCH_BIND_MOUNT:-}" ]; then
    find "$SCRATCH_DIR" -mindepth 1 -maxdepth 1 ! -name '.*' -exec rm -rf {} + 2>/dev/null || true
  fi
  cd "$SCRATCH_DIR" || { echo "  Scratch dir not available: $SCRATCH_DIR" >&2; exit 1; }
}

make_new_dir() {
  local name
  read -rp "  New folder name: " name
  if [ -z "$name" ] || [[ "$name" == */* ]] || [[ "$name" == .* ]]; then
    echo "  Invalid name." >&2
    return 1
  fi
  [ -d "$WS/$name" ] || mkdir -p "$WS/$name"
  cd "$WS/$name"
  run_claude
}

SESSIONS_BIN="${CLAUDE_SESSIONS_BIN:-claude-sessions}"
NEWSESS="__NEW__"   # special id for the "new session" row in the unified list

# pick folder -> single page: "New session" + saved sessions (resume)
# optional --back-on-esc: Esc returns to caller instead of exiting the container
start_in_dir() {
  local back_on_esc=0
  [ "${2:-}" = "--back-on-esc" ] && back_on_esc=1

  cd "$1"
  print_header
  if ! command -v fzf >/dev/null 2>&1; then
    echo
    echo "  1) New session"
    echo "  2) Resume (pick from history)"
    [ "$back_on_esc" -eq 1 ] && echo "  0) Back to main menu"
    read -rp "  Choice [1-2, default 1]: " sub
    case "${sub:-1}" in
      0) [ "$back_on_esc" -eq 1 ] && return 0 || run_claude ;;
      2) run_claude --resume ;;
      *) run_claude ;;
    esac
    return
  fi

  local list line id saved
  list="$NEWSESS"$'\t'"•  New session"
  if command -v "$SESSIONS_BIN" >/dev/null 2>&1; then
    saved="$("$SESSIONS_BIN" "$1" | sed 's/\t/\t•  /')"
    [ -n "$saved" ] && list="$list"$'\n'"$saved"
  fi

  line="$(printf '%s\n' "$list" \
    | fzf --height=60% --reverse --border=rounded --pointer='▶' \
          --color='pointer:208,prompt:208' \
          --delimiter='\t' --with-nth=2 \
          --prompt="$(basename "$1") ▸ " \
          --header='new session or resume · Enter · Esc — back' \
          --preview="[ {1} = $NEWSESS ] && echo '  New session in $1' || $SESSIONS_BIN --preview '$1' {1}" \
          --preview-window='down:45%:wrap' --no-multi)" || line=""
  if [ -z "$line" ]; then
    [ "$back_on_esc" -eq 1 ] && return 0
    exit 0
  fi
  id="${line%%$'\t'*}"
  if [ "$id" = "$NEWSESS" ]; then run_claude; else run_claude --resume "$id"; fi
}

# temporary (scratch) session; optional $1 — note shown before start
run_scratch() {
  if [ -n "${1:-}" ]; then printf '\033c\n  %s\n' "$1"; sleep 1.5; fi
  prepare_scratch
  run_claude
}

# --- direct launch (launcher passes target from host cwd) ---
case "${1:-}" in
  --exec)        shift; exec claude "$@" ;;   # passthrough: run `claude …` and exit (no menu, no screen reset)
  --scratch)     run_scratch "${2:-}" ;;
  /workspace/*)
    if [ -d "$1" ]; then
      start_in_dir "$1" --back-on-esc
      # Esc pressed — fall through to main menu
    else
      echo "  Workspace path not found: $1" >&2
      exit 1
    fi
    ;;
esac

# --- numeric fallback without fzf ---
show_numeric_menu() {
  print_header
  no_projects_hint
  echo "  1) Temporary session (scratch, not saved)"
  echo "  2) Create new folder in /workspace"
  local n=2 d choice bash_opt
  for d in "${dirs[@]}"; do
    n=$((n + 1))
    printf "  %d) Run claude in %s\n" "$n" "$d"
  done
  bash_opt=$((n + 1))
  printf "  %d) bash in container\n" "$bash_opt"
  read -rp "  Choice [1-$bash_opt]: " choice
  if [ "$choice" = "1" ]; then
    prepare_scratch; run_claude
  elif [ "$choice" = "2" ]; then
    make_new_dir || true
  elif [ "$choice" = "$bash_opt" ]; then
    cd "$WS"; exec bash
  elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 3 ] && [ "$choice" -le "$n" ]; then
    start_in_dir "${dirs[$((choice - 3))]}"
  else
    echo "  Invalid choice." >&2; exit 1
  fi
}

# --- fzf menu (loops back from session picker on Esc) ---
show_fzf_menu() {
  while true; do
    print_header
    no_projects_hint
    local dir_items=() choice
    for d in "${dirs[@]}"; do dir_items+=("•  $d"); done

    choice="$(printf '%s\n' "$SCRATCH" "$NEWDIR" "${dir_items[@]}" "$BASHC" \
      | fzf --height=60% --reverse --border=rounded --pointer='▶' \
            --color='pointer:208,prompt:208' --prompt='▸ ' \
            --header='type to search · ↑↓ select · Enter · Esc — quit' \
            --no-multi)" || choice=""

    case "$choice" in
      "")          exit 0 ;;
      "$SCRATCH")  run_scratch ;;
      "$BASHC")    cd "$WS"; exec bash ;;
      "$NEWDIR")   make_new_dir || continue ;;
      '•  /'*)     start_in_dir "${choice#•  }" --back-on-esc || continue ;;
      *)           echo "  Invalid choice." >&2; exit 1 ;;
    esac
    break
  done
}

if ! command -v fzf >/dev/null 2>&1; then
  show_numeric_menu
else
  show_fzf_menu
fi
