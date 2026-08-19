"""Stretch (b): multi-turn REPL with interrupt —  uv run python -m bughunter.repl

One ClaudeSDKClient = one session for the whole loop. Ctrl+C interrupts the running turn (then we DRAIN the
response so the client is ready for the next prompt); an empty line or 'exit' quits.
"""
import asyncio

from claude_agent_sdk import AssistantMessage, ClaudeSDKClient, ResultMessage, TextBlock, ToolUseBlock

from .__main__ import base_options


async def repl() -> None:
    options = base_options()                                     # read-only, dontAsk, plugin loaded, budget capped
    async with ClaudeSDKClient(options=options) as client:
        print("bughunter repl — ask about $OTEL; empty line to quit; Ctrl+C interrupts a turn")
        while True:
            try:
                q = input("you> ").strip()
            except EOFError:
                break
            if q in {"", "exit", "quit"}:
                break
            await client.query(q)
            try:
                async for msg in client.receive_response():      # yields until (and including) the ResultMessage
                    if isinstance(msg, AssistantMessage):
                        for b in msg.content:
                            if isinstance(b, TextBlock):
                                print(b.text)
                            elif isinstance(b, ToolUseBlock):
                                print(f"  -> {b.name}")
                    elif isinstance(msg, ResultMessage):
                        print(f"[{msg.subtype} ${msg.total_cost_usd or 0:.4f} terminal_reason={msg.terminal_reason}]")
            except (KeyboardInterrupt, asyncio.CancelledError):
                await client.interrupt()                         # stop the turn...
                async for msg in client.receive_response():      # ...then drain it
                    if isinstance(msg, ResultMessage):
                        print(f"[interrupted: {msg.terminal_reason}]")


def main() -> None:
    asyncio.run(repl())


if __name__ == "__main__":
    main()
