#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_header "modeldoki — Uninstall"

log_warn "This will remove modeldoki services and configurations."
printf "Are you sure? [y/N] "
read -r confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  log_info "Uninstall cancelled."
  exit 0
fi

# ─── Stop all services ─────────────────────────────────────────────────────
log_step "Stopping all services"
"${SCRIPT_DIR}/stop_all.sh"

# ─── Remove launchd services ───────────────────────────────────────────────
log_step "Removing launchd services"
uninstall_launchd_service "openwebui" "${HOME}/Library/LaunchAgents/com.modeldoki.openwebui.plist"
uninstall_launchd_service "llmrouter" "${HOME}/Library/LaunchAgents/com.modeldoki.llmrouter.plist"

# ─── Remove symlinks and configs ───────────────────────────────────────────
log_step "Removing configurations"
rm -f "${HOME}/.lmstudio/config.json" 2>/dev/null || true

# ─── Ask about models ──────────────────────────────────────────────────────
printf "\nRemove downloaded models? (y/N) "
read -r remove_models
if [[ "$remove_models" =~ ^[Yy]$ ]]; then
  log_step "Removing models"
  rm -rf "${MODELS_DIR}"/*.gguf "${MODELS_DIR}"/*/ 2>/dev/null || true
  log_ok "Models removed"
else
  log_info "Models preserved at ${MODELS_DIR}"
fi

# ─── Ask about data ────────────────────────────────────────────────────────
printf "\nRemove Open WebUI data (chat history, settings)? (y/N) "
read -r remove_data
if [[ "$remove_data" =~ ^[Yy]$ ]]; then
  log_step "Removing Open WebUI data"
  rm -rf "${HOME}/.modeldoki/open-webui/data" 2>/dev/null || true
  log_ok "Open WebUI data removed"
fi

# ─── Ask about full cleanup ────────────────────────────────────────────────
printf "\nRemove all modeldoki data from ~/.modeldoki? (y/N) "
read -r remove_alldata
if [[ "$remove_alldata" =~ ^[Yy]$ ]]; then
  rm -rf "${HOME}/.modeldoki" 2>/dev/null || true
  log_ok "modeldoki data directory removed"
fi

# ─── Remove logs ───────────────────────────────────────────────────────────
log_step "Removing logs"
rm -f "${LOGS_DIR}"/*.log 2>/dev/null || true
log_ok "Logs removed"

log_header "Uninstall complete"
log_info "To also remove Homebrew packages, run:"
log_info "  brew uninstall python uv node git jq wget"
log_info "  brew uninstall --cask lm-studio"
