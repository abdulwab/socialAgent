# LangGraph Step 4 PostgreSQL Checkpoint Evidence

Date: 2026-07-03

Status: `PASS`

Production migration status: `NOT APPLIED`

## Official Schema

The pinned `langgraph-checkpoint-postgres==3.1.0` schema was inspected in disposable
PostgreSQL 17. It owns only:

- `checkpoint_migrations`
- `checkpoints`
- `checkpoint_blobs`
- `checkpoint_writes`

The schema, primary keys, indexes, defaults, JSONB/BYTEA types, and official migration
versions `0..9` were reproduced in the approved Alembic revision:

```text
c3d4e5f6a7b8_add_langgraph_checkpoint_tables.py
```

The revision follows `b4e8f1a9c2d3` and is the single Alembic head.

Non-PostgreSQL development databases treat the revision as a no-op because SQLite uses
the separate development saver from Step 3.

## Runtime

Added `PooledPostgresCheckpointer`:

- official `PostgresSaver`
- `psycopg_pool.ConnectionPool`
- autocommit enabled
- `prepare_threshold=0`
- dictionary row factory
- validated minimum/maximum pool bounds
- explicit open, health check, and close lifecycle
- PostgreSQL URL validation

The runtime does not call `PostgresSaver.setup()`. Alembic owns schema creation.

## Operational Policy

Documented in:

```text
fb_agent/docs/LANGGRAPH_CHECKPOINT_OPERATIONS.md
```

Policy:

- default checkpoint retention: 30 days
- bounded future cleanup batches
- active/pending workflows excluded from cleanup
- cleanup not enabled until thread lifecycle semantics are complete
- TLS outside trusted private networks
- encrypted PostgreSQL storage and backups
- credentials prohibited from checkpoint state
- least-privilege backup access
- consistent-timestamp backup/restore
- pool health and exhaustion observability

Application-layer encryption remains optional future hardening if infrastructure
encryption is insufficient. No new key or secret setting was introduced.

## Product Data Separation

Migration upgrade/downgrade touches only the four checkpoint tables.

It does not touch:

- workflows/runs
- artifacts
- confirmations
- memories
- users
- social accounts
- scheduled or published posts

A disposable `product_sentinel` table survived downgrade, proving rollback isolation.

## Disposable PostgreSQL Tests

PostgreSQL:

```text
postgres:17-alpine
```

Integration result:

```text
1 passed
```

Verified:

- stamp previous application revision
- Alembic upgrade to checkpoint head
- exact four-table presence
- official migration rows `0..9`
- official saver writes without runtime setup
- pooled concurrent writes for separate users/threads
- state retrieval remains isolated
- abrupt child-process exit after checkpoint
- fresh process/runtime restores the conversation
- raw checkpoint inspection contains no credential keys
- Alembic downgrade removes only checkpoint tables
- product sentinel survives rollback

The disposable PostgreSQL container was removed.

## Unit and Regression Tests

Policy unit tests validate:

- retention bounds
- pool bounds
- cleanup batch bounds
- rejection of non-PostgreSQL URLs

Full backend:

```text
166 passed, 1 skipped
```

The skipped test is the disposable PostgreSQL integration test when
`TEST_POSTGRES_URL` is not supplied. It passed explicitly against the disposable
PostgreSQL instance.

Compile and Alembic-head checks passed.

## Docker

Candidate:

```text
socialhub-backend:langgraph-step4
```

Verified:

- clean build
- `/health` HTTP 200
- Alembic head `c3d4e5f6a7b8`
- `pip check` clean
- isolated application container removed

No production deployment, production migration, environment, or data was changed.
`LANGGRAPH_ENABLED` remains false.

## Gate Decision

Step 4 status: `PASS`.

Acceptance criteria met:

- official PostgreSQL checkpoint schema
- controlled upgrade and downgrade
- pooled runtime
- durable process-restart resume
- concurrent user/thread isolation
- state inspection
- product-data separation
- retention, encryption, backup, pool, and cleanup policy
- demonstrated rollback

Next gate: Step 5 — Typed Tool Platform.

