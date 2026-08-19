#!/usr/bin/env bash
# labs/m6-managed-agents/curl/steps.sh — Module 6, the same eight calls with raw HTTP + jq (§10.3).
# Note the THREE headers on every call; a missing anthropic-beta header surfaces as a 404, not a 400.
set -euo pipefail
source "${WS:?export WS (source labs/.env)}/labs/.env"     # ANTHROPIC_API_KEY, CMA_MODEL, WORKSHOP_ORG, GITHUB_USER
: "${ANTHROPIC_API_KEY:?set it in labs/.env}" "${CMA_MODEL:?full model ID in labs/.env}"
case "$CMA_MODEL" in "<"*|sonnet|opus|haiku|default) echo "CMA_MODEL='$CMA_MODEL' is a placeholder/alias — set a full model ID in labs/.env (reference §B)" >&2; exit 1;; esac
API=https://api.anthropic.com/v1
BETA="${MANAGED_AGENTS_BETA:-managed-agents-2026-04-01}"
H=(-H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01"
   -H "anthropic-beta: $BETA" -H "content-type: application/json")

# (1) environment
ENV_ID=$(curl -sS --fail-with-body "$API/environments" "${H[@]}" -d @- <<'EOF' | jq -er .id
{"name": "ws-curl", "config": {"type": "cloud", "packages": {"pip": ["ruff"]},
  "networking": {"type": "limited", "allowed_hosts": ["github.com","api.github.com","raw.githubusercontent.com"],
                 "allow_package_managers": true, "allow_mcp_servers": false}}}
EOF
)
echo "environment $ENV_ID"

# (2) agent  (system prompt inlined from the shared file with jq to keep JSON escaping correct)
AGENT=$(jq -n --arg model "$CMA_MODEL" --arg name "codebase-toolkit-${GITHUB_USER:-anon}-curl" \
        --rawfile system "$WS/labs/shared/prompts/bug_hunter_system.md" '{
  name: $name, model: $model, system: $system,
  tools: [
    {type: "agent_toolset_20260401", default_config: {permission_policy: {type: "always_allow"}},
     configs: [{name: "web_fetch", permission_policy: {type: "always_ask"}}, {name: "web_search", enabled: false}]},
    {type: "custom", name: "create_ticket", description: "File a bug ticket for one HIGH finding. Returns the ticket ID.",
     input_schema: {type: "object", properties: {title: {type: "string"}, severity: {type: "string"},
                    file: {type: "string"}, line: {type: "integer"}}, required: ["title","severity","file","line"]}}]}' \
  | curl -sS --fail-with-body "$API/agents" "${H[@]}" -d @-)
AGENT_ID=$(jq -er .id <<<"$AGENT"); echo "agent $AGENT_ID v$(jq -r .version <<<"$AGENT")"

# (3) session (idle) → (4) open the SSE stream FIRST → then send the prompt
SESSION_ID=$(jq -n --arg a "$AGENT_ID" --arg e "$ENV_ID" '{agent: $a, environment_id: $e, title: "curl bug hunt"}' \
  | curl -sS --fail-with-body "$API/sessions" "${H[@]}" -d @- | jq -er .id)
echo "session $SESSION_ID"
exec {stream}< <(curl -sS --fail-with-body -N "$API/sessions/$SESSION_ID/events/stream" "${H[@]}" -H "accept: text/event-stream")
jq -n --arg org "$WORKSHOP_ORG" '{events: [{type: "user.message", content: [{type: "text", text:
  ("Clone https://github.com/" + $org + "/opentelemetry-demo (depth 1) into /workspace, analyze src/paymentservice for bugs, write /mnt/session/outputs/bug-report.md, file a ticket per HIGH finding with create_ticket, then fetch https://raw.githubusercontent.com/open-telemetry/opentelemetry-demo/main/CHANGELOG.md and note anything already fixed upstream.")}]}]}' \
  | curl -sS --fail-with-body "$API/sessions/$SESSION_ID/events" "${H[@]}" -d @- >/dev/null

declare -A KIND NAME                                     # remember pending tool events by id  (bash 4+; on macOS use brew bash)
send() { curl -sS --fail-with-body "$API/sessions/$SESSION_ID/events" "${H[@]}" -d "$1" >/dev/null; }
while IFS= read -r -u "$stream" line; do
  [[ $line == data:* ]] || continue; ev=${line#data: }
  type=$(jq -r .type <<<"$ev")
  case $type in
    agent.message)          jq -j '.content[] | select(.type=="text") | .text' <<<"$ev" ;;
    agent.tool_use|agent.mcp_tool_use|agent.custom_tool_use)
                            id=$(jq -r .id <<<"$ev"); KIND[$id]=$type; NAME[$id]=$(jq -r .name <<<"$ev")
                            printf '\n[%s: %s]\n' "$type" "${NAME[$id]}" ;;
    span.model_request_end) jq -r '"  · in=\(.model_usage.input_tokens) out=\(.model_usage.output_tokens)"' <<<"$ev" ;;
    session.error)          jq -r '"[session.error] " + (.error.message // "unknown")' <<<"$ev" ;;
    session.status_idle)
      reason=$(jq -r .stop_reason.type <<<"$ev")
      if [[ $reason != requires_action ]]; then printf '\n[idle: %s]\n' "$reason"; break; fi
      for id in $(jq -r '.stop_reason.event_ids[]' <<<"$ev"); do
        if [[ ${KIND[$id]:-} == agent.custom_tool_use ]]; then      # (6) custom tool → our result
          send "$(jq -n --arg id "$id" --arg t "TICKET-$RANDOM" \
            '{events: [{type: "user.custom_tool_result", custom_tool_use_id: $id, content: [{type: "text", text: $t}]}]}')"
        else                                                           # (5) always_ask → human decides
          read -r -p "Allow ${NAME[$id]:-tool}? [a/d] " ans </dev/tty
          if [[ $ans == a* ]]; then
            send "$(jq -n --arg id "$id" '{events: [{type: "user.tool_confirmation", tool_use_id: $id, result: "allow"}]}')"
          else
            send "$(jq -n --arg id "$id" '{events: [{type: "user.tool_confirmation", tool_use_id: $id, result: "deny",
                     deny_message: "Operator declined; skip the upstream check."}]}')"
          fi
        fi
      done ;;
  esac
done
exec {stream}<&-

# (7) outputs + usage
FILE_ID=$(curl -fsSL "$API/files?scope_id=$SESSION_ID" "${H[@]}" | jq -r '.data[] | select(.filename|endswith("bug-report.md")) | .id' | head -1)
if [ -n "$FILE_ID" ]; then curl -fsSL "$API/files/$FILE_ID/content" "${H[@]}" -o bug-report.md && echo "downloaded bug-report.md"; fi
curl -fsSL "$API/sessions/$SESSION_ID" "${H[@]}" | jq '.usage'

# (8) stop: interrupt if still running, then archive (POST …/archive) or delete (DELETE …)
send '{"events": [{"type": "user.interrupt"}]}' || true
sleep 3
curl -fsSL -X POST "$API/sessions/$SESSION_ID/archive" "${H[@]}" | jq -r .status
echo "ids: environment=$ENV_ID agent=$AGENT_ID session=$SESSION_ID  (labs/cleanup.sh --by-prefix curl archives them)"
