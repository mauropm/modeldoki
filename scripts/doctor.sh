#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_header "modeldoki — Doctor (System Diagnostics)"

# ─── Platform ──────────────────────────────────────────────────────────────
log_step "Platform"
platform_info

# ─── macOS Version ──────────────────────────────────────────────────────────
log_step "macOS Version"
if check_macos_version; then
  log_ok "macOS version check passed"
else
  log_error "macOS version check failed"
fi

# ─── Apple Silicon ──────────────────────────────────────────────────────────
log_step "Architecture"
if check_apple_silicon; then
  log_ok "Apple Silicon check passed"
fi

# ─── Memory ──────────────────────────────────────────────────────────────────
log_step "Memory"
check_ram

total_gb=$(($(sysctl -n hw.memsize) / 1073741824))
free_kb=$(memory_pressure 2>/dev/null | grep "Pages free" | awk '{print $3}' | sed 's/\.//' || echo 0)
free_gb=$((free_kb * 16384 / 1073741824))
log_info "Free memory: ~${free_gb} GB / ${total_gb} GB"

# ─── Disk Space ──────────────────────────────────────────────────────────────
log_step "Disk Space"
df -h / | tail -1 | awk '{printf "  %s free of %s (%s used)\n", $4, $2, $5}'

# ─── Homebrew ────────────────────────────────────────────────────────────────
log_step "Homebrew"
if check_cmd brew; then
  log_ok "Homebrew: $(brew --version 2>/dev/null | head -1)"
else
  log_error "Homebrew not installed"
fi

# ─── Python ──────────────────────────────────────────────────────────────────
log_step "Python"
if check_cmd python3; then
  log_ok "Python: $(python3 --version 2>/dev/null)"
else
  log_error "Python 3 not found"
fi

# ─── uv ──────────────────────────────────────────────────────────────────────
log_step "uv"
if check_cmd uv; then
  log_ok "uv: $(uv --version 2>/dev/null)"
else
  log_error "uv not found"
fi

# ─── Node ────────────────────────────────────────────────────────────────────
log_step "Node"
if check_cmd node; then
  log_ok "Node: $(node --version 2>/dev/null)"
else
  log_error "Node not found"
fi

# ─── LM Studio ──────────────────────────────────────────────────────────────
log_step "LM Studio"
if [[ -d "/Applications/LM Studio.app" ]]; then
  log_ok "LM Studio.app installed"
  if lms_available; then
    log_ok "LM Studio CLI (lms) available"
  else
    log_warn "LM Studio CLI (lms) not found at ${LMS_CLI}"
  fi
else
  log_error "LM Studio.app not installed"
fi

# ─── Open WebUI ──────────────────────────────────────────────────────────────
log_step "Open WebUI"
OPENWEBUI_DIR="${HOME}/.modeldoki/open-webui"
if [[ -d "$OPENWEBUI_DIR" ]]; then
  log_ok "Open WebUI directory exists"
  if [[ -f "${OPENWEBUI_DIR}/.venv/bin/python" ]]; then
    log_ok "Open WebUI virtual environment exists"
    OPENWEBUI_VERSION=$("${OPENWEBUI_DIR}/.venv/bin/pip" show open-webui 2>/dev/null | grep Version | cut -d' ' -f2)
    log_ok "Open WebUI version: ${OPENWEBUI_VERSION:-unknown}"
  fi
else
  log_error "Open WebUI not installed"
fi

# ─── Bifrost ─────────────────────────────────────────────────────────────────
log_step "Bifrost"
BIFROST_BIN="${HOME}/.modeldoki/bifrost/bifrost-http"
if [[ -x "$BIFROST_BIN" ]]; then
  log_ok "Bifrost binary exists"
else
  log_warn "Bifrost binary not found"
fi

# ─── Models ──────────────────────────────────────────────────────────────────
log_step "Models"
gguf_files=( "${MODELS_DIR}"/*.gguf )
if (( ${#gguf_files[@]} > 0 )); then
  log_ok "GGUF models found:"
  for f in "${gguf_files[@]}"; do
    log_info "  ${f##*/}"
  done
else
  log_warn "No GGUF models found in ${MODELS_DIR}"
fi

# ─── Ports ───────────────────────────────────────────────────────────────────
log_step "Ports"
for port in 1234 3333 6666; do
  if port_in_use "$port"; then
    proc_info=$(lsof -i :"$port" -Fn 2>/dev/null | grep '^n' | head -1 | sed 's/^n//' || echo "unknown")
    log_ok "Port ${port} — in use by ${proc_info:-unknown}"
  else
    log_warn "Port ${port} — available"
  fi
done

# ─── launchd Services ──────────────────────────────────────────────────────
log_step "launchd Services"
for label in "com.modeldoki.openwebui" "com.modeldoki.bifrost"; do
  if launchctl list | grep -q "$label"; then
    log_ok "launchd: ${label} — loaded"
  else
    log_warn "launchd: ${label} — not loaded"
  fi
done

# ─── GPU ────────────────────────────────────────────────────────────────────
log_step "GPU"
if check_cmd system_profiler; then
  system_profiler SPDisplaysDataType 2>/dev/null | grep -E "Chipset Model|VRAM|Metal" | while read -r line; do
    log_info "${line}"
  done
fi

# ─── Summary ────────────────────────────────────────────────────────────────
log_header "Doctor check complete"
log_info "Run scripts/install_homebrew.sh to fix missing dependencies"
log_info "Run scripts/status.sh for live status"
