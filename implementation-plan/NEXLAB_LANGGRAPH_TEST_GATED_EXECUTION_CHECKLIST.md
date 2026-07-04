# NexLab LangGraph Test-Gated Execution Checklist

This checklist executes `NEXLAB_LANGGRAPH_FULL_REBUILD_PLAN.md`. Every step is a hard
gate: do not start the next step until implementation, tests, diff review, rollback
readiness, and documentation checks pass.

Current legacy findings are tracked in
`implementation-plan/NEXLAB_LANGGRAPH_LEGACY_AUDIT.md`.

## Execution Rules

For every step:

1. Record root, `fb_agent`, and `fb_dash` git status separately.
2. Preserve unrelated user changes.
3. Implement only the current step.
4. Run targeted tests, then proportional regression tests.
5. Run secret/state leakage checks when touching prompts, tools, memory, or logs.
6. Run `git diff --check` and inspect the diff.
7. Record commands, results, files changed, known gaps, and rollback instructions.
8. Mark the step `PASS`, `FAIL`, or `BLOCKED`.
9. Continue only on `PASS`.

`FAIL` means fix or revert the current step. `BLOCKED` means stop and obtain the
required approval/input. Production is never the first test environment.

## Frontend Decision

Keep the branded Next.js `/agent` product frontend. Use:

- existing custom OAuth, artifact, CSV, schedule, analytics, progress, and confirmation UI
- `assistant-ui` primitives for chat/thread rendering
- typed Server-Sent Events initially
- AG-UI/CopilotKit only later if generative UI provides a demonstrated benefit

LangGraph Studio may be used privately for graph development, not as the customer UI or
source of product state.

## Step 0 — Baseline

Status: `PASS`

Evidence: `implementation-plan/NEXLAB_LANGGRAPH_STEP_0_BASELINE.md`

- Inventory APIs, agent classes, service calls, mutations, DB tables, tests, and docs.
- Add golden scenarios for all eleven agents, Roman Urdu/English, follow-ups, and errors.
- Run backend pytest and frontend lint/build/test.
- Snapshot OpenAPI, latency, token use, and current artifact/confirmation contracts.

Pass: reproducible baseline; every mutation and behavior has an owner.

## Step 1 — Dependencies

Status: `PASS`

Evidence: `implementation-plan/NEXLAB_LANGGRAPH_STEP_1_DEPENDENCIES.md`

- Add pinned LangGraph/checkpointer dependencies.
- Prove compatibility with FastAPI, Pydantic, SQLAlchemy, Python, Z.AI, and Docker.

Tests: clean install, imports, minimal invoke/stream, full backend pytest, Docker build
and `/health`.

Pass: reproducible install and zero legacy regression.

## Step 2 — Graph Foundation

Status: `PASS`

Evidence: `implementation-plan/NEXLAB_LANGGRAPH_STEP_2_FOUNDATION.md`

- Add typed state, reducers, runtime context, graph factory, budgets, and errors.
- Adapt the existing Z.AI gateway; add no provider.
- Keep the graph behind a disabled feature flag.
- Never serialize DB sessions, ORM objects, credentials, or service clients.

Tests: serialization, reducers, graph compile, recursion/token limits, secret scanner,
full backend pytest.

Pass: deterministic, JSON-safe, secret-free graph; existing API unchanged.

## Step 3 — Thread API and Development Checkpointer

Status: `PASS`

Evidence: `implementation-plan/NEXLAB_LANGGRAPH_STEP_3_THREAD_API.md`

- Add authenticated thread create/list/get/command/resume endpoints behind the flag.
- Define typed SSE events.
- Start with development checkpointing.

Tests: auth, cross-user denial, lifecycle, SSE order/reconnect/deduplication, restart
resume, legacy API regression.

Pass: ownership cannot be bypassed and a test conversation survives restart.

## Step 4 — PostgreSQL Checkpointing

Status: `PASS`

Evidence: `implementation-plan/NEXLAB_LANGGRAPH_STEP_4_POSTGRES_CHECKPOINTS.md`

- Add official PostgreSQL checkpoint persistence.
- Define retention, encryption, backup, pool, and cleanup policy.
- Keep operational checkpoints separate from product artifacts/audit.

Tests: disposable-Postgres upgrade/downgrade, process-kill resume, concurrent isolation,
state inspection, rollback rehearsal.

Pass: durable resume, isolation, and demonstrated rollback.

## Step 5 — Typed Tool Platform

Status: `PASS`

