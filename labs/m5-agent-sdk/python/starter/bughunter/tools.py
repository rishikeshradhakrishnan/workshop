"""Step 3 — custom tool served from an in-process SDK MCP server.

TODO(step-3):
  1. implement append_ticket(title, severity, file, line) -> "AST-0001" (append to tickets.json in the cwd)
  2. decorate create_ticket with @tool("create_ticket", "<description>", {"title": str, "severity": str, "file": str, "line": int})
     - return {"content": [{"type": "text", "text": "..."}], "is_error": True} for a bad severity (do not raise)
     - otherwise append the ticket and return {"content": [{"type": "text", "text": f"created {ticket_id} ..."}]}
  3. tracker_server = create_sdk_mcp_server(name="tracker", version="1.0.0", tools=[create_ticket])
  4. in __main__.py: mcp_servers={"tracker": tracker_server} and add TICKET_TOOL to allowed_tools (until step 4)
"""
import json
import time
from pathlib import Path
from typing import Any

from claude_agent_sdk import create_sdk_mcp_server, tool  # noqa: F401  (tool is used once you fill the TODO)

TICKETS = Path("tickets.json")          # lives in the directory you run bughunter from
TICKET_TOOL = "mcp__tracker__create_ticket"   # mcp__<key in mcp_servers>__<tool name>


def append_ticket(title: str, severity: str, file: str, line: int) -> str:
    tickets = json.loads(TICKETS.read_text()) if TICKETS.exists() else []
    ticket_id = f"AST-{len(tickets) + 1:04d}"
    tickets.append({"id": ticket_id, "title": title, "severity": severity, "file": file, "line": line,
                    "created": time.strftime("%Y-%m-%dT%H:%M:%S")})
    TICKETS.write_text(json.dumps(tickets, indent=2))
    return ticket_id


# TODO(step-3): turn this into an SDK tool with the @tool decorator (see module 5.10) — keep the async signature.
async def create_ticket(args: dict[str, Any]) -> dict[str, Any]:
    return {"content": [{"type": "text", "text": "TODO(step-3): create_ticket is not implemented yet"}], "is_error": True}


# TODO(step-3): tracker_server = create_sdk_mcp_server(name="tracker", version="1.0.0", tools=[create_ticket])
tracker_server = None
