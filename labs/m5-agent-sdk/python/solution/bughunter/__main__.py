"""bughunter — Claude Agent SDK lab (Module 5).

  uv run bughunter <service-path> [--ticket]     analyze one service of $OTEL with the codebase-toolkit bug-hunter agent
  uv run bughunter followup "<question>"         resume the last session and ask a follow-up
"""
import asyncio
import json
import os
import sys
from pathlib import Path

from claude_agent_sdk import (AssistantMessage, ClaudeAgentOptions, HookMatcher, ResultMessage, SystemMessage,
                              TextBlock, ToolUseBlock, query)

from .hooks import protect_secrets_hook, ticket_policy
from .schema import FINDINGS_SCHEMA
from .tools import tracker_server

OTEL = Path(os.environ.get("OTEL", ".")).resolve()                                    # the repo the agent works in
PLUGIN = Path(os.environ.get("TOOLKIT_PLUGIN", str(OTEL.parent / "codebase-toolkit"))).resolve()  # M3 plugin dir
MODEL = os.environ.get("MODEL", "sonnet")                                             # single place to bump: labs/.env
SESSION_FILE = Path(".bughunter-session")

PROMPT = ("Use the codebase-toolkit:bug-hunter agent to analyze the service at `{service}` for bugs "
          "(logic errors, error-handling gaps, concurrency issues, resource leaks, security problems). "
          "Then consolidate its report into the required JSON findings object for service `{service}`. "
          "Every finding needs a real file path relative to the repository root and a line number you have verified.")
TICKET_SUFFIX = " After producing the findings, call the create_ticket tool once for each HIGH or MEDIUM severity finding."


def base_options(**overrides) -> ClaudeAgentOptions:
    """Step 1 — the locked-down, read-only baseline (also used by `followup`)."""
    opts = dict(
        cwd=str(OTEL),
        model=MODEL,
        setting_sources=["project"],                       # $OTEL/CLAUDE.md, .claude/settings.json, rules — nothing from ~/.claude
        plugins=[{"type": "local", "path": str(PLUGIN)}],  # agents + skill + hooks + MCP config packaged in M3
        allowed_tools=["Read", "Grep", "Glob", "Agent"],   # step 3 temporarily also listed mcp__tracker__create_ticket here
        permission_mode="dontAsk",
        max_turns=40,
        max_budget_usd=1.00,
    )
    opts.update(overrides)
    return ClaudeAgentOptions(**opts)


async def as_stream(text: str):
    """Streaming-input form of a single prompt (step 4): the documented shape for can_use_tool with query()."""
    yield {"type": "user", "message": {"role": "user", "content": text}}


async def consume(messages) -> ResultMessage | None:
    """Print the stream; return the final ResultMessage (single-shot query() raises AFTER yielding an error result)."""
    result = None
    try:
        async for msg in messages:
            if isinstance(msg, SystemMessage) and msg.subtype == "init":
                print(f"model={msg.data.get('model')} auth={msg.data.get('apiKeySource')} "
                      f"plugins={[p.get('name') for p in msg.data.get('plugins', [])]}")
            elif isinstance(msg, AssistantMessage):
                prefix = "    (subagent) " if msg.parent_tool_use_id else ""
                for block in msg.content:
                    if isinstance(block, TextBlock) and not prefix:
                        print(block.text)
                    elif isinstance(block, ToolUseBlock):
                        print(f"{prefix}-> {block.name}")
            elif isinstance(msg, ResultMessage):
                result = msg
    except Exception as exc:  # noqa: BLE001 — keep the last result we saw, report the error
        print(f"query ended with an error: {exc}", file=sys.stderr)
    return result


def report(result: ResultMessage, service: str | None) -> int:
    """Steps 2 & 5 — findings file, cost/usage, session id."""
    print(f"\nDone: {result.subtype} ${result.total_cost_usd or 0:.4f} "
          f"(turns={result.num_turns}, terminal_reason={result.terminal_reason}, session={result.session_id})")
    for denial in result.permission_denials or []:
        print(f"  permission denial: {denial}")
    u = result.usage or {}
    print(f"usage(main loop): in={u.get('input_tokens', 0)} out={u.get('output_tokens', 0)} "
          f"cache_read={u.get('cache_read_input_tokens', 0)} cache_write={u.get('cache_creation_input_tokens', 0)}")
    for model, mu in (result.model_usage or {}).items():               # whole tree incl. subagents; camelCase keys
        print(f"  {model}: ${mu.get('costUSD', 0):.4f} in={mu.get('inputTokens')} out={mu.get('outputTokens')} "
              f"cache_read={mu.get('cacheReadInputTokens')}")
    SESSION_FILE.write_text(result.session_id)
    if service and result.structured_output:
        out = OTEL / "reports" / f"{Path(service).name}.findings.json"
        out.parent.mkdir(exist_ok=True)
        out.write_text(json.dumps(result.structured_output, indent=2))
        print(f"wrote {out} ({len(result.structured_output.get('findings', []))} findings)")
    elif service:
        print("no structured_output on the result — treat as failure", file=sys.stderr)
        return 1
    return 0 if result.subtype == "success" else 1


async def run(service: str, ticket: bool) -> int:
    prompt = PROMPT.format(service=service) + (TICKET_SUFFIX if ticket else "")
    options = base_options(
        output_format={"type": "json_schema", "schema": FINDINGS_SCHEMA},                        # step 2
        mcp_servers={"tracker": tracker_server},                                                 # step 3
        hooks={"PreToolUse": [HookMatcher(matcher="Read", hooks=[protect_secrets_hook])]},       # step 4a
        can_use_tool=ticket_policy,                                                              # step 4b
        permission_mode="default",                                                               # step 4b (was dontAsk)
    )
    result = await consume(query(prompt=as_stream(prompt), options=options))
    return report(result, service) if result else 1


async def followup(question: str) -> int:
    if not SESSION_FILE.exists():
        print("no .bughunter-session yet — run an analysis first", file=sys.stderr)
        return 2
    options = base_options(resume=SESSION_FILE.read_text().strip())                             # step 5
    result = await consume(query(prompt=question, options=options))
    return report(result, None) if result else 1


def main() -> None:
    args = sys.argv[1:]
    if not args or args[0] in {"-h", "--help"}:
        print(__doc__)
        sys.exit(2)
    if not (os.environ.get("ANTHROPIC_API_KEY") or os.environ.get("CLAUDE_CODE_USE_BEDROCK")
            or os.environ.get("CLAUDE_CODE_USE_VERTEX") or os.environ.get("CLAUDE_CODE_USE_FOUNDRY")):
        print("warning: no ANTHROPIC_API_KEY / provider env set — see module 5.2", file=sys.stderr)
    if args[0] == "followup":
        sys.exit(asyncio.run(followup(" ".join(args[1:]) or "Summarize the findings in three bullets.")))
    sys.exit(asyncio.run(run(args[0], "--ticket" in args[1:])))


if __name__ == "__main__":
    main()
