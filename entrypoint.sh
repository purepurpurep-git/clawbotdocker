#!/usr/bin/env bash
set -euo pipefail

UI_MODE="${UI_MODE:-full}"   # full | browser
OPENCLAW_HOME="${OPENCLAW_HOME:-/data}"
OPENCLAW_CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$OPENCLAW_HOME/openclaw.json}"
OPENCLAW_WORKSPACE="${OPENCLAW_WORKSPACE:-/workspace}"

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

# Build OpenClaw config if missing or forced
if [ ! -f "$OPENCLAW_CONFIG_PATH" ] || [ "${OPENCLAW_CONFIG_REWRITE:-false}" = "true" ]; then
  GATEWAY_TOKEN="${OPENCLAW_GATEWAY_TOKEN:-}"
  MODEL_PRIMARY="${OPENCLAW_MODEL:-openrouter/openai/gpt-5.2-codex}"
  TELEGRAM_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
  TELEGRAM_DM_POLICY="${TELEGRAM_DM_POLICY:-pairing}"
  TELEGRAM_GROUP_POLICY="${TELEGRAM_GROUP_POLICY:-open}"
  TELEGRAM_REQUIRE_MENTION="${TELEGRAM_REQUIRE_MENTION:-false}"

  mkdir -p "$(dirname "$OPENCLAW_CONFIG_PATH")"
  cat > "$OPENCLAW_CONFIG_PATH" <<EOF
{
  "agents": {
    "defaults": {
      "model": { "primary": "$MODEL_PRIMARY" },
      "workspace": "$OPENCLAW_WORKSPACE"
    }
  },
  "gateway": {
    "port": 18789,
    "bind": "0.0.0.0",
    "auth": {
      "mode": "token",
      "token": "$GATEWAY_TOKEN"
    }
  },
  "channels": {
    "telegram": {
      "enabled": ${TELEGRAM_TOKEN:+true}${TELEGRAM_TOKEN:+' '}
    }
  }
}
EOF

  # If telegram token exists, inject config with minimal policies
  if [ -n "$TELEGRAM_TOKEN" ]; then
    cat > "$OPENCLAW_CONFIG_PATH" <<EOF
{
  "agents": {
    "defaults": {
      "model": { "primary": "$MODEL_PRIMARY" },
      "workspace": "$OPENCLAW_WORKSPACE"
    }
  },
  "gateway": {
    "port": 18789,
    "bind": "0.0.0.0",
    "auth": {
      "mode": "token",
      "token": "$GATEWAY_TOKEN"
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "$TELEGRAM_TOKEN",
      "dmPolicy": "$TELEGRAM_DM_POLICY",
      "groupPolicy": "$TELEGRAM_GROUP_POLICY",
      "groups": {
        "*": { "requireMention": $TELEGRAM_REQUIRE_MENTION }
      }
    }
  }
}
EOF
  fi
fi

# Start OpenClaw gateway
OPENCLAW_HOME="$OPENCLAW_HOME" openclaw gateway start || true

# Open dashboard in Chrome
DASHBOARD_URL="http://127.0.0.1:18789/"
if [ -n "${OPENCLAW_GATEWAY_TOKEN:-}" ]; then
  DASHBOARD_URL="${DASHBOARD_URL}?token=${OPENCLAW_GATEWAY_TOKEN}"
fi

exec dbus-run-session -- bash -lc "
  set -e
  if [ '$UI_MODE' = 'full' ]; then
    xfce4-terminal --disable-server --title='Container' &
  fi

  CHROME_FLAGS='--no-first-run --disable-dev-shm-usage --user-data-dir=$HOME/.config/google-chrome --disable-features=UseOzonePlatform --ozone-platform=x11 $DASHBOARD_URL'
  if [ \"$(id -u)\" = \"0\" ]; then
    CHROME_FLAGS='--no-sandbox '"$CHROME_FLAGS"
  fi

  (google-chrome-stable $CHROME_FLAGS >/tmp/chrome.log 2>&1 &) || true

  while pgrep -x xfce4-terminal >/dev/null || pgrep -x chrome >/dev/null || pgrep -x google-chrome >/dev/null; do
    sleep 1
  done
"
