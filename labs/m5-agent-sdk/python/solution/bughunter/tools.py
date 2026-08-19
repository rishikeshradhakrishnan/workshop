"""Step 3 — custom tool served from an in-process SDK MCP server. M6 reuses append_ticket() via labs/shared/tickets.py."""
import json
import time
from pathlib import Path
from typing import Any

from claude_agent_sdk import create_sdk_mcp_server, tool

TICKETS = Path("tickets.json")          # lives in the directory you run bughunter from


def append_ticket(title: str, severity: str, file: str, line: int) -> str:
    tickets = json.loads(TICKETS.read_text()) if TICKETS.exists() else []
    ticket_id = f"AST-{len(tickets) + 1:04d}"
    tickets.append({"id": ticket_id, "title": title, "severity": severity, "file": file, "line": line,
                    "created": time.strftime("%Y-%m-%dT%H:%M:%S")})
    TICKETS.write_text(json.dumps(tickets, indent=2))
    return ticket_id


@tool("create_ticket",
      "File a bug ticket in the Astronomy Shop tracker for one confirmed finding. Returns the new ticket id.",
      {"title": str, "severity": str, "file": str, "line": int})
async def create_ticket(args: dict[str, Any]) -> dict[str, Any]:
    severity = str(args.get("severity", "")).upper()
    if severity not in {"HIGH", "MEDIUM", "LOW"}:
        # is_error tells Claude the call failed (and why) without killing the loop
        return {"content": [{"type": "text", "text": f"severity must be HIGH, MEDIUM or LOW, got {args.get('severity')!r}"}],
                "is_error": True}
    ticket_id = append_ticket(args["title"], severity, args["file"], int(args["line"]))
    return {"content": [{"type": "text", "text": f"created {ticket_id} for {args['file']}:{args['line']}"}]}


tracker_server = create_sdk_mcp_server(name="tracker", version="1.0.0", tools=[create_ticket])
TICKET_TOOL = "mcp__tracker__create_ticket"   # mcp__<key in mcp_servers>__<tool name>
