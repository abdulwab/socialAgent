# NexLab SocialHub LangGraph Full Rebuild Plan

| Item | Decision |
|---|---|
| Status | Approved planning direction; implementation not started |
| Runtime | LangGraph for every agent workflow |
| Backend | Existing FastAPI application remains the API host |
| LLM | Existing single backend Z.AI GLM gateway remains mandatory |
| User experience | One visible Main Agent at `/agent` |
| Domain agents | 11 hidden agents represented as LangGraph subgraphs/nodes |
| Business capabilities | Existing services and platform APIs become typed tools |
| Persistence | PostgreSQL LangGraph checkpointer plus a safe long-term memory store |
| Mutations | Code-enforced approval interrupt before every risky tool |

> Execution is governed by
> `implementation-plan/NEXLAB_LANGGRAPH_TEST_GATED_EXECUTION_CHECKLIST.md`. Every step
> must pass its implementation, test, security, documentation, and rollback gate before
> the next step starts. The customer frontend remains the branded Next.js `/agent`
> application using `assistant-ui` primitives and typed SSE.
>
> The current-code findings and prioritized legacy disposition are recorded in
> `implementation-plan/NEXLAB_LANGGRAPH_LEGACY_AUDIT.md`.

## 1. Objective

Replace the current custom `AgentOrchestrator`, agent class registry, manual workflow
state transitions, frontend-owned conversation context, and incomplete memory layer
with one production LangGraph architecture.

This is a full agent-runtime replacement, not a rewrite of proven platform business
logic. Existing OAuth, analytics, media, scheduling, publishing, autopilot, and social
platform services will be preserved, hardened, and exposed as narrowly scoped
LangGraph tools.

The implementation must preserve these product rules:

- The user interacts only with Main Agent.
- Hidden agent names, graph nodes, prompts, models, tool calls, and traces are not
  returned to the normal UI.
- Z.AI remains the only LLM gateway.
- OAuth tokens and secrets never enter graph state, checkpoints, memory, or prompts.
- Publishing, scheduling, deletion, disconnect, retry, and autopilot mutations require
  an explicit user confirmation.
- A confirmation authorizes one immutable action payload and can be consumed once.

## 2. Current Implementation Audit

### 2.1 Runtime being replaced

The current runtime is custom Python orchestration:

- `fb_agent/app/agents/orchestrator.py`
  - manually creates workflow records
  - asks Main Agent for a list of intents
  - loops through agents sequentially
  - copies selected outputs into a shared dictionary
  - invokes safety review
  - creates and consumes custom confirmations
  - directly dispatches confirmed mutations
- `fb_agent/app/agents/main_agent.py`
  - LLM routing and final-response generation
- `fb_agent/app/agents/planner.py`
  - deterministic extraction and missing-requirement checks
- `fb_agent/app/agents/base.py`, `registry.py`, and `schemas.py`
  - custom agent runtime abstraction
- `fb_agent/app/agents/state_store.py`
  - manually persists workflow, run, artifact, confirmation, and memory records

These files should be retired only after LangGraph parity is proven.

### 2.2 Existing domain implementation

The current registry contains 13 handlers:

- two supporting capabilities: Assistant Chat and Product Help
- eleven product/domain agents:
  - Connection
  - Content Strategy
  - Copywriting
  - Image Generation
  - Media
  - Scheduling
  - Publishing
  - Analytics
  - Autopilot
  - Safety And Review
  - Web Search

In the target design, Assistant Chat and Product Help become Main Agent response/help
nodes. They do not increase the official domain-agent count.

### 2.3 State and memory gaps

- The browser sends only the last eight messages.
- Conversation state disappears on browser refresh.
- `agent_workflows.conversation_id` is not actively used.
- Artifacts are persisted but follow-up context primarily comes back from frontend
  state.
- `agent_memories` can be read, but application code does not create/update memories.
- No memory proposal, approval, consolidation, expiry, or provenance workflow exists.
- Workflow recovery is implemented as custom status handling rather than durable graph
  checkpoints.

### 2.4 Tooling gaps

`fb_agent/app/agent_tools/registry.py` currently exposes only:

- `social.publish_post`

Most capabilities are called directly from agents or the orchestrator. This prevents a
single permission system from consistently enforcing input validation, ownership,
confirmation, idempotency, audit, and secret boundaries.

### 2.5 Data already worth preserving

The following concepts remain useful even if their schemas evolve:

- user-visible artifacts
- confirmation audit records
- agent/tool execution audit records
- user preference and brand memory
- workflow ownership and status summaries

Historical records must not be dropped during initial cutover.

