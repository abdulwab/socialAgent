# Step 17 — Reviewed Legacy Deletion Manifest

Date: 2026-07-04  
Status: **BLOCKED — no deletions authorized**

This manifest is the review boundary for the final LangGraph cleanup. It does not
authorize deletion. Step 17 may execute only after Step 15 thresholds and observation
window pass, Step 16 production acceptance and rollback rehearsal pass, the rollback
window closes, and the user gives explicit final deletion approval.

## Current live blockers

| Dependency | Why it is still live | Required action before deletion |
|---|---|---|
| `fb_agent/app/api/v1/agent_routes.py` | Hosts legacy `/command` and `/confirm`, but also the still-used `/csv-preview` and `/csv-schedule` routes | Move CSV behavior to LangGraph thread/tool APIs and update frontend callers before removing the router |
| `fb_agent/app/agents/main_agent.py` | Imported by `app/agent_graph/rollout.py` for shadow comparison | Complete the Step 15 observation window, archive the final comparison report, and remove the legacy comparator |
| Frontend `legacyMode` | Provides the rollback path when thread APIs are unavailable | Remove only after production acceptance and the rollback window |
| `ApiManager.runAgentCommand` and `confirmAgentAction` | Used by the frontend rollback path and its regression tests | Remove with `legacyMode`, never before it |
| Legacy route registration in `fb_agent/app/main.py` | Keeps compatibility and CSV routes reachable | Split/migrate CSV routes, then unregister the compatibility router |
| Agent workflow persistence models | Shared by LangGraph action execution, audit, artifacts, and confirmations | Preserve models, rows, readers, and historical migrations; do not create a drop migration |

## Candidate deletion set

The following files are candidates only after every blocker above is closed and a
fresh import/route audit proves no live references:

- `fb_agent/app/agents/` in full:
  `analytics_agent.py`, `assistant_chat_agent.py`, `autopilot_agent.py`, `base.py`,
  `connection_agent.py`, `content_strategy_agent.py`, `copywriting_agent.py`,
  `image_generation_agent.py`, `language.py`, `main_agent.py`, `media_agent.py`,
  `memory.py`, `orchestrator.py`, `planner.py`, `product_help_agent.py`,
  `publishing_agent.py`, `registry.py`, `safety_review_agent.py`,
  `scheduling_agent.py`, `schemas.py`, `state_store.py`, `time_utils.py`,
  `web_search_agent.py`, and the package initializer.
- The `/command` and `/confirm` compatibility implementation in
  `fb_agent/app/api/v1/agent_routes.py`; delete the whole module only after CSV
  migration.
- `fb_agent/app/agent_tools/` only after its remaining platform-tool tests are
  migrated to the typed `app/agent_graph/tools/` registry and an import audit confirms
  it has no product consumer.
- Frontend `legacyMode` branches in
  `fb_dash/app/agent/components/AgentShell.tsx`.
- Frontend `runAgentCommand` and `confirmAgentAction` methods in
  `fb_dash/lib/apiManager.ts`.

## Candidate test removal or rewrite

These tests import implementation details from `app.agents` and may be removed only
when equivalent LangGraph behavioral coverage is identified in the deletion review:

- `test_agent_golden_baseline.py`
- `test_agent_image_generation.py`
- `test_agent_language_behavior.py`
- `test_agent_orchestrator_intents.py`
- `test_agent_planner_workflow.py`
- `test_agent_state_store.py`
- `test_connection_agent_intents.py`
- `test_copywriting_agent.py`
- `test_main_agent_routing.py`
- `test_web_search_agent.py`

Rewrite, rather than blindly delete:

- `test_agent_llm_gateway.py`: keep Z.AI gateway coverage and remove its dependency on
  the old agent registry.
- `test_platform_tools.py`: retain business-service/tool contract coverage against the
  typed LangGraph registry.
- Frontend fallback assertions in `agent_thread_integration.test.tsx` and
  `auth_session_regression.test.ts`: remove only with the fallback itself.

## Must remain

- `fb_agent/app/agent_graph/`, including typed state, nodes, subgraphs, tools,
  checkpointing, memory, approval, execution, audit, and rollout controls still
  required in production.
- OAuth and platform business services, `app/platforms/`, social action services,
  publishing, scheduling, analytics, autopilot, media, and Cloudinary integrations
  used by typed tools.
- `app/services/agent_llm_gateway.py` and `app/config/glm_models.json`; Z.AI remains
  the only LLM gateway.
- Clerk authentication, scheduler, FastAPI infrastructure, SQLAlchemy product models,
  Alembic history, and PostgreSQL checkpoint persistence.
- Agent workflow, run, artifact, confirmation, memory, audit, idempotency, and
  checkpoint data plus required readers. Step 17 is code cleanup, not data erasure.
- The product-specific frontend `/agent` experience and SocialHub components.
- Deployment guides, migration history, Step evidence, audit reports, rollback
  records, and production observation evidence.

## Documentation policy

Active architecture and coding-agent memory must describe LangGraph as authoritative.
Older agent-first plans, deployment records, migrations, and Step evidence remain as
historical records and should be clearly labeled rather than erased. Contradictory
active instructions may be corrected only in the final approved cleanup.

## Final deletion gate

Run this sequence after explicit approval:

1. Record passing Step 15 thresholds/observation and Step 16 production acceptance.
2. Confirm the rollback window is closed.
3. Migrate CSV routes and frontend clients to LangGraph-owned APIs.
4. Remove the shadow import and legacy comparison path.
5. Remove frontend fallback, compatibility routes, old runtime, and implementation-only tests.
6. Verify no live references with `rg` across app code, routes, tests, flags, and active docs.
7. Run backend compile and full pytest.
8. Run frontend lint, build, and test.
9. Build the backend Docker candidate and verify `/health` and OpenAPI.
10. Run all eleven LangGraph golden workflows, docs-link validation, secret scan, and
    `git diff --check`.
11. Review the complete diff before committing separately in the backend, frontend,
    and root repositories. Never push the backend repository.

## Review result

The candidate set is **not currently safe to delete**. The compatibility runtime is
still an operational rollback dependency, the shadow comparator imports the old Main
Agent, and CSV endpoints share the legacy router. The correct Step 17 status therefore
remains blocked with zero deletions performed.
