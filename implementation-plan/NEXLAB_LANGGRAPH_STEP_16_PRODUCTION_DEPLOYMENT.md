# Step 16 — Production Deployment and Observation Evidence

Date: 2026-07-04  
Status: **OBSERVATION IN PROGRESS — NOT YET PASS**

## Deployment

- AWS account access and running EC2 instance `i-0fd8932a0eb58b985` were verified.
- Backend was transferred by the approved SCP workflow. The backend repository was
  not pushed.
- Current production image:
  `socialhub-backend:step16-shadow-20260704`.
- Container: `socialhub-api`, restart policy `always`, port `8000`.
- Previous production image is retained as
  `socialhub-backend:rollback-pre-step16-20260704`.
- Persistent non-secret rollout reports are mounted from
  `/home/ubuntu/fb_agent/.langgraph` to `/app/.langgraph`.
- Production rollout state:
  `enabled=true`, `mode=shadow`, `canary=0`, `rollback=false`.
- Container start / observation timestamp:
  `2026-07-04T01:03:26Z`.

## Release gates

- Local full backend regression before deployment: `244 passed, 1 skipped`.
- PostgreSQL wiring regression after the production finding:
  `245 passed, 1 skipped`.
- Final shadow-authority regression: `246 passed, 1 skipped`.
- Python compile, `git diff --check`, Python 3.11 Docker build, isolated `/health`,
  startup logs, and all five thread OpenAPI paths passed.
- Public production `/health` returned `ok`.
- Unauthenticated thread request returned `401`.
- Scheduler, agent routes, and application startup completed without a startup
  traceback.

## Production findings fixed during acceptance

### PostgreSQL checkpointer was not wired into the thread service

The official PostgreSQL adapter and migration existed, but the production dependency
still created `DevelopmentThreadService` with SQLite. The rollout switch was activated
before continuing.

Fix:

- backend commit `336b250` selects the pooled PostgreSQL saver for PostgreSQL
  `DATABASE_URL` values while preserving SQLite for local development;
- a factory regression test proves the production selection and lifecycle;
- a production probe reported `PostgresSaver`, wrote three checkpoint rows, resumed
  the same thread, and removed the synthetic probe afterward.

### Shadow traffic could bypass the comparator

The comparison report is written by the legacy authoritative `/agent/command` route,
but shadow mode exposed `/threads`, allowing the frontend to bypass that route.

Fix:

- backend commit `22cf970` hides thread endpoints during shadow mode;
- the existing frontend fallback uses legacy command/confirm;
- safe legacy requests remain authoritative and produce LangGraph comparisons;
- mutation commands remain excluded from shadow duplication.

## Database

- Before deployment: `b4e8f1a9c2d3`.
- Applied the previously approved additive checkpoint migration.
- Current production revision: `c3d4e5f6a7b8 (head)`.
- No product, workflow, artifact, audit, or historical migration data was removed.

## Rollback rehearsal

- `LANGGRAPH_ROLLBACK=true` was applied and loaded by a recreated production
  container.
- Health remained available and the legacy frontend fallback remained the intended
  path.
- The flag was restored to `false` after PostgreSQL checkpoint verification.
- The prior production image and current migration data remain available. Database
  downgrade was intentionally not performed.

## Infrastructure note

The first EC2 candidate build stopped before restart because the 6.8 GB root disk was
full. The live container remained healthy. Only stopped build residue and obsolete,
unused test/June backup images were removed; the current and previous production
rollback generations were retained. The final deployment completed with roughly
1.6 GB free.

## Observation gate

The minimum observation period is 24 hours and the configured minimum is 20 safe
comparison samples. Initial report state is correctly not ready with zero samples.
Do not move to internal or cohort mode until:

- at least 24 hours have elapsed;
- at least 20 safe production comparisons exist;
- routing/artifact/confirmation/error/latency thresholds pass;
- one real Clerk-authenticated legacy fallback command is manually verified;
- an authenticated internal user is selected for the next canary phase.

Step 16 and Step 17 must remain incomplete until this gate passes.

## Observation checkpoint — 2026-07-07

- Public and instance-local `/health`: passing.
- Container: zero restarts since `2026-07-04T01:03:26Z`.
- Image, migration, shadow mode, 0% canary, and rollback state remain correct.
- Root disk: approximately 1.6 GB free.
- Persistent report contains one authenticated safe comparison.
- First/last sample: `2026-07-06T17:17:08Z`.
- Route match: `100%`.
- Artifact match: `100%`.
- Confirmation mismatches: `0`.
- Shadow errors: `0`.
- The authenticated fallback acceptance requirement is satisfied by this production
  sample.
- Readiness remains false because 20 samples and 24 hours between the first and last
  samples are required. Nineteen additional genuine safe requests remain, and a final
  qualifying sample cannot be earlier than `2026-07-07T17:17:08Z`.

No synthetic production traffic was generated to inflate the rollout report. Internal
canary and Step 17 deletion remain blocked.
