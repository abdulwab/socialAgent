# Step 6 Evidence — Main Routing and Planning

Date: 2026-07-03  
Status: PASS

## Delivered

- Added typed routing contracts for intents, extracted entities, validation, plans, and
  evaluation metrics.
- Added Main Graph nodes for:
  1. safe context loading;
  2. structured command understanding;
  3. deterministic validation;
  4. clarification;
  5. workflow planning;
  6. domain routing.
- Added Assistant Chat and Product Help as supporting Main Graph nodes rather than hidden
  domain agents.
- Added deterministic extraction for Facebook/Instagram/LinkedIn/X, owned Page names,
  post counts, follow-up artifact references, and relative/ISO scheduling dates.
- Added Roman Urdu handling and bounded typo aliases for routing-critical words.
- Added prompt-injection detection. Injection wording cannot disable validation,
  confirmation, ownership checks, or produce an unsafe proposal.
- Wired the Main Graph into the feature-gated development thread runtime. Empty thread
  creation remains context-only; commands run the routing pipeline.
- Kept the legacy `/api/v1/agent/command` path unchanged.

## Deterministic safety behavior

- Missing draft, platform, topic, date/time, or connected Page produces one concise
  clarification.
- Invalid/past scheduling dates produce no plan.
- Risky intents retain `requires_confirmation=true`.
- `safe_to_propose` is true only when a risky request passes deterministic validation.
- Clarification paths return an empty plan and empty tool proposals.
- Page matching uses only Page rows scoped to the authenticated runtime user.

## Gate results

Focused Step 6 suite:

```text
tests/test_main_routing_graph.py
8 passed
```

Routing/foundation/thread integration:

```text
30 passed
```

Golden evaluation:

```text
23/23 exact intent-order matches (100%)
LLM calls: 0
Estimated routing tokens: 0
Measured local maximum: 4.118 ms; average: 0.362 ms
```

The legacy Main Agent classifier requires at least one provider call and a large routing
prompt. The new deterministic path therefore removes that call and prompt-token cost for
the evaluated routing set. This is a local unit benchmark, not a production network latency
claim.

Full backend regression:

```text
python -m compileall -q app
python -m pytest -q
181 passed, 1 skipped
```

The skipped test is the existing opt-in disposable PostgreSQL integration test. Existing
deprecation warnings remain unchanged.

## Rollout state

- `LANGGRAPH_ENABLED` remains the rollout gate.
- No mutation tool is executed.
- No dependency, schema, migration, environment, secret, or production deployment change
  occurred.
- Legacy API behavior remains available and unchanged.

## Pass decision

PASS. Routing accuracy meets the agreed gate, supporting chat/help are Main Graph nodes,
and missing, invalid, ambiguous, cross-user, or injection-shaped input cannot create an
unsafe plan or proposal.
