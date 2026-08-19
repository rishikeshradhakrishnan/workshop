# Patches for this report (SAMPLE)

| Finding | Patch | Note | Status | Tests |
|---|---|---|---|---|
| F1 SQL injection in review search | `F1.patch` | `F1.md` | written — 3/3 claims vouched | 8 passed |
| F2 IDOR on private reviews | `F2.patch` | `F2.md` | written — add a cross-user test in the PR | 8 passed |

Patches are never applied automatically. Apply each on its own branch with `git apply`, run the tests, open one PR per patch.
Other findings: run `/claude-security suggest patches for F3` (etc.) on a **current** report of your own `HEAD`.
