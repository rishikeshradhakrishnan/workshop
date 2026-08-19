"""Stretch (c): outcome-graded report — a separate-context grader makes the agent revise until the rubric is satisfied."""
from _common import client, state, tail, user_message, TASK, USER

st = state()
session = client.beta.sessions.create(
    agent=st["agent_id"], environment_id=st["environment_id"], title=f"outcome demo ({USER})",
    initial_events=[
        {"type": "user.define_outcome", "description": "A bug report for src/paymentservice",
         "rubric": {"type": "text", "content": "At least 3 findings; each has file:line, a severity, and a concrete fix."},
         "max_iterations": 3},
        user_message(TASK),
    ],
)
print("session", session.id, "— watch span.outcome_evaluation_* events")
tail(session.id, replay=True)
client.beta.sessions.archive(session.id)
