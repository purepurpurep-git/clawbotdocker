#!/usr/bin/env bash
set -euo pipefail

# Auto-approve all pending device pairing requests
json=$(openclaw devices list --json 2>/dev/null || true)
if [ -z "$json" ]; then
  echo "[pair] No data from openclaw devices list. Is gateway running?"
  exit 1
fi

# Extract request IDs (JSON or fallback regex)
reqs=$(python3 - <<'PY'
import json, sys, re
raw = sys.stdin.read()
try:
  data = json.loads(raw)
  pending = data.get("pending", []) if isinstance(data, dict) else []
  for item in pending:
    rid = item.get("requestId") or item.get("request") or item.get("id")
    if rid:
      print(rid)
except Exception:
  for r in re.findall(r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}", raw):
    print(r)
PY
<<<"$json")

if [ -z "$reqs" ]; then
  echo "[pair] No pending requests."
  exit 0
fi

for rid in $reqs; do
  echo "[pair] Approving $rid"
  openclaw devices approve "$rid" || true
done
