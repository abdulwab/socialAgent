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

Execute one checklist gate at a time. The custom pre-LangGraph agent runtime has been
approved for removal; do not reintroduce compatibility command/confirm adapters.

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
- authoritative runtime: `fb_agent/app/agent_graph/`
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

The backend is authoritative for threads, history, artifacts, memories, and
confirmations. React must not send authoritative conversation/artifact context.

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


<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:6cd5cc61 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking - do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge - do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status

   # Team-maintainer opt-in only, unless current instructions forbid it:
   git pull --rebase
   git push
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**
- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.
<!-- END BEADS INTEGRATION -->
