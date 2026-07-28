#!/usr/bin/env zsh
#
# Test the coding endpoint (Qwen 2.5-Coder 7B Instruct, routed via Bifrost).
# Set API_URL=http://localhost:1234/v1/chat/completions to hit LM Studio directly.
#
set -euo pipefail

API_URL="${API_URL:-http://localhost:6666/v1/chat/completions}"
MODEL="${MODEL:-qwen2.5-coder-7b-instruct}"

curl -s "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "'"$MODEL"'",
    "messages": [
      {"role": "system", "content": "You are an expert programmer."},
      {"role": "user", "content": "Write a Python function to compute the nth Fibonacci number using recursion with memoization."}
    ],
    "temperature": 0.2,
    "max_tokens": 500
  }' | jq '.choices[0].message.content'
