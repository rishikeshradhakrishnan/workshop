"""Step 4 — guardrails as code: a PreToolUse hook callback and a can_use_tool permission callback.

TODO(step-4a): protect_secrets_hook — if tool_input.file_path matches PROTECTED, return
    {"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
                            "permissionDecisionReason": "..."}}
  otherwise return {} (no opinion). Register it in __main__.py with
    hooks={"PreToolUse": [HookMatcher(matcher="Read", hooks=[protect_secrets_hook])]}

TODO(step-4b): ticket_policy — for TICKET_TOOL: allow HIGH (PermissionResultAllow(updated_input=input_data)),
  deny everything else with a message Claude can act on (PermissionResultDeny(message=...)).
  Then in __main__.py: can_use_tool=ticket_policy, permission_mode="default", REMOVE TICKET_TOOL from allowed_tools,
  and pass the prompt through as_stream().
"""
import re

from claude_agent_sdk import PermissionResultAllow, PermissionResultDeny  # noqa: F401  (used once you fill the TODOs)

from .tools import TICKET_TOOL  # noqa: F401

PROTECTED = re.compile(r"(^|/)\.env(\.[^/]*)?$|(^|/)secrets/")


async def protect_secrets_hook(input_data, tool_use_id, context):
    """PreToolUse (matcher='Read'): deny reads of .env* and secrets/ — fires in subagents too."""
    # TODO(step-4a)
    return {}


async def ticket_policy(tool_name, input_data, context):
    """can_use_tool: reached only by calls that no rule/mode already decided (so NOT by allowed_tools entries)."""
    # TODO(step-4b)
    return PermissionResultDeny(message=f"{tool_name} is not permitted in bughunter (TODO step-4b)")
