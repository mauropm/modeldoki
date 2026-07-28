#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_header "modeldoki — Status"

# ─── Processes ──────────────────────────────────────────────────────────────
log_step "Running Processes"

process_info() {
  local name="$1"
  local pattern="$2"
  local pids
  pids=$(pgrep -f "$pattern" 2>/dev/null || true)
  if [[ -n "$pids" ]]; then
    local -a pid_list=( ${(f)pids} )
    local mem=0 pid p_mem
    for pid in "${pid_list[@]}"; do
      p_mem=$(ps -o rss= -p "$pid" 2>/dev/null || echo 0)
      mem=$((mem + p_mem))
    done
    local mem_mb=$((mem / 1024))
    log_ok "${name}: running (${#pid_list[@]} process(es), ~${mem_mb} MB)"
  else
    log_warn "${name}: not running"
  fi
}

process_info "LM Studio" "LM Studio"
process_info "Open WebUI" "open-webui"
process_info "LLMRouter" "llm-router"

# ─── Ports ──────────────────────────────────────────────────────────────────
log_step "Ports"

for port in 1234 3333 6666; do
  if port_in_use "$port"; then
    proc_name=$(lsof -i :"$port" -Fc 2>/dev/null | grep '^c' | head -1 | sed 's/^c//' || echo "unknown")
    log_ok "Port ${port}: ${proc_name:-unknown}"
  else
    log_warn "Port ${port}: available"
  fi
done

# ─── Launchd Services ──────────────────────────────────────────────────────
log_step "launchd Services"

for label in "com.modeldoki.openwebui" "com.modeldoki.llmrouter"; do
  # Parse the `launchctl list` table: PID  Status  Label
  entry=$(launchctl list 2>/dev/null | awk -v l="$label" '$3 == l' || true)
  if [[ -n "$entry" ]]; then
    pid=$(echo "$entry" | awk '{print $1}')
    last_exit=$(echo "$entry" | awk '{print $2}')
    if [[ "$pid" != "-" ]] && [[ -n "$pid" ]]; then
      log_ok "${label}: running (PID ${pid})"
    elif [[ "$last_exit" != "0" ]]; then
      log_warn "${label}: exited with status ${last_exit}"
    else
      log_ok "${label}: loaded (not running)"
    fi
  else
    log_warn "${label}: not loaded"
  fi
done

# ─── Memory ──────────────────────────────────────────────────────────────────
log_step "Memory"

vm_stat 2>/dev/null | head -10 | while read -r line; do
  log_info "${line}"
done

total_gb=$(($(sysctl -n hw.memsize) / 1073741824))
log_info "Total RAM: ${total_gb} GB"
memory_pressure 2>/dev/null | grep -E "pressure|percentage" | while read -r line; do
  log_info "${line}"
done

# ─── GPU Usage ────────────────────────────────────────────────────────────────
log_step "GPU"

if check_cmd system_profiler; then
  system_profiler SPDisplaysDataType 2>/dev/null | grep -E "Chipset Model|VRAM" | while read -r line; do
    log_info "${line}"
  done
fi

# If powermetrics is available (requires sudo), use it
if check_cmd powermetrics; then
  log_info "GPU utilization (requires sudo):"
  log_info "  sudo powermetrics --samplers gpu_power -n 1 -i 1000 2>/dev/null | grep 'GPU'"
fi

# ─── Models ──────────────────────────────────────────────────────────────────
log_step "Models on Disk"

gguf_files=( "${MODELS_DIR}"/*.gguf )
if (( ${#gguf_files[@]} > 0 )); then
  ls -lh "${gguf_files[@]}" | while read -r line; do
    fsize=$(echo "$line" | awk '{print $5}')
    log_info "${line##*/} (${fsize})"
  done
else
  log_warn "No models in ${MODELS_DIR}"
fi

log_step "Loaded Models"
if lms_available; then
  loaded=$("$LMS_CLI" ps --json 2>/dev/null | jq -r '.[].identifier' 2>/dev/null || true)
  if [[ -n "$loaded" ]]; then
    echo "$loaded" | while read -r ident; do
      log_ok "${ident}"
    done
  else
    log_info "No models currently loaded"
  fi
else
  log_warn "lms CLI not available — cannot query loaded models"
fi

log_header "Status check complete"