- Wrap existing services with strict schemas and stable names.
- Add allowed-agent, read/mutation, risk, confirmation, ownership, idempotency, timeout,
  retry, redaction, and audit metadata.
- Wrap reads first; mutations remain dry-run.

Tests: schema rejection, permission matrix, ownership, timeout/retry, audit redaction,
fake-provider integration, mutation-disabled proof.

Pass: every capability is inventoried and no secret enters graph/tool output.

Evidence:

- `implementation-plan/NEXLAB_LANGGRAPH_STEP_5_TYPED_TOOLS.md`
- `fb_agent/docs/LANGGRAPH_TOOL_INVENTORY.md`
- Targeted tests: `7 passed`
- Full backend tests: `173 passed, 1 skipped`

## Step 6 — Main Routing and Planning

Status: `PASS`

- Implement context load, structured understanding, deterministic validation,
  clarification, planning, and routing nodes.
- Make Assistant Chat and Product Help supporting Main Graph nodes.

Tests: golden routing, Roman Urdu, typos, ambiguity, follow-ups, prompt injection,
platform/page/date extraction, latency/token comparison.

Pass: agreed routing accuracy and no unsafe proposal from missing/invalid input.

Evidence:

- `implementation-plan/NEXLAB_LANGGRAPH_STEP_6_MAIN_ROUTING.md`
- Golden routing: `23/23` exact matches
- Focused tests: `8 passed`
- Full backend tests: `181 passed, 1 skipped`

## Step 7 — Memory and Context

Status: `PASS`

- Make backend `thread_id` authoritative.
- Add checkpoint short-term memory.
- Add scoped long-term retrieval, proposals, redaction, writes, provenance, expiry,
  deduplication, edit, and forget.
- Resolve follow-ups through backend artifact IDs.

Tests: refresh/restart, cross-thread same-user preferences, cross-user isolation,
irrelevant-memory exclusion, CRUD/expiry, nested-secret rejection, “schedule this”
without frontend artifact payload.

Pass: memory is genuinely read/write and frontend history is not required for correctness.

Evidence:

- `implementation-plan/NEXLAB_LANGGRAPH_STEP_7_MEMORY_CONTEXT.md`
- Focused tests: `20 passed`
- Full backend tests: `187 passed, 1 skipped`

## Step 8 — Connection Agent Subgraph

Status: `PASS`

- Implement status, pages, OAuth guidance, selection, token health, disconnect proposal.

Tests: disconnected/connected/expired, multiple pages, ownership, approval enforcement,
secret absence.

Pass: parity with legacy behavior; disconnect remains proposal-only.

Evidence:

- `implementation-plan/NEXLAB_LANGGRAPH_STEP_8_CONNECTION_SUBGRAPH.md`
- Focused tests: `36 passed`
- Full backend tests: `193 passed, 1 skipped`

## Step 9 — Strategy and Copywriting Subgraphs

Status: `PASS`

- Implement strategy and platform draft artifacts with scoped brand/analytics memory.

Tests: all platforms, languages, tone/preferences, malformed output, platform limits,
stable artifact IDs.

Pass: golden scenarios and safe read-only artifacts pass.

Evidence:

- `implementation-plan/NEXLAB_LANGGRAPH_STEP_9_STRATEGY_COPYWRITING.md`
- Focused tests: `26 passed`
- Full backend tests: `199 passed, 1 skipped`

## Step 10 — Scheduling and Safety Subgraphs

Status: `PASS`

- Implement timezone handling, previews, connection/duplicate checks, deterministic
  policy, Safety review, immutable proposals, and LangGraph interrupt.
- Keep mutation disabled.

Tests: DST/timezones, missing fields, past dates, duplicates, bulk/CSV, resume/cancel/
expire, payload tampering, replay, double-click, process restart.

Pass: preview-to-interrupt-to-resume works durably with zero mutation.

Evidence:

- `implementation-plan/NEXLAB_LANGGRAPH_STEP_10_SCHEDULING_SAFETY.md`
- Focused tests: `28 passed`
- Full backend tests: `207 passed, 1 skipped`

## Step 11 — Exactly-Once Scheduling

Status: `PASS`

- Enable scheduling only after approval with transactional idempotency and revalidation.

Tests: single/bulk/CSV, double resume, timeout boundaries, partial failure, transaction
rollback, audit.

Pass: zero unconfirmed writes and at most one logical result per approved proposal.

Evidence:

- `implementation-plan/NEXLAB_LANGGRAPH_STEP_11_EXACTLY_ONCE_SCHEDULING.md`
- Focused tests: `14 passed`
- Full backend tests: `213 passed, 1 skipped`

