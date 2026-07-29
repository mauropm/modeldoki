# Ports Reference

## Port Allocation

| Port | Service | Endpoint | Description |
|------|---------|----------|-------------|
| 1234 | LM Studio | `/v1/chat/completions` | Serves Qwen 3.5 9B |
| 3333 | Open WebUI | `http://localhost:3333` | Web chat interface |
| 6666 | Bifrost | `http://localhost:6666` | AI gateway & routing (dashboard at `/`) |

> LM Studio runs a single OpenAI-compatible server on one port with
> Qwen 3.5 9B loaded. The API accepts any `model` value — the server
> always responds with the loaded model.

## API Endpoints

### Direct (via LM Studio)

```
POST http://localhost:1234/v1/chat/completions
```

OpenAI-compatible. Any `model` value reaches the loaded Qwen 3.5 9B.

### Bifrost Gateway (routed)

```
POST http://localhost:6666/v1/chat/completions
```

Accepts any model name — Bifrost forwards the request to LM Studio (port 1234).
The loaded Qwen 3.5 9B answers all requests.

Bifrost also provides a web dashboard at `http://localhost:6666/`.

## Port Conflict Resolution

If a port is already in use, you can identify the process with:

```bash
lsof -i :<port>
```

Common conflicts:

- **Port 3333**: Another Open WebUI instance or web application
- **Port 6666**: Another dashboard or web server
- **Port 1234**: Another LM Studio instance

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