## 3. Target Architecture

```text
Next.js /agent
    |
    | command + thread_id
    v
FastAPI /api/v1/agent/*
    |
    v
LangGraph Main Graph
    |
    +-- load identity and safe context
    +-- load thread checkpoint and scoped memories
    +-- understand command / create typed plan
    +-- route to one or more hidden domain subgraphs
    +-- collect typed artifacts
    +-- deterministic safety and policy gate
    +-- interrupt before risky tools
    +-- execute approved immutable tool payload
    +-- persist checkpoint, artifacts, audit, and safe memories
    +-- produce one clean Main Agent response
```

LangGraph owns execution state. SQLAlchemy services own business data. The LLM proposes
plans and content; code owns authorization, validation, confirmation, and mutation.

## 4. Proposed Backend Layout

```text
fb_agent/app/agent_graph/
  __init__.py
  graph.py
  state.py
  context.py
  routing.py
  policies.py
  interrupts.py
  responses.py
  errors.py

  nodes/
    load_context.py
    understand_command.py
    build_plan.py
    route_work.py
    collect_results.py
    safety_gate.py
    request_confirmation.py
    execute_tools.py
    update_memory.py
    final_response.py

  agents/
    connection.py
    content_strategy.py
    copywriting.py
    image_generation.py
    media.py
    scheduling.py
    publishing.py
    analytics.py
    autopilot.py
    safety_review.py
    web_search.py

  tools/
    base.py
    registry.py
    policies.py
    connection.py
    content.py
    media.py
    scheduling.py
    publishing.py
    analytics.py
    autopilot.py
    web_search.py

  memory/
    schemas.py
    store.py
    retrieval.py
    proposals.py
    consolidation.py
    redaction.py

  persistence/
    checkpointer.py
    artifacts.py
    audit.py
```

Do not place DB sessions, ORM objects, OAuth tokens, or service clients in serializable
LangGraph state. Inject runtime dependencies through a request-scoped runtime context.

## 5. Graph State Contract

Use a typed state with reducers for append-only fields:

```python
class SocialHubGraphState(TypedDict):
    thread_id: str
    workflow_id: str
    user_id: int
    messages: Annotated[list[SafeMessage], add_messages]
    command: str
    input_mode: str
    locale: str
    timezone: str
    intent_plan: IntentPlan | None
    active_agents: list[str]
    working_context: WorkingContext
    artifacts: ArtifactState
    tool_proposals: list[ToolProposal]
    safety_decision: SafetyDecision | None
    pending_approval: ApprovalRequest | None
    execution_results: list[ToolExecutionResult]
    memory_proposals: list[MemoryProposal]
    warnings: list[str]
    errors: list[SafeError]
    final_reply: str | None
```

State must contain IDs and safe snapshots, not credentials or live Python objects.
Large media and CSV data stay in storage; graph state contains references and metadata.

## 6. Main Graph

### 6.1 Required nodes

1. `load_context`
   - validates Clerk user ownership
   - loads connected-account summaries without tokens
   - retrieves thread checkpoint and scoped long-term memories
2. `understand_command`
   - produces a strict structured routing decision through Z.AI
3. `build_plan`
   - deterministically verifies required entities and dependencies
4. `route_work`
   - selects the smallest necessary set of domain subgraphs
5. domain subgraphs
   - produce typed artifacts or typed tool proposals
6. `collect_results`
   - merges results using explicit reducers
7. `safety_gate`
   - runs deterministic policies first and the Safety Agent second
8. `request_confirmation`
   - calls LangGraph `interrupt()` with an immutable approval summary
9. `execute_tools`
   - revalidates identity, ownership, payload hash, expiry, and idempotency
10. `update_memory`
   - validates and persists only approved safe memory proposals
11. `final_response`
   - returns one user-facing answer without internal implementation details

### 6.2 Routing rules

- Prefer deterministic workflows where the required order is known.
- Use the LLM for semantic understanding, content generation, summarization, and
  ambiguous routing—not for access control.
- Agents return control to Main Graph; hidden agents do not hand off directly to each
  other.
- Parallelize only independent read/generation branches.
- Mutating branches always converge at the central safety and approval nodes.
- Set explicit recursion, tool-call, latency, and token budgets.

## 7. Eleven Domain Agents as LangGraph Subgraphs

