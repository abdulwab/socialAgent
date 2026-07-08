# SocialHub Project Instructions For Codex

## Project Identity

SocialHub / NexLab SocialHub is an AI-powered social media management platform for creating, scheduling, publishing, and analyzing posts across Facebook, Instagram, LinkedIn, and X.

The current strategic direction is an agent-first rebuild:

- The user should primarily interact with one visible Main Agent.
- Backend hidden agents/services should handle specialized work behind the scenes.
- `/agent` is the primary logged-in experience.
- Old dashboard route stubs were intentionally removed after user approval; old dashboard URLs may return 404 instead of redirecting.
- Old prompt/provider settings were intentionally removed. Do not reintroduce user-level `system_prompt`, `gemini_api_key`, `openrouter_api_key`, `claude_api_key`, or `active_provider` fields.

Important planning docs:

- `implementation-plan/NEXLAB_AGENT_FIRST_REBUILD_PLAN.md`
- `AGENTS_ARCHITECTURE_DESIGN.md`
- `implementation-plan/NEXLAB_AGENT_FIRST_COMBINED_IMPLEMENTATION_PLAN.md`
- `implementation-plan/NEXLAB_LANGGRAPH_FULL_REBUILD_PLAN.md`
- `implementation-plan/NEXLAB_LANGGRAPH_TEST_GATED_EXECUTION_CHECKLIST.md`
- `CLAUDE.md`

When implementing the LangGraph rebuild, use the LangGraph full rebuild plan as the
target architecture and the test-gated checklist as the execution authority. Re-check
the older agent-first source docs for product requirements that have not yet been
consolidated.

## Repository Layout

Root workspace:

```txt
socialhub/
  fb_dash/                  # Frontend: Next.js, React, TypeScript, Tailwind, Redux Toolkit
  fb_agent/                 # Backend: FastAPI, SQLAlchemy, Alembic, APScheduler
  implementation-plan/      # Planning docs
  AGENTS_ARCHITECTURE_DESIGN.md
  CLAUDE.md
```

There are nested git repositories:

- Root repo: `https://github.com/abdulwab/socialAgent.git`
- Frontend repo: `https://github.com/abdulwab/fb_dash.git`
- Backend repo: `https://github.com/abdulwab/fb_agent.git`

Do not assume a root commit includes frontend/backend nested repo changes. Work from the relevant folder.

## Critical Deployment Rules

### Backend

Backend code lives in:

```txt
fb_agent/
```

Hard rule from user:

```txt
Backend change = Docker deploy only, no GitHub push.
```

For backend work:

- Do not push backend changes to GitHub.
- Do not run `git push` from `fb_agent/`.
- Do not tell the user backend changes have been pushed.
- Backend production updates must be deployed through Docker/EC2.
- If deployment is requested and the exact server transfer method is not available, ask for the approved Docker deploy method before proceeding.
- If using EC2 commands, use the Docker container name from the deployment guide: `socialhub-api`.
- Backend environment lives on the server via `/home/ubuntu/fb_agent/.env`; do not edit or expose secrets unless user explicitly asks.

Known backend Docker commands from `fb_agent/AWS-DEPLOY-GUIDE.md`:

```bash
sudo docker stop socialhub-api
sudo docker rm socialhub-api
sudo docker build -t socialhub-backend .
sudo docker run -d \
  --name socialhub-api \
  --restart always \
  -p 8000:8000 \
  --env-file /home/ubuntu/fb_agent/.env \
  socialhub-backend
```

Verification commands:

```bash
sudo docker ps
sudo docker logs socialhub-api
curl http://localhost:8000/health
```

When backend model/schema changes require DB changes, add an Alembic migration and apply it inside the deployed Docker container. The prompt/provider cleanup migration is:

```txt
fb_agent/migrations/versions/f2c9d8e1a7b4_remove_user_prompt_provider_fields.py
```

Production DB status after the cleanup: old `users` prompt/provider columns are absent and `alembic_version` is stamped at `f2c9d8e1a7b4`.

The AWS deployment guide now documents the approved SCP to
`/home/ubuntu/fb_agent/`, server-side Docker rebuild, and
`/home/ubuntu/fb_agent/.env` workflow. Do not use backend GitHub push or server-side
GitHub pull.

### Frontend

Frontend code lives in:

```txt
fb_dash/
```

Frontend remote:

```txt
https://github.com/abdulwab/fb_dash.git
```

Frontend deployment is through the frontend GitHub/Vercel flow unless the user says otherwise.

Before pushing frontend changes:

```powershell
cd fb_dash
npm run lint
npm run build
```

