#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_header "modeldoki — Open WebUI Configuration"

check_macos_version
check_apple_silicon

OPENWEBUI_DIR="${HOME}/.modeldoki/open-webui"
OPENWEBUI_ENV="${CONFIGS_DIR}/openwebui.env"

if [[ ! -f "$OPENWEBUI_ENV" ]]; then
  log_warn "openwebui.env not found at ${OPENWEBUI_ENV}"
  log_info "Run scripts/install_openwebui.sh first or check configs/"
  exit 1
fi

mkdir -p "$OPENWEBUI_DIR"

log_step "Setting up Open WebUI configuration"

source "$OPENWEBUI_ENV"

# Record the effective configuration as JSON for easy reading.
# (The authoritative config is passed via environment variables in the
# launchd service — see scripts/configure_launchd.sh.)
OPENWEBUI_CONFIG="${OPENWEBUI_DIR}/config.json"
cat > "$OPENWEBUI_CONFIG" <<- CONFIG
{
  "host": "${OPENWEBUI_HOST:-127.0.0.1}",
  "port": ${OPENWEBUI_PORT:-3333},
  "openai_api_base_url": "${OPENAI_API_BASE_URL:-http://127.0.0.1:1234/v1}",
  "openai_api_key": "${OPENAI_API_KEY:-not-needed}",
  "default_model": "${OPENWEBUI_DEFAULT_MODEL:-qwen3.5-9b}",
  "log_level": "${LOG_LEVEL:-info}",
  "data_dir": "${OPENWEBUI_DIR}/data"
}
CONFIG

log_ok "Configuration recorded at ${OPENWEBUI_CONFIG}"

# Create data directory
mkdir -p "${OPENWEBUI_DIR}/data"

log_info "Open WebUI will connect to LM Studio at ${OPENAI_API_BASE_URL:-http://127.0.0.1:1234/v1}"
log_info "Default model: ${OPENWEBUI_DEFAULT_MODEL:-qwen3.5-9b}"

log_header "Open WebUI configuration complete"
log_info "Open WebUI will be available at http://${OPENWEBUI_HOST:-127.0.0.1}:${OPENWEBUI_PORT:-3333}"
log_info "Run scripts/start_all.sh to launch all services"
