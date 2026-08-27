# G2.3 / G2.4 — TaskPlan and Interaction contracts

Typed contracts. The reducer is G4.2; the interaction runtime is G4.5.

## Why TaskPlan is load-bearing

Today `PlanStep` is `sequence, agent_key, objective, mutation` — **no id, no
status, no dependencies, no result reference** — and routing re-derives its
decision from `understanding.intents` at 12 separate sites in `main_routing.py`.
The original intent set never shrinks as work completes, so "publishing is done"
is unrepresentable. Every contract below exists to make progress a fact in state
rather than an inference.

## TaskPlan

```
Goal
  goal_id            stable id
  text               the user's request, verbatim
  created_at
  tasks              IntentTask[]

IntentTask
  task_id                  stable, unique within the goal
  capability               registry capability name — never a free-text agent key
  status                   see below
  depends_on               task_id[] — completion gates, not ordering hints
  platform                 optional PlatformKey constraint
  account_ref              optional owned-account reference (id, never a token)
  artifact_refs            ids of artifacts produced or consumed
  attempts / max_attempts
  result_ref               id of a stored result; never the payload inline
  error_ref                id of a classified failure; never a raw provider body
  blocked_reason           why it cannot proceed, from a closed enum
  required_interaction_id  the InteractionRequest this task waits on
```

Two rules that are easy to get wrong:

* `result_ref` and `error_ref` are **references**, so a provider payload can
  never reach graph state, checkpoints or memory — the G1 secret boundary applies
  to the task model, not only to logs.
* `account_ref` is an owned-account **id**. A credential never enters a task.

### Statuses and legal transitions

```
pending ──► running ──► completed
   │           ├──────► blocked ──► pending      (interaction answered)
   │           ├──────► failed                   (non-retryable, or attempts exhausted)
   │           └──────► running                  (retry, attempts += 1)
   └──────► skipped                              (dependency failed, or superseded)
```

Terminal: `completed`, `failed`, `skipped`. No transition leaves a terminal
status — that is what makes "completed tasks do not re-execute" enforceable
rather than hoped for.

**Selection rule.** The next runnable task is the first `pending` task whose
`depends_on` are all `completed`. If none is runnable and none is `running` or
`blocked`, the plan is finished.

### Worked example

> "analyse last month, write something similar, make an image, schedule Friday morning"

| task_id | capability | depends_on | platform | notes |
|---|---|---|---|---|
| `t1` | `analytics.summary.v1` | — | — | reads owned metrics |
| `t2` | `content.copywriting.v1` | `t1` | facebook | consumes `t1`'s artifact |
| `t3` | `creative.image.v1` | `t2` | — | prompt derives from the copy |
| `t4` | `schedule.create.v1` | `t2`, `t3` | facebook | consequential → approval |
| `t5` | `interaction.resolve` | `t4` | — | exists only if `t4` blocks |

Five tasks, four dependency edges. `t4` is the only consequential one, and it is
the only one that can raise an approval. Compare with today: four intents, one
flat `PlanStep` list, no way to record that `t1` finished.

## InteractionRequest

```
InteractionRequest
  interaction_id
  task_id          MANDATORY — an interaction with no task is a dead end
  type             clarification | choice | approval | connection | authentication
  question         user-facing text, already safe to display
  required_fields  what an answer must supply
  options          candidates, for `choice`
  status           pending | answered | expired | cancelled
  created_at / answered_at / answered_by
  answer_ref       reference to the stored answer
```

`task_id` is mandatory because an interaction exists to unblock a specific task.
Without it, an answer cannot be routed back and the graph resumes into ambiguity.

### The five types, and why they are not one type

| Type | Means | Resolution |
|---|---|---|
| `clarification` | information is missing | user supplies it |
| `choice` | several valid candidates | user picks one |
| `approval` | understood perfectly, needs authorization | user authorizes |
| `connection` | the account is not connected | user connects it |
| `authentication` | session or credential problem | user re-authenticates |

**Ambiguity and approval are different concepts and must never be merged.**
Ambiguity means *the system does not know what to do*. Approval means *the system
knows exactly what to do and may not do it unasked*. Collapsing them produces
both failure modes at once: asking "which page did you mean?" when the answer is
obvious, and publishing without consent because the request was unambiguous.

This is already a recorded project invariant: *never substitute clarification for
approval on a fully specified consequential request.*

## Four uncertainty levels

| Level | Behaviour | Must NOT ask | Must ask |
|---|---|---|---|
| **1 safe assumption** | proceed silently | "post to my page" with exactly one connected page → use it | — |
| | | "schedule Friday" with a configured timezone → use it | — |
| **2 recoverable ambiguity** | do useful work first, ask later | draft the copy now, ask which page at schedule time | — |
| | | generate the image, ask about the caption afterwards | — |
| **3 blocking ambiguity** | ask before acting | — | "post it" with three connected pages and no hint |
| | | — | "delete the draft" with two drafts and no discriminator |
| **4 consequential approval** | ask even when certain | — | publish now, to a specific named page |
| | | — | delete a scheduled post; disconnect an account |

Level 4 is orthogonal to 1–3. A request can be perfectly unambiguous (level 1 on
understanding) and still require approval. The levels answer *do I know what to
do*; approval answers *may I do it*.

## Checkpoint behaviour

| Property | Mechanism |
|---|---|
| completed tasks survive resume | task status lives in checkpointed graph state |
| a pending interaction survives resume | `InteractionRequest` is checkpointed with `status=pending`; the graph is suspended at an interrupt |
| an answered interaction resumes the same task | `task_id` on the interaction is the routing key |
| completed tasks do not re-execute | terminal statuses have no outgoing transition; selection only considers `pending` |
| no credential or OAuth secret enters graph state | tasks carry `account_ref`, `result_ref`, `error_ref` — ids, never payloads. Enforced by the existing observability sanitizer and the `secrets_in_graph_state` gate invariant |

## Dynamic capability exposure

```
registry
  → authenticated context      (tenant from the verified JWT, once)
  → connected providers        (which accounts this tenant actually has)
  → provider support / scopes  (what those providers can do)
  → policy                     (what this actor may do)
  → relevant tool subset
  → LLM
```

Each stage can only **narrow**. The model receives a subset and cannot widen it.

**A model naming a hidden capability must not make it executable.** A name
outside the exposed subset is rejected before Policy is consulted — so an
invented, remembered or hallucinated capability name fails at selection, not at
execution. This is not a new mechanism: `capabilities/visibility.py` already
implements narrowing, and `_hidden_reason` already records *why* something was
withheld. G4 wires it to the loop rather than to the router.
