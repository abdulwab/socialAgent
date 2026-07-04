# Step 13 Evidence - Analytics, Publishing, and Autopilot Subgraphs

Date: 2026-07-04  
Status: PASS

## Delivered

- Added typed LangGraph subgraphs for analytics, publishing/retry, and autopilot.
- Analytics reads authenticated-user database snapshots only and returns deterministic
  empty, partial, or full read-only artifacts.
- Publishing supports Facebook, Instagram, LinkedIn, and X through the existing platform
  adapters.
- Enforced Instagram image requirements and the X 280-character limit before approval.
- Added owned failed-post retry proposals with execution-time stale-state validation.
- Added autopilot enable, disable, platform, cadence, time, and tone proposals.
- Reused the existing immutable approval envelope, canonical payload hash, LangGraph
  interrupt, `agent_confirmations`, and `agent_runs` audit framework.
- Added an atomic `pending -> executing` claim before external mutations.
- Added terminal provider-failure handling; a failed approval cannot call the provider
  again and requires a fresh user approval.
- Added safe API `409` handling for stale or failed approved actions.

No dependency, model, schema, or migration change was required.

## Approval and isolation guarantees

- Analytics rows, account references, failed posts, drafts, and autopilot state are
  selected by authenticated `user_id`.
- Provider credentials remain inside database/service adapters and never enter graph
  state, approval payloads, or audit output.
- Publish and retry require immutable approval identity and payload-hash verification.
- Draft hash and failed-post version are revalidated at execution time.
- Autopilot version is revalidated after approval; competing stale approvals fail.
- Atomic claim prevents replay or concurrent execution of one approval.
- Completed approval replay returns the original logical result without a provider call.
- Provider failure is audited with a redacted error and makes the approval terminal.

## Gate results

Focused Step 13 golden suite:

```text
12 passed
```

Step 13 plus all subgraph/shared-approval/API regression:

```text
57 passed
```

Final API-focused regression:

```text
18 passed
```

Full backend regression:

```text
python -m compileall -q app/agent_graph
python -m pytest -q
230 passed, 1 skipped
```

Coverage includes empty/partial/full analytics, cross-user analytics exclusion, all four
platforms, provider success/failure, Instagram/X rules, immutable approvals, replay
protection, failed-post retry, autopilot toggle/config changes, stale state, competing
approvals, and compilation of all eleven hidden subgraphs.

The skipped test remains the existing opt-in disposable PostgreSQL integration test.
Existing deprecation warnings are non-blocking.

## Rollout state

- Existing legacy APIs remain unchanged.
- LangGraph remains behind its feature flag.
- No dependency edit, migration, production data change, deployment, frontend change, or
  backend GitHub push occurred.

## Pass decision

PASS. All eleven hidden subgraphs pass their golden/regression gates, while scheduling,
publishing, retry, autopilot, and proposal-only destructive actions use the same immutable
approval-envelope and interrupt contract.
