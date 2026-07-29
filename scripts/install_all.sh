#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_header "modeldoki — Full Install & Start"

# ─── 1. System dependencies ───────────────────────────────────────────────
log_step "Installing system dependencies"
"${SCRIPT_DIR}/install_homebrew.sh"

# ─── 2. LM Studio ─────────────────────────────────────────────────────────
log_step "Installing LM Studio"
"${SCRIPT_DIR}/install_lmstudio.sh"

# ─── 3. Open WebUI ────────────────────────────────────────────────────────
log_step "Installing Open WebUI"
"${SCRIPT_DIR}/install_openwebui.sh"

# ─── 4. Bifrost ───────────────────────────────────────────────────────────
log_step "Installing Bifrost"
"${SCRIPT_DIR}/install_bifrost.sh"

# ─── 5. Model + configure everything ──────────────────────────────────────
log_step "Ensuring model and configuring all services"
"${SCRIPT_DIR}/install_models.sh"

# ─── 6. Launchd services ──────────────────────────────────────────────────
log_step "Installing launchd services"
"${SCRIPT_DIR}/configure_launchd.sh"

# ─── 7. Start everything ──────────────────────────────────────────────────
log_step "Starting all services"
"${SCRIPT_DIR}/start_all.sh"

log_header "modeldoki is up and running"
log_info "Open WebUI:       http://localhost:3333"
log_info "Bifrost Gateway:  http://localhost:6666"
log_info "LM Studio API:    http://localhost:1234/v1"
