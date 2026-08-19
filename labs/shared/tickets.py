"""Shared create_ticket handler — the Astronomy Shop's toy bug tracker.

Module 5 (Agent SDK) serves it as an in-process MCP tool (`mcp__tracker__create_ticket`);
Module 6 (Managed Agents) calls the very same function when the hosted agent emits an
`agent.custom_tool_use` for `create_ticket`. Tickets are appended to ./tickets.json in the
directory you run from, so each lab keeps its own file.
"""
from __future__ import annotations

import json
import time
from pathlib import Path
from typing import Any

TICKETS = Path("tickets.json")
SEVERITIES = {"HIGH", "MEDIUM", "LOW"}

# JSON Schema for the tool input — reused verbatim as the Managed Agents custom tool `input_schema` (M6).
CREATE_TICKET_INPUT_SCHEMA: dict[str, Any] = {
    "type": "object",
    "properties": {
        "title": {"type": "string", "description": "One-line summary of the confirmed finding"},
        "severity": {"type": "string", "enum": ["HIGH", "MEDIUM", "LOW"]},
        "file": {"type": "string", "description": "Path relative to the repository root"},
        "line": {"type": "integer", "minimum": 1},
    },
    "required": ["title", "severity", "file", "line"],
}

CREATE_TICKET_DESCRIPTION = (
    "File a bug ticket in the team tracker. Call once per HIGH-severity finding, after you have "
    "confirmed the file and line. Returns the new ticket ID. Do not call for MEDIUM/LOW findings."
)


def append_ticket(title: str, severity: str, file: str, line: int, *, path: Path = TICKETS) -> str:
    """Append one ticket and return its id (AST-0001, AST-0002, ...)."""
    tickets = json.loads(path.read_text()) if path.exists() else []
    ticket_id = f"AST-{len(tickets) + 1:04d}"
    tickets.append({
        "id": ticket_id,
        "title": title,
        "severity": severity,
        "file": file,
        "line": int(line),
        "created": time.strftime("%Y-%m-%dT%H:%M:%S"),
    })
    path.write_text(json.dumps(tickets, indent=2))
    return ticket_id


def create_ticket(title: str, severity: str, file: str, line: int, **_ignored: Any) -> str:
    """Validate and file a ticket. Returns a short human/agent-readable result string.

    Extra keyword arguments are ignored so `create_ticket(**event.input)` is safe even if the
    model adds a field. Invalid severities produce an error string rather than an exception —
    the caller sends it back as the tool result and the agent adapts.
    """
    sev = str(severity or "").upper()
    if sev not in SEVERITIES:
        return f"error: severity must be HIGH, MEDIUM or LOW, got {severity!r}"
    try:
        line_no = int(line)
    except (TypeError, ValueError):
        return f"error: line must be an integer, got {line!r}"
    ticket_id = append_ticket(str(title), sev, str(file), line_no)
    return f"created {ticket_id} for {file}:{line_no}"


if __name__ == "__main__":  # tiny self-test: python labs/shared/tickets.py
    import tempfile
    tmp = Path(tempfile.mkdtemp()) / "tickets.json"
    print(append_ticket("demo", "HIGH", "src/x.go", 1, path=tmp), "->", tmp)
    print(create_ticket(title="bad", severity="URGENT", file="a", line=1))
