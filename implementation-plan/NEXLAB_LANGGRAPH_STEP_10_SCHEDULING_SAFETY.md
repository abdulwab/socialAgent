# Step 10 Evidence — Scheduling and Safety Subgraphs

Date: 2026-07-04  
Status: PASS

## Delivered

- Added a typed Scheduling subgraph for timezone normalization, read-only previews,
  connection checks, duplicate checks, and bulk/CSV row validation.
- Added IANA timezone support with UTC-normalized schedule output.
- Added deterministic DST handling:
  - nonexistent local times are rejected;
  - ambiguous local times require an explicit fold/offset;
  - both DST folds normalize to distinct UTC instants.
- Added a separate deterministic Safety subgraph.
- Added immutable approval envelopes containing:
  - approval, thread, and user IDs;
  - stable preview ID;
  - versioned typed-tool name;
  - canonical payload hash;
  - creation and expiry times;
  - confirmation and mutation-disabled policy.
- Added a real LangGraph `interrupt()` before approval.
- Added durable resume using `Command(resume=...)`.
- Added confirm, cancel, expiry, payload-tamper, replay, and double-click behavior.
- Added a waiting-thread guard so a new command cannot bypass a pending approval.
- Added process-restart resume through the durable checkpoint.
- Kept all scheduling mutation execution disabled.

## Deterministic policy

- Missing draft, platform, or date/time is clarified before preview creation.
- Past, invalid, nonexistent DST, unconnected, duplicate, or malformed rows cannot reach
  approval.
- Any invalid bulk/CSV row rejects the batch from approval.
- Client resume data may contain only action, approval ID, and payload hash.
- Approval ID/hash mismatch or extra payload fields produce `tampered`.
- Expired approvals produce `expired`.
- Replayed/double-clicked resumes return the terminal checkpoint without a second effect.
- Confirmed approvals stop at `confirmed_dry_run`.
- `scheduled_posts` remains unchanged in every tested path.

## Gate results

Focused scheduling/safety and integration tests:

```text
28 passed
```

Dedicated durable interrupt tests plus the prior artifact-follow-up test:

```text
9 passed
```

Coverage includes:

- Asia/Karachi and America/New_York;
- DST gaps, ambiguous folds, and explicit fold selection;
- missing fields and past dates;
- disconnected platforms;
- existing and in-batch duplicates;
- bulk/CSV mixed-validity previews;
- preview → interrupt → confirm/cancel/expire;
- immutable proposal verification;
- payload tampering;
- replay and double-click;
- command-while-waiting bypass prevention;
- process restart;
- zero mutation.

Full backend regression:

```text
python -m compileall -q app
python -m pytest -q
207 passed, 1 skipped
```

The skipped test is the existing opt-in disposable PostgreSQL integration test. Existing
deprecation warnings remain non-blocking.

## Rollout state

- `LANGGRAPH_ENABLED` remains the runtime gate.
- The legacy scheduling API remains unchanged.
- No dependency, migration, environment, production data, deployment, or frontend change
  occurred.
- Approval is operational checkpoint state; no production schedule is created.

## Pass decision

PASS. Preview-to-interrupt-to-resume works across process restart, deterministic policy
blocks unsafe/tampered requests, and all confirmation outcomes produce zero mutation.
