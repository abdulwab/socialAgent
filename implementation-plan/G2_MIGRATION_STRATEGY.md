# G2.5 — Strangler migration and shadow strategy

Strategy document. **No runtime changes.** `main_routing.py` is not deleted by
this or any G4 bead except **G4.10**.

## The failure mode being avoided

SocialHub has already paid for running two runtimes side by side. A third —
legacy REST + old LangGraph routing + a new agent loop — would be worse than the
original defect. **No third permanent runtime is allowed.** Every step below is
shaped by that constraint: the new runtime is either off, or shadowing, or
serving a named scenario, and there is a written deletion trigger for the old one.

## The flag

```
AGENT_TASK_RUNTIME_MODE = off | shadow | canary | on
```

One setting, four states, default `off`. One flag rather than several because two
flags produce four combinations and only three are meaningful, and the fourth is
where a half-migrated state hides.

| Mode | Old routing | New runtime | Provider side effects |
|---|---|---|---|
| `off` | serves | not built | old only |
| `shadow` | serves | runs, **execution disabled** | old only |
| `canary` | serves | serves listed scenarios | whichever served |
| `on` | built but unreachable | serves | new only |

**The flag cannot re-enable known-insecure behaviour.** It selects between two
runtimes that both sit *behind* the G1 boundaries — identity from the verified
JWT, Policy, the credential store, the error boundary. It is not a security
switch, and the security gate's 18 invariants hold in every mode. Nothing removed
in G1A–G1D is reachable from any value of it. A test asserts the enum has exactly
these four members, so a fifth cannot be added without review.

## Shadow comparison that provably cannot double-execute

The rule: **in `shadow`, the new runtime is constructed with an Execution Engine
that has no provider adapters bound.** Not "an engine told not to execute" — an
engine that has nothing to execute with. A mutation attempt raises rather than
calls a provider.

```
request ─┬─► old routing ──► Policy ──► Execution ──► provider   (real)
         └─► new runtime ──► Policy ──► Execution(∅) ──► raises   (recorded)
                                          │
                                     comparison record
```

Three properties, each independently sufficient:

1. **Structural** — no adapter is bound, so there is no code path to a provider.
2. **Policy-level** — the shadow run carries a context flag Policy treats as
   never-approved, so consequential capabilities stop at the approval boundary.
3. **Idempotency-level** — if both runtimes somehow reached execution, they
   compute the *same* idempotency key from the same operation fingerprint, and
   the Execution Engine's effectively-once check collapses them.

Comparison records **decisions**, not outputs: capability chosen, arguments,
policy verdict, task graph shape, termination reason. Comparing generated text
would produce noise; comparing decisions catches the divergences that matter.

## The characterization net

**1,010 backend tests** are the safety net, not a formality. They are
characterization coverage for the current behaviour, and the migration rule is:
a scenario moves only when the new runtime passes the same tests, unchanged.

Tests are not rewritten to suit the new runtime. If a test must change, that is a
deliberate behaviour change requiring its own justification — the same standard
applied when `TestBug016ForgotPassword` was found asserting a vulnerability.

## Ordered scenario migration

Least consequential first, so the blast radius grows only after confidence does.

| # | Scenario | Why here |
|---|---|---|
| 1 | `assistant_chat`, `product_help` | no side effects, no provider, no approval |
| 2 | read-only retrieval (accounts, drafts, schedules) | reads only; exercises ownership scoping |
| 3 | analytics summary | reads only; exercises the first real tool chain |
| 4 | content strategy + copywriting | first A-list sub-agent; artifacts, no publish |
| 5 | image + media | external fetch; still no publish |
| 6 | artifact lifecycle (create/edit/delete drafts) | first DB mutations, low consequence |
| 7 | connection status + connect | first interaction type (`connection`) |
| 8 | scheduling | first approval-bearing capability |
| 9 | publishing | most consequential; last |
| 10 | multi-intent combinations | the reason the epic exists; needs 1–9 stable |

Scenario 10 is deliberately last: it is the one the current runtime cannot do,
so it has no characterization baseline to preserve.

## Deletion trigger for `main_routing.py`

`main_routing.py` may be deleted **only by G4.10**, and only when all of:

1. every scenario 1–10 is served by the new runtime in `on`;
2. the full backend suite passes with `AGENT_TASK_RUNTIME_MODE=on`, with no test
   modified to accommodate the new runtime;
3. **G12 validation has passed** — shadow comparison over a representative
   period shows no unexplained decision divergence;
4. the security gate reports 18/18 with PostgreSQL and frontend evidence, in
   `on` mode;
5. no `capabilities/routing.py` or `PlanStep` reference remains outside the
   module being deleted.

Until all five hold, the old routing stays. It is dead weight, not a hazard.

## Exact G4 implementation sequence

| Bead | Delivers | Depends on |
|---|---|---|
| G4.1 | `TaskPlan` / `IntentTask` typed schemas | G2.3 |
| G4.2 | plan reducer — selection, transitions, progress invariant | G4.1 |
| G4.3 | `InteractionRequest` schemas + store | G2.4 |
| G4.4 | Policy integration — approval requirement, idempotency | G4.2 |
| G4.5 | Interaction runtime — interrupt, checkpoint, resume-by-task_id | G4.3 |
| G4.6 | the agent loop — reason → expose → decide → execute → observe → update | G4.2, G4.4 |
| G4.7 | capability selection wired to the loop (registry ∩ context ∩ policy) | G4.6 |
| G4.8 | Execution Engine extracted from `action_execution` + `scheduling_execution` | G4.6 |
| G4.9 | the bridge — `AGENT_TASK_RUNTIME_MODE`, shadow comparison | G4.6, G4.8 |
| **G4.10** | **delete `main_routing.py`** | **all above + G12** |

G4.1–G4.5 add code that nothing calls yet. G4.9 is the first bead that can change
what a user experiences, and only at `canary` or `on`.
