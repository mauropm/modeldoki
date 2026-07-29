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

# ─── Switch to headless mode ───────────────────────────────────────────────
# If the LM Studio GUI app is open it can block CLI operations; shut it
# down so the headless daemon handles everything.
ensure_headless_lmstudio

# ─── Import and load the model ─────────────────────────────────────────────
log_step "Importing and loading Qwen 3.5 9B"

model_file="$(resolve_model_file "qwen3.5-9b" || true)"

if [[ -n "$model_file" ]]; then
  lms_ensure_model_loaded "$model_file" "qwen3.5-9b" 32768 || true
else
  # No local GGUF — check whether the model is already known to LM Studio
  # (e.g. downloaded via `lms get` or imported previously).
  log_info "No local GGUF in ${MODELS_DIR}, checking LM Studio model index..."
  lms_ensure_model_loaded "" "qwen3.5-9b" 32768 || \
    log_warn "Qwen 3.5 9B not found — run scripts/install_models.sh or lms get"
fi

# ─── Disable thinking for faster inference ─────────────────────────────────
# Qwen 3.5 9B enables thinking/reasoning by default, which adds significant
# latency. Inject the disable override into the model's chat template.
log_step "Disabling thinking in Qwen 3.5 9B chat template"

MODEL_TEMPLATE=$(find "${HOME}/.lmstudio/models" -path "*/Qwen*3.5*9B*/chat_template.jinja" 2>/dev/null | head -1)
if [[ -z "$MODEL_TEMPLATE" ]]; then
  log_warn "Qwen model chat template not found — thinking may still be enabled"
elif grep -q "enable_thinking = false" "$MODEL_TEMPLATE" 2>/dev/null; then
  log_ok "Thinking already disabled"
else
  # Prepend the override line to the Jinja template.
  { echo '{%- set enable_thinking = false %}'; cat "$MODEL_TEMPLATE"; } > "${MODEL_TEMPLATE}.tmp" && \
    mv "${MODEL_TEMPLATE}.tmp" "$MODEL_TEMPLATE" && \
    log_ok "Thinking disabled in $(basename "$(dirname "$MODEL_TEMPLATE")")" || \
    log_warn "Could not patch chat template"
fi

# ─── Start the local server ────────────────────────────────────────────────
# (ensure_headless_lmstudio already ran above — the server is started here.)
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
log_info "  Model: qwen3.5-9b"
