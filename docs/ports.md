# Ports Reference

## Port Allocation

| Port | Service | Endpoint | Description |
|------|---------|----------|-------------|
| 1234 | LM Studio Chat | `/v1/chat/completions` | Qwen 2.5 7B Instruct (chat) |
| 1337 | LM Studio Coder | `/v1/chat/completions` | Qwen 2.5-Coder 7B Instruct (coding) |
| 3333 | Open WebUI | `http://localhost:3333` | Web chat interface |
| 6666 | LLMRouter | `http://localhost:6666` | Admin dashboard & routed API |

## API Endpoints

### Chat (Direct)
```
POST http://localhost:1234/v1/chat/completions
```
OpenAI-compatible. Use model name `qwen2.5-7b-instruct`.

### Coding (Direct)
```
POST http://localhost:1337/v1/chat/completions
```
OpenAI-compatible. Use model name `qwen2.5-coder-7b-instruct`.

### LLMRouter (Routed)
```
POST http://localhost:6666/v1/chat/completions
GET  http://localhost:6666/dashboard
```
Routes requests based on model name. Use either model name.

## Port Conflict Resolution

If a port is already in use, you can identify the process with:

```bash
lsof -i :<port>
```

Common conflicts:
- **Port 3333**: Another Open WebUI instance or web application
- **Port 6666**: Another dashboard or game server
- **Port 1234/1337**: Another LM Studio or llama.cpp instance

To free a port:

```bash
lsof -ti :<port> | xargs kill -TERM
```

## Changing Ports

To change any port, update:
1. `configs/openwebui.env` — Open WebUI port
2. `configs/llmrouter.yaml` — LLMRouter server port
3. Run `scripts/configure_launchd.sh` to update launchd plists
4. Run `scripts/restart_all.sh` to apply changes
