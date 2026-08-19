"""Shared helpers for the Module 6 preview/stretch snippets. Run them from the directory that holds your
.cma-state.json (labs/m6-managed-agents/python/starter or /solution):  uv run python ../../snippets/<name>.py"""
from __future__ import annotations

import itertools
import json
import os
import pathlib
import sys

SHARED = pathlib.Path(__file__).resolve().parents[2] / "shared"
sys.path.append(str(SHARED))
from cma_constants import BETA, MEMORY_BETA, TOOLSET  # noqa: E402,F401
from tickets import create_ticket  # noqa: E402

from anthropic import Anthropic  # noqa: E402

STATE_FILE = pathlib.Path(".cma-state.json")
client = Anthropic()
USER = os.environ.get("GITHUB_USER") or os.environ.get("USER") or "anon"
ORG = os.environ.get("WORKSHOP_ORG", "<WORKSHOP_ORG>")
MODEL = os.environ.get("CMA_MODEL", "")          # full model ID from labs/.env (aliases 400 on this API)
TASK = (f"Clone https://github.com/{ORG}/opentelemetry-demo (depth 1) into /workspace. "
        "Analyze src/paymentservice for bugs and write the report to /mnt/session/outputs/bug-report.md. "
        "File a ticket for each HIGH finding with create_ticket.")


def state() -> dict:
    if not STATE_FILE.exists():
        sys.exit(f"no {STATE_FILE} in {pathlib.Path.cwd()} — run deploy_toolkit_agent.py step1..step3 here first")
    return json.loads(STATE_FILE.read_text())


def user_message(text: str) -> dict:
    return {"type": "user.message", "content": [{"type": "text", "text": text}]}


def tail(session_id: str, *, send: list | None = None, auto_yes: bool = True, replay: bool = False) -> str | None:
    """Minimal stream loop shared by the snippets: open stream, optionally send, render, auto-answer pauses."""
    seen, by_id, reason = set(), {}, None
    with client.beta.sessions.events.stream(session_id) as stream:
        backlog = list(client.beta.sessions.events.list(session_id)) if replay else []
        if send:
            client.beta.sessions.events.send(session_id, events=send)
        for ev in itertools.chain(backlog, stream):
            if ev.type in ("event_start", "event_delta"):
                continue
            if getattr(ev, "id", None):
                if ev.id in seen:
                    continue
                seen.add(ev.id); by_id[ev.id] = ev
            if ev.type == "agent.message":
                print("".join(b.text for b in ev.content if b.type == "text"), end="", flush=True)
            elif ev.type in ("agent.tool_use", "agent.custom_tool_use", "agent.mcp_tool_use"):
                print(f"\n[{ev.type}: {ev.name}]")
            elif ev.type == "session.usage":
                print(f"\n[session.usage] {ev}")
            elif ev.type.startswith("span.outcome_evaluation"):
                print(f"\n[{ev.type}] {getattr(ev, 'result', '')}")
            elif ev.type in ("session.thread_created", "agent.thread_message_sent", "agent.thread_message_received"):
                print(f"\n[{ev.type}]")
            elif ev.type == "session.error":
                print(f"\n[session.error] {getattr(ev.error, 'message', ev)}")
            elif ev.type == "session.status_idle":
                reason = ev.stop_reason.type
                if reason == "requires_action":
                    for i in ev.stop_reason.event_ids:
                        p = by_id.get(i)
                        if p is None:
                            continue
                        if p.type == "agent.custom_tool_use":
                            res = create_ticket(**p.input) if p.name == "create_ticket" else "unknown tool"
                            reply = {"type": "user.custom_tool_result", "custom_tool_use_id": p.id, "content": [{"type": "text", "text": str(res)}]}
                        else:
                            ok = auto_yes or input(f"\nAllow {p.name}? [a/d] ").lower().startswith("a")
                            reply = {"type": "user.tool_confirmation", "tool_use_id": p.id, "result": "allow" if ok else "deny"}
                        client.beta.sessions.events.send(session_id, events=[reply])
                    continue
                print(f"\n[idle: {reason}]")
                break
            elif ev.type == "session.status_terminated":
                reason = "terminated"; break
    return reason
