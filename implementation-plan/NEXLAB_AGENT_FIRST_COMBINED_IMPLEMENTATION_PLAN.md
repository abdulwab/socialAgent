# NexLab SocialHub Combined Agent-First Implementation Plan

> **2026-07-03 migration notice:** Previously completed custom agent-runtime work is now
> the behavior baseline for a full LangGraph rebuild. Do not extend the custom
> orchestrator with new workflow architecture. Use
> `implementation-plan/NEXLAB_LANGGRAPH_FULL_REBUILD_PLAN.md` as the execution
> checklist for graph state, all eleven domain subgraphs, typed service tools, durable
> memory, approval interrupts, compatibility rollout, and eventual legacy removal.
> Every migration step must pass the gates in
> `implementation-plan/NEXLAB_LANGGRAPH_TEST_GATED_EXECUTION_CHECKLIST.md`. The
> customer frontend remains the custom Next.js `/agent` interface; Open WebUI is not
> the production product UI.

| Field | Details |
|---|---|
| Project | NexLab / SocialHub |
| Purpose | Combined execution plan for implementing `NEXLAB_AGENT_FIRST_REBUILD_PLAN.md` and `AGENTS_ARCHITECTURE_DESIGN.md` |
| Source Documents | `implementation-plan/NEXLAB_AGENT_FIRST_REBUILD_PLAN.md`, `AGENTS_ARCHITECTURE_DESIGN.md` |
| Status | V1 implemented; cleanup/migration verification in progress |

---

## 0. Execution Progress

Last updated: 2026-06-23.

Completed initial vertical slice:

- Phase 1 backend agent foundation: implemented.
- Phase 2 single Z.AI GLM gateway: implemented.
- Phase 3 agent command API: implemented.
- Phase 5 frontend `/agent` route: implemented.
- Phase 6 auth redirect migration: implemented.
- Additional practical workflow slices: implemented CSV preview endpoint/UI, Image Generation Agent media-service hook, and Analytics Agent lightweight DB summary.
- Frontend pushed to GitHub `abdulwab/fb_dash` main: commit `181521a`.
- Frontend lint/test stabilization pushed to GitHub `abdulwab/fb_dash` main: commit `b0bc943`.
- Frontend legacy lint warning cleanup pushed to GitHub `abdulwab/fb_dash` main: commit `c295fbf`.
- Frontend V1 agent workflow UI completion pushed to GitHub `abdulwab/fb_dash` main: commit `88df17d`.
- Frontend old route stub deletion pushed to GitHub `abdulwab/fb_dash` main: commit `13929d3`.
- Backend deployed to AWS Docker via SCP/server-side build/container restart. Backend GitHub was not pushed.
- Backend V1 workflow execution deployed to AWS Docker via SCP/server-side build/container restart. Backend GitHub was not pushed.
- After user validation, old dashboard UI code was removed from the active frontend experience.
- Old dashboard route redirect stubs were deleted after explicit user approval; old dashboard URLs may now return 404.
- Old prompt/provider settings were removed from frontend, backend model/schema/routes, and DB migration:
  - `fb_agent/migrations/versions/f2c9d8e1a7b4_remove_user_prompt_provider_fields.py`
- Production DB was cleaned and Alembic-stamped at `f2c9d8e1a7b4`; old `users` columns are absent.
- Persistent DB-backed agent state was implemented:
  - `agent_workflows`
  - `agent_runs`
  - `agent_artifacts`
  - `agent_confirmations`
  - `agent_memories`
  - migration `fb_agent/migrations/versions/a9b7c6d5e4f3_add_agent_workflow_memory_tables.py`
- Production backend Docker deploy completed for persistent agent state. Alembic version is `a9b7c6d5e4f3` and all five agent tables exist.

Verified against source docs:

- `NEXLAB_AGENT_FIRST_REBUILD_PLAN.md` sections for `/agent`, backend command API, frontend architecture, auth redirects, hidden subagents, Z.AI GLM gateway, and safety rules.
- `AGENTS_ARCHITECTURE_DESIGN.md` sections for single visible assistant, Main Agent orchestration, structured contracts, workflow state, hidden backend agents, and safety before mutation.

