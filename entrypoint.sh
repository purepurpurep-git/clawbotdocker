#!/usr/bin/env bash
set -euo pipefail

UI_MODE="${UI_MODE:-full}"   # full | browser
OPENCLAW_HOME="${OPENCLAW_HOME:-/data}"
OPENCLAW_CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$OPENCLAW_HOME/openclaw.json}"
OPENCLAW_WORKSPACE="${OPENCLAW_WORKSPACE:-/workspace}"
GATEWAY_PORT="${GATEWAY_PORT:-18789}"

mkdir -p "$OPENCLAW_HOME" "$OPENCLAW_WORKSPACE"

# XDG runtime for dbus
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/xdg-runtime}"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Cursor theme
export XCURSOR_THEME="${XCURSOR_THEME:-DMZ-White}"
export XCURSOR_SIZE="${XCURSOR_SIZE:-24}"

# If WSLg socket exists, assume display :0
if [ -d /mnt/wslg/.X11-unix ]; then
  export DISPLAY="${DISPLAY:-:0}"
fi

# Export OpenRouter key if present
if [ -n "${OPENROUTER_API_KEY:-}" ]; then
  export OPENCLAW_OPENROUTER_API_KEY="$OPENROUTER_API_KEY"
fi

# Build OpenClaw config if missing or forced
if [ ! -f "$OPENCLAW_CONFIG_PATH" ] || [ "${OPENCLAW_CONFIG_REWRITE:-false}" = "true" ]; then
  mkdir -p "$(dirname "$OPENCLAW_CONFIG_PATH")"

  python3 - <<PY
import json, os

cfg = {
  "agents": {
    "defaults": {
      "model": {"primary": os.environ.get("OPENCLAW_MODEL", "openrouter/openai/gpt-5.2-codex")},
      "workspace": os.environ.get("OPENCLAW_WORKSPACE", "/workspace")
    }
  },
  "gateway": {
    "port": int(os.environ.get("GATEWAY_PORT", "18789")),
    "bind": "0.0.0.0",
    "auth": {"mode": "token", "token": os.environ.get("OPENCLAW_GATEWAY_TOKEN", "")}
  }
}

telegram_token = os.environ.get("TELEGRAM_BOT_TOKEN", "")
if telegram_token:
  cfg["channels"] = {
    "telegram": {
      "enabled": True,
      "botToken": telegram_token,
      "dmPolicy": os.environ.get("TELEGRAM_DM_POLICY", "pairing"),
      "groupPolicy": os.environ.get("TELEGRAM_GROUP_POLICY", "open"),
      "groups": {"*": {"requireMention": os.environ.get("TELEGRAM_REQUIRE_MENTION", "false").lower() == "true"}}
    }
  }

path = os.environ.get("OPENCLAW_CONFIG_PATH", "/data/openclaw.json")
with open(path, "w") as f:
  json.dump(cfg, f, indent=2)
PY
fi

# Start OpenClaw gateway in foreground (no systemd in containers)
openclaw gateway run --bind custom --port "$GATEWAY_PORT" --allow-unconfigured --force >/var/log/openclaw-gateway.log 2>&1 &

# Open dashboard in Chrome
DASHBOARD_URL="http://127.0.0.1:${GATEWAY_PORT}/"
if [ -n "${OPENCLAW_GATEWAY_TOKEN:-}" ]; then
  DASHBOARD_URL="${DASHBOARD_URL}?token=${OPENCLAW_GATEWAY_TOKEN}"
fi

exec dbus-run-session -- bash -lc "
  set -e
  if [ '$UI_MODE' = 'full' ]; then
    xfce4-terminal --disable-server --title='Container' &
  fi

  CHROME_FLAGS='--no-first-run --disable-dev-shm-usage --user-data-dir=\$HOME/.config/google-chrome --disable-features=UseOzonePlatform --ozone-platform=x11 $DASHBOARD_URL'
  if [ \"\$(id -u)\" = \"0\" ]; then
    CHROME_FLAGS=\"--no-sandbox \$CHROME_FLAGS\"
  fi

  (google-chrome-stable \$CHROME_FLAGS >/tmp/chrome.log 2>&1 &) || true

  # Keep container alive even if browser exits
  tail -f /dev/null
"
