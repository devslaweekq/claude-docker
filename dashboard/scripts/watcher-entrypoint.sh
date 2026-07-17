#!/usr/bin/env bash
# Entrypoint for the `dashboard-watcher` compose service.
#
# This container is the ONLY thing in the dashboard feature that mounts
# /var/run/docker.sock (read-only). It never listens on a port and never
# talks to the network — it just polls host + container stats, writes one
# JSON file to the shared volume, sleeps, repeats. The browser-facing
# `dashboard` gateway container reads that file; it never touches the
# socket itself, so a browser-side compromise there can't reach Docker.
set -uo pipefail

OUT_FILE="/home/node/.claude/dashboard-stats.json"
INTERVAL="${DASHBOARD_WATCH_INTERVAL:-4}"

is_number() { [[ "$1" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; }

# --- host CPU: classic two-sample /proc/stat delta ---------------------

read_cpu_stat() {
  awk '/^cpu / {print $2, $3, $4, $5, $6, $7, $8, $9}' /proc/stat
}

host_cpu_percent() {
  local s1 s2
  s1="$(read_cpu_stat)"
  sleep 0.1
  s2="$(read_cpu_stat)"
  awk -v s1="$s1" -v s2="$s2" 'BEGIN {
    split(s1, a, " "); split(s2, b, " ")
    # idle bucket = idle + iowait; everything else counts as busy time
    idle1 = a[4] + a[5]; idle2 = b[4] + b[5]
    busy1 = a[1] + a[2] + a[3] + a[6] + a[7] + a[8]
    busy2 = b[1] + b[2] + b[3] + b[6] + b[7] + b[8]
    total1 = idle1 + busy1; total2 = idle2 + busy2
    totald = total2 - total1; idled = idle2 - idle1
    if (totald <= 0) { printf "0"; exit }
    printf "%.1f", (totald - idled) / totald * 100
  }'
}

# --- host memory / disk --------------------------------------------------

host_mem_mb() {
  local total_kb avail_kb
  total_kb="$(awk '/^MemTotal:/{print $2}' /proc/meminfo)"
  avail_kb="$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)"
  # MemAvailable-based "used" is more accurate than total-free (accounts for
  # reclaimable cache/buffers that aren't actually unavailable to workloads).
  awk -v t="${total_kb:-0}" -v a="${avail_kb:-0}" 'BEGIN{printf "%d %d", (t-a)/1024, t/1024}'
}

host_disk_percent() {
  local pct
  # /home/node is the shared host-backed volume; bare `/` on some setups is
  # just the container's own thin overlay and reports meaningless numbers.
  pct="$(df -P /home/node 2>/dev/null | awk 'NR==2{print $5}')"
  [ -z "$pct" ] && pct="$(df -P / 2>/dev/null | awk 'NR==2{print $5}')"
  pct="${pct%\%}"
  is_number "$pct" || pct=0
  echo "$pct"
}

# docker reports per-container CPU% relative to a single core (a busy 3-core
# container reads ~300%, not 100%) — expose the host's core count so the UI
# can show that number in context instead of it looking broken past 100%.
host_cpu_cores() {
  nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo 1
}

# --- docker helpers --------------------------------------------------------

# "N Unit" (one side of a MemUsage pair, already split) -> MB, unit-normalized.
mem_chunk_to_mb() {
  local num unit
  num="$(echo "$1" | sed -E 's/[A-Za-z]+$//' | xargs)"
  unit="$(echo "$1" | grep -oE '[A-Za-z]+$')"
  case "$unit" in
    GiB|GB) awk -v n="${num:-0}" 'BEGIN{printf "%.0f", n*1024}' ;;
    KiB|KB) awk -v n="${num:-0}" 'BEGIN{printf "%.0f", n/1024}' ;;
    B)      awk -v n="${num:-0}" 'BEGIN{printf "%.0f", n/1024/1024}' ;;
    *)      awk -v n="${num:-0}" 'BEGIN{printf "%.0f", n}' ;;  # MiB/MB, or unrecognized -> treat as-is
  esac
}

# docker stats' MemUsage is "USED / LIMIT" (e.g. "123.4MiB / 8GiB") — LIMIT is
# the container's real cgroup memory limit, which defaults to the host's total
# memory when nothing in compose sets one explicitly (true here for every
# service in this project). Prints "<usedMb>\t<limitMb>".
parse_docker_mem() {
  local used_chunk limit_chunk
  used_chunk="$(echo "$1" | awk -F'/' '{print $1}' | xargs)"
  limit_chunk="$(echo "$1" | awk -F'/' '{print $2}' | xargs)"
  printf '%s\t%s' "$(mem_chunk_to_mb "$used_chunk")" "$(mem_chunk_to_mb "$limit_chunk")"
}

# Every docker call below is wrapped so a missing socket, permission error,
# or dead daemon degrades to an empty/false result instead of propagating —
# that's what lets a Docker hiccup leave host stats intact for the cycle.

