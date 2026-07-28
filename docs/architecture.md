# Architecture

## Overview

ModelDoki provides a complete local AI workstation on macOS. All services run natively on Apple Silicon, managed by `launchd` instead of Docker.

## System Diagram

```mermaid
graph TB
    subgraph Browser["Browser"]
        OW[Open WebUI<br/>localhost:3333]
    end

    subgraph Tools["Developer Tools"]
        OC[OpenCode<br/>OpenAI-compatible]
    end

    subgraph Router["LLMRouter<br/>localhost:6666"]
        LR[Routing Engine]
        DB[Dashboard]
    end

    subgraph LMStudio["LM Studio — localhost:1234"]
        CHAT[Qwen 2.5 7B Instruct<br/>model: qwen2.5-7b-instruct]
        CODER[Qwen 2.5-Coder 7B Instruct<br/>model: qwen2.5-coder-7b-instruct]
    end

    OW -->|Chat requests| CHAT
    OC -->|/v1/chat/completions| LR
    LR -->|model: qwen2.5-7b-instruct| CHAT
    LR -->|model: qwen2.5-coder-7b-instruct| CODER
    DB -->|Admin UI| LR
```

## Component Descriptions

### LM Studio

- Native macOS application for running local LLMs
- Exposes **one** OpenAI-compatible endpoint on port 1234
- Both models are loaded simultaneously; the server dispatches each request
  by its `model` field:
  - `qwen2.5-7b-instruct` → Qwen 2.5 7B Instruct (chat/general)
  - `qwen2.5-coder-7b-instruct` → Qwen 2.5-Coder 7B Instruct (coding)
- GPU acceleration via Metal on Apple Silicon

### Open WebUI

- Feature-rich chat interface
- Connects to the LM Studio endpoint (port 1234)
- Runs natively via Python (uv/pip) — no Docker required
- Provides: conversation management, markdown rendering, code highlighting

### LLMRouter

- Smart request router in front of LM Studio
- Exposes an OpenAI-compatible API at port 6666
- Routes based on model name prefix:
  - `qwen2.5-7b-instruct*` → chat model
  - `qwen2.5-coder-7b-instruct*` → coder model
- Provides an admin dashboard at port 6666

### OpenCode

- CLI coding assistant
- Connects to the routed endpoint at port 6666 (or directly to LM Studio
  at port 1234) with model `qwen2.5-coder-7b-instruct`
- Uses the OpenAI-compatible `/v1/chat/completions` API

## Data Flow

1. **Chat flow**: Browser → Open WebUI (3333) → LM Studio (1234) → Qwen 2.5 7B
2. **Coding flow**: OpenCode → LLMRouter (6666) → LM Studio (1234) → Qwen 2.5-Coder 7B
3. **Routed flow**: Any client → LLMRouter (6666) → routing rules → LM Studio (1234) → selected model

## Process Management

All services (except LM Studio) are managed by `launchd`:

- `com.modeldoki.openwebui` — Open WebUI server
- `com.modeldoki.llmrouter` — LLMRouter server

LM Studio is managed via its GUI or CLI (`~/.lmstudio/bin/lms`).
