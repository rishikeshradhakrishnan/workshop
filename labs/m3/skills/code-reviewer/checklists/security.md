# Security checklist (loaded only when focus = security)

Apply each item to the code under review and cite file:line for every hit.

1. **Injection** — SQL/NoSQL/command/template strings built by concatenation or
   f-strings with request data; shelling out with user input.
2. **Authentication & authorization** — endpoints or RPCs reachable without a check;
   object IDs taken from the request without an ownership check (IDOR).
3. **Secrets** — API keys, passwords, tokens, private keys in source, config samples,
   tests or logs; secrets compared with non-constant-time equality.
4. **Outbound requests** — URLs assembled from user input (SSRF); TLS verification
   disabled; missing timeouts.
5. **Deserialization & parsing** — unsafe YAML/pickle/object deserialization of
   untrusted data; XML external entities.
6. **File system** — paths joined from user input without normalization (traversal);
   world-writable temp files.
7. **Web output** — unescaped user data in HTML/templates (XSS); verbose stack traces
   or debug mode enabled in production paths.
8. **Dependencies** — obviously outdated or unpinned security-relevant libraries
   (note only; do not guess CVEs).

Do NOT report: missing rate limiting, missing security headers, or theoretical issues
without a concrete code location. Severity: exploitable without auth = HIGH.
