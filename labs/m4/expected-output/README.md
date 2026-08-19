# Module 4 — expected output

Read-along material for participants without a working headless run or without an API key for Path B.

| File | What it is |
|---|---|
| `adservice.findings.json` | Shape of `bug-hunt.sh src/adservice` output (`claude -p --output-format json --json-schema …`): the result envelope with `structured_output` matching `labs/shared/findings.schema.json`. **Illustrative sample** — finding text and line numbers are placeholders; regenerate from a real run before each delivery (see below). |
| `stream.log` *(maintainers add)* | `bug-hunt-stream.sh src/adservice \| jq -r -f stream-filter.jq` transcript: `init … plugins=codebase-toolkit`, `Agent`, indented subagent `Read/Grep/Glob`, `done success …`. |
| `two-step-session.log` *(maintainers add)* | Path A step 3: the `session_id` capture and the resumed call showing large `cache_read` tokens. |
| `pr-sticky-comment.png`, `code-review-inline.png` *(maintainers add)* | Path B: the `@claude` sticky comment and an inline review comment on `demo/add-export-endpoint`. |

Regenerate (instructor machine, CP3 state, `source labs/.env`):

```bash
cd $OTEL && $WS/labs/m4/bug-hunt.sh src/adservice > $WS/labs/m4/expected-output/adservice.findings.json
jq .structured_output $WS/labs/m4/expected-output/adservice.findings.json | npx -y ajv-cli validate -s $WS/labs/shared/findings.schema.json -d /dev/stdin
```
