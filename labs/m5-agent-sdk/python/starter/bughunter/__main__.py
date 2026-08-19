"""bughunter — Claude Agent SDK lab (Module 5) — STARTER.

  uv run bughunter <service-path> [--ticket]     analyze one service of $OTEL with the codebase-toolkit bug-hunter agent
  uv run bughunter followup "<question>"         resume the last session and ask a follow-up

Fill the TODO(step-n) blocks in order; every step has a success check in modules/05-claude-agent-sdk.md.
Stuck for longer than the step's minute budget? Copy that block from ../solution/ and move on.
"""
import asyncio
import json
import os
import sys
from pathlib import Path

from claude_agent_sdk import (AssistantMessage, ClaudeAgentOptions, HookMatcher, ResultMessage,  # noqa: F401
                              SystemMessage, TextBlock, ToolUseBlock, query)

from .hooks import protect_secrets_hook, ticket_policy  # noqa: F401  (step 4)
from .schema import FINDINGS_SCHEMA  # noqa: F401  (step 2)
from .tools import TICKET_TOOL, tracker_server  # noqa: F401  (step 3)

OTEL = Path(os.environ.get("OTEL", ".")).resolve()                                    # the repo the agent works in
PLUGIN = Path(os.environ.get("TOOLKIT_PLUGIN", str(OTEL.parent / "codebase-toolkit"))).resolve()  # M3 plugin dir
MODEL = os.environ.get("MODEL", "sonnet")                                             # single place to bump: labs/.env
SESSION_FILE = Path(".bughunter-session")

PROMPT = ("Use the codebase-toolkit:bug-hunter agent to analyze the service at `{service}` for bugs "
          "(logic errors, error-handling gaps, concurrency issues, resource leaks, security problems). "
          "Then consolidate its report into the required JSON findings object for service `{service}`. "
          "Every finding needs a real file path relative to the repository root and a line number you have verified.")
TICKET_SUFFIX = " After producing the findings, call the create_ticket tool once for each HIGH severity finding."
# step 4 changes the suffix to "...for each HIGH or MEDIUM severity finding" so the policy has something to refuse.


def base_options(**overrides) -> ClaudeAgentOptions:
    """Step 1 — the locked-down, read-only baseline (also used by `followup`)."""
    # TODO(step-1): cwd=str(OTEL), model=MODEL, setting_sources=["project"],
    #               plugins=[{"type": "local", "path": str(PLUGIN)}],
    #               allowed_tools=["Read", "Grep", "Glob", "Agent"], permission_mode="dontAsk",
    #               max_turns=40, max_budget_usd=1.00
    opts = dict(
        cwd=str(OTEL),
        max_budget_usd=1.00,      # pre-set: never remove the budget cap in a workshop room
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
            # TODO(step-1): SystemMessage(subtype=="init") -> print msg.data["plugins"] names and msg.data["apiKeySource"]
            #               AssistantMessage -> print TextBlock.text and "-> {ToolUseBlock.name}"
            #                                   (prefix "    (subagent) " when msg.parent_tool_use_id is set)
            #               ResultMessage -> keep it in `result` (do NOT break out of the loop)
            if isinstance(msg, ResultMessage):
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
    # TODO(step-5): print result.usage (input_tokens, output_tokens, cache_read_input_tokens, cache_creation_input_tokens)
    #               and per-model result.model_usage (costUSD, inputTokens, outputTokens, cacheReadInputTokens);
    #               write result.session_id to SESSION_FILE
    # TODO(step-2): if service and result.structured_output: write it to OTEL/"reports"/f"{Path(service).name}.findings.json"
    #               (json.dumps(..., indent=2)); if service but no structured_output: print an error and return 1
    return 0 if result.subtype == "success" else 1


async def run(service: str, ticket: bool) -> int:
    prompt = PROMPT.format(service=service) + (TICKET_SUFFIX if ticket else "")
    options = base_options(
        # TODO(step-2): output_format={"type": "json_schema", "schema": FINDINGS_SCHEMA},
        # TODO(step-3): mcp_servers={"tracker": tracker_server},  and add TICKET_TOOL to allowed_tools
        # TODO(step-4): hooks={"PreToolUse": [HookMatcher(matcher="Read", hooks=[protect_secrets_hook])]},
        #               can_use_tool=ticket_policy, permission_mode="default"  (and remove TICKET_TOOL from allowed_tools)
    )
    # TODO(step-4): query(prompt=as_stream(prompt), options=options)
    result = await consume(query(prompt=prompt, options=options))
    return report(result, service) if result else 1


async def followup(question: str) -> int:
    if not SESSION_FILE.exists():
        print("no .bughunter-session yet — run an analysis first (and finish step 5)", file=sys.stderr)
        return 2
    # TODO(step-5): options = base_options(resume=SESSION_FILE.read_text().strip()); consume(query(prompt=question, options=options))
    print("TODO(step-5): followup not implemented yet", file=sys.stderr)
    return 2


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
