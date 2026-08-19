# CLAUDE.md — OpenTelemetry "Astronomy Shop" demo (workshop fork)

Reference project memory for the workshop (`labs/checkpoint.sh CP1`). Your own `/init` output will differ in wording;
what matters is that it stays short, specific and verifiable. Verify service directory names against `ls src/` on the
pinned `workshop` branch — upstream renamed several services between releases.

## What this repo is
A polyglot microservice demo of an online telescope shop, instrumented end-to-end with OpenTelemetry. ~15 services under
`src/`, one shared protobuf contract in `pb/demo.proto`, wired together by Docker Compose (`docker-compose.yml`) or the
Helm chart. In this workshop we **read and edit source only** — nothing needs to be built or run locally.

## Layout
- `src/<service>/` — one directory per service, each with its own Dockerfile and README. Languages by service:
  Go (`checkoutservice`, `productcatalogservice`, `accountingservice` in older tags), C# (.NET: `cartservice`), Java (`adservice`),
  Kotlin (`frauddetectionservice`), JavaScript/Node.js (`paymentservice`), TypeScript/Next.js (`frontend`), Python
  (`recommendationservice`, `loadgenerator`), Rust (`shippingservice`), C++ (`currencyservice`), Ruby (`emailservice`),
  PHP (`quoteservice`), plus infra: `frontendproxy` (Envoy), `flagd` (feature flags), `kafka`, `otelcollector`, `imageprovider`.
- `pb/demo.proto` — gRPC contracts for every service; generated stubs live inside each service (`genproto/`, `*_pb2.py`, …).
- `src/flagd/demo.flagd.json` — feature flags (e.g. `paymentServiceFailure`, `adServiceFailure`, `cartServiceFailure`).
- `test/` — trace-based tests (Tracetest); `internal/tools/` — repo tooling; `.env` — image versions and ports for Compose.

## Commands (run from the repo root; most need Docker, which the workshop does not require)
- Regenerate protobuf stubs after editing `pb/demo.proto`: `make generate-protobuf` (or `docker compose run` targets in `Makefile`)
- Lint everything: `make check` · markdown/yaml lint: `make markdownlint yamllint` · license headers: `make checklicense`
- Build & run the shop: `make start` / `docker compose up -d` (frontend on :8080 via `frontendproxy`) · stop: `make stop`
- Per-service unit tests where they exist: Go `go test ./...` inside the service dir; Node `npm test`; .NET `dotnet test`;
  Java `./gradlew test`; Rust `cargo test`; Python `pytest`. Not every service ships tests — say so rather than inventing a command.

## How services talk
gRPC between backends (contracts in `pb/demo.proto`), HTTP from `frontend` through `frontendproxy`, Kafka from
`checkoutservice` → `accountingservice`/`frauddetectionservice`. Every service exports traces/metrics/logs via OTLP to `otelcollector`.

## Conventions
- Every new HTTP/gRPC endpoint must emit an OpenTelemetry span named `<service>.<operation>` and record errors on the span.
- Go code uses table-driven tests.
- Never commit directly to the `workshop` branch — use feature branches and small, reviewable commits.
- Do not hand-edit generated protobuf code; change `pb/demo.proto` and regenerate (see `.claude/rules/proto.md`).
- Keep changes scoped to one service per commit unless the change is to `pb/` or shared config.
- Prefer each service's existing logging/telemetry helpers over new dependencies.

## Gotchas
- Service names differ across upstream releases (`paymentservice` vs `payment`); trust `ls src/`, not memory.
- `.env` here holds Compose image tags and ports, not secrets — but project rules still deny reading `.env*` on principle.
- Reports and generated docs go to `reports/` and `docs/` (git-ignored on the workshop branch); security scan output to `CLAUDE-SECURITY-*/`.
