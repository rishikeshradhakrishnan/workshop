# Template-repo maintenance (not used by participants)

Create the branch the M4 Path B lab opens a PR from:

```bash
git switch -c demo/add-export-endpoint main
git apply .workshop/maintainers/demo-add-export-endpoint.patch     # adds POST /exports (admin-only CSV export writer)
uv run pytest -q && git commit -am "Add CSV export endpoint" && git push -u origin demo/add-export-endpoint
git switch main
```

Also after every sync from `apps/astroshop-reviews/`: repo is a **template**, Actions enabled for repos created from it,
`uv run pytest -q` green, `git apply --check .workshop/introduce-ssrf.patch` clean on `main`.