| Agent | LangGraph responsibilities | Primary tools |
|---|---|---|
| Connection | list apps/pages, explain OAuth, propose select/disconnect | connection status, OAuth URL, select page, disconnect |
| Content Strategy | audience/campaign reasoning and content calendar artifacts | brand context, analytics insights, saved ideas |
| Copywriting | platform-specific drafts, rewrites, hashtags | brand memory read, content validation |
| Image Generation | prompt creation and image-generation request | GLM image, media persistence |
| Media | inspect, upload-reference, attach, validate, delete proposal | Cloudinary/media services |
| Scheduling | normalize time, validate queue, create schedule preview/proposal | connection check, schedule create/update/delete |
| Publishing | create publish preview/proposal and interpret provider result | publish and retry services |
| Analytics | query metrics and produce evidence-based summaries | analytics query services |
| Autopilot | inspect and propose recurring configuration changes | autopilot read/update services |
| Safety And Review | assess content/tool proposals and enforce risk policy | policy engine; no unrestricted mutations |
| Web Search | gather current sources and return cited research artifacts | approved search/fetch adapter |

Each subgraph must expose a stable typed input/output contract. Future agents register a
subgraph manifest, allowed tools, memory scopes, risk tier, and test contract.

## 8. Existing Services Become Typed Tools

### 8.1 Tool wrapper requirements

Every tool must define:

- stable name and version
- strict Pydantic input/output models
- allowed agent/subgraph list
- read or mutation classification
- risk tier
- confirmation requirement
- user/resource ownership validation
- timeout and retry policy
- idempotency key behavior
- redacted audit representation
- safe user-facing errors

### 8.2 Initial tool catalog

Connection tools:

- `connections.list_status`
- `connections.list_facebook_pages`
- `connections.create_oauth_url`
- `connections.select_page`
- `connections.disconnect`
- `connections.inspect_token_health`

Content and strategy tools:

- `content.load_brand_context`
- `content.load_recent_performance`
- `content.validate_platform_copy`
- `content.list_saved_ideas`

Media and image tools:

- `media.inspect`
- `media.store_generated_image`
- `media.attach_to_draft`
- `media.delete`
- `image.generate`

Scheduling and publishing tools:

- `schedule.preview`
- `schedule.create`
- `schedule.bulk_create`
- `schedule.update`
- `schedule.delete`
- `publish.preview`
- `publish.execute`
- `publish.retry_failed`

Analytics tools:

- `analytics.summary`
- `analytics.platform_breakdown`
- `analytics.best_times`
- `analytics.top_content`

Autopilot tools:

- `autopilot.get_config`
- `autopilot.preview_change`
- `autopilot.apply_change`

Research tools:

- `web.search`
- `web.fetch`

The wrappers call existing services. They must not duplicate platform API logic.

## 9. Memory and Context Redesign

### 9.1 Short-term memory

- Assign a backend `thread_id` to each conversation.
- Store messages and working state using a PostgreSQL LangGraph checkpointer.
- Frontend sends `thread_id` and the new user input, not the authoritative message
  history or complete artifacts.
- Resume the same thread after refresh, reconnect, worker restart, or confirmation.
- Apply message trimming/summarization based on token budget while preserving original
  audit records outside the prompt.

### 9.2 Long-term memory

Use a persistent LangGraph Store (PostgreSQL-backed) or a project-owned adapter
implementing the Store contract. Namespace by user and scope:

```text
(user_id, "preferences")
(user_id, "brand")
(user_id, "platform_defaults")
(user_id, "analytics_insights")
(user_id, "artifact_index")
```

Long-term memory flow:

1. An agent may emit a typed `MemoryProposal`.
2. A deterministic redaction and allowlist policy validates it.
3. Main Graph decides whether it is useful, scoped, and non-sensitive.
4. Persistent-default changes require confirmation when they alter future behavior.
5. Store the value with source, confidence, created/updated time, expiry, and provenance.
6. Retrieve only memories relevant to the current intent.
7. Support edit, forget, expire, and deduplicate operations.

Never store:

- OAuth access/refresh tokens
- API keys
- cookies or authorization headers
- passwords or payment data
- raw provider responses containing credentials
- unrestricted full prompts/tool payloads

### 9.3 Artifact memory

Artifacts remain domain records with stable IDs. Graph state stores references to:

- drafts
- generated images/media
- research reports
- schedule previews
- analytics reports
- CSV validation batches

The frontend must not be the source of truth for follow-up phrases such as “schedule
this” or “use the second image.”

## 10. Confirmation and Mutation Security

LangGraph interrupts provide pause/resume, but approval security remains code-owned.

For every risky action:

1. Agent creates a typed tool proposal.
2. Safety node validates policy and produces a user-readable preview.
3. Backend creates an approval envelope containing:
   - workflow/thread/user IDs
   - tool name and version
   - normalized payload hash
   - expiry
   - idempotency key
