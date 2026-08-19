#!/usr/bin/env python3
"""labs/m4/streamjson-driver.py <service-path> — Module 4 stretch (a): drive `claude -p` over stdin.

Feeds two user turns through ONE claude process using
  --input-format stream-json --output-format stream-json --verbose --replay-user-messages
Each stdin line is a user message in the Agent SDK wire shape:
  {"type":"user","message":{"role":"user","content":[{"type":"text","text":"..."}]},"parent_tool_use_id":null}
The script prints tool calls as they stream, waits for the `result` event of turn 1, then sends turn 2,
waits for its `result`, closes stdin and exits with 0 only if both turns succeeded.
This is the protocol the Agent SDK speaks for you in Module 5.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys


def user_line(text: str) -> str:
    return json.dumps({
        "type": "user",
        "message": {"role": "user", "content": [{"type": "text", "text": text}]},
        "parent_tool_use_id": None,
    }) + "\n"


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] in {"-h", "--help"}:
        print(__doc__)
        return 2
    target = sys.argv[1]
    turns = [
        f"List the source files under {target} and say in one sentence what the service does.",
        "Now name the single riskiest function in that service and why, citing file:line. Two sentences.",
    ]
    cmd = [
        "claude", "-p",
        "--input-format", "stream-json", "--output-format", "stream-json", "--verbose", "--replay-user-messages",
        "--allowedTools", "Read,Grep,Glob", "--permission-mode", "dontAsk",
        "--max-turns", "12", "--max-budget-usd", "0.50",
        "--model", os.environ.get("MODEL", "sonnet"),
    ]
    cwd = os.environ.get("OTEL") or os.getcwd()
    print(f"$ (cd {cwd}) {' '.join(cmd)}", file=sys.stderr)
    proc = subprocess.Popen(cmd, cwd=cwd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, bufsize=1)
    assert proc.stdin and proc.stdout

    def send(text: str) -> None:
        print(f"\n>>> user: {text}")
        proc.stdin.write(user_line(text))
        proc.stdin.flush()

    ok = True
    turn = 0
    send(turns[turn])
    for raw in proc.stdout:
        raw = raw.strip()
        if not raw:
            continue
        try:
            ev = json.loads(raw)
        except json.JSONDecodeError:
            print(raw)
            continue
        t = ev.get("type")
        if t == "system" and ev.get("subtype") == "init":
            print(f"init  session={ev.get('session_id')} model={ev.get('model')}")
        elif t == "user" and ev.get("isReplay"):
            pass  # our own message echoed back because of --replay-user-messages
        elif t == "assistant":
            for block in ev.get("message", {}).get("content", []):
                if block.get("type") == "tool_use":
                    print(f"  -> {block.get('name')} {json.dumps(block.get('input'))[:80]}")
                elif block.get("type") == "text" and block.get("text", "").strip():
                    print(block["text"].strip())
        elif t == "result":
            print(f"<<< result turn {turn + 1}: {ev.get('subtype')} cost=${ev.get('total_cost_usd', 0):.4f} turns={ev.get('num_turns')}")
            ok = ok and not ev.get("is_error", False)
            turn += 1
            if turn < len(turns):
                send(turns[turn])
            else:
                proc.stdin.close()   # EOF tells claude to finish
    return 0 if (proc.wait() == 0 and ok) else 1


if __name__ == "__main__":
    sys.exit(main())
