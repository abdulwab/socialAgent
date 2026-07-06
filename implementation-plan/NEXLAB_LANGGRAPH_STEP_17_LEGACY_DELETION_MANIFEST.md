# Step 17 — Reviewed Legacy Deletion Manifest

Date: 2026-07-07
Status: **DEPLOYED — observation started**

This manifest is the review boundary and execution record for the final LangGraph
cleanup. The user explicitly approved removal of the old custom agent runtime after the
global LangGraph cutover.

## Resolution of former blockers

| Dependency | Former reason it was live | Resolution |
|---|---|---|
| Compatibility agent router | Hosted command/confirm plus CSV routes | CSV behavior moved to a dedicated support router; command/confirm removed |
| Shadow comparator | Imported the old Main Agent | Removed after user-directed global cutover |
| Frontend fallback mode | Provided pre-thread fallback when thread APIs were unavailable | Removed; `/agent` now requires backend-owned LangGraph threads |
| Compatibility API methods | Used only by the fallback path and tests | Removed from `ApiManager` and rewritten tests |
| Legacy route registration | Kept compatibility and CSV routes reachable | Registration now points to CSV support plus thread/memory routers |
| Agent workflow persistence models | Shared by LangGraph execution, audit, artifacts, confirmations, and memory | Preserved; no data-erasure migration |

## Deleted set

Deleted after import/route audit and replacement tests:

- Full custom class-based backend agent runtime package.
- Old backend agent tool registry package.
- Shadow rollout comparator/report helpers.
- Compatibility agent route module; CSV endpoints now live in the dedicated CSV support
  router.
- Frontend fallback branches and compatibility API client methods.
- Implementation-detail tests that imported the removed runtime.

## Rewritten or preserved tests

Rewritten:

- Z.AI gateway tests keep single-provider/model-policy coverage without depending on
  the old class registry.
- Agent graph foundation test now asserts LangGraph thread routes are authoritative and
  compatibility command/confirm routes are absent.
- Frontend thread integration/session tests no longer call compatibility methods.

Preserved replacement coverage:

- LangGraph foundation, thread API, memory/context, typed tools, main routing, domain
  subgraphs, scheduling/safety, exactly-once execution, media/search, analytics,
  publishing, autopilot, and frontend assistant-ui tests.

## Must remain

- `fb_agent/app/agent_graph/`, including typed state, nodes, subgraphs, tools,
  checkpointing, memory, approval, execution, and audit controls.
- OAuth/platform business services, publishing, scheduling, analytics, autopilot,
  media, Cloudinary, scheduler, and SQLAlchemy product models used by typed tools.
- `fb_agent/app/services/agent_llm_gateway.py` and
  `fb_agent/app/config/glm_models.json`; Z.AI remains the only LLM gateway.
- Clerk authentication, Alembic history, PostgreSQL checkpoint persistence, and all
  required artifact/audit data readers.
- Product-specific frontend `/agent` experience and SocialHub components.
- Deployment guides, migration history, step evidence, audit reports, and operational
  deployment records.

## Local gate results

- Active-code reference scan: passed for removed imports/routes/flags/methods.
- Backend compile: passed.
- Full backend pytest: `172 passed, 1 skipped`.
- Frontend lint: passed.
- Frontend tests: `3 suites, 13 tests`.
- Frontend build: passed.
- Backend Docker build: `socialhub-backend:langgraph-only-local` passed.
- Local Docker health: passed.
- Local Docker OpenAPI: LangGraph thread routes present; compatibility command/confirm
  routes absent; CSV support routes present.

## Production deployment evidence

- Backend commit deployed: `e45bcd1`.
- Production image: `socialhub-backend:langgraph-only-e45bcd1`.
- Rollback image retained: `socialhub-backend:rollback-pre-legacy-e45bcd1`.
- Deployment method: approved SCP archive plus server-side `sudo rsync`, Docker build,
  and `socialhub-api` container restart with `/home/ubuntu/fb_agent/.env`.
- `/health`: passed.
- OpenAPI: LangGraph thread routes present; compatibility command/confirm routes absent;
  CSV support routes present.
- Server file audit: removed custom agent runtime, old tool registry, compatibility route
  module, and shadow rollout helper are absent from `/home/ubuntu/fb_agent/`.
- Startup logs: route registration, scheduler startup, and Uvicorn startup completed
  without errors.

## Deployment rule

Backend must not be pushed to GitHub. Deploy the backend through the approved SCP and
server-side Docker workflow only. Frontend changes may be pushed through the
frontend GitHub/Vercel flow after lint/build/test pass.