Verification results:

- `npm.cmd exec eslint app/agent -- --max-warnings=0`: passed.
- `npm.cmd run lint` in `fb_dash`: passed with clean output.
- `npm.cmd run build` in `fb_dash`: passed.
- `npm.cmd test -- --runInBand` in `fb_dash`: passed.
- `.venv\Scripts\python.exe -m compileall app migrations\versions\f2c9d8e1a7b4_remove_user_prompt_provider_fields.py` in `fb_agent`: passed.
- Full backend pytest with `DATABASE_URL=sqlite:///./test_local.db`: passed, 68 tests.
- Production backend verification after Docker deploy: `/health` passed and OpenAPI showed `/api/v1/agent/command`, `/api/v1/agent/confirm`, `/api/v1/agent/csv-preview`, and `/api/v1/agent/csv-schedule`.
- Production OpenAPI has no prompt-settings prompt route.
- Production DB verification: `old_columns_present []`, `alembic_version [('f2c9d8e1a7b4',)]`.
- Production DB verification after persistent agent state deploy: `missing_tables []`, `alembic_version [('a9b7c6d5e4f3',)]`.
- Full backend pytest after DB state implementation: passed, 70 tests.

Pending phases:

- Advanced web search provider integration if a dedicated search API key/provider is approved. V1 has best-effort web search plus graceful fallback.
- Final old dashboard/sidebar active UI cleanup is complete, including route stub deletion after user approval.

---

## 1. Implementation Rule

This plan must be executed with a source-document verification loop.

After every implementation step:

1. Re-check the matching section in `NEXLAB_AGENT_FIRST_REBUILD_PLAN.md`.
2. Re-check the matching section in `AGENTS_ARCHITECTURE_DESIGN.md`.
3. Confirm the code still follows these non-negotiable rules:
   - user sees only Main Agent
   - hidden agents are backend/internal only
   - no subagent names, raw logs, routing traces, model names, or API keys in normal UI
   - all risky actions require confirmation
   - all LLM calls go through the single backend Z.AI GLM gateway
   - OAuth is used for social connections, never username/password collection
4. Mark the step as complete only when implementation and source-doc checks both pass.

---

## 2. Execution Order

Implementation should happen in this order:

1. Backend agent foundation
2. Backend command endpoint and orchestrator
3. Frontend `/agent` shell
4. Auth redirect migration
5. Core workflows
6. Creative, CSV, voice, analytics, and advanced workflows
7. Old navigation removal/hiding
8. Testing and production polish

This order keeps the architecture stable before replacing the visible product experience.

---

## 3. Phase 1: Backend Agent Foundation

### Goal

Create the internal agent system foundation without changing the user-facing app yet.

### Implement

- Create backend agent package:
  - `fb_agent/app/agents/base.py`
  - `fb_agent/app/agents/schemas.py`
  - `fb_agent/app/agents/registry.py`
  - `fb_agent/app/agents/orchestrator.py`
  - `fb_agent/app/agents/state_store.py`
  - `fb_agent/app/agents/memory.py`
- Define structured contracts:
  - `AgentRequest`
  - `AgentResponse`
  - `AgentResult`
  - `WorkflowState`
  - `ConfirmationState`
  - `Artifact`
- Add agent registry keys:
  - `connection`
  - `content_strategy`
  - `copywriting`
  - `image_generation`
  - `media`
  - `scheduling`
  - `publishing`
  - `analytics`
  - `autopilot`
  - `safety_review`
  - `web_search`
- Add initial deterministic intent classifier.
- Add workflow statuses:
  - `created`
  - `planning`
  - `running`
  - `waiting_for_confirmation`
  - `confirmed`
  - `executing_mutation`
  - `completed`
  - `failed`
  - `cancelled`

### Verification Against Source Docs

Check:

- `AGENTS_ARCHITECTURE_DESIGN.md` sections 2, 3, 4, 7, 8, 10, 11
- `NEXLAB_AGENT_FIRST_REBUILD_PLAN.md` sections 6, 7, 8, 13, 14

