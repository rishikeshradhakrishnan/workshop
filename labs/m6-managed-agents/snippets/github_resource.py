"""Stretch (a): mount the repo as a session resource instead of cloning in bash. Needs GITHUB_TOKEN (read-only PAT works)."""
import os
from _common import client, state, tail, user_message, ORG, USER

token = os.environ.get("GITHUB_TOKEN") or exit("export GITHUB_TOKEN=<fine-grained read-only PAT> (required even for public repos)")
st = state()
session = client.beta.sessions.create(
    agent=st["agent_id"], environment_id=st["environment_id"], title=f"repo resource demo ({USER})",
    resources=[{"type": "github_repository", "url": f"https://github.com/{ORG}/opentelemetry-demo",
                "authorization_token": token, "checkout": {"type": "branch", "name": "workshop"}}],   # cached across sessions; token never echoed
)
tail(session.id, send=[user_message("The repo is already mounted under /workspace. Analyze src/paymentservice for bugs and write /mnt/session/outputs/bug-report.md.")])
client.beta.sessions.archive(session.id)