Only push frontend changes from inside `fb_dash/`, not from root.

### Root Docs / Plans

Root-level planning and instruction files belong to the root repo:

```txt
https://github.com/abdulwab/socialAgent.git
```

Examples:

- `AGENTS.md`
- `CLAUDE.md`
- `AGENTS_ARCHITECTURE_DESIGN.md`
- `implementation-plan/*.md`

Do not mix root docs commits with frontend/backend code unless user explicitly asks.

## Backend Technical Notes

Backend stack:

- FastAPI
- SQLAlchemy
- Alembic
- Pydantic
- APScheduler
- PostgreSQL in production
- SQLite/local DB for development or demo
- Cloudinary media support

Important backend paths:

```txt
fb_agent/app/main.py
fb_agent/app/api/v1/
fb_agent/app/services/
fb_agent/app/db/
fb_agent/app/schemas/
fb_agent/app/core/
fb_agent/migrations/
fb_agent/requirements.txt
```

API pattern:

- Routes start with `/api/v1/`.
- JWT auth uses `Authorization: Bearer <token>`.
- Scheduler runs background scheduled-post execution.
- Health endpoint is `/health`.

Common backend task flow:

1. Add route file in `fb_agent/app/api/v1/`.
2. Add or reuse Pydantic schemas.
3. Put business logic in services or CRUD helpers.
4. Register router in `fb_agent/app/main.py`.
5. Test locally where possible.
6. Deploy through Docker only when user requests deployment.

Backend verification:

```powershell
cd fb_agent
pytest
```

If tests are absent or incomplete, run the most relevant targeted checks and report what was not covered.

## Frontend Technical Notes

Frontend stack:

- Next.js 16
- React 19
- TypeScript
- Tailwind CSS 4
- Redux Toolkit
- lucide-react icons

Important frontend paths:

```txt
fb_dash/app/
fb_dash/lib/apiManager.ts
fb_dash/lib/features/agentSlice.ts
fb_dash/lib/store.ts
fb_dash/lib/hooks.ts
fb_dash/package.json
```

Current API base:

```ts
const API_BASE_URL = "/api/proxy/api/v1";
```

Common frontend task flow:

1. Add page under `fb_dash/app/<route>/page.tsx`.
2. Add components near the route or existing component pattern.
3. Add API method to `fb_dash/lib/apiManager.ts`.
4. Add Redux state/thunks if needed.
5. Use Tailwind utilities and `lucide-react`.
6. Run lint/build before final when practical.

Frontend verification:

```powershell
cd fb_dash
npm run lint
npm run build
npm test
```

## Agent-First Rebuild Rules

Non-negotiable product rules:

- User sees only Main Agent.
- Hidden agents are backend/internal services only.
- Do not show subagent names in normal UI.
- Do not show raw logs, internal routing, model names, or tool traces in normal UI.
- Do not build a visible `SubagentsPanel`.
- Use generic progress wording such as:
  - `Working...`
  - `Creating drafts...`
  - `Generating image...`
  - `Checking before scheduling...`
  - `Ready for confirmation`
- Risky actions require confirmation before execution.
- OAuth is required for social connections. Never collect social media usernames/passwords.
- LLM API keys and provider/model settings must be backend-owned, not user-facing in the final agent product.

Risky actions requiring confirmation:

- publish now
- schedule posts
- bulk schedule / CSV scheduling
- delete posts
- delete media/generated images
- disconnect social app
- enable/disable autopilot
- change autopilot frequency or schedule
- bulk retry failed posts
- overwrite drafts

Safe actions that usually do not need confirmation:

- generate content
- generate image preview
- summarize analytics
- check connected apps
- inspect token status
- show queue/preview

## Agent Architecture Direction

Main Agent / Orchestrator responsibilities:

- receive user command
- detect input mode: text, voice, CSV, media upload
- classify intent
- create workflow plan
- call hidden agents through structured contracts
- own context and sequencing
- run safety review
- return clean user-visible response
- ask for confirmation when needed

Hidden agents:

- Connection Agent
- Content Strategy Agent
- Copywriting Agent
- Image Generation Agent
- Media Agent
- Scheduling Agent
- Publishing Agent
- Analytics Agent
- Autopilot Agent
- Safety And Review Agent
- Web Search Agent

Agents should communicate through Main Agent:

```txt
User -> Main Agent -> Hidden Agent -> Main Agent -> User
```

Avoid uncontrolled direct chains:

```txt
Agent A -> Agent B -> Agent C
```

Use structured JSON request/response contracts. Keep internal traces server-side.

## LLM And Secrets Policy

