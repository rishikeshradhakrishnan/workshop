( select(.type=="system" and .subtype=="init")
    | "init  model=\(.model)  plugins=\([.plugins[]?.name] | join(","))" ),
( select(.type=="assistant") | (if .parent_tool_use_id then "  sub " else "tool  " end) as $p
    | .message.content[]? | select(.type=="tool_use") | "\($p)\(.name)  \(.input | tostring | .[0:70])" ),
( select(.type=="result") | "done  \(.subtype)  turns=\(.num_turns)  cost=$\(.total_cost_usd)" )
