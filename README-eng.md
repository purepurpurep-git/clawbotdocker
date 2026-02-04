# clawbotdocker — OpenClaw container with browser dashboard

This project builds a Docker container that:
- installs OpenClaw CLI
- starts the Gateway automatically
- opens Chrome with the Control UI (dashboard)

Two modes are supported:
- **dev** — terminal + browser (GUI)
- **user** — no GUI, only a dashboard URL printed to logs

---

## 0) Prerequisites (simple steps)

1. **Install Docker**
   - Windows/macOS: Docker Desktop
   - Linux: docker + docker‑compose

2. **Verify Docker works**
   ```bash
   docker --version
   docker compose version
   ```

3. **Clone the project**
   ```bash
   git clone https://github.com/purepurpurep-git/clawbotdocker.git
   cd clawbotdocker
   ```

---

## 1) Quick start (minimal steps)

```bash
./init.sh
# open .env and fill:
#   OPENCLAW_GATEWAY_TOKEN
#   one provider API key (see list below)

# dev mode (terminal + browser)
docker compose --profile dev up --build

# user mode (no GUI, only URL in logs)
docker compose --profile user up --build
```

### Privileges

Compose already sets `privileged: true` for both modes.
If you run manually with `docker run`, use:

```bash
docker run -it --rm --privileged \
  -p ${HOST_PORT:-18789}:${GATEWAY_PORT:-18789} \
  -e DISPLAY=:0 -e WAYLAND_DISPLAY=wayland-0 \
  -v /mnt/wslg:/mnt/wslg \
  -v /mnt/wslg/.X11-unix:/tmp/.X11-unix \
  -v "$(pwd)/data":/data \
  -v "$(pwd)/workspace":/workspace \
  -w /workspace \
  clawbotdocker-clawbot-dev
```

If `.env` is not configured, the container will start but the model will not work.

---

## 2) Where to open the dashboard

If the container runs on the same machine:
```
http://127.0.0.1:${HOST_PORT}/?token=<OPENCLAW_GATEWAY_TOKEN>
```

If the container runs inside another container, expose the port and use the same URL.

---

## 3) Ports & modes warning

`dev` and `user` use the same `${HOST_PORT}` — **do not run them simultaneously**.
Stop one mode before switching:
```bash
docker compose --profile dev down
# or
docker compose --profile user down
```

---

## 4) .env settings

`.env` is **not committed**. Use `.env.example` as a template.

**Required:**
- `OPENCLAW_GATEWAY_TOKEN` — dashboard access token
- **one API key from any provider** (see list below)

**Recommended:**
- `OPENCLAW_CONFIG_REWRITE=true` — always rebuild openclaw.json from .env
- `OPENCLAW_GATEWAY_BIND=custom` — listen on 0.0.0.0 inside container

**Available providers (fill only what you use):**
- `OPENROUTER_API_KEY`
- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `GEMINI_API_KEY`
- `GROQ_API_KEY`
- `MISTRAL_API_KEY`
- `CEREBRAS_API_KEY`
- `XAI_API_KEY`
- `ZAI_API_KEY`
- `AI_GATEWAY_API_KEY`
- `OPENCODE_API_KEY`
- `OPENCODE_ZEN_API_KEY`
- `MOONSHOT_API_KEY`
- `KIMI_API_KEY`
- `MINIMAX_API_KEY`
- `SYNTHETIC_API_KEY`
- `VENICE_API_KEY`
- `OLLAMA_API_KEY`
- `XIAOMI_API_KEY`

**Optional:**
- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_DM_POLICY`, `TELEGRAM_GROUP_POLICY`, `TELEGRAM_REQUIRE_MENTION`
- `OPENCLAW_MODEL`

---

## First connection: pairing

On first Control UI connect, a new browser needs **pairing**.
If you see:
```
disconnected (1008): pairing required
```
run:

```bash
./pair.sh
# or manually:
# openclaw devices list
# openclaw devices approve <requestId>
```

After approval, the browser is remembered.

---

## Reinstall / reset

Full reset:
```bash
docker compose down -v
rm -rf data workspace
```

Rebuild & start:
```bash
docker compose --profile dev up --build
# or
# docker compose --profile user up --build
```

---

## What’s inside the container

- **entrypoint.sh** syncs `openclaw.json` from `.env`
- runs `openclaw gateway run`
- starts Chrome and opens the dashboard

---

## File descriptions

Each file has its own description in `<name>.md`.
Examples:
- `Dockerfile.md`
- `entrypoint.sh.md`
- `docker-compose.yml.md`

These files are included in the repository.
