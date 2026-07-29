#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_header "modeldoki — Bifrost Installation"

check_macos_version
check_apple_silicon

require curl

BIFROST_DIR="${HOME}/.modeldoki/bifrost"
BIFROST_BIN="${BIFROST_DIR}/bifrost-http"

if [[ -x "$BIFROST_BIN" ]]; then
  log_ok "Bifrost binary already found at ${BIFROST_BIN}"
else
  log_step "Downloading Bifrost binary"

  mkdir -p "$BIFROST_DIR"

  # Resolve latest version from the API endpoint.
  LATEST_VERSION=$(curl -sfL "https://getbifrost.ai/latest-release" 2>/dev/null | \
    jq -r '.version // empty' 2>/dev/null || echo "")
  BIFROST_VERSION="${LATEST_VERSION:-v1.6.3}"
  BIFROST_URL="https://downloads.getmaxim.ai/bifrost/${BIFROST_VERSION}/darwin/arm64/bifrost-http"

  log_info "Version: ${BIFROST_VERSION}"
  log_info "Downloading from ${BIFROST_URL}..."

  if download_with_retry "$BIFROST_URL" "$BIFROST_BIN" 3; then
    chmod +x "$BIFROST_BIN"
    log_ok "Bifrost downloaded and installed"
  else
    log_error "Failed to download Bifrost binary."
    log_error "Try downloading manually from https://github.com/maximhq/bifrost"
    exit 1
  fi
fi

log_step "Writing Bifrost configuration"

cat > "${BIFROST_DIR}/config.json" <<- CONFIG
{
  "\$schema": "https://www.getbifrost.ai/schema",
  "providers": {
    "lm-studio": {
      "keys": [
        {
          "name": "local-lm-studio",
          "value": "not-needed",
          "models": ["*"],
          "weight": 1.0
        }
      ],
      "network_config": {
        "base_url": "http://127.0.0.1:1234/v1",
        "default_request_timeout_in_seconds": 120
      },
      "custom_provider_config": {
        "base_provider_type": "openai",
        "allowed_requests": {
          "chat_completion": true,
          "chat_completion_stream": true
        }
      }
    }
  },
  "config_store": {
    "enabled": false
  }
}
CONFIG

log_ok "Configuration written to ${BIFROST_DIR}/config.json"

log_header "Bifrost installation complete"
log_info "Binary: ${BIFROST_BIN}"
log_info "Config: ${BIFROST_DIR}/config.json"
log_info ""
log_info "Bifrost forwards all requests to LM Studio (port 1234, Qwen 3.5 9B)."
log_info ""
log_info "Run scripts/configure_bifrost.sh or start manually:"
log_info "  ${BIFROST_BIN} --app-dir ${BIFROST_DIR} --port 6666 --host 127.0.0.1"
