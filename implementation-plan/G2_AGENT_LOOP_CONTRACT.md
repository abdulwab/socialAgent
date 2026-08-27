# G2.2 — Agent-loop contract

Contract document. No implementation; G4.6 builds the loop.

## Governing invariant

```
The LLM decides WHAT to do.
Policy decides WHETHER it may be done.
Execution decides HOW to do it reliably.
```

These three are disjoint. A decision appearing in two of them is a defect, not a
design choice — that overlap is how a model ends up nominating a tenant.

## Component boundaries

| Component | Owns | May never |
|---|---|---|
| **Conversation Agent (LLM)** | what the user means; which capability to propose; arguments to propose; how to phrase the reply | decide ownership, authentication, permission, approval, idempotency, or locking |
| **LangGraph harness** | node execution, checkpointing, resume, interrupts, budgets | interpret meaning; make policy decisions |
| **Task Planner** | turning a goal into `IntentTask`s with dependencies; selecting the next runnable task | execute anything; call providers |
| **Interaction Manager** | raising, storing, matching and resolving `InteractionRequest`s | decide whether an approval is *required* — Policy does that |
| **Capability Registry** | the set of capabilities, their schemas, platform support | evaluate permission; execute |
| **Policy Engine** | may this actor perform this capability on this resource; is approval required; idempotency key; operation fingerprint | choose what to do; produce user-facing content |
| **Application Commands** | deterministic app operations (drafts, schedules, settings) | bypass Policy |
| **Execution Engine** | ordering, locking, retry, effectively-once semantics, failure classification | decide whether the action was permitted |
| **Provider Adapters** | one provider's HTTP contract and error shapes | make authorization decisions; touch other tenants |
| **Memory/context** | scoped, non-secret user and brand context | hold credentials, tokens, or another tenant's data |

### The two lists, disjoint by construction

**LLM decides** — capability to propose · arguments to propose · task ordering
*preference* · reply wording · when it believes it is finished · whether it needs
to ask the user something.

**Deterministic code decides** — tenant identity (from the verified JWT, once, at
the auth boundary) · authentication validity · whether the capability exists ·
whether the tenant owns the target resource · provider scope truth · whether
approval is required · whether an approval is still valid · the idempotency key ·
transaction and lock boundaries · retry counts and backoff · whether the loop may
continue.

No item appears in both lists.

### What the model naming something does *not* achieve

A capability the model names but which selection did not expose is **not
executable**. The registry is consulted with the *authenticated* context; a name
outside the returned subset is rejected before Policy is even reached. Naming is
not authorization.

## The loop

```
        ┌─────────────────────────────────────────────┐
        ▼                                             │
   [ select next runnable task ]                      │
        │  none runnable → terminate                  │
        ▼                                             │
   [ reason ]      LLM proposes capability + arguments │
        ▼                                             │
   [ expose ]      registry ∩ context ∩ policy        │
        ▼                                             │
   [ decide ]      Policy: allow / deny / needs approval
        │            deny     → task failed            │
        │            approval → raise Interaction ─────┼─► interrupt, checkpoint
        ▼                                             │
   [ execute ]     Execution Engine, idempotent        │
        ▼                                             │
   [ observe ]     typed result or classified failure  │
        ▼                                             │
   [ update ]      task status, artifacts, attempts ───┘
```

Tool results re-enter context as **typed observations**, never as raw provider
payloads — the credential and error-disclosure boundaries already established in
G1 apply unchanged.

## Termination and progress

**Progress invariant.** Every iteration must do exactly one of:

1. move a task to a terminal status (`completed`, `failed`, `skipped`), or
2. raise an `InteractionRequest` and suspend, or
3. increment `attempts` on a task whose `attempts < max_attempts`, or
4. terminate the loop.

An iteration that does none of these is a defect. It is detectable: compare the
multiset of `(task_id, status, attempts)` before and after — unchanged means no
progress, and the loop must terminate with `failed` rather than continue.

**Bounded by construction**, and the bound has ONE definition:

```python
from app.agent_graph.task_progress import max_iterations
budget = max_iterations(plan)
```

The runtime calls that function. It does not restate the formula, because a
duplicated bound drifts from the state machine it is supposed to describe — which
is precisely what happened here.

*The correction (socialhub-ijn.6.11).* This document originally said `T × R + 1`
for `T` tasks and `R` attempts, reasoning that every iteration either terminates a
task, consumes an attempt, or suspends. **That is wrong for any task that blocks
on an interaction.** Blocking and resuming are two further iterations that
terminate nothing and consume no attempt — the suspend is legitimate progress, and
the resume is legitimate progress, and neither shows up in `T × R`. A loop
configured with `T × R + 1` would therefore abort a plan that used an interaction,
which is every plan containing a consequential capability. The bound was not
merely tight; it was smaller than the shortest legal execution.

`max_iterations()` carries the derivation in its docstring and allows three
iterations per attempt — start, block, resume — plus one terminal step per task
and one final iteration to observe that the plan is finished. A test asserts the
derived bound exceeds `T × R + 1`, so the two cannot silently converge again.

Additional ceilings, already present in `budgets.py`: node steps, LLM calls, tool
calls, total tokens, recursion limit. Whichever binds first wins.

**This is what the current runtime cannot state.** Routing re-reads
`understanding.intents` at 12 sites and `PlanStep` has no status, so "has this
task finished" is unrepresentable — and therefore so is progress.

## Failure and retry inside the loop

Failures are classified by `failure_recovery.py`, which already returns a curated
safe message and a `retryable` flag. The loop retries only when the classifier
says retryable **and** `attempts < max_attempts`; a non-retryable failure moves
the task to `failed` immediately. Retry never re-executes a provider mutation
without a fresh idempotency decision from Policy.
