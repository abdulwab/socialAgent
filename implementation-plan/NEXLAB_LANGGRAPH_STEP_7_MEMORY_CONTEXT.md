# Step 7 Evidence — Memory and Context

Date: 2026-07-03  
Status: PASS

## Delivered

- Kept backend `thread_id` and checkpoint state authoritative.
- Strict command requests accept only the new message and input mode; client-supplied
  history or artifact payloads are rejected.
- Checkpointed both user and assistant messages for restart-safe short-term memory.
- Added a SQLAlchemy long-term memory store using the existing `agent_memories` table.
  No migration was needed.
- Added typed memory proposals with scopes:
  - `user_preference`
  - `brand`
  - `app`
  - `artifact`
  - `analytics`
- Added intent-relevant retrieval so unrelated memories are excluded.
- Added create/list/edit/forget API routes behind `LANGGRAPH_ENABLED`.
- Added user-scoped ownership, unique-key deduplication, provenance, confidence, source,
  thread origin, timestamps, and optional expiry.
- Added recursive nested-secret and credential-shaped-value rejection.
- Added sanitized FastAPI validation responses that do not echo rejected secret values.
- Added checkpoint-owned artifact indexes with stable backend artifact IDs.
- Follow-ups such as `Schedule this tomorrow at 10 AM` resolve the latest backend draft
  ID and platform without frontend artifact history.

## Persistence design

Existing `agent_memories.value_json` stores a version-compatible envelope:

```json
{
  "value": {},
  "_meta": {
    "provenance": "...",
    "confidence": 1.0,
    "thread_id": "thread_...",
    "created_at": "...",
    "updated_at": "...",
    "expires_at": null
  }
}
```

Legacy rows remain readable. Expired or unsafe legacy values are excluded from retrieval.
The existing unique constraint on `(user_id, memory_type, key)` provides deterministic
deduplication.

## Gate results

Focused memory/context/thread/routing suite:

```text
20 passed
```

It proves:

- refresh/restart restores checkpoint conversation and context;
- preferences written in one thread are retrieved in another thread for the same user;
- another user's memories and artifacts are inaccessible;
- irrelevant memory scopes are excluded;
- create, read, edit, expiry, deduplication, and forget work against a real SQL database;
- nested secrets and credential-shaped values are rejected and not echoed;
- `schedule this` resolves a backend artifact ID without a frontend artifact payload;
- client attempts to send history/artifacts are rejected.

Full backend regression:

```text
python -m compileall -q app
python -m pytest -q
187 passed, 1 skipped
```

The skipped test is the existing opt-in disposable PostgreSQL integration test. Existing
deprecation warnings remain non-blocking.

## Safety and rollout

- `LANGGRAPH_ENABLED` remains the route/runtime gate.
- Memory queries always include the authenticated `user_id`.
- OAuth tokens, API keys, passwords, cookies, authorization data, and credential-shaped
  strings cannot be written to memory.
- Runtime DB sessions and ORM objects are never checkpointed.
- No dependency, migration, environment, production data, deployment, or frontend change
  occurred.
- Mutation tools remain dry-run.

## Pass decision

PASS. Memory now performs real scoped reads and writes, checkpoint context survives restart,
and correct follow-up routing no longer depends on frontend-owned history or artifacts.
