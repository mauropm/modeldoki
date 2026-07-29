#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_header "modeldoki — Model Setup & Configuration"

check_macos_version
check_apple_silicon

if ! lms_available; then
  log_error "LM Studio CLI (lms) not found at ${LMS_CLI}"
  log_info "Run scripts/install_lmstudio.sh first"
  exit 1
fi

# ─── Check for existing models in LM Studio ───────────────────────────────
log_step "Checking for existing models in LM Studio"

existing_models=$("$LMS_CLI" ls --json 2>/dev/null | \
  jq -r '.[] | select(.type == "llm") | .displayName + " (" + .modelKey + ")"' 2>/dev/null || true)

if [[ -n "$existing_models" ]]; then
  log_info "Found existing model(s) in LM Studio:"
  while IFS= read -r m; do
    log_info "  - ${m}"
  done <<< "$existing_models"
  # Check if our target model is among them
  if echo "$existing_models" | grep -qi "qwen.*3[. ]*5.*9[. ]*[Bb]"; then
    log_ok "Qwen 3.5 9B is already installed — using local model"
  else
    log_info "Qwen 3.5 9B not found among existing models — will download"
    NEED_DOWNLOAD=1
  fi
else
  log_info "No LLM models found in LM Studio"
  NEED_DOWNLOAD=1
fi

# ─── Download Qwen 3.5 9B MLX if needed ──────────────────────────────────
if [[ "${NEED_DOWNLOAD:-0}" -eq 1 ]]; then
  log_step "Downloading Qwen 3.5 9B MLX model"
  log_info "This downloads the Apple Silicon–native MLX variant (~6 GB)..."
  if "$LMS_CLI" get "qwen/qwen3.5-9b" --mlx -y; then
    log_ok "Qwen 3.5 9B MLX model downloaded"
  else
    log_error "Failed to download Qwen 3.5 9B"
    log_info "You can also download manually via the LM Studio GUI"
    exit 1
  fi
fi

# ─── Clean up stale GGUF files from previous model versions ──────────────
# The project previously downloaded GGUF files into models/.  Now that we
# use MLX models managed by LM Studio, remove those to avoid confusion.
if ls "${MODELS_DIR}"/*.gguf >/dev/null 2>&1; then
  log_info "Removing stale GGUF files from ${MODELS_DIR} (project now uses MLX)..."
  rm -f "${MODELS_DIR}"/*.gguf
  log_ok "Stale GGUF files removed"
fi

# ─── Configure all tools ─────────────────────────────────────────────────
log_step "Configuring LM Studio"
"${SCRIPT_DIR}/configure_lmstudio.sh"

log_step "Configuring Bifrost"
"${SCRIPT_DIR}/configure_bifrost.sh"

log_step "Configuring Open WebUI"
"${SCRIPT_DIR}/configure_openwebui.sh"

log_header "All set — run scripts/start_all.sh to launch everything"