4. Graph interrupts before tool execution.
5. `/confirm` resumes the same thread/checkpoint.
6. Execution node re-checks user ownership, payload hash, expiry, current connection
   state, and one-time claim.
7. Tool executes exactly once.
8. Result and safe audit metadata are persisted.

Never allow an LLM response, prompt statement, or client-side boolean to bypass the
approval gate.

## 11. API and Frontend Contract

Recommended API:

- `POST /api/v1/agent/threads`
- `GET /api/v1/agent/threads`
- `GET /api/v1/agent/threads/{thread_id}`
- `POST /api/v1/agent/threads/{thread_id}/commands`
- `POST /api/v1/agent/threads/{thread_id}/resume`
- `GET /api/v1/agent/threads/{thread_id}/stream`
- existing CSV/media upload endpoints may remain specialized transport endpoints

Compatibility:

- Keep `/api/v1/agent/command` and `/confirm` behind an adapter during migration.
- Add `thread_id`, stable artifact IDs, event IDs, and resumable status.
- Use SSE initially for progress events; do not expose internal node or agent names.
- Frontend displays generic progress labels and confirmation previews.
- Remove frontend ownership of authoritative conversation and artifact context only
  after backend thread hydration works.

## 12. Persistence and Database Strategy

This phase requires explicit user approval before models, migrations, or production DB
are changed.

Preferred approach:

- Add LangGraph PostgreSQL checkpoint tables through the official checkpointer setup or
  reviewed Alembic-managed equivalents.
- Add/modify application tables only where business/audit requirements are not covered
  by checkpoints.
- Preserve existing `agent_workflows`, `agent_runs`, `agent_artifacts`,
  `agent_confirmations`, and `agent_memories` during cutover.
- Backfill thread/workflow references only if required.
- After a retention period, archive obsolete custom-runtime records; do not drop tables
  in the initial migration.

Checkpoint state is operational runtime data. Audit and user-visible artifacts are
separate durable product records and must not depend solely on checkpoint retention.

## 13. Observability and Evaluation

- Generate one correlation ID per command and associate graph run, LLM calls, tools,
  approvals, and provider operations.
- Keep internal traces server-side.
- Redact secrets before persistence and logging.
- Record node duration, tool duration, token usage, retries, interrupt duration,
  failure category, and outcome.
- Add scenario evaluation datasets for routing, scheduling dates, platform selection,
  policy decisions, Roman Urdu, and follow-up references.
- Add graph visualization in developer/test tooling only.
- LangSmith is optional; production correctness must not require an external tracing
  SaaS.

## 14. Full Replacement Phases

### Phase 0 — Freeze and characterize

- Freeze new features in the custom orchestrator.
- Capture current API contracts and representative production-safe scenarios.
- Add characterization tests for all existing successful workflows and failures.
- Inventory every direct service call and mutation.
- Define latency/token baselines.

Exit: reproducible baseline and complete service-to-tool inventory.

### Phase 1 — LangGraph foundation

- Obtain approval for dependency changes before editing `requirements.txt`.
- Add typed graph state, runtime context, graph factory, error taxonomy, and Z.AI model
  adapter.
- Add development checkpointer first; design PostgreSQL setup.
- Add thread API behind a disabled feature flag.

Exit: simple chat/help graph passes unit and restart/resume tests.

### Phase 2 — Tool platform

- Wrap existing read services first.
- Implement centralized tool registry and policy metadata.
- Add mutation wrappers without enabling execution.
- Add ownership, idempotency, redaction, timeout, and audit middleware.

Exit: every existing service/API capability has an owner and typed tool contract.

### Phase 3 — Context and memory

- Implement backend threads and checkpoint hydration.
- Implement scoped memory retrieval and memory proposal pipeline.
- Add artifact reference resolution.
- Add user memory controls and deletion behavior.

Exit: refresh/restart continuity works and safe preference memory persists across
threads.

### Phase 4 — Core domain subgraphs

Implement and test:

1. Connection
2. Copywriting
3. Scheduling
4. Safety And Review

Prove draft → schedule preview → interrupt → confirm → exactly-once scheduling.

Exit: core graph matches current behavior under a shadow/canary flag.

### Phase 5 — Creative and research subgraphs

Implement:

5. Content Strategy
6. Image Generation
7. Media
8. Web Search

Exit: multi-branch research/content/image workflows produce referenced artifacts and
respect budgets.

### Phase 6 — Advanced action subgraphs

Implement:

9. Analytics
10. Publishing
11. Autopilot

