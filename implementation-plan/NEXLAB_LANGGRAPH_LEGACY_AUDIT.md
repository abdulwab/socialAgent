# NexLab LangGraph Legacy Audit

Audit date: 2026-07-03

Scope:

- `fb_agent` runtime, routes, tools, state, memory, services, tests, and dependencies
- `fb_dash` agent UI, API manager, Redux state, routes, and client-owned context
- comparison against `NEXLAB_LANGGRAPH_FULL_REBUILD_PLAN.md` and its test-gated checklist

This is a static code audit. It does not authorize early deletion of functional legacy
code. Items are removed only after their LangGraph replacement passes its gate.

## Executive Result

The running product is still the custom agent implementation. LangGraph, checkpointing,
thread APIs, interrupts, and streaming are not implemented yet.

High-priority contradictions:

1. Frontend still contains removed user-level prompt/provider settings code.
2. Frontend remains the source of truth for recent conversation and artifacts.
3. Backend orchestration manually loops over agent classes and manually persists state.
4. Confirmed scheduling, publishing, and autopilot mutations occur directly in the
   orchestrator or route instead of typed tools.
5. Long-term agent memory is read-only in application code.
6. `conversation_id` exists but new workflows persist it as `None`.
7. Tool registry exposes only `social.publish_post`; most services bypass it.

## Backend Findings

### B1 — Custom runtime is fully active

Files:

- `app/agents/orchestrator.py`
- `app/agents/base.py`
- `app/agents/registry.py`
- `app/agents/planner.py`
- `app/agents/schemas.py`
- `app/agents/state_store.py`
- all class-based files under `app/agents/`
- `app/api/v1/agent_routes.py`

Current behavior:

- `/agent/command` calls the singleton custom orchestrator.
- Main Agent returns a list of intents.
- The orchestrator loops through registered agent classes.
- Outputs are manually copied into a shared context dictionary.
- Workflow, run, artifact, and confirmation records are manually managed.

Disposition: retain as baseline through Steps 0–16; delete in Step 17 after graph parity.

### B2 — No LangGraph implementation exists

No current references were found for:

- `langgraph`
- checkpointers
- LangGraph `thread_id`
- `interrupt()`
- graph nodes/subgraphs

Disposition: implement through checklist Steps 1–4 before migrating agents.

### B3 — Mutations bypass a unified tool layer

Direct mutation locations include:

- `app/agents/orchestrator.py`
  - scheduled-post DB writes
  - direct `social_action_service.publish_post`
  - publishing-record writes
  - autopilot configuration writes
- `app/api/v1/agent_routes.py`
  - CSV scheduling writes and commits
- `app/agents/state_store.py`
  - custom workflow/confirmation/artifact commits

`app/agent_tools/registry.py` currently registers only `social.publish_post`.

Risk:

- confirmation, ownership, idempotency, retries, audit, and redaction are not enforced
  through one policy boundary.

Disposition: wrap services in typed tools during Step 5; enable mutations only at their
specific gated steps.

### B4 — Memory is incomplete

Files:

- `app/agents/memory.py`
- `app/agents/state_store.py`
- `app/db/models.py`

Current behavior:

- safe `AgentMemory` rows can be read
- application runtime has no memory create/update/consolidate path
- no proposal, provenance, confidence, expiry, edit, forget, or deduplication pipeline
- workflows set `conversation_id=None`

Disposition: replace with user-namespaced checkpoint/store design in Step 7. Preserve
historical memory records until an approved migration strategy exists.

### B5 — Tests are coupled to legacy implementation details

Examples:

- `test_agent_planner_workflow.py`
- `test_main_agent_routing.py`
- `test_agent_state_store.py`
- per-class agent tests constructing `AgentRequest`
- gateway tests importing `AGENT_REGISTRY`

Disposition: first extract behavior/golden assertions. Replace implementation-coupled
tests as each graph/tool gate passes; delete legacy tests only in Step 17.

### B6 — Provider cleanup is correct in backend runtime

No active OpenRouter/Gemini runtime branch was found. References in gateway tests are
negative assertions ensuring old providers remain absent.

Disposition: preserve the single Z.AI gateway and its negative tests.

## Frontend Findings

### F1 — Removed provider/settings code still exists

Files:

- `lib/apiManager.ts`
- `lib/features/agentSlice.ts`

Stale fields/methods include:

- `systemPrompt`
- `geminiApiKey`
- `claudeApiKey`
- `openrouterApiKey`
- `activeAiProvider`
- user-settings fetch/update handling
- payload fields for the removed prompt/provider API

