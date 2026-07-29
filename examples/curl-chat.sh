#!/usr/bin/env zsh
#
# Test the LM Studio endpoint (Qwen 3.5 9B)
#
set -euo pipefail

API_URL="${API_URL:-http://localhost:1234/v1/chat/completions}"
MODEL="${MODEL:-qwen3.5-9b}"

curl -s "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "'"$MODEL"'",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "What is the capital of France? Reply in one sentence."}
    ],
    "temperature": 0.7,
    "max_tokens": 100
  }' | jq '.choices[0].message.content'
