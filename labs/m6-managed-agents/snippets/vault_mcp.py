"""Stretch (d): vault + GitHub MCP toolset with approval. Needs GITHUB_TOKEN (fine-grained PAT) and your astroshop-reviews repo."""
import os
from _common import client, state, tail, user_message, USER, TOOLSET

GITHUB_MCP_URL = "https://api.githubcopilot.com/mcp/"     # [verify-on-day]
token = os.environ.get("GITHUB_TOKEN") or exit("export GITHUB_TOKEN=<fine-grained PAT with issues:write on your astroshop-reviews>")
st = state()

vault = client.beta.vaults.create(display_name=f"ws-{USER}")
client.beta.vaults.credentials.create(vault.id, display_name="github-mcp",
                                       auth={"type": "static_bearer", "mcp_server_url": GITHUB_MCP_URL, "token": token})   # write-only from here on
agent = client.beta.agents.retrieve(st["agent_id"])
agent = client.beta.agents.update(
    agent.id, version=agent.version,
    mcp_servers=[{"type": "url", "name": "github", "url": GITHUB_MCP_URL}],
    tools=[{"type": TOOLSET, "default_config": {"permission_policy": {"type": "always_allow"}},
            "configs": [{"name": "web_search", "enabled": False}]},
           {"type": "mcp_toolset", "mcp_server_name": "github"}],       # default policy for MCP toolsets: always_ask
)
print("agent version", agent.version, "now has the github MCP toolset")
env = client.beta.environments.create(name=f"ws-{USER}-mcp", config={"type": "cloud", "networking": {
    "type": "limited", "allowed_hosts": ["github.com", "api.github.com"], "allow_mcp_servers": True, "allow_package_managers": False}})
session = client.beta.sessions.create(agent=agent.id, environment_id=env.id, vault_ids=[vault.id], title=f"vault+mcp demo ({USER})")
repo = f"{os.environ.get('GITHUB_USER', USER)}/astroshop-reviews"
tail(session.id, auto_yes=False,
     send=[user_message(f"Using the github tools, open an issue in {repo} titled 'Workshop: triage SQL injection in review search' with a two-line body. Do nothing else.")])
client.beta.sessions.archive(session.id)
