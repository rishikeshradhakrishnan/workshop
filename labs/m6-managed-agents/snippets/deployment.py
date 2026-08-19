"""Step 6 (b): a scheduled deployment (cron) for your agent, one manual run, then archive so nothing fires tomorrow."""
import os
from _common import client, state, user_message, TASK, USER

TZ = os.environ.get("TZ_NAME", "UTC")          # e.g. Europe/Berlin
st = state()
dep = client.beta.deployments.create(
    name=f"nightly-bughunt-{USER}",
    agent=st["agent_id"], environment_id=st["environment_id"],
    initial_events=[user_message(TASK)],
    schedule={"type": "cron", "expression": "0 7 * * 1-5", "timezone": TZ},   # weekdays 07:00
    budget={"type": "limit", "max_list_cost": {"amount": "100", "currency": "USD"}},   # per-run cap: $1.00
)
print("deployment", dep.id, "upcoming:", getattr(dep, "upcoming_runs_at", None))
run = client.beta.deployments.run(dep.id)
print("manual run:", run)
for r in client.beta.deployment_runs.list(deployment_id=dep.id):
    print("run", r.id, getattr(r, "status", ""), "session", getattr(r, "session_id", None))
client.beta.deployments.archive(dep.id)
print("archived deployment (its manual-run session, if any, is archived by labs/cleanup.sh)")
