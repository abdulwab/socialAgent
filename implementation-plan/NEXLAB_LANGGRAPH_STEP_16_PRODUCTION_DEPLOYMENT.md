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

## Routing correction and fresh observation — 2026-07-07

The first 11-sample report failed the routing threshold at `63.6%`. Mismatches were
concentrated in common Product Help, token-health, and draft/caption wording. The failed
report was preserved as:

```text
/home/ubuntu/fb_agent/.langgraph/shadow-reports-pre-e746708-20260707.jsonl
```

Backend commit `e746708` added deterministic coverage for those production phrases.
Focused routing/shadow tests passed (`25 passed`) and the full backend suite passed
(`251 passed, 1 skipped`).

Deployment verification:

- image: `socialhub-backend:routing-e746708`;
- rollback image: `socialhub-backend:rollback-pre-routing-e746708`;
- health: passing internally and publicly;
- migration: `c3d4e5f6a7b8 (head)`;
- rollout: enabled, shadow, 0% canary, rollback false;
- startup: application, agent routes, and scheduler healthy;
- fresh report: `0/20` samples;
- old report: preserved with all 11 records.

The observation clock and 20-sample threshold restart from the first genuine safe
request against this routing release.

### First post-fix batch

Ten authenticated safe commands were submitted against `e746708`.

- sample count: `10/20`;
- route match: `100%`;
- artifact fingerprint match: `100%`;
- confirmation mismatches: `0`;
- shadow errors: `0`;
- covered connection, analytics, copywriting, content strategy, and product help.

Manual answer review also found three legacy-authoritative quality issues that the
numeric routing report does not measure:

- token-health returned generic navigation guidance instead of verified health;
- two analytics answers contradicted each other about Instagram connectivity;
- one content-strategy request returned a temporary Z.AI availability error.

These findings do not invalidate the routing comparison, but they are mandatory
internal-canary acceptance cases. Step 16 cannot pass solely from the numeric shadow
summary.

### Grounded-response quality deployment

Backend commit `7c8f773` was deployed as
`socialhub-backend:quality-7c8f773`.

- Token-health replies now use verified owned connection state and never ask the LLM
  to infer token status.
- Analytics status/connectivity output is deterministic and database-grounded.
- Content strategy returns a safe degraded starter plan when Z.AI is temporarily
  unavailable.
- Assistant-ui thread/composer hierarchy and controls were repaired in frontend
  commits `1735230` and `fc8c07d`, deployed through GitHub/Vercel.
- Backend regression: `253 passed, 1 skipped`.
- Frontend regression: lint/build and `12/12` tests passed.
- Previous backend image retained as
  `socialhub-backend:rollback-pre-quality-7c8f773`.
- Health, migration, startup, scheduler, and rollout configuration passed.
- The active report was preserved and contains `11/20` passing samples with `100%`
  route/artifact/confirmation agreement and zero shadow errors.

### Tester-specific thread preview

The initial assistant-ui integration did not include a visible conversation rail, and
global shadow mode correctly forced all users through the legacy fallback. That made
the production screen appear unchanged even though primitives were installed.

The corrective preview adds:

- visible New Chat and backend-owned conversation history;
- thread selection/hydration and URL state;
- assistant-ui Thread/Message/Composer primitives around the complete conversation;
- an explicit shadow-mode exception for internal user IDs only.

Frontend commit `15f2653` was pushed through GitHub/Vercel. Backend commit `2e90a9d`
was deployed as `socialhub-backend:preview-2e90a9d`.

Only the active Clerk-linked tester row (`user_id=8`) is in
`LANGGRAPH_INTERNAL_USER_IDS`. Verification proved user 8 is allowed and a non-listed
user receives 404. Global mode remains shadow, canary remains 0%, rollback remains
false, and the existing `11/20` report is preserved.

### User-directed global assistant workspace cutover

The rollout owner explicitly required the complete assistant workspace for every
logged-in user rather than the legacy shadow fallback. This superseded the remaining
20-sample shadow UI gate; the historical 11-sample report remains preserved for audit.

Backend commit `864ad66` and frontend commit `996d2a8` provide:

- global authenticated LangGraph thread access;
- responsive dark conversation sidebar and mobile drawer;
- New Chat, persistent history, switching, URL hydration;
- owned rename and delete with confirmation;
- modern neutral/emerald message and composer styling;
- retained SocialHub account, connection, asset, CSV, voice, and approval controls.

Production state:

- image: `socialhub-backend:full-864ad66`;
- rollout: enabled, `full`, rollback false;
- rollback image: `socialhub-backend:rollback-pre-full-864ad66`;
- migration: `c3d4e5f6a7b8 (head)`;
- user 8 and a non-internal user both passed the global access gate;
- OpenAPI exposes GET/PATCH/DELETE thread lifecycle methods;
- PostgreSQL create/rename/delete probe passed and was cleaned up;
- health, agent routes, scheduler, logs, and resources passed.

Automated gates: backend `255 passed, 1 skipped`; frontend lint/build and `14/14`
tests. Manual logged-in responsive and lifecycle acceptance remains required before
Step 16 can be marked PASS.
