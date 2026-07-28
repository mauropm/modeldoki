#!/usr/bin/env zsh
#
# modeldoki - shared library
# Source this file from any script in this directory.
#

set -euo pipefail

# Expand non-matching globs to nothing instead of erroring (zsh default is NOMATCH).
setopt NULL_GLOB

# ─── Colors ────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  readonly RED='\033[0;31m'
  readonly GREEN='\033[0;32m'
  readonly YELLOW='\033[1;33m'
  readonly BLUE='\033[0;34m'
  readonly MAGENTA='\033[0;35m'
  readonly CYAN='\033[0;36m'
  readonly BOLD='\033[1m'
  readonly NC='\033[0m'
else
  readonly RED=''
  readonly GREEN=''
  readonly YELLOW=''
  readonly BLUE=''
  readonly MAGENTA=''
  readonly CYAN=''
  readonly BOLD=''
  readonly NC=''
fi

# ─── Paths ──────────────────────────────────────────────────────────────────
readonly PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
readonly SCRIPTS_DIR="${PROJECT_DIR}/scripts"
readonly CONFIGS_DIR="${PROJECT_DIR}/configs"
readonly LAUNCHD_DIR="${CONFIGS_DIR}/launchd"
readonly DOCS_DIR="${PROJECT_DIR}/docs"
readonly EXAMPLES_DIR="${PROJECT_DIR}/examples"
readonly LOGS_DIR="${PROJECT_DIR}/logs"
readonly MODELS_DIR="${PROJECT_DIR}/models"

mkdir -p "${LOGS_DIR}" "${MODELS_DIR}"