Agent architecture uses exactly one backend Z.AI GLM gateway:

```txt
fb_agent/app/services/agent_llm_gateway.py
```

Rules:

- `ZAI_API_KEY` and `ZAI_BASE_URL` belong in the backend/server `.env`.
- Agent model, fallback, thinking, temperature, and token settings belong in
  `fb_agent/app/config/glm_models.json`.
- OpenRouter and other provider gateways must not be reintroduced.
- Agent source files must not hardcode model IDs, fallbacks, thinking, or token limits.
- Frontend must never receive or send LLM API keys.
- Do not pass OAuth tokens, refresh tokens, cookies, passwords, payment details, or API secrets into LLM prompts.
- User-facing final agent UI should not expose API key inputs, provider selectors, or model selectors.

## Database And Migration Rules

Database schema changes are sensitive.

Before doing any of these, ask the user for explicit confirmation:

- editing DB models in a way that requires migration
- running `alembic revision`
- running `alembic upgrade`
- altering production schema
- changing existing production data

Never run destructive DB commands without explicit approval.

## Protected Files And Actions

Do not touch without explicit permission:

- `.env`
- secret files
- production credentials
- OAuth redirect URI settings
- CORS production origins
- `requirements.txt`
- `package.json`
- lockfiles, unless dependency work is explicitly requested
- database migrations
- production deployment

Do not run destructive commands such as:

- `git reset --hard`
- deleting user files
- dropping DB tables
- force-pushing branches

## Coding Style

General:

- Prefer existing project patterns.
- Keep changes scoped.
- Do not refactor unrelated code.
- Use `rg` for search.
- Use `apply_patch` for manual edits.
- Do not revert user changes.
- Explain the problem first, then code.
- For small fixes, be concise and direct.

Frontend:

- Functional React components with hooks.
- TypeScript strictness matters.
- Redux Toolkit async thunks for API flows.
- Tailwind utility classes.
- Use `lucide-react` icons where appropriate.
- Avoid inline styles unless there is a strong reason.
- Make mobile layout usable and text non-overlapping.

Backend:

- FastAPI dependencies with `Depends`.
- SQLAlchemy sessions through `Depends(get_db)`.
- Pydantic schemas for request/response validation.
- Keep business logic in services where possible.
- Use async routes where they fit the existing pattern.

Comments:

- Add Roman Urdu comments only where helpful for non-obvious logic.
- Avoid noisy comments that restate the code.

## User Communication Preferences

User prefers Urdu + English mix / Roman Urdu.

Working style:

- Start new work with a short explanation of what you are about to do.
- Explain the problem before the code.
- Ask before breaking changes.
- Ask when something is genuinely unclear and risky.
- For small fixes, do the work directly and keep explanation short.
- Keep final answers practical and not too long.

## Current Strategic Implementation Order

The active runtime direction is LangGraph-only. Follow the test-gated LangGraph
checklist and do not recreate the removed custom agent runtime.

Active sequence:

1. Keep `/agent` as the primary logged-in experience.
2. Keep backend thread APIs authoritative for conversation state, artifacts, memory,
   approvals, and SSE.
3. Keep existing OAuth/platform/scheduler/business services as typed LangGraph tools.
4. Preserve the custom SocialHub assistant-ui frontend.
5. Remove only dead or contradictory old code/docs after replacement tests pass.

After each implementation step, re-check:

- `implementation-plan/NEXLAB_LANGGRAPH_FULL_REBUILD_PLAN.md`
- `implementation-plan/NEXLAB_LANGGRAPH_TEST_GATED_EXECUTION_CHECKLIST.md`
- `.CLAUDE/memory/`

## Current Implementation State

Last updated by Codex: 2026-07-08.

Active state:

- `/agent` is the primary authenticated experience for all logged-in users.
- The custom class-based agent runtime has been approved for deletion and must not be
  recreated.
- Backend agent execution is under `fb_agent/app/agent_graph/`.
- Agent APIs are thread based:
  - `GET/POST /api/v1/agent/threads`
  - `GET/PATCH/DELETE /api/v1/agent/threads/{thread_id}`
  - `POST /api/v1/agent/threads/{thread_id}/commands`
  - `POST /api/v1/agent/threads/{thread_id}/resume`
  - `GET /api/v1/agent/threads/{thread_id}/stream`
- CSV endpoints remain available as support APIs: `/api/v1/agent/csv-preview` and
  `/api/v1/agent/csv-schedule`.
- Frontend `/agent` uses assistant-ui primitives, a visible conversation rail, typed
  SSE, backend thread hydration, rename/delete/new chat controls, and backend-owned
  approvals.
