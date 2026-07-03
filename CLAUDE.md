# SocialHub Coding-Agent Context

## Product and Target

NexLab SocialHub is a multi-user social-media platform. `/agent` is the primary
authenticated experience and users see only Main Agent.

Target architecture:

- LangGraph runtime with eleven hidden domain-agent nodes/subgraphs
- existing business/platform services wrapped as typed tools
- PostgreSQL checkpoints for user-specific threads and resumable workflows
- scoped persistent memory for safe user and brand context
- code-enforced confirmation interrupts for risky actions
- one backend Z.AI GLM gateway
- custom Next.js frontend using `assistant-ui` primitives and typed SSE

Authoritative documents:

- `implementation-plan/NEXLAB_LANGGRAPH_FULL_REBUILD_PLAN.md`
- `implementation-plan/NEXLAB_LANGGRAPH_TEST_GATED_EXECUTION_CHECKLIST.md`
- `implementation-plan/NEXLAB_LANGGRAPH_LEGACY_AUDIT.md`
- `AGENTS_ARCHITECTURE_DESIGN.md`

Execute one checklist gate at a time. Do not delete legacy behavior before its
replacement passes tests, canary, production observation, and deletion approval.

## Repository Boundaries

- Root: instructions, architecture, plans, coding-agent memory
- `fb_dash/`: frontend nested repository
- `fb_agent/`: backend nested repository

A root commit does not include nested repositories.

## User Isolation

The verified Clerk JWT determines `user_id`. Never authorize with a client-provided ID.
Every thread, checkpoint, memory, artifact, confirmation, connected account, page,
schedule, analytics query, and tool call must validate ownership.

Never put tokens, cookies, passwords, API keys, authorization headers, DB sessions, ORM
objects, or service clients into prompts, graph state, checkpoints, memory, traces, SSE,
or user-visible responses.

## Safety and Protected Changes

Publishing, scheduling, deletion, disconnect, bulk retry, draft overwrite, and
autopilot mutations require explicit one-time confirmation.

Dependencies, migrations, production schema/data, OAuth redirect URIs, production CORS,
secrets, deployment, and final legacy deletion require explicit approval.

## Backend

- FastAPI, SQLAlchemy, Alembic, PostgreSQL, APScheduler
- current legacy runtime: `fb_agent/app/agents/`
- target runtime: `fb_agent/app/agent_graph/`
- LLM gateway: `fb_agent/app/services/agent_llm_gateway.py`
- model policy: `fb_agent/app/config/glm_models.json`
- API prefix: `/api/v1/`; health: `/health`

Backend changes are never pushed to GitHub. Production uses approved SCP transfer and
Docker rebuild with container `socialhub-api` and
`/home/ubuntu/fb_agent/.env`.

## Frontend

- Next.js 16, React 19, TypeScript, Tailwind 4, Redux Toolkit, Clerk
- primary UI: `fb_dash/app/agent/`
- API client: `fb_dash/lib/apiManager.ts`
- API base: `/api/proxy/api/v1`

The backend will become authoritative for threads, history, artifacts, memories, and
confirmations.

## Verification

```powershell
cd fb_agent
$env:DATABASE_URL="sqlite:///./test_local.db"
pytest

cd ..\fb_dash
npm run lint
npm run build
npm test
```

Run targeted tests first, proportional regressions second, and stop on failure.
