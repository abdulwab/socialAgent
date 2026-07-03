# Backend API and Tools

FastAPI routes use `/api/v1/`; health is `/health`.

Current compatibility endpoints include `/agent/command`, `/agent/confirm`,
`/agent/csv-preview`, and `/agent/csv-schedule`.

Target APIs create/list/get user threads, submit commands, resume interrupts, and stream
typed SSE events.

Existing services become strict tools declaring schemas, allowed agents, risk,
confirmation, ownership, idempotency, timeout, retry, redacted audit, and safe errors.
New graph nodes must not perform direct mutations.

Legacy locations and disposition are tracked in
`implementation-plan/NEXLAB_LANGGRAPH_LEGACY_AUDIT.md`.