get_session_containers() {
  local ps_out fragments=()
  ps_out="$(docker ps --filter "label=claude-docker.role=session" \
    --format '{{.Names}}\t{{.Label "claude-docker.project"}}' 2>/dev/null)" || { echo "{}"; return; }
  [ -z "$ps_out" ] && { echo "{}"; return; }

  local name project stats cpu_raw mem_raw cpu mem mem_limit
  while IFS=$'\t' read -r name project; do
    [ -z "$name" ] && continue
    [ -z "$project" ] && continue
    stats="$(docker stats --no-stream --format '{{.CPUPerc}}\t{{.MemUsage}}' "$name" 2>/dev/null)" || continue
    [ -z "$stats" ] && continue
    IFS=$'\t' read -r cpu_raw mem_raw <<< "$stats"
    cpu="${cpu_raw%\%}"; is_number "$cpu" || cpu=0
    IFS=$'\t' read -r mem mem_limit <<< "$(parse_docker_mem "$mem_raw")"
    is_number "$mem" || mem=0
    is_number "$mem_limit" || mem_limit=0
    fragments+=("$(jq -n --arg k "$project" --argjson cpu "$cpu" --argjson mem "$mem" --argjson memLimit "$mem_limit" \
      '{($k): {role:"session", cpuPercent:$cpu, memUsedMb:$mem, memLimitMb:$memLimit}}')")
  done <<< "$ps_out"

  [ "${#fragments[@]}" -eq 0 ] && { echo "{}"; return; }
  printf '%s\n' "${fragments[@]}" | jq -s 'add'
}

get_companion() {
  local role="$1" name stats cpu_raw mem_raw cpu mem mem_limit
  name="$(docker ps --filter "label=claude-docker.role=${role}" --format '{{.Names}}' 2>/dev/null | head -n1)" || true
  [ -z "${name:-}" ] && { echo '{"running":false}'; return; }

  stats="$(docker stats --no-stream --format '{{.CPUPerc}}\t{{.MemUsage}}' "$name" 2>/dev/null)" || true
  [ -z "${stats:-}" ] && { echo '{"running":false}'; return; }

  IFS=$'\t' read -r cpu_raw mem_raw <<< "$stats"
  cpu="${cpu_raw%\%}"; is_number "$cpu" || cpu=0
  IFS=$'\t' read -r mem mem_limit <<< "$(parse_docker_mem "$mem_raw")"
  is_number "$mem" || mem=0
  is_number "$mem_limit" || mem_limit=0
  jq -n --argjson cpu "$cpu" --argjson mem "$mem" --argjson memLimit "$mem_limit" \
    '{running:true, cpuPercent:$cpu, memUsedMb:$mem, memLimitMb:$memLimit}'
}

# --- snapshot assembly ----------------------------------------------------

write_snapshot() {
  local ts cpu_pct cpu_cores mem_used mem_total disk_pct containers comfyui headroom dashboard dashboard_watcher tmp_file
  ts="$(date +%s)"
  cpu_pct="$(host_cpu_percent)"
  cpu_cores="$(host_cpu_cores)"
  read -r mem_used mem_total <<< "$(host_mem_mb)"
  disk_pct="$(host_disk_percent)"
  containers="$(get_session_containers)"
  comfyui="$(get_companion comfyui)"
  headroom="$(get_companion headroom)"
  dashboard="$(get_companion dashboard)"
  dashboard_watcher="$(get_companion dashboard-watcher)"

  mkdir -p "$(dirname "$OUT_FILE")"
  tmp_file="$(mktemp "${OUT_FILE}.XXXXXX")"
  # This container runs as root (needed for the docker.sock group); the `dashboard`
  # gateway reading this file runs as the unprivileged `node` user — mktemp's
  # default 0600 would leave it unreadable there, so open it up before the
  # readers ever see it (chmod before the atomic mv, not after).
  chmod 644 "$tmp_file"
  jq -n \
    --argjson ts "$ts" \
    --argjson cpuPercent "$cpu_pct" \
    --argjson cpuCores "$cpu_cores" \
    --argjson memUsedMb "$mem_used" \
    --argjson memTotalMb "$mem_total" \
    --argjson diskUsedPercent "$disk_pct" \
    --argjson containers "$containers" \
    --argjson comfyui "$comfyui" \
    --argjson headroom "$headroom" \
    --argjson dashboard "$dashboard" \
    --argjson dashboardWatcher "$dashboard_watcher" \
    '{
      timestamp: $ts,
      host: {cpuPercent: $cpuPercent, cpuCores: $cpuCores, memUsedMb: $memUsedMb, memTotalMb: $memTotalMb, diskUsedPercent: $diskUsedPercent},
      containers: $containers,
      companions: {comfyui: $comfyui, headroom: $headroom, dashboard: $dashboard, dashboardWatcher: $dashboardWatcher}
    }' > "$tmp_file"
  # atomic swap: readers on the shared volume never see a half-written file
  mv -f "$tmp_file" "$OUT_FILE"
}

echo "dashboard-watcher: polling every ${INTERVAL}s, writing to ${OUT_FILE}"

# No -e in the loop body: a transient docker/proc read failure mid-cycle
# must not kill the watcher process, since nothing would ever restart it
# into a working state again (next cycle just tries fresh). Individual
# helpers above already fail soft; this outer guard is the last resort.
while true; do
  { write_snapshot; } 2>/dev/null || true
  sleep "$INTERVAL"
done
