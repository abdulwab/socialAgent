# User State and Memory

- Clerk JWT determines user ownership; never trust client `user_id`.
- Every thread, checkpoint, memory, artifact, confirmation, account, page, schedule,
  analytics query, and tool call is user-isolated.
- Short-term state will use PostgreSQL LangGraph checkpoints with `thread_id`.
- Long-term memory is scoped to preferences, brand, platform defaults, analytics
  insights, and artifact indexes.
- Memory needs proposals, redaction, provenance, expiry, deduplication, edit, and forget.
- Backend becomes authoritative; frontend history/artifacts are not the final source of truth.

Never store credentials, OAuth tokens, cookies, authorization headers, DB sessions, ORM
objects, or service clients in prompts, graph state, memory, traces, or SSE.

