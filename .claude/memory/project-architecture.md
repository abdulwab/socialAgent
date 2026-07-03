# Project Architecture

SocialHub is multi-user and agent-first. Users see one Main Agent at `/agent`.

```text
Next.js /agent
  -> authenticated FastAPI thread API
  -> LangGraph Main Graph
  -> hidden domain subgraphs
  -> typed service tools
  -> safety/confirmation interrupt
  -> idempotent execution
```

Domain agents: Connection, Content Strategy, Copywriting, Image Generation, Media,
Scheduling, Publishing, Analytics, Autopilot, Safety And Review, Web Search.

The class-based `fb_agent/app/agents/` runtime is temporary baseline code. Migrate one
test gate at a time and remove it only after production parity.

Repositories: root plans/instructions, `fb_dash` frontend, `fb_agent` backend.

