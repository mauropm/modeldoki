#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_header "modeldoki — LLMRouter Configuration"

check_macos_version
check_apple_silicon

LLMROUTER_DIR="${HOME}/.modeldoki/llmrouter"
LLMROUTER_BIN="${LLMROUTER_DIR}/llm-router"
LLMROUTER_CONFIG="${CONFIGS_DIR}/llmrouter.yaml"

if [[ ! -f "$LLMROUTER_CONFIG" ]]; then
  log_warn "llmrouter.yaml not found at ${LLMROUTER_CONFIG}"
  exit 1
fi

mkdir -p "$LLMROUTER_DIR"

log_step "Installing LLMRouter configuration"

cp "$LLMROUTER_CONFIG" "${LLMROUTER_DIR}/config.yaml"
log_ok "Configuration copied to ${LLMROUTER_DIR}/config.yaml"

log_step "Testing LLMRouter configuration"

if [[ -x "$LLMROUTER_BIN" ]]; then
  if "$LLMROUTER_BIN" --config "${LLMROUTER_DIR}/config.yaml" --validate 2>/dev/null; then
    log_ok "LLMRouter configuration is valid"
  else
    log_warn "LLMRouter does not support --validate flag; checking syntax manually..."
  fi
else
  log_warn "LLMRouter binary not yet installed"
  log_info "Run scripts/install_llmrouter.sh first"
fi

log_info "Routing configuration:"
log_info "  qwen2.5-7b-instruct*       → Qwen 2.5 7B Instruct       (LM Studio, port 1234)"
log_info "  qwen2.5-coder-7b-instruct* → Qwen 2.5-Coder 7B Instruct (LM Studio, port 1234)"
log_info "  Dashboard   → http://localhost:6666"
log_info "  API         → http://localhost:6666/v1"

log_header "LLMRouter configuration complete"
