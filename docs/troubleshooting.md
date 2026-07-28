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

# Check logs
ls -la ~/.lmstudio/logs/
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

### LLMRouter not responding

```bash
# Check binary exists
ls -la ~/.modeldoki/llmrouter/llm-router

# Check config
ls -la configs/llmrouter.yaml

# Check logs
tail -f logs/llmrouter.stderr.log
```

### Port already in use

```bash
# Find what's using a port
lsof -i :3333

# Kill the process
lsof -ti :3333 | xargs kill -TERM
```

### Models won't download

```bash
# Check internet connectivity
ping -c 3 huggingface.co

# Check disk space
df -h /

# Manual download URL
# Visit https://huggingface.co/Qwen/Qwen2.5-7B-Instruct-GGUF
# Download Q4_K_M version to models/
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
./scripts/install_llmrouter.sh
./scripts/install_models.sh
./scripts/configure_lmstudio.sh
./scripts/configure_openwebui.sh
./scripts/configure_llmrouter.sh
./scripts/configure_launchd.sh
./scripts/start_all.sh
```

## Getting Help

- [Open an issue](https://github.com/anomalyco/modeldoki/issues)
- Check `docs/memory.md` for memory-related tips
- Run `./scripts/doctor.sh` and include the output in your issue
