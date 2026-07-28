#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_header "modeldoki — Bifrost Configuration"

check_macos_version
check_apple_silicon

BIFROST_DIR="${HOME}/.modeldoki/bifrost"
BIFROST_BIN="${BIFROST_DIR}/bifrost-http"
BIFROST_CONFIG="${BIFROST_DIR}/config.json"

if [[ ! -f "$BIFROST_CONFIG" ]]; then
  log_warn "Bifrost config not found at ${BIFROST_CONFIG}"
  log_info "Run scripts/install_llmrouter.sh first"
  exit 1
fi

mkdir -p "$BIFROST_DIR"

log_step "Bifrost configuration is ready"

if [[ -x "$BIFROST_BIN" ]]; then
  "$BIFROST_BIN" --help >/dev/null 2>&1 && \
    log_ok "Bifrost binary responds" || \
    log_warn "Bifrost binary did not respond to --help"
fi

log_info "Bifrost will serve on http://localhost:6666"
log_info "All models are routed to LM Studio (http://localhost:1234/v1)"
log_info "Config file: ${BIFROST_CONFIG}"

log_header "Bifrost configuration complete"
log_info "Run scripts/start_all.sh to launch"