Pass criteria:

- Agents are backend services, not frontend components.
- Main Agent owns context and coordination.
- Hidden agents return structured JSON.
- No direct uncontrolled agent-to-agent calls.
- State supports workflow, run, artifact, confirmation, and memory records.

---

## 4. Phase 2: Z.AI GLM Gateway

### Goal

Centralize all LLM calls behind backend configuration.

### Implement

- Create:
  - `fb_agent/app/services/agent_llm_gateway.py`
  - `fb_agent/app/services/agent_model_policy.py`
  - `fb_agent/app/services/agent_llm_errors.py`
- Add backend-only environment handling:
  - `ZAI_API_KEY`
  - `ZAI_BASE_URL`
  - `ZAI_MODEL_CONFIG_PATH`
- Add gateway helpers:
  - `run_reasoning_llm`
  - `run_fast_llm`
  - `run_json_llm`
  - `generate_agent_response`
- Add timeout, retry, JSON parsing, and error handling.
- Ensure frontend never sends or receives provider/model/API key data.
- Deprecate or wrap existing generic LLM service through this gateway where practical.

### Verification Against Source Docs

Check:

- `AGENTS_ARCHITECTURE_DESIGN.md` sections 3, 9, 12
- `NEXLAB_AGENT_FIRST_REBUILD_PLAN.md` sections 7, 8, 9, 15

Pass criteria:

- Raw Z.AI key exists only in the backend/server environment.
- User-facing UI has no provider selector or API key input.
- OAuth tokens, API keys, cookies, and credentials are never passed into prompts.
- LLM gateway can return text and structured JSON.

---

## 5. Phase 3: Agent Command API

### Goal

Expose one clean backend endpoint for the Main Agent interface.

### Implement

- Create:
  - `fb_agent/app/api/v1/agent_routes.py`
- Register router in:
  - `fb_agent/app/main.py`
- Add endpoint:
  - `POST /api/v1/agent/command`
- Add request shape:
  - `message`
  - `input_mode`
  - `context`
  - optional uploaded artifact references
- Add response shape:
  - `reply`
  - `actions`
  - `artifacts`
  - `progress_label`
  - `requires_confirmation`
  - `pending_confirmation`
- Add confirmation endpoint if needed:
  - `POST /api/v1/agent/confirm`
- Keep internal trace server-side only.

### Verification Against Source Docs

Check:

- `NEXLAB_AGENT_FIRST_REBUILD_PLAN.md` sections 8, 13, 14
- `AGENTS_ARCHITECTURE_DESIGN.md` sections 4, 7, 8, 14, 17

Pass criteria:

- Normal API response contains only clean Main Agent output.
- No hidden agent names or raw execution logs are returned for normal users.
- Mutations are blocked until confirmation is complete.
- Workflow and confirmation states can be persisted or safely emulated for V1.

---

## 6. Phase 4: Core Hidden Agents

### Goal

Implement the minimum useful agent workflows first.

### Implement

Start with:

- Connection Agent
  - connected app status
  - OAuth launch URLs
  - reconnect/disconnect preview
- Copywriting Agent
  - post generation
  - rewrites
  - hashtags
  - health-check reuse
- Scheduling Agent
  - schedule preview
  - timezone handling
  - scheduled post creation after confirmation
- Safety And Review Agent
  - publish/schedule/delete/disconnect/autopilot confirmation detection
  - duplicate checks
  - platform limit checks
  - missing connection checks

Reuse existing backend where possible:

- `/api/v1/user/channel-status`
- existing OAuth login URL helpers
- `/api/v1/post/generate`
- `/api/v1/post/ai-describe`
- `/api/v1/post/health-check`
- `/api/v1/scheduled-posts`
- current timezone and duplicate logic

### Verification Against Source Docs

Check:

- `NEXLAB_AGENT_FIRST_REBUILD_PLAN.md` sections 5, 6, 7, 8, 13, 14
- `AGENTS_ARCHITECTURE_DESIGN.md` sections 2, 5, 13, 14, 16

Pass criteria:

