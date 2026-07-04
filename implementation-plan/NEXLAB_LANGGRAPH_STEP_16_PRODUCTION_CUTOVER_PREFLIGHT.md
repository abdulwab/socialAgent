# Step 16 Evidence - Production Cutover Preflight

Date: 2026-07-04  
Status: BLOCKED - DEPLOYMENT AND STEP 15 OBSERVATION APPROVAL REQUIRED

## Completed preflight

- Verified root, frontend, and backend repositories were clean before preflight.
- Re-read the approved SCP/server-side Docker deployment and rollback workflow.
- Confirmed no migration is required for Steps 12 through 16.
- Built local candidate image:

```text
socialhub-backend:step16-preflight
```

- Started an isolated local container with LangGraph internal-canary configuration.
- Verified:
  - `/health`;
  - agent route loading;
  - thread OpenAPI routes;
  - container startup logs;
  - local full backend regression.

## Preflight defect found and fixed

The first Python 3.11 container loaded `/health` but omitted all agent routes with:

```text
'function' object is not subscriptable
```

Cause: Python 3.11 eagerly evaluated class annotations after a method named `list`,
shadowing the built-in generic in memory/thread services. Local development uses Python
3.14 and did not reproduce it.

Fix:

- enabled postponed annotation evaluation in:
  - `app/agent_graph/memory_store.py`;
  - `app/agent_graph/thread_service.py`.

Rebuilt candidate result:

```text
Agent routes loaded successfully
/health = ok
/api/v1/agent/threads = present
/api/v1/agent/threads/{thread_id}/commands = present
/api/v1/agent/threads/{thread_id}/resume = present
/api/v1/agent/threads/{thread_id}/stream = present
```

Full backend regression after the compatibility fix:

```text
244 passed, 1 skipped
```

The isolated local container was stopped and removed after verification.

## Required authorization before production mutation

Production deployment has not occurred. Before proceeding, the rollout owner must
explicitly authorize:

1. SCP transfer to `ubuntu@3.109.208.88:/home/ubuntu/fb_agent/`.
2. A uniquely tagged candidate build on EC2.
3. Controlled edit of rollout-only keys in `/home/ubuntu/fb_agent/.env` without reading,
   printing, downloading, or replacing existing secrets.
4. Restart of `socialhub-api` using the approved Docker workflow.
5. Internal canary user IDs.
6. The Step 15 thresholds and minimum 24-hour observation window.
7. A deployed rollback rehearsal using `LANGGRAPH_ROLLBACK=true`.

## Proposed initial production state

Production should start in safe shadow mode, not full cutover:

```text
LANGGRAPH_ENABLED=true
LANGGRAPH_ROLLOUT_MODE=shadow
LANGGRAPH_CANARY_PERCENT=0
LANGGRAPH_ROLLBACK=false
```

After a clean shadow observation window:

```text
LANGGRAPH_ROLLOUT_MODE=internal
LANGGRAPH_INTERNAL_USER_IDS=<approved IDs>
```

Only after internal acceptance and rollback rehearsal:

```text
LANGGRAPH_ROLLOUT_MODE=cohort
LANGGRAPH_CANARY_PERCENT=5
```

The legacy fallback remains available throughout.

## Current decision

BLOCKED. Local production-image readiness passed, but Step 15 has not completed its live
observation window and explicit production deployment/env/restart approval has not been
granted.
