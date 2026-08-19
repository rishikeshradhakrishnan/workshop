"""Stretch (b): team conventions (your M1 CLAUDE.md) as a READ-ONLY memory store mounted at /mnt/memory/<store>/."""
import os, pathlib
from _common import client, state, tail, user_message, USER

st = state()
otel = pathlib.Path(os.environ.get("OTEL", "."))
claude_md = (otel / "CLAUDE.md").read_text() if (otel / "CLAUDE.md").exists() else "# Conventions\n- Go code uses table-driven tests.\n"
store = client.beta.memory_stores.create(name=f"team-conventions-{USER}", description="Astronomy Shop project conventions (read-only reference)")
client.beta.memory_stores.memories.create(store.id, path="/CLAUDE.md", content=claude_md)
print("memory store", store.id)
session = client.beta.sessions.create(
    agent=st["agent_id"], environment_id=st["environment_id"], title=f"memory demo ({USER})",
    resources=[{"type": "memory_store", "memory_store_id": store.id, "access": "read_only"}],   # read_only: injected docs cannot poison it (M7 T6)
)
tail(session.id, send=[user_message("Read the team conventions in your memory and tell me which apply to src/currencyservice. Do not clone anything.")])
client.beta.sessions.archive(session.id)
