#!/usr/bin/env zsh
#
# Test the coding endpoint (Qwen 2.5-Coder 7B Instruct via LM Studio on port 1337)
#
set -euo pipefail

API_URL="${API_URL:-http://localhost:1337/v1/chat/completions}"
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
