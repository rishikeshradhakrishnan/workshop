"""One place to bump the Claude Managed Agents identifiers used by the M6 lab code (verify before each delivery; Ref §O)."""
import os

BETA = os.environ.get("MANAGED_AGENTS_BETA", "managed-agents-2026-04-01")   # anthropic-beta header value (SDKs add it for you)
MEMORY_BETA = "agent-memory-2026-07-22"                                       # only for /v1/memory_stores/* endpoints
TOOLSET = "agent_toolset_20260401"                                            # built-in toolset type
API_VERSION = "2023-06-01"                                                    # anthropic-version header for raw HTTP
SESSION_HOUR_USD = 0.08                                                       # runtime list price per session-hour while `running` (Aug 2026 — check the pricing page)
