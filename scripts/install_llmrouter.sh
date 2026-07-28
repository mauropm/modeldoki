#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_header "modeldoki — LLMRouter Installation"

check_macos_version
check_apple_silicon

LLMROUTER_DIR="${HOME}/.modeldoki/llmrouter"
LLMROUTER_BIN="${LLMROUTER_DIR}/llm-router"
LLMROUTER_VERSION="v0.4.6"
# TODO: point this at the actual LLMRouter repository for your deployment.
LLMROUTER_REPO="${LLMROUTER_REPO:-https://github.com/your-org/llm-router}"
LLMROUTER_REPO_API="${LLMROUTER_REPO/github.com/api.github.com\/repos}"

if [[ -x "$LLMROUTER_BIN" ]]; then
  log_ok "LLMRouter binary found at ${LLMROUTER_BIN}"
else
  log_step "Downloading LLMRouter binary"

  mkdir -p "$LLMROUTER_DIR"

  LATEST_TAG=$(curl -sfL "${LLMROUTER_REPO_API}/releases/latest" 2>/dev/null | \
    jq -r '.tag_name // empty' 2>/dev/null || echo "")
  LLMROUTER_TAG="${LATEST_TAG:-$LLMROUTER_VERSION}"

  DOWNLOAD_URL="${LLMROUTER_REPO}/releases/download/${LLMROUTER_TAG}/llm-router-darwin-arm64"

  log_info "Downloading LLMRouter ${LLMROUTER_TAG} from ${DOWNLOAD_URL}..."
  if curl -fSL -o "$LLMROUTER_BIN" "$DOWNLOAD_URL" 2>/dev/null; then
    chmod +x "$LLMROUTER_BIN"
    log_ok "LLMRouter downloaded and installed"
  else
    log_warn "Could not download pre-built binary."
    log_step "Attempting to build LLMRouter from source"

    if check_cmd go; then
      log_info "Building with Go..."
      BUILD_DIR=$(mktemp -d)
      if git clone --depth 1 "${LLMROUTER_REPO}.git" "$BUILD_DIR" 2>/dev/null && \
         (cd "$BUILD_DIR" && go build -o "$LLMROUTER_BIN" .); then
        chmod +x "$LLMROUTER_BIN"
        log_ok "LLMRouter built from source"
      else
        log_error "Build failed."
        log_error "Set LLMROUTER_REPO to a reachable repository, e.g.:"
        log_error "  LLMROUTER_REPO=https://github.com/<org>/llm-router $0"
        log_error "Or install the binary manually to: ${LLMROUTER_BIN}"
        rm -rf "$BUILD_DIR"
        exit 1
      fi
      rm -rf "$BUILD_DIR"
    else
      log_error "Go is not installed and no pre-built binary is available."
      log_error "Either: brew install go   (then re-run this script)"
      log_error "Or install the llm-router binary manually to: ${LLMROUTER_BIN}"
      exit 1
    fi
  fi
fi

log_header "LLMRouter installation complete"
log_info "Binary: ${LLMROUTER_BIN}"
log_info "Run scripts/configure_llmrouter.sh to set up routing"