- React must not send authoritative message history, generated artifacts, or hidden
  agent/tool state.
- Backend routing is LLM-first when `LANGGRAPH_LLM_UNDERSTANDING_ENABLED=True`:
  - every non-empty user command goes through
    `fb_agent/app/agent_graph/llm_understanding.py` and the backend Z.AI `main`
    model first;
  - LLM understanding returns strict JSON only and never executes tools directly;
  - deterministic validation remains the safety gate for all tool/subgraph routing.
- If LLM understanding fails or returns invalid output, the existing rule router is
  the fallback. Keep this fallback path tested. Tests may disable/mock LLM
  understanding to avoid real provider calls.
- Backend thread command handling owns durable draft/caption artifact memory:
  generated copywriting artifacts are stored with user/thread/platform/type metadata,
  reloaded from user-scoped memory, and resolved by backend artifact ID.
- Artifact references such as latest Instagram caption, latest LinkedIn draft,
  previous/past chat draft, this/jo/in captions, and platform-specific follow-ups
  must be resolved server-side. If multiple user-owned artifacts match, ask a
  clarification with options instead of guessing.
- Scheduling and edits must use resolved backend artifact IDs; frontend chat history
  or generated panel payloads are not authoritative context.
- Draft/caption edits use `fb_agent/app/agent_graph/artifact_editing.py`.
  Explicit user-added phrases from commands like `Add this line to the Instagram
  caption: ...` are protected phrases. They must be preserved across future
  improve/rewrite operations, should not become standalone final lines, and are
  recovered from thread history if artifact metadata is missing or stale.
- Draft/caption artifacts carry durable metadata: `user_id`, `thread_id`,
  `created_at`, `updated_at`, `parent_artifact_id`, `revision_number`, and
  bounded `revision_history`. Edits keep the active artifact ID for UI/scheduling
  compatibility while preserving prior content in revision history so improve/add
  operations do not silently lose earlier user-approved text.
- Pending clarification state is saved in thread working context. The next user answer
  resumes the original intent and must not fall back to the generic help reply.
- Pending risky tool proposals are saved in thread working context as
  `pending_action`. Follow-up questions such as "confirmation kaise doon?", "confirm",
  or "cancel karo" must use this short-term state instead of generic assistant chat.
  The reusable classifier/reply logic lives in
  `fb_agent/app/agent_graph/pending_actions.py`; do not add one-off phrase handling
  directly inside thread service.
- `connections.disconnect.v1` is now an approved mutation path: the connection
  subgraph creates a backend-owned approval envelope, the frontend shows the normal
  confirmation UI, and `ActionExecutionService` executes the disconnect only after a
  valid confirm resume with user ownership revalidation. After successful disconnect,
  backend artifacts return a platform-specific `connection_actions` connect CTA so
  the same app can be reconnected from chat. Connection CTA cards should also be
  attached to the assistant message that produced them, so they stay anchored in the
  original chat position instead of moving below later prompts. Other risky mutation
  tools remain behind their existing approval/dry-run policies unless explicitly
  changed.
- Connection verification prompts such as "is LinkedIn disconnected or not?",
  "verify LinkedIn connection status", or "confirm Facebook is connected" are safe
  read/status requests. They must route through the Connection Agent status path and
  DB-owned connection snapshot, not generic assistant chat and not mutation approval.
  Keep this as semantic intent handling, not one-off hardcoded sentence matching.
- Single backend Z.AI gateway remains at
  `fb_agent/app/services/agent_llm_gateway.py`; model policy remains in
  `fb_agent/app/config/glm_models.json`.
- Clerk JWT owns user identity; every thread, checkpoint, memory, artifact,
  confirmation, connected account, page, schedule, analytics query, and tool call must
  validate user ownership.
- Backend deploy remains Docker/SCP only; never push backend to GitHub.

## Final Checklist Before Reporting Done

For frontend work:

- Relevant files changed under `fb_dash/`.
- Lint/build/test run or skipped with reason.
- UI follows agent-first and responsive rules when applicable.
- Frontend push only if user asked or workflow requires it.

For backend work:

- Relevant files changed under `fb_agent/`.
- No backend GitHub push.
- Docker deployment only if user asked and deploy method is clear.
- Secrets untouched.
- Migration/dependency/CORS/OAuth changes confirmed first.
- Backend tests or targeted checks run where possible.

For docs/plans:

- Relevant root docs updated.
- No frontend/backend repo actions unless requested.
- Source docs kept consistent.
- LangGraph checklist status and test evidence updated after every implementation gate.
