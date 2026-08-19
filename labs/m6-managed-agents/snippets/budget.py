"""Step 6 (a): cap a session's spend, watch it pause with budget_reached, then raise the cap to resume."""
from _common import client, state, tail, user_message, TASK, USER

st = state()
session = client.beta.sessions.create(
    agent=st["agent_id"], environment_id=st["environment_id"], title=f"budget demo ({USER})",
    budget={"type": "limit", "max_list_cost": {"amount": "50", "currency": "USD"}},   # whole US cents as a STRING: "50" = $0.50
    initial_events=[user_message(TASK)],
)
print("session", session.id, "with a $0.50 cap")
reason = tail(session.id, replay=True)
if reason == "budget_reached":
    print("\nraising the cap to $1.50 — no event needed; the paused work restarts")
    client.beta.sessions.update(session.id, budget={"type": "limit", "max_list_cost": {"amount": "150", "currency": "USD"}})
    tail(session.id)
print("\nusage:", client.beta.sessions.retrieve(session.id).usage)
client.beta.sessions.archive(session.id)
