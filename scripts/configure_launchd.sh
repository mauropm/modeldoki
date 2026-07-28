#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_header "modeldoki — launchd Service Installation"

check_macos_version
check_apple_silicon

OPENWEBUI_DIR="${HOME}/.modeldoki/open-webui"
LLMROUTER_DIR="${HOME}/.modeldoki/llmrouter"
OPENWEBUI_ENV="${CONFIGS_DIR}/openwebui.env"

mkdir -p "${HOME}/Library/LaunchAgents" "${LAUNCHD_DIR}"

# Load Open WebUI settings (host/port/API endpoint) so the generated plist
# matches configs/openwebui.env.
if [[ -f "$OPENWEBUI_ENV" ]]; then
  source "$OPENWEBUI_ENV"
else
  log_warn "openwebui.env not found at ${OPENWEBUI_ENV} — using defaults"
fi

OPENWEBUI_HOST="${OPENWEBUI_HOST:-127.0.0.1}"
OPENWEBUI_PORT="${OPENWEBUI_PORT:-3333}"
OPENAI_API_BASE_URL="${OPENAI_API_BASE_URL:-http://127.0.0.1:1234/v1}"
OPENAI_API_KEY="${OPENAI_API_KEY:-not-needed}"
WEBUI_SECRET_KEY="${WEBUI_SECRET_KEY:-modeldoki-openwebui-secret}"
WEBUI_DATA_DIR="${WEBUI_DATA_DIR:-${OPENWEBUI_DIR}/data}"

# ─── Open WebUI launchd service ──────────────────────────────────────────────
log_step "Installing Open WebUI launchd service"

OPENWEBUI_PLIST="${LAUNCHD_DIR}/com.modeldoki.openwebui.plist"

cat > "$OPENWEBUI_PLIST" <<- PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.modeldoki.openwebui</string>
    <key>ProgramArguments</key>
    <array>
        <string>${OPENWEBUI_DIR}/.venv/bin/open-webui</string>
        <string>serve</string>
        <string>--host</string>
        <string>${OPENWEBUI_HOST}</string>
        <string>--port</string>
        <string>${OPENWEBUI_PORT}</string>
    </array>
    <key>WorkingDirectory</key>
    <string>${OPENWEBUI_DIR}</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>OPENAI_API_BASE_URL</key>
        <string>${OPENAI_API_BASE_URL}</string>
        <key>OPENAI_API_KEY</key>
        <string>${OPENAI_API_KEY}</string>
        <key>WEBUI_SECRET_KEY</key>
        <string>${WEBUI_SECRET_KEY}</string>
        <key>WEBUI_DATA_DIR</key>
        <string>${WEBUI_DATA_DIR}</string>
    </dict>
    <key>StandardOutPath</key>
    <string>${LOGS_DIR}/openwebui.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>${LOGS_DIR}/openwebui.stderr.log</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>10</integer>
</dict>
</plist>
PLIST

if plutil -lint "$OPENWEBUI_PLIST" >/dev/null 2>&1; then
  log_ok "Open WebUI plist is valid"
else
  log_error "Open WebUI plist failed validation: ${OPENWEBUI_PLIST}"
  exit 1
fi

install_launchd_service "openwebui" "$OPENWEBUI_PLIST" "${HOME}/Library/LaunchAgents/com.modeldoki.openwebui.plist"

# ─── LLMRouter launchd service ────────────────────────────────────────────────
log_step "Installing LLMRouter launchd service"

LLMROUTER_PLIST="${LAUNCHD_DIR}/com.modeldoki.llmrouter.plist"

cat > "$LLMROUTER_PLIST" <<- PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.modeldoki.llmrouter</string>
    <key>ProgramArguments</key>
    <array>
        <string>${LLMROUTER_DIR}/llm-router</string>
        <string>--config</string>
        <string>${LLMROUTER_DIR}/config.yaml</string>
    </array>
    <key>WorkingDirectory</key>
    <string>${LLMROUTER_DIR}</string>
    <key>StandardOutPath</key>
    <string>${LOGS_DIR}/llmrouter.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>${LOGS_DIR}/llmrouter.stderr.log</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>10</integer>
</dict>
</plist>
PLIST

if plutil -lint "$LLMROUTER_PLIST" >/dev/null 2>&1; then
  log_ok "LLMRouter plist is valid"
else
  log_error "LLMRouter plist failed validation: ${LLMROUTER_PLIST}"
  exit 1
fi

install_launchd_service "llmrouter" "$LLMROUTER_PLIST" "${HOME}/Library/LaunchAgents/com.modeldoki.llmrouter.plist"

log_info "Generated plists (in project):"
log_info "  Open WebUI:  ${OPENWEBUI_PLIST}"
log_info "  LLMRouter:   ${LLMROUTER_PLIST}"

log_header "launchd service installation complete"
log_info "Services will auto-start on login"
log_info "Run scripts/start_all.sh to start immediately"
