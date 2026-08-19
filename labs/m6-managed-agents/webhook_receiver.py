"""labs/m6-managed-agents/webhook_receiver.py — Module 6 step 6 (c): a minimal, verifying webhook endpoint.

  cd labs/m6-managed-agents/python/starter        # (or solution) — .cma-state.json lives here
  ANTHROPIC_WEBHOOK_SIGNING_KEY=whsec_... uv run python ../../webhook_receiver.py [--port 8787]
  ngrok http 8787      # or: cloudflared tunnel --url http://localhost:8787   (must pass the RAW body through)
  Console -> Manage -> Webhooks -> add https://<tunnel-host>/hook for session.status_idled (copy the whsec_ secret; shown once)

Payloads are thin ({type, id, ...}); we verify the signature with client.beta.webhooks.unwrap(), then re-fetch the
session and act on its status / stop_reason. Deliveries repeat the same event id on retry — dedupe on it.
"""
from __future__ import annotations

import json
import os
import sys

try:
    from anthropic import Anthropic
    from flask import Flask, abort, request
except ImportError:
    sys.exit("run `uv sync` in labs/m6-managed-agents/python (needs anthropic[webhooks] and flask)")

PORT = int(sys.argv[sys.argv.index("--port") + 1]) if "--port" in sys.argv else 8787
SIGNING_KEY = os.environ.get("ANTHROPIC_WEBHOOK_SIGNING_KEY")
if not SIGNING_KEY:
    print("warning: ANTHROPIC_WEBHOOK_SIGNING_KEY not set — deliveries will be logged but NOT verified", file=sys.stderr)

client = Anthropic()          # reads ANTHROPIC_API_KEY and ANTHROPIC_WEBHOOK_SIGNING_KEY from the environment
app = Flask(__name__)
seen_ids: set[str] = set()


@app.post("/hook")
def hook():
    raw = request.get_data(as_text=True)                       # the EXACT bytes that were signed — never re-serialise
    if SIGNING_KEY:
        try:
            event = client.beta.webhooks.unwrap(raw, headers=dict(request.headers))
        except Exception as exc:                                # bad signature, stale timestamp, malformed body
            print(f"rejected delivery: {exc}", file=sys.stderr)
            abort(400)
        payload = event.model_dump() if hasattr(event, "model_dump") else json.loads(raw)
    else:
        payload = json.loads(raw or "{}")

    event_id = payload.get("id") or request.headers.get("webhook-id", "")
    if event_id in seen_ids:
        print(f"duplicate delivery {event_id} — ignored")
        return {"ok": True, "duplicate": True}
    seen_ids.add(event_id)

    data = payload.get("data") or {}
    kind, obj_id = data.get("type") or payload.get("type"), data.get("id")
    print(f"webhook {event_id}: {kind} {obj_id}")
    if kind == "session.status_idled" and obj_id:
        sess = client.beta.sessions.retrieve(obj_id)            # thin payload -> re-fetch and act on the real state
        print(f"session idled: {sess.id} status={sess.status} title={sess.title!r}")
    elif kind and kind.startswith("session.") and obj_id:
        print(f"  (session event; retrieve {obj_id} if you need details)")
    return {"ok": True}


@app.get("/")
def index():
    return {"service": "workshop webhook receiver", "post_to": "/hook", "verified": bool(SIGNING_KEY)}


if __name__ == "__main__":
    print(f"listening on http://0.0.0.0:{PORT}/hook  (verification {'ON' if SIGNING_KEY else 'OFF'})")
    app.run(host="0.0.0.0", port=PORT, debug=False)
