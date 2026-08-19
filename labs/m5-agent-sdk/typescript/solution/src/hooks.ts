import type { CanUseTool, HookCallback, PreToolUseHookInput } from "@anthropic-ai/claude-agent-sdk";
import { TICKET_TOOL } from "./tools.js";

const PROTECTED = /(^|\/)\.env(\.[^/]*)?$|(^|\/)secrets\//;

export const protectSecretsHook: HookCallback = async (input) => {
  const filePath = String(((input as PreToolUseHookInput).tool_input as { file_path?: string })?.file_path ?? "");
  if (PROTECTED.test(filePath)) {
    console.log(`  [hook] denied Read ${filePath}`);
    return { hookSpecificOutput: { hookEventName: "PreToolUse", permissionDecision: "deny",
                                   permissionDecisionReason: `bughunter policy: ${filePath} is a protected path` } };
  }
  return {};
};

export const ticketPolicy: CanUseTool = async (toolName, input) => {
  if (toolName === TICKET_TOOL) {
    const severity = String(input.severity ?? "").toUpperCase();
    if (severity === "HIGH") { console.log("  [policy] allowed create_ticket (HIGH)"); return { behavior: "allow", updatedInput: input }; }
    console.log(`  [policy] denied create_ticket (${severity})`);
    return { behavior: "deny", message: "only HIGH severity gets a ticket; mention lower-severity items in the summary instead" };
  }
  return { behavior: "deny", message: `${toolName} is not permitted in bughunter` };
};
