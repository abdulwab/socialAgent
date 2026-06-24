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
- `CLAUDE.md`

When implementing the agent-first rebuild, always re-check the matching sections in the first two source docs and use the combined plan as the execution checklist.

## Repository Layout

Root workspace:

```txt
socialhub/
  fb_dash/                  # Frontend: Next.js, React, TypeScript, Tailwind, Redux Toolkit
  fb_agent/                 # Backend: FastAPI, SQLAlchemy, Alembic, APScheduler
  implementation-plan/      # Planning docs
  AGENTS_ARCHITECTURE_DESIGN.md
  CLAUDE.md
  PRODUCT_PLAN.md
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

Note: The AWS deployment guide contains a GitHub pull workflow and an older `/home/ubuntu/.env` path. The latest working deployment uses SCP to `/home/ubuntu/fb_agent/`, server-side Docker rebuild, and `/home/ubuntu/fb_agent/.env`. Do not use backend GitHub push. Be careful with any server-side `git pull` flow because local backend changes will not be on GitHub.

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

Future agent architecture should use backend OpenRouter gateway:

```txt
fb_agent/app/services/agent_llm_gateway.py
```

Rules:

- `OPENROUTER_API_KEY` belongs in backend/server environment only.
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

For the agent-first rebuild, follow this order:

1. Backend agent foundation
2. OpenRouter LLM gateway
3. `/api/v1/agent/command`
4. Frontend `/agent` route
5. Auth redirects to `/agent`
6. Core workflows: connection, copywriting, scheduling, safety
7. Creative/media/web-search/CSV workflows
8. Voice command
9. Analytics, publishing, autopilot
10. Hide/remove old user-facing dashboard navigation
11. Memory, audit, observability
12. Testing and production polish

After each implementation step, re-check:

- `implementation-plan/NEXLAB_AGENT_FIRST_REBUILD_PLAN.md`
- `AGENTS_ARCHITECTURE_DESIGN.md`
- `implementation-plan/NEXLAB_AGENT_FIRST_COMBINED_IMPLEMENTATION_PLAN.md`

## Current Implementation State

Last updated by Codex: 2026-06-23.

Completed initial vertical slice:

- Backend internal agent package added under `fb_agent/app/agents/`.
- Backend agent route added at `POST /api/v1/agent/command`.
- Backend confirmation route added at `POST /api/v1/agent/confirm`.
- OpenRouter-only backend gateway scaffold added at `fb_agent/app/services/agent_llm_gateway.py`.
- Hidden agents are backend-only and return structured data.
- V1 workflow and confirmation state use in-memory storage to avoid DB migrations.
- `/agent` frontend route added under `fb_dash/app/agent/`.
- `/agent` uses its own Agent UI and does not depend on old Sidebar.
- Connect Apps dropdown added inside `/agent` top bar.
- Composer supports text and browser voice input fallback.
- Generated assets panel and confirmation modal added.
- Login, signup, Google auth, landing authenticated CTA, and social OAuth callback returns now route users to `/agent`.

Important caveats:

- Old dashboard pages and route redirect stubs have been removed after user approval.
- Old prompt/provider settings have been removed from frontend, backend model/schema/routes, and production DB through Alembic migration.
- Frontend old route stub deletion was pushed to `abdulwab/fb_dash` main as commit `13929d3`.
- Persistent agent DB workflow/run/artifact/confirmation/memory tables are implemented with migration `a9b7c6d5e4f3_add_agent_workflow_memory_tables.py`.
- Agent workflow state, hidden agent runs, artifacts, confirmations, and safe memories are DB-backed. Normal UI still shows only clean Main Agent output.
- Production DB is stamped at `a9b7c6d5e4f3`; `agent_workflows`, `agent_runs`, `agent_artifacts`, `agent_confirmations`, and `agent_memories` exist.
- Backend Docker deployment was performed on 2026-06-23 using SCP to `ubuntu@3.109.208.88:/home/ubuntu/fb_agent/`, server-side `docker build -t socialhub-backend .`, and container restart with `--env-file /home/ubuntu/fb_agent/.env`.
- Backend deployment verification passed: `/health` returned `{"status":"ok","message":"API is running"}`, and OpenAPI exposed `/api/v1/agent/command` plus `/api/v1/agent/csv-preview`.
- Frontend changes were committed and pushed to `abdulwab/fb_dash` main with commit `181521a` (`feat: add agent-first command center`).
- Added practical second slice after initial foundation: CSV preview endpoint/UI, real image service hook in Image Generation Agent, and DB-backed lightweight Analytics Agent summary.
- Full frontend `npm run lint` passes with clean output.
- Frontend `npm run build` passes.
- Frontend `npm test` passes: 2 suites / 14 tests.
- Frontend lint/test stabilization was committed and pushed to `abdulwab/fb_dash` main with commit `b0bc943` (`chore: stabilize frontend checks`).
- Legacy lint warning baseline cleanup was committed and pushed to `abdulwab/fb_dash` main with commit `c295fbf` (`chore: silence legacy lint warnings`).
- Agent workflow UI completion was committed and pushed to `abdulwab/fb_dash` main with commit `88df17d` (`feat: complete agent workflow UI`).
- Backend new agent files compile with `.venv\Scripts\python.exe -m compileall`.
- Full backend pytest passes with local `DATABASE_URL=sqlite:///./test_local.db`: 68 tests passed.
- Backend Docker was redeployed after test fixes on 2026-06-23. Verification passed: `/health` OK, OpenAPI exposed `/api/v1/agent/command` and `/api/v1/agent/csv-preview`, and `socialhub-api` container was running from `socialhub-backend`.
- Backend Docker was redeployed again on 2026-06-23 after completing V1 workflow execution. Verification passed: `/health` OK, OpenAPI exposed `/api/v1/agent/command`, `/confirm`, `/csv-preview`, and `/csv-schedule`, and `socialhub-api` was running.
- V1 agent confirmation now executes real scheduling into `scheduled_posts`, CSV valid-row scheduling, direct publish attempts through existing platform services, and autopilot enable/config updates through existing `autopilot_configs`.
- Agent command context now carries previous drafts/images from the frontend so follow-up commands like "schedule this post tomorrow at 10 AM" use the existing draft instead of generating a new one.
- After user validation, old dashboard UI pages were removed from the active frontend experience on 2026-06-23. Heavy legacy page/component code was deleted, and old route stubs were later deleted too, so old dashboard URLs may return 404.

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
