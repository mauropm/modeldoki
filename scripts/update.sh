#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_header "modeldoki — Update"

# ─── 1. Update Homebrew ────────────────────────────────────────────────────
log_step "Updating Homebrew"
if check_cmd brew; then
  brew update 2>/dev/null && log_ok "Homebrew updated" || log_warn "Homebrew update failed"
  brew upgrade 2>/dev/null && log_ok "Homebrew packages upgraded" || log_warn "Homebrew upgrade failed"
else
  log_warn "Homebrew not installed, skipping"
fi

# ─── 2. Update Python packages ─────────────────────────────────────────────
log_step "Updating Python dependencies"
OPENWEBUI_DIR="${HOME}/.modeldoki/open-webui"
if [[ -f "${OPENWEBUI_DIR}/.venv/bin/pip" ]]; then
  "${OPENWEBUI_DIR}/.venv/bin/pip" install --upgrade open-webui 2>/dev/null && \
    log_ok "Open WebUI updated" || \
    log_warn "Open WebUI update failed"

  "${OPENWEBUI_DIR}/.venv/bin/pip" list --outdated 2>/dev/null | tail -n +3 | head -10 | while read -r line; do
    log_info "Outdated: ${line}"
  done
else
  log_warn "Open WebUI virtual environment not found"
fi

# ─── 3. Check for newer model versions ──────────────────────────────────────
log_step "Checking for newer model versions"

for model_name in "qwen2.5-7b-instruct" "qwen2.5-coder-7b-instruct"; do
  model_file="$(resolve_model_file "$model_name" || true)"
  if [[ -n "$model_file" ]]; then
    size_mb=$(($(stat -f%z "$model_file" 2>/dev/null || stat -c%s "$model_file" 2>/dev/null) / 1048576))
    log_info "${model_name}: ${model_file##*/} (${size_mb} MB, existing)"
    log_info "  Check https://huggingface.co/Qwen for newer versions"
  else
    log_warn "${model_name}: not downloaded"
    log_info "  Run scripts/install_models.sh to download"
  fi
done

# ─── 4. Check for script updates (git) ─────────────────────────────────────
log_step "Checking for project updates"
if [[ -d "${PROJECT_DIR}/.git" ]]; then
  if check_cmd git; then
    git -C "$PROJECT_DIR" fetch --tags 2>/dev/null && log_ok "Git repo updated" || log_warn "Git fetch failed"
    local current_tag
    current_tag=$(git -C "$PROJECT_DIR" describe --tags 2>/dev/null || echo "no-tags")
    local latest_tag
    latest_tag=$(git -C "$PROJECT_DIR" tag --list 2>/dev/null | sort -V | tail -1 || echo "no-tags")
    if [[ "$current_tag" != "$latest_tag" ]]; then
      log_info "Current version: ${current_tag}"
      log_info "Latest version:  ${latest_tag}"
      log_info "Run: git pull to update"
    else
      log_ok "Up to date: ${current_tag}"
    fi
  fi
fi

log_header "Update complete"
log_info "Run scripts/doctor.sh to verify system health"
