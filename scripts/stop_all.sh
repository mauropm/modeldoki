#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_header "modeldoki — Stopping All Services"

# ─── 1. Stop LM Studio server and unload models ─────────────────────────────
log_step "Stopping LM Studio"

if lms_available; then
  "$LMS_CLI" server stop >/dev/null 2>&1 && log_ok "LM Studio server stopped" || \
    log_info "LM Studio server was not running"
  "$LMS_CLI" unload --all >/dev/null 2>&1 && log_ok "Models unloaded" || true
fi

# Terminate any remaining LM Studio processes.
# (zsh: ${(f)...} splits multi-line pgrep output into separate PIDs.)
LM_STUDIO_PIDS=$(pgrep -f "LM Studio" 2>/dev/null || true)
if [[ -n "$LM_STUDIO_PIDS" ]]; then
  log_info "Terminating LM Studio processes..."
  kill -TERM ${(f)LM_STUDIO_PIDS} 2>/dev/null || true
  sleep 2
  LM_STUDIO_PIDS=$(pgrep -f "LM Studio" 2>/dev/null || true)
  if [[ -n "$LM_STUDIO_PIDS" ]]; then
    log_warn "Force-killing remaining LM Studio processes..."
    kill -KILL ${(f)LM_STUDIO_PIDS} 2>/dev/null || true
  fi
  log_ok "LM Studio stopped"
else
  log_info "LM Studio not running"
fi

# ─── 2. Unload Open WebUI ────────────────────────────────────────────────────
log_step "Stopping Open WebUI"

if launchctl list | grep -q "com.modeldoki.openwebui"; then
  OPENWEBUI_PLIST="${HOME}/Library/LaunchAgents/com.modeldoki.openwebui.plist"
  if [[ -f "$OPENWEBUI_PLIST" ]]; then
    launchctl bootout gui/"$(id -u)" "$OPENWEBUI_PLIST" 2>/dev/null || \
      launchctl unload -w "$OPENWEBUI_PLIST" 2>/dev/null || true
    log_ok "Open WebUI stopped"
  fi
else
  log_info "Open WebUI not running"
fi

# Kill any orphaned open-webui processes
OPENWEBUI_PIDS=$(pgrep -f "open-webui" 2>/dev/null || true)
if [[ -n "$OPENWEBUI_PIDS" ]]; then
  kill -TERM ${(f)OPENWEBUI_PIDS} 2>/dev/null || true
  log_ok "Open WebUI orphan processes killed"
fi

# ─── 3. Unload LLMRouter ────────────────────────────────────────────────────
log_step "Stopping LLMRouter"

if launchctl list | grep -q "com.modeldoki.llmrouter"; then
  LLMROUTER_PLIST="${HOME}/Library/LaunchAgents/com.modeldoki.llmrouter.plist"
  if [[ -f "$LLMROUTER_PLIST" ]]; then
    launchctl bootout gui/"$(id -u)" "$LLMROUTER_PLIST" 2>/dev/null || \
      launchctl unload -w "$LLMROUTER_PLIST" 2>/dev/null || true
    log_ok "LLMRouter stopped"
  fi
else
  log_info "LLMRouter not running"
fi

LLMROUTER_PIDS=$(pgrep -f "llm-router" 2>/dev/null || true)
if [[ -n "$LLMROUTER_PIDS" ]]; then
  kill -TERM ${(f)LLMROUTER_PIDS} 2>/dev/null || true
  log_ok "LLMRouter orphan processes killed"
fi

# ─── 4. Verify ports are free ────────────────────────────────────────────────
log_step "Verifying ports"
sleep 1

for port in 1234 3333 6666; do
  if port_in_use "$port"; then
    log_warn "Port ${port} is still in use — you may need to force-kill:"
    log_info "  lsof -ti :${port} | xargs kill -KILL"
  else
    log_ok "Port ${port} is free"
  fi
done

log_header "All services stopped"
