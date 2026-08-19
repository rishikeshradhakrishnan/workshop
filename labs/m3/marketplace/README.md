# workshop-marketplace (reference)

`marketplace.json` for the local marketplace built in Module 3 step 11. At lab time the directory layout is:

```
workshop-marketplace/
├── .claude-plugin/marketplace.json     "source": "./codebase-toolkit"
└── codebase-toolkit/                   a copy of the plugin (cp -r ../codebase-toolkit .)
```

`labs/checkpoint.sh CP3` materialises exactly this next to `$OTEL` (as `$OTEL/../workshop-marketplace/`).
The org-published twin lives at `github.com/<WORKSHOP_ORG>/claude-marketplace` (marketplace name `<WORKSHOP_ORG>-marketplace`).
