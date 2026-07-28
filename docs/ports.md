# Ports Reference

## Port Allocation

| Port | Service | Endpoint | Description |
|------|---------|----------|-------------|
| 1234 | LM Studio | `/v1/chat/completions` | Serves **both** models (see note below) |
| 3333 | Open WebUI | `http://localhost:3333` | Web chat interface |
| 6666 | Bifrost | `http://localhost:6666` | AI gateway & routing (dashboard at `/`) |

> **Why only one LM Studio port?** A single LM Studio instance runs one
> OpenAI-compatible server on one port. Both models (chat and coder) are
> loaded into that server, and it dispatches each request based on the
> request's `model` field. There is no per-model port.

## API Endpoints

### Chat or Coding (direct, via LM Studio)

```
POST http://localhost:1234/v1/chat/completions
```

OpenAI-compatible. The `model` field selects which loaded model answers:

- `qwen2.5-7b-instruct` → Qwen 2.5 7B Instruct (chat)
- `qwen2.5-coder-7b-instruct` → Qwen 2.5-Coder 7B Instruct (coding)

### Bifrost Gateway (routed)

```
POST http://localhost:6666/v1/chat/completions
```

Accepts any model name — Bifrost forwards the request to LM Studio (port 1234).
Use either model name; unknown names fall back to LM Studio's default.

Bifrost also provides a web dashboard at `http://localhost:6666/`.

## Port Conflict Resolution

If a port is already in use, you can identify the process with:

```bash
lsof -i :<port>
```

Common conflicts:

- **Port 3333**: Another Open WebUI instance or web application
- **Port 6666**: Another dashboard or web server
- **Port 1234**: Another LM Studio or llama.cpp server instance

To free a port:

```bash
lsof -ti :<port> | xargs kill -TERM
```

## Changing Ports

To change any port, update:

1. `configs/openwebui.env` — Open WebUI port (`OPENWEBUI_PORT`)
2. `~/.modeldoki/bifrost/config.json` — Bifrost config (port is set via `--port` in the launchd plist)
3. Run `scripts/configure_launchd.sh` to regenerate the launchd plists
4. Run `scripts/restart_all.sh` to apply changes
