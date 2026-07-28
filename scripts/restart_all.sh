#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_header "modeldoki — Restarting All Services"

"${SCRIPT_DIR}/stop_all.sh"
sleep 2
"${SCRIPT_DIR}/start_all.sh"

log_header "Restart complete"
