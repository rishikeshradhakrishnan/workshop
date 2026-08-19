# Performance checklist (loaded only when focus = performance)

Apply each item to the code under review and cite file:line for every hit.

1. **Remote calls in loops** — per-item gRPC/HTTP/DB calls that could be batched (N+1).
2. **Missing timeouts / retries without backoff** on calls to other services.
3. **Allocation churn** — building large strings/arrays in hot paths; repeated
   (de)serialization of the same payload; regex compiled per call.
4. **Blocking work on request threads / event loop** — sync I/O in async handlers,
   CPU-heavy work without offloading.
5. **Caching** — identical lookups repeated per request (currency rates, product
   catalog, feature flags) with no cache or memoization.
6. **Unbounded growth** — maps/lists/queues that only grow; goroutine/task leaks;
   listeners never removed.
7. **Telemetry cost** — spans or logs emitted inside tight loops; high-cardinality
   attributes.

Severity: user-visible latency or memory growth under normal load = HIGH;
measurable but bounded = MEDIUM; micro-optimizations = LOW (mention at most three).