## Step 12 — Image, Media, and Web Search Subgraphs

Status: `PASS`

- Implement image generation/storage, media references/validation/attachment/deletion
  proposal, and cited approved search/fetch.
- Treat external content as untrusted.

Tests: success/failure, ownership, formats, deletion interrupt, search degradation,
citations, prompt injection, large-reference handling.

Pass: durable referenced artifacts and no external-content policy escalation.

Evidence:

- `implementation-plan/NEXLAB_LANGGRAPH_STEP_12_IMAGE_MEDIA_SEARCH.md`
- Focused tests: `5 passed`
- Step 12 plus adjacent graph regression: `39 passed`
- Full backend tests: `218 passed, 1 skipped`

## Step 13 — Analytics, Publishing, and Autopilot Subgraphs

Status: `PASS`

- Implement analytics reads and publish/retry/autopilot approved mutations.

Tests: empty/partial/full analytics, every platform, provider failures, Instagram/X
rules, replay protection, autopilot changes, stale state and concurrent approvals.

Pass: all eleven subgraphs pass golden tests and share one approval framework.

Evidence:

- `implementation-plan/NEXLAB_LANGGRAPH_STEP_13_OPERATIONAL_SUBGRAPHS.md`
- Focused Step 13 tests: `12 passed`
- All-subgraph/shared-approval/API regression: `57 passed`
- Full backend tests: `230 passed, 1 skipped`

## Step 14 — Frontend Integration

Status: `PASS`

- Hydrate backend threads, stream typed SSE, reconnect, and resume approvals.
- Preserve custom SocialHub components.
- Stop sending authoritative conversation/artifact context from React after parity.
- Add the selected `assistant-ui` dependency after explicit dependency approval.

Tests: components/contracts, hydrate/refresh/multi-device, reconnect/deduplication,
confirm/cancel/expiry, responsive/accessibility, leakage checks, full lint/build/test.

Pass: backend-owned context works and usability is preserved or improved.

Evidence:

- `implementation-plan/NEXLAB_LANGGRAPH_STEP_14_FRONTEND_INTEGRATION.md`
- Frontend tests: `3 suites / 10 tests passed`
- Frontend lint/build: `passed`
- Backend thread tests: `7 passed`
- Full backend tests: `231 passed, 1 skipped`

## Step 15 — Shadow and Canary

Status: `PENDING`

- Shadow only safe/read operations; never duplicate mutations.
- Compare routing, artifacts, confirmations, latency, tokens, errors, and costs.
- Canary internal users, then a small cohort.

Tests: comparison reports, load/concurrency, restart/fault injection, rollback rehearsal,
monitoring/alerts.

Pass: agreed quality/security/reliability thresholds and observation window pass.

## Step 16 — Production Cutover

Status: `BLOCKED: explicit deployment approval needed`

- Deploy by approved backend Docker/SCP workflow only.
- Enable LangGraph while retaining the legacy rollback switch.

Tests: health/OpenAPI, authenticated thread, checkpoint/resume, memory retrieval,
controlled confirmation flows, logs/resources.

Pass: production acceptance and observation window pass.

## Step 17 — Legacy Removal

Status: `BLOCKED: explicit final deletion approval needed`

- Generate a reviewed deletion manifest from imports, routes, flags, tests, and docs.
- Delete only code with a passing LangGraph replacement.
- Remove adapters after the rollback window.
- Consolidate active docs while preserving migration/deployment/audit history.

Likely removals:

- custom `AgentOrchestrator`
- old `BaseAgent`, registry, planner, memory builder, and manual state runtime
- old class-based agents after subgraph parity
- compatibility command/confirm adapters
- tests tied only to deleted implementation details

Must remain:

- OAuth/platform business services used as tools
- Z.AI gateway/model config
- Clerk, scheduler, SQLAlchemy product models, and historical migrations
- required artifact/audit data and readers
- product-specific `/agent` UI
- operational deployment history

Tests: no live references via `rg`, backend compile/full pytest, frontend lint/build/test,
Docker candidate health, eleven golden workflows, docs link check, `git diff --check`.

Pass: LangGraph-only runtime with no dead/contradictory active code or docs.

## Evidence Log Template

```text
Step:
Status: PASS | FAIL | BLOCKED
Date:
Files changed:
Commands run:
Results:
Security/leakage checks:
Docs re-checked:
Known gaps:
Rollback verified:
Next allowed step:
```
