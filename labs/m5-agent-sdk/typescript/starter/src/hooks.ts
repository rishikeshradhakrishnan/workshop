/* Step 4 — guardrails as code.
 * TODO(step-4a): protectSecretsHook — if tool_input.file_path matches PROTECTED, return
 *   { hookSpecificOutput: { hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: "..." } }
 *   else return {}. Register in main.ts: hooks: { PreToolUse: [{ matcher: "Read", hooks: [protectSecretsHook] }] }
 * TODO(step-4b): ticketPolicy — for TICKET_TOOL allow HIGH ({ behavior: "allow", updatedInput: input }),
 *   deny the rest ({ behavior: "deny", message }). Then in main.ts: canUseTool: ticketPolicy, permissionMode: "default",
 *   and REMOVE TICKET_TOOL from allowedTools.
 */
import type { CanUseTool, HookCallback, PreToolUseHookInput } from "@anthropic-ai/claude-agent-sdk";  // eslint-disable-line @typescript-eslint/no-unused-vars
import { TICKET_TOOL } from "./tools.js";                                                              // eslint-disable-line @typescript-eslint/no-unused-vars

export const PROTECTED = /(^|\/)\.env(\.[^/]*)?$|(^|\/)secrets\//;

export const protectSecretsHook: HookCallback = async (_input) => {
  // TODO(step-4a)
  return {};
};

export const ticketPolicy: CanUseTool = async (toolName, _input) => {
  // TODO(step-4b)
  return { behavior: "deny", message: `${toolName} is not permitted in bughunter (TODO step-4b)` };
};
