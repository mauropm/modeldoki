#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_header "modeldoki — Starting All Services"

# ─── 1. LM Studio ──────────────────────────────────────────────────────────
log_step "Starting LM Studio"

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

  # Load models (idempotent — skipped when already loaded). Both models are
  # served on the same port; the API dispatches by the request's model field.
  chat_file="$(resolve_model_file "qwen2.5-7b-instruct" || true)"
  [[ -n "$chat_file" ]] && lms_ensure_model_loaded "$chat_file" "qwen2.5-7b-instruct" 32768 || true

  coder_file="$(resolve_model_file "qwen2.5-coder-7b-instruct" || true)"
  [[ -n "$coder_file" ]] && lms_ensure_model_loaded "$coder_file" "qwen2.5-coder-7b-instruct" 32768 || true

  if [[ -z "$chat_file" && -z "$coder_file" ]]; then
    log_warn "No models in ${MODELS_DIR} — run scripts/install_models.sh"
  fi
elif [[ -d "$LM_STUDIO_APP" ]]; then
  log_info "Launching LM Studio.app..."
  open -a "LM Studio"
  log_info "Please start the server (port ${LM_STUDIO_PORT}) and load the models in the GUI:"
  log_info "  Chat:  qwen2.5-7b-instruct"
  log_info "  Coder: qwen2.5-coder-7b-instruct"
else
  log_warn "LM Studio not installed. Run scripts/install_lmstudio.sh"
fi

# ─── 2. Open WebUI ──────────────────────────────────────────────────────────
log_step "Starting Open WebUI"

if launchctl list | grep -q "com.modeldoki.openwebui"; then
  log_ok "Open WebUI launchd service is running"
else
  OPENWEBUI_PLIST="${HOME}/Library/LaunchAgents/com.modeldoki.openwebui.plist"
  if [[ -f "$OPENWEBUI_PLIST" ]]; then
    launchctl load -w "$OPENWEBUI_PLIST" 2>/dev/null && \
      log_ok "Open WebUI started via launchd" || \
      launchctl bootstrap gui/"$(id -u)" "$OPENWEBUI_PLIST" 2>/dev/null && \
      log_ok "Open WebUI bootstrapped via launchd" || \
      log_warn "Could not start Open WebUI via launchd"
  else
    log_warn "Open WebUI launchd plist not found"
    log_info "Run scripts/configure_launchd.sh first"
  fi
fi

# ─── 3. LLMRouter ────────────────────────────────────────────────────────────
log_step "Starting LLMRouter"

if launchctl list | grep -q "com.modeldoki.llmrouter"; then
  log_ok "LLMRouter launchd service is running"
else
  LLMROUTER_PLIST="${HOME}/Library/LaunchAgents/com.modeldoki.llmrouter.plist"
  if [[ -f "$LLMROUTER_PLIST" ]]; then
    launchctl load -w "$LLMROUTER_PLIST" 2>/dev/null && \
      log_ok "LLMRouter started via launchd" || \
      launchctl bootstrap gui/"$(id -u)" "$LLMROUTER_PLIST" 2>/dev/null && \
      log_ok "LLMRouter bootstrapped via launchd" || \
      log_warn "Could not start LLMRouter via launchd"
  else
    log_warn "LLMRouter launchd plist not found"
    log_info "Run scripts/configure_launchd.sh first"
  fi
fi

# ─── Summary ────────────────────────────────────────────────────────────────
log_header "Service Status"
sleep 1

for port in 1234 3333 6666; do
  if port_in_use "$port"; then
    log_ok "Port ${port} — in use"
  else
    log_warn "Port ${port} — not detected"
  fi
done

log_header "All services started"
log_info "LM Studio API:    http://localhost:1234/v1  (both models)"
log_info "Open WebUI:       http://localhost:3333"
log_info "LLMRouter Admin:  http://localhost:6666"
