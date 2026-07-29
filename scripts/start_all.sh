#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_header "modeldoki — Starting All Services"

# ─── 1. LM Studio ──────────────────────────────────────────────────────────
log_step "Starting LM Studio"

# Shut down the GUI if open so the headless CLI has full control.
ensure_headless_lmstudio

LM_STUDIO_APP="/Applications/LM Studio.app"
LM_STUDIO_PORT=1234

if lms_available; then
  if port_available "$LM_STUDIO_PORT"; then
    "$LMS_CLI" server start --port "$LM_STUDIO_PORT" --cors >/dev/null 2>&1 && \
      log_ok "LM Studio server started on port ${LM_STUDIO_PORT}" || \
      log_warn "Could not start LM Studio server via lms"
  else
    log_ok "LM Studio server already listening on port ${LM_STUDIO_PORT}"
  fi

  # Load the model (idempotent — skipped when already loaded).
  # Prefer a local GGUF from models/; fall back to LM Studio's model index.
  model_file="$(resolve_model_file "qwen3.5-9b" || true)"
  if [[ -n "$model_file" ]]; then
    lms_ensure_model_loaded "$model_file" "qwen3.5-9b" 32768 || true
  else
    lms_ensure_model_loaded "" "qwen3.5-9b" 32768 || \
      log_warn "Qwen 3.5 9B not found — run scripts/install_models.sh"
  fi
elif [[ -d "$LM_STUDIO_APP" ]]; then
  log_info "Launching LM Studio.app..."
  open -a "LM Studio"
  log_info "Please start the server (port ${LM_STUDIO_PORT}) and load the model in the GUI:"
  log_info "  Model: qwen3.5-9b"
else
  log_warn "LM Studio not installed. Run scripts/install_lmstudio.sh"
fi

# ─── 2. Open WebUI ──────────────────────────────────────────────────────────
log_step "Starting Open WebUI"

OPENWEBUI_DIR="${HOME}/.modeldoki/open-webui"
OPENWEBUI_BIN="${OPENWEBUI_DIR}/.venv/bin/open-webui"
OPENWEBUI_ENV="${CONFIGS_DIR}/openwebui.env"
OPENWEBUI_PORT=3333

# Try launchd first; fall back to starting the process directly.
start_openwebui_direct() {
  if [[ ! -x "$OPENWEBUI_BIN" ]]; then
    log_warn "Open WebUI not installed. Run scripts/install_openwebui.sh"
    return 1
  fi
  # Source env file for environment variables.
  if [[ -f "$OPENWEBUI_ENV" ]]; then
    source "$OPENWEBUI_ENV"
  fi
  log_info "Starting Open WebUI directly on port ${OPENWEBUI_PORT}..."
  # `nohup … &` is safe under set -e — the & returns 0.
  nohup "$OPENWEBUI_BIN" serve \
    --host "${OPENWEBUI_HOST:-127.0.0.1}" \
    --port "${OPENWEBUI_PORT}" \
    > "${LOGS_DIR}/openwebui.stdout.log" \
    2> "${LOGS_DIR}/openwebui.stderr.log" &
  sleep 3
  if port_in_use "$OPENWEBUI_PORT"; then
    log_ok "Open WebUI started on port ${OPENWEBUI_PORT} (PID $!)"
  else
    log_warn "Open WebUI may not have started — check logs/openwebui.stderr.log"
  fi
}

if launchctl list | grep -q "com.modeldoki.openwebui" 2>/dev/null; then
  log_ok "Open WebUI launchd service is running"
else
  OPENWEBUI_PLIST="${HOME}/Library/LaunchAgents/com.modeldoki.openwebui.plist"
  if [[ -f "$OPENWEBUI_PLIST" ]]; then
    launchctl load -w "$OPENWEBUI_PLIST" 2>/dev/null && \
      log_ok "Open WebUI started via launchd" || \
      launchctl bootstrap gui/"$(id -u)" "$OPENWEBUI_PLIST" 2>/dev/null && \
      log_ok "Open WebUI bootstrapped via launchd" || \
      start_openwebui_direct
  else
    start_openwebui_direct
  fi
fi

# ─── 3. Bifrost ──────────────────────────────────────────────────────────────
log_step "Starting Bifrost"

BIFROST_DIR="${HOME}/.modeldoki/bifrost"
BIFROST_BIN="${BIFROST_DIR}/bifrost-http"
BIFROST_PORT=6666

start_bifrost_direct() {
  if [[ ! -x "$BIFROST_BIN" ]]; then
    log_warn "Bifrost not installed. Run scripts/install_bifrost.sh"
    return 1
  fi
  log_info "Starting Bifrost directly on port ${BIFROST_PORT}..."
  nohup "$BIFROST_BIN" \
    --app-dir "$BIFROST_DIR" \
    --port "$BIFROST_PORT" \
    --host "127.0.0.1" \
    > "${LOGS_DIR}/bifrost.stdout.log" \
    2> "${LOGS_DIR}/bifrost.stderr.log" &
  sleep 2
  if port_in_use "$BIFROST_PORT"; then
    log_ok "Bifrost started on port ${BIFROST_PORT} (PID $!)"
  else
    log_warn "Bifrost may not have started — check logs/bifrost.stderr.log"
  fi
}

if launchctl list | grep -q "com.modeldoki.bifrost" 2>/dev/null; then
  log_ok "Bifrost launchd service is running"
else
  BIFROST_PLIST="${HOME}/Library/LaunchAgents/com.modeldoki.bifrost.plist"
  if [[ -f "$BIFROST_PLIST" ]]; then
    launchctl load -w "$BIFROST_PLIST" 2>/dev/null && \
      log_ok "Bifrost started via launchd" || \
      launchctl bootstrap gui/"$(id -u)" "$BIFROST_PLIST" 2>/dev/null && \
      log_ok "Bifrost bootstrapped via launchd" || \
      start_bifrost_direct
  else
    start_bifrost_direct
  fi
fi

# ─── Summary ────────────────────────────────────────────────────────────────
log_header "Service Status"

# Some services (Open WebUI in particular) take a moment to bind after launch.
# Retry each port a few times before reporting it as not detected.
check_port() {
  local port="$1" attempt
  for attempt in 1 2 3; do
    if port_in_use "$port"; then
      log_ok "Port ${port} — in use"
      return 0
    fi
    [[ $attempt -lt 3 ]] && sleep 2
  done
  log_warn "Port ${port} — not detected"
}

check_port 1234
check_port 3333
check_port 6666

log_header "All services started"
log_info "LM Studio API:    http://localhost:1234/v1  (Qwen 3.5 9B)"
log_info "Open WebUI:       http://localhost:3333"
log_info "Bifrost Gateway:  http://localhost:6666"
