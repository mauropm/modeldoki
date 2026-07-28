#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_header "modeldoki — LM Studio Installation"

check_macos_version
check_apple_silicon

LM_STUDIO_APP="/Applications/LM Studio.app"

if [[ -d "$LM_STUDIO_APP" ]]; then
  log_ok "LM Studio.app already installed"
else
  log_step "Installing LM Studio via Homebrew cask"
  if ! brew install --cask lm-studio; then
    log_error "Homebrew cask installation failed."
    log_error "Please install LM Studio manually from https://lmstudio.ai"
    log_info "Then re-run this script."
    exit 1
  fi
  log_ok "LM Studio.app installed"
fi

if lms_available; then
  log_ok "LM Studio CLI available at ${LMS_CLI}"
else
  log_warn "LM Studio CLI (lms) not found at ${LMS_CLI}"
  log_info "Open LM Studio, then enable the CLI:"
  log_info "  LM Studio → Settings → Developer → Install lms (CLI)"
fi

log_header "LM Studio installation complete"
log_info "Next steps:"
log_info "  1. Run scripts/install_models.sh to download the Qwen models"
log_info "  2. Run scripts/configure_lmstudio.sh to import and load them"
