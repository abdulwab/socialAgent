# Backend API and Tools

FastAPI routes use `/api/v1/`; health is `/health`.

Authoritative agent endpoints are thread based:

- `/agent/threads`
- `/agent/threads/{thread_id}`
- `/agent/threads/{thread_id}/commands`
- `/agent/threads/{thread_id}/resume`
- `/agent/threads/{thread_id}/stream`

CSV upload support remains available through `/agent/csv-preview` and
`/agent/csv-schedule` while CSV behavior is wrapped as typed LangGraph tooling.

Existing services become strict tools declaring schemas, allowed agents, risk,
confirmation, ownership, idempotency, timeout, retry, redacted audit, and safe errors.
New graph nodes must not perform direct mutations.

Do not reintroduce pre-thread compatibility adapters.
