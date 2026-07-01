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

# Plugin marketplaces clone via git@github.com — container has no SSH keys; use HTTPS.
if ! git config --global --get-all url.https://github.com/.insteadof 2>/dev/null \
     | grep -qF 'git@github.com:'; then
  git config --global url."https://github.com/".insteadOf "git@github.com:"
fi

if [ ! -f "$HOME/.claude/settings.json" ] && [ -f "$DEF/settings.json" ]; then
  cp "$DEF/settings.json" "$HOME/.claude/settings.json"
fi

# slash commands: copy any shipped command not already present (never clobber user edits)
if [ -d "$DEF/commands" ]; then
[ -d "$HOME/.claude/commands" ] || mkdir -p "$HOME/.claude/commands"
  cp -n "$DEF/commands/"*.md "$HOME/.claude/commands/" 2>/dev/null || true
fi

# OAuth token in .env: skip first-run login wizard (Claude Code ignores env token in onboarding)
if [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
  [ -f "$HOME/.claude.json" ] || echo '{}' > "$HOME/.claude.json"
  tmp="$(mktemp)"
  jq '.hasCompletedOnboarding = true' "$HOME/.claude.json" > "$tmp" && mv "$tmp" "$HOME/.claude.json"
fi

# claude-mem plugin requires zod v4 but doesn't bundle it — install if missing.
_cm_dir="$HOME/.claude/plugins/cache/thedotmack/claude-mem"
if [ -d "$_cm_dir" ]; then
  _cm_ver=$(ls -1 "$_cm_dir" 2>/dev/null | sort -V | tail -1)
  if [ -n "$_cm_ver" ] && [ ! -f "$_cm_dir/$_cm_ver/node_modules/zod/package.json" ]; then
    echo "==> Fixing claude-mem plugin: installing zod …" >&2
    (cd "$_cm_dir/$_cm_ver" && npm install zod@'^4.4.3' --no-save --ignore-scripts >/dev/null 2>&1) || true
  fi
  unset _cm_ver
fi
unset _cm_dir

# workspace subdirs, newest (by mtime) first
mapfile -t dirs < <(find "$WS" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -printf '%T@\t%p\n' 2>/dev/null | sort -rn | cut -f2-)

SCRATCH="•  Temporary session (scratch, not saved)"
NEWDIR="•  Create new folder in /workspace…"
MCPCONF="⚙  Configure MCP servers"
BASHC="•  bash in container"
SCRATCH_DIR="$HOME/scratch"
MCP_CONF_FILE="$HOME/.claude-docker-mcp-configured"
MCP_MANAGED_FILE="$HOME/.claude-docker-mcp-managed"

O=$'\033[38;5;208m'; B=$'\033[1m'; D=$'\033[2m'; R=$'\033[0m'   # orange / bold / dim / reset

print_header() {
  printf '\033[3J\033[2J\033[H'
  printf '\033%%G'
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
  printf '\033[3J\033[2J\033[H'
  printf '\033%%G'
  claude "$@"
  local rc=$?
  printf '\033[3J\033[2J\033[H'
  printf '\033%%G'
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

# --- MCP server selection ---

# Remove previously managed MCP servers from ~/.claude.json
mcp_remove_managed() {
  [ -f "$MCP_MANAGED_FILE" ] || return 0
  [ -f "$HOME/.claude.json" ] || return 0
  local managed_json tmp
  managed_json="$(cat "$MCP_MANAGED_FILE")"
  tmp="$(mktemp)"
  jq --argjson mgd "$managed_json" \
     'if .mcpServers then .mcpServers |= with_entries(select(.key | IN($mgd[]) | not)) else . end' \
     "$HOME/.claude.json" > "$tmp" && mv "$tmp" "$HOME/.claude.json"
}

# Show fzf/numeric selection UI, apply selected servers, update managed list
mcp_select_and_apply() {
  local mcp_file="$DEF/mcp.json"
  [ -f "$mcp_file" ] || return 0

  local all_servers
  mapfile -t all_servers < <(jq -r '.mcpServers | keys | sort[]' "$mcp_file")
  [ ${#all_servers[@]} -eq 0 ] && return 0

  local selected_servers=()

  if command -v fzf >/dev/null 2>&1; then
    local selected
    selected="$(printf '%s\n' "${all_servers[@]}" | \
      fzf --multi --height=80% --reverse --border=rounded \
          --pointer='▶' --marker='✓' \
          --color='pointer:208,prompt:208,marker:208' \
          --prompt='MCP servers ▸ ' \
          --header='Tab — toggle · Ctrl+A — all · Enter — confirm · Esc — skip' \
          --bind='ctrl-a:toggle-all')" || selected=""
    [ -n "$selected" ] && mapfile -t selected_servers <<< "$selected"
  else
    print_header
    printf '   Configure MCP Servers\n\n'
    local i=1
    for s in "${all_servers[@]}"; do
      printf '  %2d) %s\n' "$i" "$s"
      i=$((i + 1))
    done
    printf '   A) All servers\n   Enter — skip all\n\n'
    local choice
    read -rp '  Select (space-separated numbers or A): ' choice
    if [ "${choice,,}" = "a" ] || [ "${choice,,}" = "all" ]; then
      selected_servers=("${all_servers[@]}")
    else
      for num in $choice; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#all_servers[@]}" ]; then
          selected_servers+=("${all_servers[$((num - 1))]}")
        fi
      done
    fi
  fi

  # Remove previously managed servers before applying new selection
  mcp_remove_managed

  [ -f "$HOME/.claude.json" ] || echo '{}' > "$HOME/.claude.json"

  if [ ${#selected_servers[@]} -gt 0 ]; then
    local selected_json tmp
    selected_json="$(printf '%s\n' "${selected_servers[@]}" | jq -R . | jq -s .)"
    tmp="$(mktemp)"
    jq --slurpfile d "$mcp_file" \
       --argjson sel "$selected_json" \
       '.mcpServers = (($d[0].mcpServers | with_entries(select(.key | IN($sel[])))) + (.mcpServers // {}))' \
       "$HOME/.claude.json" > "$tmp" && mv "$tmp" "$HOME/.claude.json"
    printf '%s\n' "${selected_servers[@]}" | jq -R . | jq -s . > "$MCP_MANAGED_FILE"
    printf '\n  Added MCP servers: %s\n' "${selected_servers[*]}"
  else
    echo '[]' > "$MCP_MANAGED_FILE"
    printf '\n  No MCP servers added.\n'
  fi

  touch "$MCP_CONF_FILE"
  sleep 1.2
}

# First-run MCP onboarding screen
mcp_onboarding() {
  printf '\033[3J\033[2J\033[H'
  printf '\033%%G'
  printf '   %s╭────────────────────────────────────────╮%s\n' "$O" "$R"
  printf '   %s│ %sMCP Server Setup%s                       │%s\n' "$O" "$B" "$O" "$R"
  printf '   %s│ %sChoose which MCP servers to enable%s     │%s\n' "$O" "$D" "$R" "$O" "$R"
  printf '   %s╰────────────────────────────────────────╯%s\n\n' "$O" "$R"
  mcp_select_and_apply
}

# --- end MCP section ---

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
  if [ -n "${1:-}" ]; then
    printf '\033[3J\033[2J\033[H'
    printf '\033%%G'
    printf '  %s\n' "$1"
    sleep 1.5
  fi
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
  local n=2 d choice mcp_opt bash_opt
  for d in "${dirs[@]}"; do
    n=$((n + 1))
    printf "  %d) Run claude in %s\n" "$n" "$d"
  done
  mcp_opt=$((n + 1))
  bash_opt=$((n + 2))
  printf "  %d) Configure MCP servers\n" "$mcp_opt"
  printf "  %d) bash in container\n" "$bash_opt"
  read -rp "  Choice [1-$bash_opt]: " choice
  if [ "$choice" = "1" ]; then
    prepare_scratch; run_claude
  elif [ "$choice" = "2" ]; then
    make_new_dir || true
  elif [ "$choice" = "$mcp_opt" ]; then
    mcp_select_and_apply; show_numeric_menu
  elif [ "$choice" = "$bash_opt" ]; then
    printf '\033[3J\033[2J\033[H'; printf '\033%%G'
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

    choice="$(printf '%s\n' "$SCRATCH" "$NEWDIR" "${dir_items[@]}" "$MCPCONF" "$BASHC" \
      | fzf --height=60% --reverse --border=rounded --pointer='▶' \
            --color='pointer:208,prompt:208' --prompt='▸ ' \
            --header='type to search · ↑↓ select · Enter · Esc — quit' \
            --no-multi)" || choice=""

    case "$choice" in
      "")           exit 0 ;;
      "$SCRATCH")   run_scratch ;;
      "$BASHC")     printf '\033[3J\033[2J\033[H'; printf '\033%%G'; cd "$WS"; exec bash ;;
      "$NEWDIR")    make_new_dir || continue ;;
      "$MCPCONF")   mcp_select_and_apply; continue ;;
      '•  /'*)      start_in_dir "${choice#•  }" --back-on-esc || continue ;;
      *)            echo "  Invalid choice." >&2; exit 1 ;;
    esac
    break
  done
}

# MCP onboarding: run once on first container start (after all functions are defined)
if [ -f "$DEF/mcp.json" ] && [ ! -f "$MCP_CONF_FILE" ]; then
  mcp_onboarding
fi

if ! command -v fzf >/dev/null 2>&1; then
  show_numeric_menu
else
  show_fzf_menu
fi