This directly contradicts the product policy that users must not receive or send LLM
keys, prompts, providers, or models.

Disposition: treat as an early cleanup candidate, but first confirm no live component
imports or backend dependency. Remove with targeted TypeScript/API tests in a dedicated
frontend cleanup step before LangGraph UI cutover.

### F2 — Client-owned conversation and artifacts

File:

- `app/agent/components/AgentShell.tsx`

Current request sends:

- browser timezone
- complete current artifact state
- last eight messages, truncated client-side

Current response replaces local artifact state and stores pending workflow/confirmation
IDs in React state.

Risk:

- refresh loses the authoritative conversation
- follow-up correctness depends on browser state
- another device cannot resume naturally
- artifacts can be replayed from client input

Disposition: preserve until backend threads work. Replace during Steps 3, 7, and 14
with backend-owned `thread_id`, hydration, artifact IDs, and typed SSE.

### F3 — No LangGraph thread/stream client exists

No current implementation was found for:

- thread create/list/get
- checkpoint resume
- `EventSource`/SSE graph events
- stream event deduplication

Disposition: implement behind a frontend feature flag in Step 14 after backend thread
and checkpoint gates pass.

### F4 — Large legacy Redux surface remains

`lib/features/agentSlice.ts` still contains legacy dashboard-era state and thunks for:

- local app auth token/user storage
- direct content generation/publishing
- user list
- overview stats and ideas
- old provider settings
- multiple platform callback/account caches

Some platform connection state remains useful for the `/agent` Connect Apps UI. The
file must not be deleted wholesale without an import/usage audit.

Disposition:

1. map every exported thunk/action to live imports
2. preserve active connection/auth behavior
3. move agent thread state into a focused slice/runtime
4. remove confirmed dead exports in small tested changes

### F5 — Small stale UI terminology/assets

- `app/privacy-policy/page.tsx` still says “Back to Dashboard.”
- `app/scheduled-posts/datepicker-custom.css` remains although the route page was removed.

Disposition:

- update terminology to “Back to Main Agent”
- verify the CSS file has no imports, then delete as a small frontend cleanup

## User-Isolation Requirements

Every replacement must enforce:

- Clerk JWT-derived `user_id`; never authorize with a client-provided ID
- checkpoint namespace includes verified user ownership and thread
- memory namespace begins with verified user identity
- artifact, confirmation, account, page, schedule, and tool resources are ownership-checked
- cross-user thread/resume/read/execute tests
- no OAuth token/API key/cookie/password in state, memory, prompt, trace, or SSE

## Prioritized Action Order

1. Complete checklist Step 0 golden behavior tests.
2. Remove confirmed-dead frontend provider/settings code with lint/build/test.
3. Remove verified-unreferenced scheduled-post CSS and stale wording.
4. Obtain approval for LangGraph backend dependencies.
5. Build graph/thread/checkpoint foundation behind flags.
6. Build typed tools and central policies.
7. Implement user-specific memory and artifact references.
8. Migrate all eleven agents through their gates.
9. Cut frontend to backend threads and typed SSE.
10. Canary, deploy, observe, then generate the final legacy deletion manifest.

## Early Deletion Candidates

These may be removed before full LangGraph cutover only after targeted usage checks:

- frontend prompt/provider fields, methods, thunks, reducers, and types
- unreferenced `app/scheduled-posts/datepicker-custom.css`
- stale dashboard wording

## Do Not Delete Yet

- `app/agents/` custom runtime
- `/api/v1/agent/command` and `/confirm`
- legacy state tables or migrations
- current AgentShell context handoff
- platform/OAuth services
- scheduling/publishing/autopilot services
- current legacy tests before golden replacements exist

Deleting these now would break the running product or remove the behavior baseline.

## Audit Verification Commands

```powershell
rg -n "AgentOrchestrator|BaseAgent|AGENT_REGISTRY" fb_agent/app fb_agent/tests
rg -n "db\.add|db\.commit|social_action_service" fb_agent/app/agents fb_agent/app/api/v1/agent_routes.py
rg -n -i "langgraph|checkpointer|thread_id|interrupt\(" fb_agent/app fb_agent/tests fb_agent/requirements.txt
rg -n -i "gemini|openrouter|claude|systemPrompt|activeAiProvider" fb_dash/app fb_dash/lib
rg -n "slice\(-8\)|conversation|artifacts|thread_id|EventSource" fb_dash/app/agent fb_dash/lib
```

