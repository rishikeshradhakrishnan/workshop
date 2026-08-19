# astroshop-reviews — product reviews for the Astronomy Shop

> [!CAUTION]
> ## SECURITY NOTICE — INTENTIONALLY VULNERABLE TEACHING CODE
> This service is the practice target for **Module 7 (Securing agentic development)** of the *Claude for Builders*
> workshop. It contains **deliberately seeded security vulnerabilities** so that scanners, reviewers and patches have
> something real to find. **Never deploy it, never expose it to a network you do not fully control, never point real
> credentials or real data at it, and never copy code from it into another project.** All keys and secrets in this
> repository are fake placeholders. Run it only locally, only for the lab, and delete your copy when you are done.
> The maintainers' answer key lives in the workshop repository (`labs/m7-security/SOLUTIONS.md`), not here.

A small Flask + sqlite3 microservice that stores and serves customer reviews for Astronomy Shop products
(telescopes, binoculars, accessories). In the workshop narrative it is the shop's review backend; it is **not** wired
into the OpenTelemetry demo deployment and needs no other service to run.

## Run the tests (this is all the workshop needs)

```bash
uv sync                 # or: python -m venv .venv && . .venv/bin/activate && pip install -r requirements.txt
uv run pytest -q        # 8 fast tests, all green
```

Optional local dev server (binds to all interfaces with the debugger on — see the notice above; do not do this on a shared network):

```bash
uv run flask --app wsgi init-db     # creates reviews.db with two users and three reviews
uv run python wsgi.py               # http://127.0.0.1:5000/reviews?product_id=telescope-01
```

## API sketch

| Method & path | Auth | What |
|---|---|---|
| `POST /login` | – | `{username, password}` → `{token}` (seed users `ada` / `grace`, password `x`) |
| `GET /reviews?product_id=` | – | public reviews for a product |
| `GET /reviews/search?q=` | – | full-text search over public reviews (JSON, or HTML with `Accept: text/html`) |
| `POST /reviews` | bearer | create a review `{product_id, rating, body, private?}` |
| `POST /reviews/import` | bearer | bulk import from a YAML list |
| `GET /users/<id>/reviews/private` | bearer | a user's private drafts |
| `GET /exports/<name>` | bearer | download a CSV export from `exports/` |

## Layout

```
app/            Flask blueprints (reviews, users, exports), sqlite helpers, stdlib HS256 tokens, one Jinja template
tests/          pytest suite (conftest builds a temp database per test)
exports/        sample CSV export
.workshop/      lab assets used verbatim in Module 7 (patch to introduce an SSRF, CI workflow, security-guidance rules,
                sample Claude Security scan results, expected output) — see .workshop/README.md
.github/        ci.yml only (pytest); the security-review workflow is added during the lab
CLAUDE.md       project notes for coding agents (includes one planted line for the prompt-injection demonstration)
```

## Using this template in the workshop

1. Click **Use this template** → owner: *your* GitHub account, name `astroshop-reviews`, public.
2. `git clone https://github.com/<you>/astroshop-reviews "$REV" && cd "$REV" && uv sync && uv run pytest -q`
3. Module 4 Path B adds the `@claude` and code-review workflows; Module 7 scans, patches and gates it.

License: educational use as part of the workshop materials. No warranty; see the notice at the top.
