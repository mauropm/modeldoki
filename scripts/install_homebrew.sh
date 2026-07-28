#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_header "modeldoki — Homebrew Installation"

check_macos_version
check_apple_silicon

if check_cmd brew; then
  brew_version="$(brew --version 2>/dev/null | head -1)"
  log_ok "Homebrew already installed: ${brew_version}"
else
  log_step "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ "$(uname -m)" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  if ! check_cmd brew; then
    log_error "Homebrew installation failed."
    exit 1
  fi
  log_ok "Homebrew installed: $(brew --version 2>/dev/null | head -1)"
fi

log_step "Installing required packages"
brew_packages=(
  python
  uv
  node
  git
  jq
  wget
  curl
)

for pkg in "${brew_packages[@]}"; do
  if brew list "$pkg" &>/dev/null; then
    log_ok "${pkg} already installed"
  else
    log_info "Installing ${pkg}..."
    brew install "$pkg"
    log_ok "${pkg} installed"
  fi
done

log_header "Homebrew installation complete"