Exit: all risky tools pass the same interrupt and one-time execution path.

### Phase 7 — Frontend cutover

- Create/hydrate threads from backend.
- Stream generic graph progress.
- Resume approvals against thread checkpoints.
- Stop sending full conversation/artifact context from React.
- Preserve current Main-Agent-only visual design.

Exit: page refresh, multi-device continuation, expired approvals, and reconnect work.

### Phase 8 — Parallel verification and cutover

- Run old and new planning paths in shadow mode for safe/read-only requests.
- Compare intent, artifact shape, confirmation decision, latency, and token use.
- Canary internal/test users on LangGraph.
- Expand rollout only after acceptance gates pass.
- Keep rollback switch to custom runtime during the observation window.

Exit: LangGraph is the production default with monitored stability.

### Phase 9 — Remove old implementation

Only after production acceptance:

- remove `AgentOrchestrator`
- remove `BaseAgent`, old registry, planner runtime, manual memory builder, and manual
  state store where no longer used
- convert or delete old class-based agents after every behavior has a subgraph/node
  owner
- remove compatibility API adapters
- archive obsolete tests and replace them with graph/tool tests
- retain necessary historical data and audit readers

Do not delete old code at the start. Replacement must be proven before removal.

### Phase 10 — Documentation and production deployment

- Update architecture, combined checklist, API documentation, operations runbook,
  memory policy, confirmation threat model, and agent-extension guide.
- Run full backend tests locally.
- Apply approved migrations and deploy backend by Docker/SCP only.
- Do not push backend to GitHub.
- Verify health, OpenAPI, checkpoint setup, resume, approvals, and all 11 workflows.

## 15. Test Strategy

Unit:

- state reducers and serialization
- routing schemas and unsupported intents
- tool input/output schemas
- tool permissions and risk classification
- memory allowlist/redaction/expiry
- time and timezone normalization
- immutable approval payload hashing

Graph:

- each node and conditional edge
- each of the 11 subgraphs
- independent parallel branches
- retryable and terminal errors
- recursion/tool/token limits
- checkpoint resume after process restart

Security:

- cross-user thread and artifact access
- confirmation replay and double-click
- payload substitution after approval
- expired approvals
- prompt injection through web/media/CSV content
- OAuth/API secrets absent from prompts, state, checkpoints, logs, and traces

Integration:

- OAuth status and page selection
- Cloudinary/image generation
- schedule single/bulk/CSV
- publish and retry
- analytics queries
- autopilot changes
- web-search citations

Frontend:

- thread create/list/hydrate
- refresh continuity
- SSE reconnect
- generic progress wording
- confirmation resume/cancel/expiry
- responsive artifact views
- no hidden-agent or trace leakage

Production acceptance:

- all existing backend tests or migrated equivalents pass
- full frontend lint/build/test pass
- zero unconfirmed mutations
- exactly-once behavior under retries
- restart-safe confirmation resume
- all 11 agents pass golden scenarios
- rollback path tested before rollout

## 16. Documentation Updates

During implementation keep these synchronized:

- `AGENTS.md`
- `CLAUDE.md`
- `AGENTS_ARCHITECTURE_DESIGN.md`
- `implementation-plan/NEXLAB_AGENT_FIRST_REBUILD_PLAN.md`
- `implementation-plan/NEXLAB_AGENT_FIRST_COMBINED_IMPLEMENTATION_PLAN.md`
- this LangGraph rebuild plan
- backend API/OpenAPI notes
- Docker deployment guide where operationally necessary

After every phase, record:

- files added/removed
- tests and results
- schema/migration status
- deployment status
- known gaps
- next acceptance gate

## 17. Decisions Requiring Explicit Approval

Before implementation starts, obtain separate approval for:

1. editing `fb_agent/requirements.txt` to add LangGraph/checkpointer packages
2. adding or changing DB models/migrations
3. applying local or production migrations
4. production Docker deployment
5. final deletion of the old runtime after cutover

## 18. Definition of Done

The rebuild is complete only when:

- every user command enters a LangGraph thread
- all eleven domain agents are LangGraph nodes/subgraphs
- all platform capabilities are typed permissioned tools
- PostgreSQL checkpoints provide durable pause/resume
- conversation context survives refresh and restart
- safe long-term memory is both read and written with provenance
- artifacts are backend-owned and referenceable across turns
- risky tools cannot execute without a valid one-time approval
- Z.AI remains the only LLM gateway
- normal UI exposes only Main Agent
- old custom runtime is removed after verified production cutover
- documentation and tests match the deployed architecture
