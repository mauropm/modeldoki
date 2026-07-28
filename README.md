# ModelDoki

> macOS-first setup toolkit for a complete local LLM workstation. No Docker required.

ModelDoki automates the installation and configuration of a local AI development environment on Apple Silicon Macs. It sets up LM Studio, Open WebUI, LLMRouter, and downloads optimized models — all managed natively with `launchd`.

## Architecture

```
Browser                    Developer Tools (OpenCode, etc.)
    │                              │
    ▼                              ▼
Open WebUI                 LLMRouter (localhost:6666)
:3333                           │
    │                    ┌───────┴───────┐
    ▼                    ▼               ▼
LM Studio Chat     LM Studio Chat   LM Studio Coder
:1234               :1234             :1337
    │                    │               │
Qwen 2.5 7B          Qwen 2.5 7B    Qwen 2.5-Coder 7B
```

## Quick Start

```bash
git clone https://github.com/anomalyco/modeldoki.git
cd modeldoki

./scripts/install_homebrew.sh
./scripts/install_lmstudio.sh
./scripts/install_openwebui.sh
./scripts/install_llmrouter.sh
./scripts/install_models.sh        # Downloads Qwen 2.5 models (~8 GB total)

./scripts/configure_lmstudio.sh
./scripts/configure_openwebui.sh
./scripts/configure_llmrouter.sh
./scripts/configure_launchd.sh     # Installs launchd services

./scripts/start_all.sh
```

Once running:

| Service | URL | Purpose |
|---------|-----|---------|
| Open WebUI | http://localhost:3333 | Chat interface with Qwen 2.5 7B |
| Coding API | http://localhost:1337/v1 | OpenAI-compatible (Qwen 2.5-Coder) |
| LLMRouter | http://localhost:6666 | Admin dashboard & request routing |

## Requirements

- macOS Sonoma 14+ (Sequoia 15 recommended)
- Apple Silicon (M1/M2/M3/M4)
- 16 GB RAM minimum (32 GB recommended)
- ~15 GB free disk space
- Internet connection for downloads

## Installation Steps

Each script is **idempotent** — running them multiple times is safe.

1. **`install_homebrew.sh`** — Installs Homebrew and required packages (python, uv, node, git, jq, wget)
2. **`install_lmstudio.sh`** — Installs LM Studio via Homebrew cask or direct download
3. **`install_openwebui.sh`** — Installs Open WebUI in a Python virtual environment (no Docker)
4. **`install_llmrouter.sh`** — Installs LLMRouter binary for request routing
5. **`install_models.sh`** — Downloads Qwen 2.5 7B Instruct and Qwen 2.5-Coder 7B Instruct (Q4_K_M)
6. **`configure_lmstudio.sh`** — Configures LM Studio endpoints and model loading
7. **`configure_openwebui.sh`** — Configures Open WebUI to use LM Studio
8. **`configure_llmrouter.sh`** — Sets up routing rules
9. **`configure_launchd.sh`** — Creates launchd plists for auto-start on login

## Utility Scripts

| Script | Purpose |
|--------|---------|
| `start_all.sh` | Starts all services |
| `stop_all.sh` | Gracefully stops all services |
| `restart_all.sh` | Restarts all services |
| `status.sh` | Shows running processes, ports, memory, GPU |
| `doctor.sh` | System diagnostics and health check |
| `update.sh` | Updates packages and checks for new models |
| `uninstall.sh` | Removes all services, configs, and optionally models |

## OpenCode Configuration

To use OpenCode with the coding endpoint, save this to `~/.config/opencode.json`:

```json
{
  "provider": "openai",
  "base_url": "http://localhost:1337/v1",
  "api_key": "dummy",
  "model": "qwen2.5-coder-7b-instruct"
}
```

Test it:

```bash
opencode "Write a Python function to merge two sorted lists."
```

Or with curl:

```bash
./examples/curl-coder.sh
```

## Model Routing

LLMRouter at `localhost:6666` automatically routes requests:

| Request Model | Routes To |
|---------------|-----------|
| `qwen2.5-7b-instruct*` | Qwen 2.5 7B (chat, port 1234) |
| `qwen2.5-coder-7b-instruct*` | Qwen 2.5-Coder 7B (coding, port 1337) |
| `*coder*` | Qwen 2.5-Coder 7B (coding, port 1337) |
| Anything else | Qwen 2.5 7B (chat, port 1234, default) |

## Memory Recommendations

Running two 7B models simultaneously on 16 GB RAM requires careful memory management.

- Close Chrome, Teams, Slack, Docker Desktop, and other memory-heavy apps before loading models
- Aim for at least **6–8 GB free memory** before loading a 7B model
- Monitor with `memory_pressure` or Activity Monitor
- If swapping occurs, inference will be 10–100x slower
- Start with one model at a time if memory pressure is high

See [docs/memory.md](docs/memory.md) for detailed guidance.

## Project Layout

```
modeldoki/
├── scripts/           # Installation, configuration, management
├── configs/           # Service configurations and launchd plists
├── docs/              # Architecture, memory, ports, troubleshooting
├── examples/          # curl examples and OpenCode config
├── models/            # Downloaded GGUF models (gitignored)
├── logs/              # Service logs (gitignored)
└── .github/           # CI, issue templates, PR template
```

## Uninstalling

```bash
./scripts/uninstall.sh
```

You can optionally keep downloaded models and chat history.

## FAQ

**Why no Docker?**  
Docker adds overhead, consumes significant memory, and complicates GPU passthrough on macOS. Native processes with `launchd` are simpler and more performant.

**Can I add more models?**  
Yes. Place GGUF files in `models/` and update `configs/llmrouter.yaml` with new upstream entries and routing rules.

**Can I change ports?**  
Yes. Update `configs/openwebui.env` and `configs/llmrouter.yaml`, then reconfigure launchd.

**Does this work on Intel Macs?**  
No. This project targets Apple Silicon. Intel Macs lack the unified memory and GPU acceleration that make local LLMs practical.

**Why LM Studio instead of ollama?**  
LM Studio provides a GUI, built-in server management, and easy model configuration. Ollama is also compatible — you can adapt the scripts if preferred.

## Contributing

See `.github/PULL_REQUEST_TEMPLATE.md`. All scripts must be ShellCheck-compliant and use `set -euo pipefail`.

## License

MIT
