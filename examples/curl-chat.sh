#!/usr/bin/env zsh
#
# Test the chat endpoint (Qwen 2.5 7B Instruct via LM Studio)
#
set -euo pipefail

API_URL="${API_URL:-http://localhost:1234/v1/chat/completions}"
MODEL="${MODEL:-qwen2.5-7b-instruct}"

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
