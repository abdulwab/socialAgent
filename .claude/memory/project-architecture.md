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

Domain agents are implemented as LangGraph nodes/subgraphs: Connection, Content
Strategy, Copywriting, Image Generation, Media, Scheduling, Publishing, Analytics,
Autopilot, Safety And Review, and Web Search.

The class-based custom agent runtime has been removed. Do not recreate the old custom
orchestrator, class registry, planner runtime, tool registry, or manual state store.

Repositories: root plans/instructions, `fb_dash` frontend, `fb_agent` backend.