# ─── Logging helpers ────────────────────────────────────────────────────────
log_info()   { printf "${BLUE}  [INFO]${NC}  %s\n" "$*"; }
log_ok()     { printf "${GREEN}   [OK]${NC}  %s\n" "$*"; }
log_warn()   { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
log_error()  { printf "${RED}[ERROR]${NC} %s\n" "$*"; }
log_step()   { printf "\n${BOLD}${CYAN}──── %s ────${NC}\n" "$*"; }
log_header() { printf "${BOLD}${MAGENTA}━━━ %s ━━━${NC}\n" "$*"; }

# ─── Command checks ─────────────────────────────────────────────────────────
require() {
  local cmd="$1"
  if ! command -v "$cmd" &>/dev/null; then
    log_error "'${cmd}' is required but not found."
    return 1
  fi
}

check_cmd() {
  command -v "$1" &>/dev/null
}

# ─── Sudo elevation ─────────────────────────────────────────────────────────
ensure_sudo() {
  if [[ $EUID -ne 0 ]]; then
    log_info "Elevating privileges with sudo..."
    exec sudo "$0" "$@"
  fi
}

# ─── macOS version check ────────────────────────────────────────────────────
check_macos_version() {
  local version major minor
  version="$(sw_vers -productVersion 2>/dev/null)"
  major="${version%%.*}"
  minor="${${version#*.}%%.*}"
  if [[ "$major" -lt 14 ]]; then
    log_error "macOS Sonoma (14) or later required. Detected: ${version}"
    return 1
  fi
  log_ok "macOS ${version} (>= 14)"
}

# ─── Apple Silicon check ────────────────────────────────────────────────────
check_apple_silicon() {
  local arch
  arch="$(uname -m)"
  if [[ "$arch" != "arm64" ]]; then
    log_error "Apple Silicon (arm64) required. Detected: ${arch}"
    return 1
  fi
  log_ok "Apple Silicon (${arch})"
}

# ─── RAM check ──────────────────────────────────────────────────────────────
check_ram() {
  local total_gb
  total_gb=$(($(sysctl -n hw.memsize) / 1073741824))
  if [[ "$total_gb" -lt 16 ]]; then
    log_warn "16 GB RAM recommended. Detected: ${total_gb} GB"
  else
    log_ok "${total_gb} GB RAM"
  fi
}

# ─── Port availability ──────────────────────────────────────────────────────
port_available() {
  local port="$1"
  if lsof -i :"$port" &>/dev/null; then
    return 1
  fi
  return 0
}

port_in_use() {
  ! port_available "$@"
}

# ─── Launchd helpers ────────────────────────────────────────────────────────
launchd_label_for() {
  local name="$1"
  echo "com.modeldoki.${name}"
}

launchd_plist_path() {
  local name="$1"
  echo "${LAUNCHD_DIR}/com.modeldoki.${name}.plist"
}

launchd_user_plist() {
  local name="$1"
  echo "${HOME}/Library/LaunchAgents/com.modeldoki.${name}.plist"
}

install_launchd_service() {
  local name="$1"
  local src="$2"
  local dst="$3"

  mkdir -p "${HOME}/Library/LaunchAgents"
  cp "$src" "$dst"
  log_info "Installed launchd plist for ${name}"

  launchctl load -w "$dst" 2>/dev/null && log_ok "Loaded ${name}" || {
    if launchctl bootstrap gui/"$(id -u)" "$dst" 2>/dev/null; then
      log_ok "Bootstrapped ${name} via launchctl bootstrap"
    else
      log_warn "Could not load ${name} automatically. Run: launchctl load -w ${dst}"
    fi
  }
}

uninstall_launchd_service() {
  local name="$1"
  local dst="$2"

  if [[ -f "$dst" ]]; then
    launchctl bootout gui/"$(id -u)" "$dst" 2>/dev/null || true
    launchctl unload -w "$dst" 2>/dev/null || true
    rm -f "$dst"
    log_ok "Unloaded and removed ${name}"
  fi
}

# ─── Download helpers ───────────────────────────────────────────────────────
download_with_retry() {
  local url="$1"
  local dest="$2"
  local max_attempts="${3:-3}"
  local attempt=1

  mkdir -p "$(dirname "$dest")"

  while [[ "$attempt" -le "$max_attempts" ]]; do
    log_info "Downloading (attempt ${attempt}/${max_attempts}): ${url}"
    if wget -q --show-progress -c "$url" -O "$dest" 2>/dev/null; then
      log_ok "Downloaded to ${dest}"
      return 0
    fi
    if curl -fSL -o "$dest" "$url" 2>/dev/null; then
      log_ok "Downloaded to ${dest}"
      return 0
    fi
    log_warn "Download failed (attempt ${attempt}/${max_attempts})"
    attempt=$((attempt + 1))
    sleep 2
  done

  log_error "Failed to download after ${max_attempts} attempts: ${url}"
  return 1
}

# ─── Model file resolution ──────────────────────────────────────────────────
# Echo the loadable GGUF path for a model name. Handles both single-file
# models (name-q4_k_m.gguf) and multi-shard models (name-q4_k_m-00001-of-00002.gguf
# + siblings — llama.cpp/LM Studio only needs the first shard path).
# Returns 1 if no file for the model exists.
resolve_model_file() {
  local name="$1"
  local exact="${MODELS_DIR}/${name}.gguf"
  if [[ -f "$exact" ]]; then
    print -r -- "$exact"
    return 0
  fi
  local -a matches=( "${MODELS_DIR}/${name}"*.gguf )
  (( ${#matches[@]} > 0 )) || return 1
  local f
  for f in "${matches[@]}"; do
    if [[ "$f" == *-00001-of-*.gguf ]]; then
      print -r -- "$f"
      return 0
    fi
  done
  print -r -- "${matches[1]}"
}

# ─── LM Studio CLI ───────────────────────────────────────────────────────────
LMS_CLI="${HOME}/.lmstudio/bin/lms"

lms_available() {
  [[ -x "$LMS_CLI" ]]
}

# Load a model into LM Studio with a clean API identifier.
# Usage: lms_ensure_model_loaded <gguf-path> <identifier> [context-length]
lms_ensure_model_loaded() {
  local model_file="$1"
  local identifier="$2"
  local context_length="${3:-32768}"

  if ! lms_available; then
    log_warn "LM Studio CLI (lms) not found at ${LMS_CLI}"
    return 1
  fi

  # Already loaded?
  if "$LMS_CLI" ps --json 2>/dev/null | jq -r '.[].identifier' 2>/dev/null | grep -qx "$identifier"; then
    log_ok "${identifier} already loaded"
    return 0
  fi

  # Import (hard-link, keeps the file in models/) — safe to re-run.
  "$LMS_CLI" import "$model_file" --hard-link -y >/dev/null 2>&1 || true

  if "$LMS_CLI" load "$model_file" --identifier "$identifier" \
      --gpu max --context-length "$context_length" -y >/dev/null 2>&1; then
    log_ok "Loaded ${identifier}"
  else
    log_warn "Could not load ${identifier} via lms — load it in the LM Studio GUI"
    return 1
  fi
}

# ─── Version comparison ──────────────────────────────────────────────────────
version_compare() {
  if [[ "$1" == "$2" ]]; then
    return 0
  fi
  # zsh: explicit splitting on '.' (no implicit word splitting like bash)
  local -a ver1 ver2
  ver1=( ${(s:.:)1} )
  ver2=( ${(s:.:)2} )
  local i
  for ((i = ${#ver1[@]}; i < ${#ver2[@]}; i++)); do
    ver1+=("0")
  done
  for ((i = 1; i <= ${#ver1[@]}; i++)); do
    if [[ -z "${ver2[i]:-}" ]]; then
      ver2[i]="0"
    fi
    if ((10#${ver1[i]} > 10#${ver2[i]})); then
      return 1
    fi
    if ((10#${ver1[i]} < 10#${ver2[i]})); then
      return 2
    fi
  done
  return 0
}

# ─── Platform info ──────────────────────────────────────────────────────────
platform_info() {
  printf "macOS %s | %s | %d GB RAM | %s\n" \
    "$(sw_vers -productVersion 2>/dev/null || echo "?")" \
    "$(uname -m)" \
    "$(($(sysctl -n hw.memsize) / 1073741824))" \
    "$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Apple Silicon")"
}