- Connection uses OAuth only.
- Copywriting does not schedule or publish.
- Scheduling does not silently create posts without confirmation.
- Safety Agent runs before every mutating action.
- User-facing wording remains generic and polished.

---

## 7. Phase 5: Frontend `/agent` Route

### Goal

Create the new primary logged-in product interface.

### Implement

- Create route:
  - `fb_dash/app/agent/page.tsx`
- Create components:
  - `fb_dash/app/agent/components/AgentShell.tsx`
  - `fb_dash/app/agent/components/AgentTopBar.tsx`
  - `fb_dash/app/agent/components/ConnectAppsDropdown.tsx`
  - `fb_dash/app/agent/components/AgentChat.tsx`
  - `fb_dash/app/agent/components/AgentComposer.tsx`
  - `fb_dash/app/agent/components/WorkProgressIndicator.tsx`
  - `fb_dash/app/agent/components/GeneratedAssetsPanel.tsx`
  - `fb_dash/app/agent/components/ConfirmationModal.tsx`
- Add API method:
  - `fb_dash/lib/apiManager.ts` -> `runAgentCommand`
- Add state:
  - messages
  - progress label
  - generated drafts/images/previews
  - loading/error
  - pending confirmation
- Ensure responsive behavior:
  - desktop: command center layout
  - mobile: chat first, composer sticky, generated assets below or drawer

### Verification Against Source Docs

Check:

- `NEXLAB_AGENT_FIRST_REBUILD_PLAN.md` sections 3, 5, 9, 13, 14
- `AGENTS_ARCHITECTURE_DESIGN.md` sections 1, 3, 7, 15, 17

Pass criteria:

- `/agent` does not depend on old dashboard tabs.
- No `SubagentsPanel` or visible hidden-agent statuses exist.
- Progress labels are generic: "Working...", "Creating drafts...", "Ready for confirmation".
- Connect Apps dropdown shows status and OAuth actions.
- Confirmation UI appears for risky actions.

---

## 8. Phase 6: Auth Redirect Migration

### Goal

Make `/agent` the default authenticated destination.

### Implement

- Update login success redirect to `/agent`.
- Update signup success redirect to `/agent`.
- Update Google auth success redirect to `/agent`.
- Update landing page authenticated CTA to `/agent`.
- Keep old routes manually accessible during migration.
- Ensure unauthenticated `/agent` redirects to login/landing.

### Verification Against Source Docs

Check:

- `NEXLAB_AGENT_FIRST_REBUILD_PLAN.md` sections 2, 4, 14, 15
- `AGENTS_ARCHITECTURE_DESIGN.md` sections 1, 19

Pass criteria:

- New users land on Main Agent after auth.
- Returning authenticated users CTA to `/agent`.
- Old dashboard route redirects are no longer the primary flow.

---

## 9. Phase 7: Creative, Media, Web Search, And CSV

### Goal

Add the workflows that make the agent experience complete.

### Implement

- Content Strategy Agent:
  - post angles
  - campaign plans
  - weekly/monthly content plans
- Image Generation Agent:
  - image prompt generation
  - generated image request
  - failure does not block text draft
- Media Agent:
  - upload handling
  - generated media storage
  - attach media to drafts
- Web Search Agent:
  - current/latest/trends/research intent
  - search/fetch layer
  - source summary layer
  - graceful fallback when search fails
- CSV flow:
  - upload from composer
  - drag/drop on desktop
  - dry-run validation
  - preview rows/warnings/errors
  - final scheduling only after confirmation
- Optional component:
  - `fb_dash/app/agent/components/CsvUploadPreview.tsx`

Reuse:

- `/api/v1/media/generate-image`
- `media_service.generate_and_upload_image`
- `ApiManager.generateImageFromPrompt`
- `/api/v1/media/upload`
- `/api/v1/post/bulk-upload`

Add if needed:

- `POST /api/v1/agent/csv-preview`

### Verification Against Source Docs

Check:

- `NEXLAB_AGENT_FIRST_REBUILD_PLAN.md` sections 6, 7, 8, 11, 12, 13, 15
- `AGENTS_ARCHITECTURE_DESIGN.md` sections 5, 6, 13, 15, 16

