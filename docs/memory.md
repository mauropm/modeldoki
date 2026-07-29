# Memory Management

## Why Memory Matters

Running local LLMs is memory-intensive. Qwen 3.5 9B (MLX 4-bit) uses approximately **5–7 GB of RAM** when loaded.

On a 16 GB Mac, that leaves limited headroom for other applications.

## Recommended Free Memory

Before loading models, aim for at least **6–8 GB of free memory**.

Monitor with:

```bash
memory_pressure
# or
vm_stat
```

## Applications to Close

For best inference performance, close or quit applications that consume significant memory:

| Application | Typical Memory Usage |
|-------------|---------------------|
| Google Chrome (many tabs) | 2–8+ GB |
| Microsoft Teams | 1–3 GB |
| Slack | 500 MB–2 GB |
| Discord | 500 MB–1.5 GB |
| Zoom | 300 MB–1 GB |
| Docker Desktop | 2–8 GB |
| Xcode | 2–6 GB |
| Android Studio | 2–6 GB |
| VS Code (many extensions) | 500 MB–2 GB |
| Virtual Machines | 4–16 GB |
| Adobe Creative Cloud | 1–6 GB |
| Photo/Video editing apps | 2–8 GB |

## Quick Memory Free-up

```bash
# Check memory pressure
memory_pressure

# Top memory consumers
ps aux --sort=-%mem | head -20

# Force-quit a specific app
pkill -f "App Name"
```

## Memory Tips

- **Use compressed memory sparingly** — excessive swapping degrades inference performance significantly (10–100x slower).
- **Monitor with Activity Monitor** (⌘Space → "Activity Monitor") — check the Memory tab for pressure graph.
- **Restart periodically** — macOS memory fragmentation can build up over days.
- **Consider a smaller MLX model** if you have only 16 GB. It uses less RAM at the cost of slightly lower quality.
- **Upgrade RAM** if you run models frequently — 32 GB or 64 GB makes a substantial difference.

## Expected Memory Usage

| Scenario | Memory Used | Notes |
|----------|-------------|-------|
| macOS idle | 4–6 GB | Fresh boot |
| + Browser (5 tabs) | 6–10 GB | |
| + Qwen 3.5 9B (MLX 4-bit) | 11–17 GB | Model loaded, may swap on 16 GB |
| + All services + apps | 16+ GB | Heavy swapping likely |

## What Happens When Memory Runs Out

- **Swapping**: macOS writes memory pages to disk. Inference slows dramatically.
- **OOM kills**: The kernel terminates processes. LM Studio or Open WebUI may crash.
- **UI lag**: The system becomes unresponsive.

If you experience any of these, use `scripts/stop_all.sh` and close memory-intensive applications before restarting.
