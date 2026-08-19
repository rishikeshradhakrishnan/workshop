# Module 1 — prompts to paste

Every prompt used in the Module 1 demo and lab, in order, so you can copy instead of type.
Lines starting with `/` or `!` are typed at the Claude Code prompt exactly as shown; `bash`
blocks go in your terminal. See `modules/01-claude-code-essentials.md` for the narrative.

> If your fork's pinned tag lays out `src/` differently (e.g. `payment` instead of
> `paymentservice`), run `! ls src` first and adapt the paths below.

## Instructor demo

```text
Give me a one-paragraph tour of this repo and list the services under src/ with their language. Use the Explore agent.
```

```text
Which service converts currencies and where is the conversion table loaded from? One sentence.
```

```text
Which service converts currencies and where is the conversion table loaded from? One sentence. ultrathink
```

```text
/init
```

```bash
mkdir -p .claude/rules && cp $WS/labs/m1/rules/proto.md .claude/rules/ && cat .claude/rules/proto.md
```

```text
/plan add a /healthz endpoint to src/paymentservice (Node) that returns 200 and the service version; follow existing conventions
```

## Lab 1 — Drive, remember, plan, undo

### Step 1 — start uniformly and drive

```bash
cd $OTEL
git status --short
claude --permission-mode default -n m1-essentials
```

```text
Which services call CartService over gRPC? Cite the files and lines where the client is created.
```

```text
@src/checkoutservice/main.go what port does this listen on?
```

```text
! ls src
```

### Step 2 — give the project a memory

```text
/init
```

```text
Add to CLAUDE.md, under a "Conventions" heading: (1) every new HTTP/gRPC endpoint must emit an OpenTelemetry span named <service>.<operation>; (2) Go code uses table-driven tests; (3) never commit directly to the workshop branch — use feature branches.
```

```bash
mkdir -p .claude/rules
cp $WS/labs/m1/rules/proto.md .claude/rules/proto.md
cat .claude/rules/proto.md
```

Success check (second terminal, from `$OTEL`):

```bash
claude -p "What rules apply when editing pb/demo.proto?"
# forcing variant if the answer is generic:
claude -p "Read pb/demo.proto, then tell me which project rules apply when editing it."
```

### Step 3 — plan, edit the plan, approve

```text
/plan Add input validation for currency codes in src/currencyservice: reject codes that are not 3 uppercase letters or not in the supported list, with a clear error, following the service's existing error-handling style.
```

Optional line to add in the plan editor (`Ctrl+G`): `Do not touch generated protobuf code.`

```text
! git diff --stat
```

### Step 4 — undo with a checkpoint

`Esc` `Esc` on an empty prompt → select the `/plan Add input validation…` prompt → **Restore code and conversation**.

```text
! git status --short
```

### Step 5 — meters, model, effort

```text
/context
/usage
/cost
/model sonnet
/model default
/effort medium
```

## Stretch prompts

```text
/rename m1-essentials-<yourname>
/model opusplan
/btw which files has this session read so far?
```

```text
remember that in this repo we say 'Astronomy Shop', never 'webstore'
```
