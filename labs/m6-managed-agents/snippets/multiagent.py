"""Stretch (f): coordinator + roster. Creates a service-documenter agent, then a coordinator that delegates to it and to bug-hunter."""
import pathlib
from _common import client, state, tail, user_message, USER, MODEL, TOOLSET

st = state()
doc_prompt = (pathlib.Path(__file__).resolve().parents[2] / "m3" / "agents" / "service-documenter.md").read_text().split("---", 2)[-1].strip()
documenter = client.beta.agents.create(name=f"service-documenter-{USER}", model=MODEL, system=doc_prompt, tools=[{"type": TOOLSET}])
coordinator = client.beta.agents.create(
    name=f"toolkit-coordinator-{USER}", model=MODEL,
    system="You coordinate a documentation specialist and a bug hunter. Delegate; then merge their outputs into one onboarding note.",
    tools=[{"type": TOOLSET}],
    multiagent={"type": "coordinator", "agents": [{"type": "agent", "id": documenter.id}, {"type": "agent", "id": st["agent_id"]}]},
)
session = client.beta.sessions.create(agent=coordinator.id, environment_id=st["environment_id"], title=f"multiagent demo ({USER})")
tail(session.id, send=[user_message(
    f"Clone https://github.com/{__import__('os').environ.get('WORKSHOP_ORG', '<WORKSHOP_ORG>')}/opentelemetry-demo (depth 1) into /workspace. "
    "Have the documenter summarize src/emailservice and the bug hunter review src/paymentservice, in parallel threads, then merge.")])
for th in client.beta.sessions.threads.list(session.id):
    print("thread", th.id, getattr(th, "agent_id", ""))
client.beta.sessions.archive(session.id)
