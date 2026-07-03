# Step 11 Evidence — Exactly-Once Scheduling

Date: 2026-07-04  
Status: PASS

## Delivered

- Enabled scheduling mutation only for a valid confirmed LangGraph approval.
- Persisted each immutable checkpoint approval into the existing:
  - `agent_workflows`;
  - `agent_confirmations`.
- Uses `AgentConfirmation.id` as the durable idempotency key.
- Added a transactional executor that:
  1. locks and verifies the owned pending confirmation;
  2. re-hashes the immutable payload;
  3. checks approval identity and expiry;
  4. reloads backend draft artifacts;
  5. revalidates future time, connection ownership, destination, and duplicates;
  6. creates all scheduled rows;
  7. records a success audit;
  8. marks confirmation/workflow complete;
  9. commits once.
- Added rollback-safe failure audits.
- Added local resume serialization plus PostgreSQL row-lock semantics.
- Added crash recovery for the DB-commit-before-checkpoint boundary.
- Kept Step 10's explicit dry-run mode available to its historical safety tests.

No migration was required. Existing table primary keys, foreign keys, confirmation status,
and audit JSON fields support the exactly-once contract.

## Exactly-once guarantees

- An unconfirmed proposal cannot call the executor.
- Approval ID and payload hash must match both checkpoint and persisted confirmation.
- Unexpected resume payload fields are rejected.
- Expiry is rechecked at execution time; equality with the expiry instant is expired.
- Every destination query is filtered by authenticated `user_id`.
- Every approved draft is reloaded from backend checkpoint artifacts.
- Existing content/platform/time duplicates are rejected.
- Single, bulk, and CSV batches are atomic.
- A failure after any staged insert rolls back the entire batch.
- A completed approval returns the original audited logical result.
- Repeated/double resume produces no additional row or success audit.
- If DB commit succeeds before checkpoint resume, the next resume reuses the completed
  approval result and completes the checkpoint without another write.

## Gate results

Focused exactly-once plus Step 10 compatibility suite:

```text
14 passed
```

Coverage includes:

- single scheduling;
- bulk/CSV scheduling;
- zero unconfirmed writes;
- double resume/replay;
- exact expiry boundary;
- connection loss between preview and execution;
- partial-batch precondition failure;
- injected mid-transaction failure;
- complete transaction rollback;
- success and failure audit records;
- DB-commit/checkpoint-resume crash recovery.

Full backend regression:

```text
python -m compileall -q app
python -m pytest -q
213 passed, 1 skipped
```

The skipped test is the existing opt-in disposable PostgreSQL integration test. Existing
deprecation warnings remain non-blocking.

## Rollout state

- Scheduling executes only through the feature-gated thread approval path.
- Legacy scheduling APIs are unchanged.
- No dependency, migration, environment, production data, deployment, or frontend change
  occurred.
- No backend GitHub push occurred.

## Pass decision

PASS. There are zero unconfirmed writes, atomic rollback prevents partial batches, and each
approved proposal produces at most one durable logical scheduling result.