Pass criteria:

- Latest/current commands trigger Web Search internally.
- Source summaries are shown only when useful.
- Image generation failure keeps text drafts usable.
- CSV never schedules silently.
- CSV preview includes valid rows, invalid rows, warnings, and confirmation action.

---

## 10. Phase 8: Voice Command

### Goal

Support voice command in V1 using browser speech recognition.

### Implement

- Add microphone control to `AgentComposer`.
- Use Web Speech API when available.
- Convert voice to editable composer text.
- Send as `input_mode: "voice"` after user submits.
- Add fallback message for unsupported browsers.

### Verification Against Source Docs

Check:

- `NEXLAB_AGENT_FIRST_REBUILD_PLAN.md` sections 3, 10, 15
- `AGENTS_ARCHITECTURE_DESIGN.md` sections 4, 7

Pass criteria:

- Voice fills text input before send.
- User can edit transcription.
- Unsupported browsers get a clean fallback.
- Voice does not bypass confirmation rules.

---

## 11. Phase 9: Analytics, Publishing, And Autopilot

### Goal

Move remaining dashboard workflows into Main Agent commands.

### Implement

- Analytics Agent:
  - overview
  - posts
  - growth
  - best posting times
- Publishing Agent:
  - publish now preview
  - retry failed posts
  - platform error explanations
- Autopilot Agent:
  - setup preview
  - tone/platform/frequency configuration
  - dry-run support
  - enable/disable only after confirmation

Reuse:

- `/api/v1/analytics/overview`
- `/api/v1/analytics/posts`
- `/api/v1/analytics/growth`
- `/api/v1/analytics/best-times`
- `/api/v1/post/publish`
- retry endpoint
- `/api/v1/autopilot`
- `/api/v1/autopilot/dry-run`
- `/api/v1/autopilot/generate-now`

### Verification Against Source Docs

Check:

- `NEXLAB_AGENT_FIRST_REBUILD_PLAN.md` sections 6, 7, 8, 13, 15
- `AGENTS_ARCHITECTURE_DESIGN.md` sections 2, 5, 13, 14, 16

Pass criteria:

- Analytics is safe and does not require confirmation.
- Publishing requires confirmation.
- Bulk retry requires confirmation.
- Autopilot enable/disable/frequency changes require confirmation.
- Platform errors are user-readable.

---

## 12. Phase 10: Remove Old User-Facing Navigation

### Goal

Make Main Agent the final client-facing app experience.

### Implement

- Hide/remove old sidebar from final logged-in app shell.
- Remove old tabs from normal user navigation:
  - Overview
  - Post Queue
  - Ideas Board
  - AI Autopilot
  - Calendar
  - My Posts
  - Bulk Upload
  - Analytics
  - Media Library
  - Social Channels
  - Prompt Settings
  - Privacy Policy inside app navigation
- Remove/hide final UI access to:
  - Gemini API key input
  - Claude API key input
  - OpenRouter API key input
  - provider/model selector
  - Prompt Settings page
- Keep old routes only if needed for internal/manual testing until equivalent agent workflows pass.

### Verification Against Source Docs

Check:

- `NEXLAB_AGENT_FIRST_REBUILD_PLAN.md` sections 3, 4, 9, 14, 15
- `AGENTS_ARCHITECTURE_DESIGN.md` sections 1, 3, 12, 19

Pass criteria:

- Final user flow starts and stays in `/agent`.
- Normal users cannot reach provider/API key controls from app navigation.
- No old dashboard tabs appear in final user-facing navigation.

---

## 13. Phase 11: Memory, Audit, And Observability

### Goal

Add durable context and engineering visibility without exposing internals to users.

### Implement

- Add safe memory support:
  - user preferences
  - brand voice
  - preferred platforms
  - reusable content style
- Add audit records:
  - confirmation action
  - confirmed payload
  - user ID
  - timestamp
- Add server-side observability:
  - workflow ID
  - agent run ID
  - agent key
  - status
  - duration
  - token usage
  - model used
  - error reason
- Keep debug/admin traces out of normal UI.

