# Troubleshooting

## Quick Diagnostics

```bash
./scripts/doctor.sh   # System health check
./scripts/status.sh   # Running services and ports
```

## Common Issues

### LM Studio won't start

```bash
# Check if it's installed
ls -la /Applications/LM\ Studio.app

# Try launching manually
open -a "LM Studio"

# Check the CLI is available
~/.lmstudio/bin/lms server status

# Check logs
ls -la ~/.lmstudio/server-logs/
```

### Open WebUI won't start

```bash
# Check logs
tail -f logs/openwebui.stderr.log

# Verify virtual environment
ls ~/.modeldoki/open-webui/.venv/bin/python

# Reinstall
./scripts/install_openwebui.sh
```

### Bifrost not responding

```bash
# Check binary exists
ls -la ~/.modeldoki/bifrost/bifrost-http

# Check config
ls -la ~/.modeldoki/bifrost/config.json

# Check logs
tail -f logs/bifrost.stderr.log
```

### Port already in use

```bash
# Find what's using a port
lsof -i :1234

# Kill the process
lsof -ti :1234 | xargs kill -TERM
```

### A model name is not recognized

Both models are served by LM Studio on the single port 1234, dispatched by
the request's `model` field. Check which models are actually loaded:

```bash
~/.lmstudio/bin/lms ps
# Expected identifiers:
#   qwen2.5-7b-instruct
#   qwen2.5-coder-7b-instruct
```

If one is missing, run `./scripts/configure_lmstudio.sh` to import and load it.

### Models won't download

```bash
# Check internet connectivity
ping -c 3 huggingface.co

# Check disk space
df -h /

# Manual download
# Visit https://huggingface.co/Qwen/Qwen2.5-7B-Instruct-GGUF and
# https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF
# Download the Q4_K_M files into models/ keeping their original names:
#   qwen2.5-7b-instruct-q4_k_m-00001-of-00002.gguf   (chat is split — BOTH shards required)
#   qwen2.5-7b-instruct-q4_k_m-00002-of-00002.gguf
#   qwen2.5-coder-7b-instruct-q4_k_m.gguf            (coder is a single file)
```

### Slow inference

```bash
# Check memory pressure
memory_pressure

# Close memory-heavy apps (Chrome, Teams, etc.)
# See docs/memory.md for details

# Try loading only one model at a time
```

### Launchd service won't load

```bash
# Check plist syntax
plutil -lint ~/Library/LaunchAgents/com.modeldoki.openwebui.plist

# Load manually
launchctl load -w ~/Library/LaunchAgents/com.modeldoki.openwebui.plist

# Check service status
launchctl list com.modeldoki.openwebui
```

## Logs

All service logs are stored in `logs/`:

```bash
ls -la logs/
tail -f logs/*.log
```

## Reset Everything

```bash
./scripts/stop_all.sh
./scripts/uninstall.sh
```

Then reinstall step by step:

```bash
./scripts/install_homebrew.sh
./scripts/install_lmstudio.sh
./scripts/install_openwebui.sh
./scripts/install_bifrost.sh
./scripts/install_models.sh
./scripts/configure_lmstudio.sh
./scripts/configure_openwebui.sh
./scripts/configure_bifrost.sh
./scripts/configure_launchd.sh
./scripts/start_all.sh
```

## Getting Help

- [Open an issue](https://github.com/anomalyco/modeldoki/issues)
- Check `docs/memory.md` for memory-related tips
- Run `./scripts/doctor.sh` and include the output in your issue
