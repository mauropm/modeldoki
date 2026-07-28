#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_header "modeldoki — LM Studio Configuration"

check_macos_version
check_apple_silicon

LM_STUDIO_APP="/Applications/LM Studio.app"
LM_STUDIO_PORT=1234

if [[ ! -d "$LM_STUDIO_APP" ]]; then
  log_error "LM Studio is not installed. Run scripts/install_lmstudio.sh first."
  exit 1
fi

if ! lms_available; then
  log_error "LM Studio CLI (lms) not found at ${LMS_CLI}"
  log_info "Enable it in LM Studio → Settings → Developer, then re-run this script."
  exit 1
fi

# ─── Import and load models ────────────────────────────────────────────────
# One LM Studio instance serves ONE server port. Both models are loaded into
# the same server; the API dispatches requests by the "model" field, using
# the identifiers assigned below.

log_step "Importing and loading models"

chat_file="$(resolve_model_file "qwen2.5-7b-instruct" || true)"
coder_file="$(resolve_model_file "qwen2.5-coder-7b-instruct" || true)"

if [[ -n "$chat_file" ]]; then
  lms_ensure_model_loaded "$chat_file" "qwen2.5-7b-instruct" 32768 || true
else
  log_warn "Chat model not found in ${MODELS_DIR} — run scripts/install_models.sh"
fi

if [[ -n "$coder_file" ]]; then
  lms_ensure_model_loaded "$coder_file" "qwen2.5-coder-7b-instruct" 32768 || true
else
  log_warn "Coder model not found in ${MODELS_DIR} — run scripts/install_models.sh"
fi

# ─── Start the local server ────────────────────────────────────────────────
log_step "Starting LM Studio server on port ${LM_STUDIO_PORT}"

if port_in_use "$LM_STUDIO_PORT"; then
  log_ok "Port ${LM_STUDIO_PORT} already in use — server may already be running"
elif "$LMS_CLI" server start --port "$LM_STUDIO_PORT" --cors >/dev/null 2>&1; then
  log_ok "LM Studio server started on port ${LM_STUDIO_PORT}"
else
  log_warn "Could not start the server via lms."
  log_info "Start it manually: LM Studio → Developer → Start Server (port ${LM_STUDIO_PORT})"
fi

log_header "LM Studio configuration complete"
log_info "OpenAI-compatible endpoint: http://localhost:${LM_STUDIO_PORT}/v1"
log_info "  Chat model:  qwen2.5-7b-instruct"
log_info "  Coder model: qwen2.5-coder-7b-instruct"
log_info "(Both models are served on the same port; the model field selects which one answers.)"
