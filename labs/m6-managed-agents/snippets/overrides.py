"""Stretch (e): same agent, cheaper model for one session via agent_with_overrides. Set HAIKU_MODEL to a full model ID."""
import os
from _common import client, state, tail, user_message, TASK, USER

haiku = os.environ.get("HAIKU_MODEL") or exit("export HAIKU_MODEL=<full haiku model id>")
st = state()
session = client.beta.sessions.create(
    agent={"type": "agent_with_overrides", "id": st["agent_id"], "model": {"id": haiku}},   # a model override runs at that model's default effort
    environment_id=st["environment_id"], title=f"override demo ({USER})",
    initial_events=[user_message(TASK)],
)
tail(session.id, replay=True)
print("\nusage:", client.beta.sessions.retrieve(session.id).usage, "— compare list_cost with your step-5 numbers")
client.beta.sessions.archive(session.id)
