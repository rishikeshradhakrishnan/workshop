---
paths:
  - "**/*.proto"
  - "pb/**"
---
# Protobuf and generated code

- `pb/demo.proto` is the single source of truth for service contracts. Propose changes there; never hand-edit generated code (`*_pb2.py`, `*_pb2_grpc.py`, `*.pb.go`, `*_grpc.pb.go`, generated Java/Kotlin/C#/TypeScript stubs under any `genproto/` or `protos/` directory).
- After changing a message or service, list every consumer service that must regenerate stubs and the command each one uses (see that service's README or Dockerfile).
- Field numbers are forever: never renumber or reuse a field; mark removed fields `reserved`.
- Keep backwards compatibility: additive changes only unless the task explicitly says "breaking".
