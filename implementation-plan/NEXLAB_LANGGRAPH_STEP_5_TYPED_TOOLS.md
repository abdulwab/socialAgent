# Step 5 Evidence — Typed Tool Platform

Date: 2026-07-03  
Status: PASS

## Delivered

- Added an isolated LangGraph tool package under `fb_agent/app/agent_graph/tools/`.
- Added strict Pydantic inputs, typed results, stable `.v1` names, and a duplicate-safe registry.
- Added per-tool metadata for allowed agents, read/mutation kind, risk, confirmation,
  ownership, idempotency, timeout, retry, redaction, audit, and mutation enablement.
- Added four executable user-scoped read tools.
- Inventoried fifteen mutation capabilities; all return dry-run proposals and cannot call
  mutation handlers.
- Added recursive input/output/audit redaction.
- Kept DB sessions, ORM objects, provider clients, users, and credentials in runtime context,
  outside graph/checkpoint state.
- Documented excluded infrastructure and the complete capability disposition in
  `fb_agent/docs/LANGGRAPH_TOOL_INVENTORY.md`.

## Gate results

Targeted suite:

```text
tests/test_typed_tool_platform.py
7 passed
```

The suite proves:

- undeclared schema fields are rejected;
- unauthorized agents cannot invoke handlers;
- ownership denial does not reveal cross-user resource existence;
- read timeouts and bounded retries work;
- fake-provider outputs and audits are recursively redacted;
- mutations require idempotency and remain dry-run;
- every registered tool is unique, versioned, and fully described;
- a real DB read returns only the verified user's rows.

Full backend regression:

```text
python -m compileall -q app
python -m pytest -q
173 passed, 1 skipped
```

The skipped test is the existing opt-in disposable PostgreSQL integration test. Existing
deprecation warnings remain unchanged.

## Safety and rollout

- No API route was switched to the new registry.
- No legacy behavior changed.
- No dependency, migration, environment, secret, or production deployment change occurred.
- `LANGGRAPH_ENABLED` behavior is unchanged.
- Mutation execution remains impossible in Step 5.

## Pass decision

PASS. Current service/API capabilities are inventoried, safe reads are wrapped, mutation
capabilities are registered but disabled, ownership is user-scoped, and secrets are removed
from tool results and audit records.
