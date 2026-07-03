# LangGraph Step 3 Thread API Evidence

Date: 2026-07-03

Status: `PASS`

## Dependency

Approved and pinned:

```text
langgraph-checkpoint-sqlite==3.1.0
```

The development checkpointer uses a separate file:

```text
.langgraph/checkpoints.sqlite
```

The path is configurable through `LANGGRAPH_DEV_CHECKPOINT_PATH`. No application DB
model, Alembic migration, or production schema was changed.

## API

Added authenticated endpoints under the existing agent prefix:

```text
POST /api/v1/agent/threads
GET  /api/v1/agent/threads
GET  /api/v1/agent/threads/{thread_id}
POST /api/v1/agent/threads/{thread_id}/commands
POST /api/v1/agent/threads/{thread_id}/resume
GET  /api/v1/agent/threads/{thread_id}/stream
```

All endpoints:

- require the existing authenticated `get_current_user`
- derive ownership from the verified backend user
- return 404 for another user's thread
- are hidden behind `LANGGRAPH_ENABLED`
- return 404 while the flag remains disabled

The compatibility `/command`, `/confirm`, `/csv-preview`, and `/csv-schedule` endpoints
remain unchanged.

## User Isolation

The SQLite checkpointer metadata and graph state contain the verified numeric `user_id`.
Every list/get/command/resume/stream operation compares stored ownership with the
authenticated user.

Cross-user tests verify:

- detail is not discoverable
- command cannot be submitted
- resume cannot be called
- stream cannot be read
- list returns no foreign thread

## Development Persistence

`DevelopmentThreadService` uses LangGraph `SqliteSaver`.

Thread state contains:

- backend-generated thread/workflow/message IDs
- user ownership
- title and ISO timestamps
- safe message history
- graph counters and safe artifacts/context placeholders

A service instance was closed, recreated against the same SQLite file, and successfully
restored the thread and conversation. This proves process/service restart persistence
for the development gate.

## Typed SSE

Defined typed events:

- `thread.snapshot`
- `thread.progress`
- `thread.completed`

Properties:

- generic user-visible names; no graph node/hidden-agent/model details
- checkpoint-derived deterministic IDs
- ordered emission
- `Last-Event-ID` reconnect support
- already-seen events are skipped
- completion reconnect returns no duplicates
- `text/event-stream` and no-cache headers

## Tests

Targeted:

```text
22 passed
```

Coverage:

- authentication required
- disabled flag behavior
- create/list/get/command/resume lifecycle
- cross-user denial
- message persistence
- SSE content type and ordering
- reconnect and deduplication
- restart persistence
- legacy API subset regression

Full backend:

```text
164 passed
169 warnings
```

Compile check passed for the graph package and thread route.

## Docker Verification

Candidate:

```text
socialhub-backend:langgraph-step3
```

Verified:

- clean dependency installation
- `pip check`: no broken requirements
- `SqliteSaver` import
- `/health`: HTTP 200
- thread endpoint while default-disabled: HTTP 404
- isolated test containers removed

No production container, environment, database, or deployment was touched.

## Gate Decision

Step 3 status: `PASS`.

Acceptance criteria met:

- authenticated thread API
- strict cross-user isolation
- lifecycle and resume surface
- typed reconnectable/deduplicated SSE
- development SQLite checkpoint persistence
- conversation survives service restart
- legacy agent API remains available
- default production behavior remains disabled

Next gate: Step 4 — PostgreSQL checkpointing. It requires explicit migration/design
approval before implementation.

