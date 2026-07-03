# Step 8 Evidence — Connection Agent Subgraph

Date: 2026-07-03  
Status: PASS

## Delivered

- Added a dedicated LangGraph Connection subgraph with nodes for:
  1. owned connection snapshot loading;
  2. deterministic connection-action understanding;
  3. safe response or disconnect proposal creation.
- Added read behavior for:
  - connected/disconnected status;
  - Facebook Page listing;
  - OAuth connect/reconnect guidance;
  - workflow-scoped Facebook Page selection;
  - LinkedIn and X token health.
- Added Facebook, Instagram, LinkedIn, and X connection metadata parity with legacy
  connection behavior.
- Added current-workflow Page selection without changing a persistent default.
- Integrated the Connection subgraph into the feature-gated Main Graph and checkpointed
  thread runtime.
- Reused the Step 5 typed `connections.disconnect.v1` tool contract.
- Disconnect returns a dry-run proposal with confirmation metadata and never invokes the
  legacy mutation route or deletes account rows.
- Changed current-command tool proposals to replacement semantics so an old disconnect
  proposal cannot leak into the next command.

## Security behavior

- Every account/Page query is filtered by authenticated runtime `user_id`.
- Fuzzy Page matching uses a stricter ownership-safe threshold; a similarly named foreign
  Page cannot be selected.
- Snapshot output contains account IDs, names, health, counts, and internal connect
  endpoints only.
- OAuth access tokens, refresh tokens, user access tokens, cookies, passwords, and raw
  provider payloads never enter graph state or user output.
- OAuth guidance explicitly tells the user not to share social passwords.
- Disconnect requires confirmation and remains proposal-only.

## Gate results

Focused Connection/Main Graph/thread/foundation suite:

```text
36 passed
```

It proves:

- fully disconnected status;
- connected Facebook, LinkedIn, and X behavior;
- expired and active token-health states;
- multiple Facebook Pages;
- owned Page selection and cross-user denial;
- OAuth guidance;
- disconnect approval enforcement and mutation-disabled behavior;
- stale proposal clearing;
- absence of provider secrets;
- Main Graph and checkpointed thread integration.

Full backend regression:

```text
python -m compileall -q app
python -m pytest -q
193 passed, 1 skipped
```

The skipped test is the existing opt-in disposable PostgreSQL integration test. Existing
deprecation warnings remain non-blocking.

## Rollout state

- `LANGGRAPH_ENABLED` remains the rollout gate.
- Legacy `/api/v1/agent/command` and OAuth callback routes are unchanged.
- No dependency, migration, environment, production data, deployment, or frontend change
  occurred.
- Disconnect execution remains disabled.

## Pass decision

PASS. The Connection subgraph matches the legacy read behavior, enforces user ownership,
keeps provider secrets absent, and produces only confirmation-bound dry-run disconnect
proposals.