### Verification Against Source Docs

Check:

- `AGENTS_ARCHITECTURE_DESIGN.md` sections 8, 9, 10, 17
- `NEXLAB_AGENT_FIRST_REBUILD_PLAN.md` sections 7, 8, 13, 15

Pass criteria:

- No secrets are stored in memory or passed to LLM.
- Hidden agent runs are observable server-side.
- Normal users see only clean Main Agent output.
- Confirmation history is auditable.

---

## 14. Phase 12: Testing And Production Polish

### Goal

Verify the agent-first product end to end.

### Automated Tests

Run frontend:

```txt
npm run lint
npm run build
npm test
```

Run backend:

```txt
pytest
```

### Manual Test Checklist

Auth:

- signup redirects to `/agent`
- login redirects to `/agent`
- Google auth redirects to `/agent`
- unauthenticated `/agent` redirects safely

Agent UI:

- text command works
- voice command fills text
- unsupported voice shows fallback
- generic progress label appears
- no hidden agent names visible
- no raw logs visible
- desktop layout is complete
- mobile layout is chat-first

Connect Apps:

- connected status loads
- OAuth launch works
- disconnect asks confirmation

Content:

- single post generation works
- multi-platform variants work
- hashtags and rewrites work

Image:

- image generation works
- generated image saves
- image preview renders
- failure does not break text draft

CSV:

- CSV upload works from composer
- preview shows valid/invalid rows
- scheduling requires confirmation

Scheduling:

- single schedule requires confirmation
- bulk schedule requires confirmation
- invalid times show clean errors

Publishing:

- publish now requires confirmation
- failed retry works
- platform errors are readable

Analytics:

- performance summary returns useful result
- missing connection is explained clearly

Web Search:

- latest/trends commands use Web Search internally
- useful source summaries appear
- search failure has graceful fallback

LLM/API policy:

- backend owns the Z.AI key and GLM model policy
- frontend never receives API keys
- users cannot edit provider/model settings

### Verification Against Source Docs

Check:

- `NEXLAB_AGENT_FIRST_REBUILD_PLAN.md` section 15
- `AGENTS_ARCHITECTURE_DESIGN.md` sections 16, 17, 19

Pass criteria:

- Automated tests pass or failures are documented.
- Manual checklist passes for desktop and mobile.
- Final product follows agent-first UX and hidden-agent architecture.

---

## 15. Per-Step Implementation Checklist Template

Use this checklist for every task while implementing:

```txt
Step:
Files changed:
Related source-doc sections:

Implementation check:
[ ] Code matches planned behavior
[ ] Existing reusable code was preferred
[ ] No unrelated refactor was added

Agent architecture check:
[ ] Main Agent remains the only visible assistant
[ ] Hidden agent internals are not exposed
[ ] Structured request/response contract is preserved
[ ] Main Agent owns context and sequencing

Safety check:
[ ] Mutating action requires confirmation
[ ] No secrets are sent to LLM
[ ] OAuth is used for social connection
[ ] API keys/provider controls are not user-facing

UI check:
[ ] No old dashboard tab was introduced into final flow
[ ] Desktop layout is usable
[ ] Mobile layout is chat-first
[ ] Text does not overlap or overflow

Verification:
[ ] Re-read matching section in NEXLAB_AGENT_FIRST_REBUILD_PLAN.md
[ ] Re-read matching section in AGENTS_ARCHITECTURE_DESIGN.md
[ ] Run relevant tests or note why not run
```

---

## 16. Expert Implementation Notes

- Build thin vertical slices first: command endpoint, one route, one workflow, one confirmation.
- Do not build visible subagent dashboards.
- Do not delete old dashboard pages until equivalent agent workflows are working.
- Prefer deterministic routing in V1; add deeper autonomous planning later.
- Keep generated artifacts structured so frontend can render drafts, images, schedule previews, and CSV previews predictably.
- Treat confirmations as first-class backend state, not only frontend modals.
- Keep frontend API simple: message in, clean Main Agent response out.
- Use existing OAuth, media, post, scheduler, analytics, and autopilot services wherever possible.
