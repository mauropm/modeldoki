#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

log_header "modeldoki — Model Installation"

check_macos_version
check_apple_silicon

require jq
require curl

HUGGINGFACE_API="https://huggingface.co/api/models"

# ─── Model definitions ─────────────────────────────────────────────────────
# Each entry: name|repo|quantization
# Note: on Hugging Face, qwen2.5-7b-instruct-q4_k_m is shipped as TWO shard
# files (-00001-of-00002, -00002-of-00002); qwen2.5-coder-7b-instruct-q4_k_m
# is a single file. Both are handled transparently.

MODELS=(
  "qwen2.5-7b-instruct|Qwen/Qwen2.5-7B-Instruct-GGUF|q4_k_m"
  "qwen2.5-coder-7b-instruct|Qwen/Qwen2.5-Coder-7B-Instruct-GGUF|q4_k_m"
)

# ─── Discover model files from Hugging Face ────────────────────────────────
# Prints the file name(s) to download for the given model/quant, one per line.
# Prefers the single-file variant; falls back to all shards of a split model.
discover_model_files() {
  local name="$1"
  local repo="$2"
  local quant="$3"

  local response
  response=$(curl -sfL "${HUGGINGFACE_API}/${repo}/tree/main" 2>/dev/null || echo "")
  [[ -n "$response" ]] || return 1

  # jq test() takes a REGEX (not a glob).
  local regex="^${name}-${quant}(-[0-9]+-of-[0-9]+)?\\.gguf\$"
  local -a files
  files=( ${(f)"$(echo "$response" | jq -r --arg re "$regex" \
    '.[] | select(.type == "file") | select(.path | test($re)) | .path' 2>/dev/null)"} )

  (( ${#files[@]} > 0 )) || return 1

  local single="${name}-${quant}.gguf"
  if (( ${files[(Ie)$single]} )); then
    print -r -- "$single"
  else
    print -rl -- "${files[@]}"
  fi
}

# ─── Fallback file lists if discovery fails ────────────────────────────────
fallback_model_files() {
  local name="$1"
  local quant="$2"

  case "$name" in
    qwen2.5-7b-instruct)
      # Only shipped as a 2-shard split in this quantization.
      print -r -- "${name}-${quant}-00001-of-00002.gguf"
      print -r -- "${name}-${quant}-00002-of-00002.gguf"
      ;;
    qwen2.5-coder-7b-instruct)
      print -r -- "${name}-${quant}.gguf"
      ;;
    *)
      return 1
      ;;
  esac
}

# ─── Download one model (all of its files) ─────────────────────────────────
download_model() {
  local name="$1"
  local repo="$2"
  local quant="$3"

  if resolve_model_file "$name" >/dev/null 2>&1; then
    local existing
    existing=$(resolve_model_file "$name")
    local size_mb
    size_mb=$(($(stat -f%z "$existing" 2>/dev/null || stat -c%s "$existing" 2>/dev/null) / 1048576))
    log_ok "${name} already downloaded (${existing##*/}, ${size_mb} MB)"
    return 0
  fi

  log_step "Resolving files for ${name} (${quant})"

  local -a files
  # `|| true` inside the substitution: without it, set -e would abort here
  # when discovery fails, before the fallback gets a chance to run.
  files=( ${(f)"$(discover_model_files "$name" "$repo" "$quant" || true)"} )
  if (( ${#files[@]} == 0 )); then
    log_info "Discovery failed, using fallback file list"
    files=( ${(f)"$(fallback_model_files "$name" "$quant" || true)"} )
  fi

  if (( ${#files[@]} == 0 )); then
    log_error "No files could be determined for ${name}"
    log_info "Download manually from: https://huggingface.co/${repo}"
    return 1
  fi

  local fname url dest
  for fname in "${files[@]}"; do
    url="https://huggingface.co/${repo}/resolve/main/${fname}"
    dest="${MODELS_DIR}/${fname}"

    if [[ -f "$dest" ]]; then
      log_ok "${fname} already downloaded"
      continue
    fi

    log_info "Downloading ${fname}"
    if download_with_retry "$url" "${dest}.part" 5; then
      mv "${dest}.part" "$dest"
      local size_mb
      size_mb=$(($(stat -f%z "$dest" 2>/dev/null || stat -c%s "$dest" 2>/dev/null) / 1048576))
      log_ok "${fname} downloaded (${size_mb} MB)"
    else
      rm -f "${dest}.part"
      log_error "Failed to download ${fname}"
      log_info "You can manually download it from: ${url}"
      return 1
    fi
  done

  if resolve_model_file "$name" >/dev/null 2>&1; then
    log_ok "${name} ready"
  else
    log_error "${name} incomplete after download"
    return 1
  fi
}

# ─── Main ──────────────────────────────────────────────────────────────────
for entry in "${MODELS[@]}"; do
  model_name="${entry%%|*}"
  rest="${entry#*|}"
  repo="${rest%%|*}"
  quantization="${rest##*|}"

  log_info "Model: ${model_name} | Repo: ${repo} | Quant: ${quantization}"
  download_model "$model_name" "$repo" "$quantization" || true
done

log_header "Model installation complete"
log_info "Models stored in: ${MODELS_DIR}"
gguf_list=( "${MODELS_DIR}"/*.gguf )
if (( ${#gguf_list[@]} > 0 )); then
  ls -lh "${gguf_list[@]}" | while read -r line; do
    log_info "${line}"
  done
else
  log_warn "No GGUF models found in ${MODELS_DIR}"
fi
