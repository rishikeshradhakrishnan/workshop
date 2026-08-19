"""Instructor demo (Module 5, live-code beat 2):  cd $WS/labs/m5-agent-sdk/python && uv run python demo.py [--plugin]

The smallest useful Agent SDK program, then the same program with the M3 plugin loaded (pass --plugin).
Reads OTEL, MODEL from labs/.env; ANTHROPIC_API_KEY must be exported.
"""
import asyncio
import os
import sys
from pathlib import Path

from claude_agent_sdk import (AssistantMessage, ClaudeAgentOptions, ResultMessage, SystemMessage, TextBlock,
                              ToolUseBlock, query)

OTEL = Path(os.environ.get("OTEL", "../../../../opentelemetry-demo")).resolve()
MODEL = os.environ.get("MODEL", "sonnet")
WITH_PLUGIN = "--plugin" in sys.argv[1:]


async def main() -> None:
    opts = dict(cwd=str(OTEL), model=MODEL, allowed_tools=["Read", "Grep", "Glob"], permission_mode="dontAsk",
                max_turns=20, max_budget_usd=0.50)
    prompt = "Give me a one-paragraph tour of src/paymentservice."
    if WITH_PLUGIN:                                            # the two lines added live
        opts["plugins"] = [{"type": "local", "path": str(OTEL.parent / "codebase-toolkit")}]
        opts["allowed_tools"] = ["Read", "Grep", "Glob", "Agent"]
        prompt = "Use the codebase-toolkit:bug-hunter agent to analyze src/adservice; give me its top three findings."
    async for msg in query(prompt=prompt, options=ClaudeAgentOptions(**opts)):
        if isinstance(msg, SystemMessage) and msg.subtype == "init":
            print(f"init: model={msg.data.get('model')} apiKeySource={msg.data.get('apiKeySource')} "
                  f"plugins={[p.get('name') for p in msg.data.get('plugins', [])]}")
        elif isinstance(msg, AssistantMessage):
            for b in msg.content:
                if isinstance(b, TextBlock):
                    print(b.text)
                elif isinstance(b, ToolUseBlock):
                    print(f"  -> {b.name}")
        elif isinstance(msg, ResultMessage):
            print(f"Done: {msg.subtype} ${msg.total_cost_usd or 0:.4f}")


asyncio.run(main())
