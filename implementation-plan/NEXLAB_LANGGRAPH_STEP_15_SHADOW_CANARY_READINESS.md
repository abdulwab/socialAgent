# Step 15 Evidence - Shadow and Canary Readiness

Date: 2026-07-04  
Status: READY FOR OBSERVATION

## Delivered

- Added a hard safe/read-only shadow policy.
- Mutation commands are never sent to the shadow runner:
  - publish;
  - schedule;
  - delete;
  - disconnect;
  - retry;
  - autopilot changes;
  - bulk/CSV actions.
- Added legacy-vs-LangGraph routing shadow comparison after authoritative legacy responses.
- Shadow failure cannot change or delay the already-produced authoritative result.
- Added append-only JSONL reports with:
  - routing;
  - artifact fingerprints;
  - confirmation behavior;
  - latency;
  - tokens;
  - configured cost estimate;
  - errors.
- Reports contain hashed user/command identifiers, not raw user IDs or commands.
- Added concurrent write locking, flush/fsync, restart loading, and incomplete-tail recovery.
- Added threshold summaries and alert logging.
- Added deterministic internal-user and percentage-cohort selection.
- Added an instant master rollback flag.
- Added frontend legacy fallback for excluded/rollback users without sending React-owned
  conversation or artifact context.

No dependency, migration, model, or production-data change was required.

## Proposed rollout thresholds

These are encoded defaults and require rollout-owner acceptance before production canary:

- routing match: at least 90%;
- artifact match: at least 85%;
- shadow error rate: at most 2%;
- confirmation mismatch: exactly 0%;
- p95 shadow/authoritative latency ratio: at most 1.25;
- minimum sample count: 20;
- minimum observation window: 24 hours.

Cost is calculated from `LANGGRAPH_COST_USD_PER_1K_TOKENS`. It defaults to `0` until the
approved Z.AI commercial rate is configured.

## Configuration controls

```text
LANGGRAPH_ENABLED
LANGGRAPH_ROLLOUT_MODE=off|shadow|internal|cohort|full
LANGGRAPH_INTERNAL_USER_IDS=7,12
LANGGRAPH_CANARY_PERCENT=5
LANGGRAPH_ROLLBACK=false
LANGGRAPH_SHADOW_REPORT_PATH=.langgraph/shadow-reports.jsonl
LANGGRAPH_SHADOW_MIN_SAMPLES=20
LANGGRAPH_SHADOW_OBSERVATION_HOURS=24
LANGGRAPH_COST_USD_PER_1K_TOKENS=0
```

Recommended sequence:

1. Docker deploy with `LANGGRAPH_ROLLOUT_MODE=shadow`.
2. Observe safe/read-only reports for at least 24 hours.
3. Resolve every confirmation mismatch and threshold alert.
4. Set `internal` with explicit internal user IDs.
5. Rehearse `LANGGRAPH_ROLLBACK=true`.
6. Set `cohort` at 5% only after internal checks pass.
7. Expand gradually; never bypass the observation gate.

Operational report command:

```text
python -m app.agent_graph.rollout_report
```

Exit code `0` means the observation gate passed, `1` means it is not ready, and `2` means
one or more alert thresholds were breached.

## Gate results

Focused rollout, load, restart, fault, and API suite:

```text
36 passed
```

Full backend regression:

```text
244 passed, 1 skipped
```

Frontend rollback fallback:

```text
3 suites / 11 tests passed
npm run lint: passed
npm run build: passed
```

Coverage includes mutation suppression, comparison reports, 100 concurrent report writes,
restart with an incomplete report tail, shadow timeout isolation, threshold alerts,
deterministic cohorts, internal users, instant rollback, excluded-user legacy fallback,
and non-authoritative frontend fallback payloads.

## Why this is not PASS yet

The Step 15 pass condition explicitly requires an agreed observation window to pass.
No production deployment or live observation was authorized in this step. Therefore:

- no Docker deployment occurred;
- no server `.env` was changed;
- no internal production users were selected;
- no 24-hour production report exists;
- proposed thresholds have not yet been explicitly accepted by the rollout owner.

## Current decision

READY FOR OBSERVATION, not PASS. The implementation and automated reliability gates are
complete. PASS requires authorized Docker deployment, threshold acceptance, internal
canary selection, rollback rehearsal in the deployed environment, and a clean 24-hour
observation report.
