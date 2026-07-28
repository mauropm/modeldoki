#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_header "modeldoki — Open WebUI Installation"

check_macos_version
check_apple_silicon

require python3
require uv

OPENWEBUI_DIR="${HOME}/.modeldoki/open-webui"

if [[ -d "$OPENWEBUI_DIR" ]]; then
  log_ok "Open WebUI directory exists at ${OPENWEBUI_DIR}"
else
  log_step "Creating Open WebUI directory"
  mkdir -p "$OPENWEBUI_DIR"
fi

log_step "Setting up Python virtual environment for Open WebUI"
UV_PROJECT_ENV="${OPENWEBUI_DIR}/.venv"

if [[ -d "$UV_PROJECT_ENV" ]]; then
  log_ok "Virtual environment already exists"
else
  uv venv "$UV_PROJECT_ENV" --python 3.12
  log_ok "Virtual environment created"
fi

source "${UV_PROJECT_ENV}/bin/activate"

log_step "Installing Open WebUI"
if pip install -q open-webui 2>/dev/null; then
  log_ok "Open WebUI installed via pip"
else
  log_info "Trying uv pip install..."
  uv pip install -q open-webui
  log_ok "Open WebUI installed via uv"
fi

OPENWEBUI_VERSION=$(pip show open-webui 2>/dev/null | grep Version | cut -d' ' -f2)
log_ok "Open WebUI version: ${OPENWEBUI_VERSION:-unknown}"

deactivate 2>/dev/null || true

log_header "Open WebUI installation complete"
log_info "Run scripts/configure_openwebui.sh to configure"
log_info "Run scripts/start_all.sh to start the service"
