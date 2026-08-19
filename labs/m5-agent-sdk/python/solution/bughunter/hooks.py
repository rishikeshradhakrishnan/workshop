"""Step 4 — guardrails as code: a PreToolUse hook callback and a can_use_tool permission callback."""
import re

from claude_agent_sdk import PermissionResultAllow, PermissionResultDeny

from .tools import TICKET_TOOL

PROTECTED = re.compile(r"(^|/)\.env(\.[^/]*)?$|(^|/)secrets/")


async def protect_secrets_hook(input_data, tool_use_id, context):
    """PreToolUse (matcher='Read'): deny reads of .env* and secrets/ — fires in subagents too."""
    path = input_data.get("tool_input", {}).get("file_path", "")
    if PROTECTED.search(path):
        print(f"  [hook] denied Read {path}")
        return {"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
                                       "permissionDecisionReason": f"bughunter policy: {path} is a protected path"}}
    return {}


async def ticket_policy(tool_name, input_data, context):
    """can_use_tool: reached only by calls that no rule/mode already decided (so NOT by allowed_tools entries)."""
    if tool_name == TICKET_TOOL:
        severity = str(input_data.get("severity", "")).upper()
        if severity == "HIGH":
            print("  [policy] allowed create_ticket (HIGH)")
            return PermissionResultAllow(updated_input=input_data)
        print(f"  [policy] denied create_ticket ({severity})")
        return PermissionResultDeny(message="only HIGH severity gets a ticket; mention lower-severity items in the summary instead")
    return PermissionResultDeny(message=f"{tool_name} is not permitted in bughunter")
