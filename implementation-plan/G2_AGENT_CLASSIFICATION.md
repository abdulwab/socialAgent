# G2.1 — Classification of every agent, subgraph and capability

Architecture gate. **No runtime code was modified.** Every claim below was traced
from the tree at `socialbackend/app/agent_graph/` (57 modules, ~21,000 lines).

## The measurement that decides most of this

```
Modules in app/agent_graph/ that call the LLM gateway:  4
    content_graphs.py          strategy + copywriting generation
    creative_research_graphs.py image prompt + web-search synthesis
    artifact_editing.py         draft rewriting
    llm_understanding.py        hybrid intent understanding
  (llm.py is a 13-line adapter over the gateway, not a caller)

Modules that call it:                                  53 → 0
    understanding.py            512 lines, PURE REGEX, zero LLM calls
    platform_agents/subgraphs.py 601 lines, FOUR "platform agents", zero LLM calls
```

SocialHub advertises "eleven hidden domain agents". **Four modules reason.** The
rest are deterministic pipelines wearing an agent costume — which is exactly what
this gate exists to establish, because until it is written down, G4 has no
defensible target and every module can argue it deserves to survive.

## Classification key

| | |
|---|---|
| **A** | genuine reasoning specialist — survives as a sub-agent |
| **B** | deterministic capability — becomes a tool |
| **C** | provider adapter — becomes an adapter |
| **D** | policy / execution infrastructure — becomes policy or execution engine |
| **E** | obsolete wrapper / routing artifact — deleted after migration |

---

## The A-list — three entries, deliberately

An A classification must name reasoning that deterministic code **cannot** do.
"It is hard to write" is not that. The test applied: *could a well-specified
function with the same inputs produce an acceptable output?* If yes, it is B.

| Module | Reasoning that code cannot do | Target |
|---|---|---|
| `content_graphs.py` — strategy + copywriting | Produces novel natural-language content conditioned on brand voice, platform register and audience. There is no correct answer to compute; the output is judged, not verified. | **Content sub-agent** behind `content.*` tools |
| `creative_research_graphs.py` — image prompt + search synthesis | Turns an underspecified request into an image prompt, and synthesises fetched pages into an answer. Both are open-ended generation over unbounded input. | **Creative/Research sub-agent** |
| `llm_understanding.py` | Resolves *natural-language* ambiguity the regex layer cannot: novel phrasings, Roman-Urdu/English mixing, references to prior turns. | **Folded into the Conversation Agent.** Not a sub-agent — it becomes the planner's input, never a router |

`artifact_editing.py` calls the LLM but is **B**: it rewrites a draft under
explicit constraints (`repair_protected_phrases`, `merge_line_into_caption`,
`split_trailing_hashtag_block`), and most of its 265 lines are deterministic
string surgery. It is a tool that happens to use a model, not a specialist.

**The A-list stays at three.** Adding a fourth requires naming the reasoning and
defending it against the test above.

---

## Full classification

Every node and subgraph carries exactly one classification.

### Reasoning (A)

| Module | Responsibility | LLM | Tools | State | Side effects | Target | Risk |
|---|---|---|---|---|---|---|---|
| `content_graphs.py` | strategy + copywriting subgraphs | **yes** | none | `artifacts` | none | Content sub-agent | **low** — already isolated behind an injectable `generator` |
| `creative_research_graphs.py` | image, media, web-search subgraphs | **yes** | HTTP fetch | `artifacts` | outbound HTTP (2) | Creative/Research sub-agent | **medium** — external fetch needs the URL validation it already has |
| `llm_understanding.py` | hybrid understanding over the rule layer | **yes** | none | `understanding` | outbound HTTP (1) | Conversation Agent input | **medium** — becomes planning input, must stop being a router |

### Deterministic capabilities (B) — become tools

| Module | Responsibility | LLM | State | Side effects | Target | Risk |
|---|---|---|---|---|---|---|
| `understanding.py` (512) | regex intent/entity extraction | no | `understanding` | none | Planner pre-pass; **demoted, not deleted** — it is a cheap, deterministic prior | low |
| `artifact_editing.py` (265) | constrained draft rewriting | yes | `artifacts` | none | `artifact.edit.v1` tool | low |
| `operational_graphs.py` (452) | analytics / publishing / autopilot subgraphs | no | `artifacts` | via execution | three tools | **medium** — publishing is consequential |
| `scheduling_graphs.py` (222) | schedule + safety subgraphs | no | `artifacts` | none | `schedule.*` tools | low |
| `connection_graph.py` (339) | connection snapshot + subgraph | no | `working_context` | reads DB | `connection.status.v1` tool **+ interaction source** | low |
| `capabilities/retrieval.py` (397) | owned-resource reads | no | none | reads DB | retrieval tools | low |
| `capabilities/artifact_lifecycle.py` (376) | artifact CRUD | no | `artifacts` | DB writes | artifact tools | low |
| `capabilities/post_lifecycle.py` (475) | post CRUD | no | none | **DB writes (5)** | post tools | **medium** |
| `failure_recovery.py` (328) | classify provider failures into safe messages | no | none | none | execution-engine helper | low |
| `pending_actions.py` (133) | pending action bookkeeping | no | `pending` | none | Interaction Manager | low |
| `evaluation_*.py` (3 modules, 1,176) | command evaluation harness | no | none | none | **stays** — G10 owns it | none |

### Provider adapters (C)

| Module | Responsibility | LLM | Side effects | Target | Risk |
|---|---|---|---|---|---|
| `platform_agents/subgraphs.py` (601) | four "platform agents" | **no** | none directly | **Adapter shells.** Traced: zero LLM calls. They validate an envelope, build a proposal, shape a result | **medium** — they are the loudest "agent" claim and the least agent-like |
| `platform_agents/tools.py` (372) | per-platform tool surface | no | via execution | merged into the registry | medium |
| `platform_agents/shared_tools.py` (776) | cross-platform tool bodies | no | via execution | merged into the registry | medium |
| `platform_agents/state_store.py` (173) | platform state snapshots | no | reads DB | execution-engine context | low |
| *(`app/platforms/*.py`, outside agent_graph)* | real provider adapters | no | **provider HTTP** | **stay as-is** — already the right shape | low |

### Policy / execution infrastructure (D)

| Module | Responsibility | Target | Risk |
|---|---|---|---|
| `capabilities/policy.py` (577) | approval envelopes, idempotency keys, operation fingerprints, resume verification | **Policy Engine.** Already the right shape | low |
| `capabilities/registry.py` (806) | 22 model-facing tools, platform support matrix, legacy alias map | **Capability Registry.** Already the right shape | low |
| `capabilities/visibility.py` (318) | which capabilities a context may see | **Capability selection.** Already the right shape | low |
| `capabilities/tool_schemas.py` (683) | typed tool I/O | stays | low |
| `capabilities/schemas.py` (185) | capability definitions | stays | low |
| `action_execution.py` (847) | approved-action execution | **Execution Engine.** DB writes (11), provider calls (3) | **high** — the single most consequential module |
| `scheduling_execution.py` (293) | approval persistence + schedule execution | Execution Engine | **high** — DB writes (8) |
| `platform_agents/confirmation.py` (536) | confirmation envelopes | Policy Engine | medium |
| `budgets.py`, `state.py`, `reducers.py`, `context.py`, `errors.py` | harness primitives | stay | low |
| `memory_store.py` (278) | scoped memory | Memory/context | low |
| `observability*.py`, `trace_schemas.py`, `langsmith_tracing.py`, `production_observability.py` (2,220) | tracing and redaction | stay | low |
| `thread_service.py` (1,267) | thread lifecycle, checkpointing | **Harness.** Already the right shape | medium |
| `postgres.py`, `graph.py` | checkpointer, foundation graph | stay | low |
| `tools/*` (6 modules, 377) | legacy tool catalog/executor | **merge into the registry**, then E | medium |

### Obsolete routing artifacts (E)

| Module | Why | Deleted by |
|---|---|---|
| `main_routing.py` (**3,759**) | 28 nodes of hand-written branching that re-derives every decision from `understanding.intents`. Replaced by the agent loop + TaskPlan | **G4.10 only** |
| `routing_schemas.py` — `PlanStep` | `sequence, agent_key, objective, mutation`. **No id, no status, no dependencies, no result.** A plan that cannot record progress | G4.2 |
| `connection_intent.py` (85) | intent-shaped wrapper over the connection snapshot | G4.x |
| `capabilities/routing.py` (391) | capability routing table, subsumed by the registry + planner | G4.x |
| `main_routing.build_plan` | orders intents into `PlanStep`s with no status | G4.2 |

---

## The defect this classification exposes

`build_plan` produces a `PlanStep` list with **no status field**, and routing
reads `understanding.intents` at **12 separate sites** (`main_routing.py` lines
176, 432, 597, 704, 710, 772, 830, 918, 922, 926, 1688, 1730) rather than
consuming a task list.

So the router re-derives its decision from the *original* intent set on every
pass, and that set never shrinks as work completes. With N intents there is no
state that says "publishing is done" — which is the mechanism behind the
multi-intent non-termination this epic was opened for.

**This is why G2.3's TaskPlan is the load-bearing contract**, not a modelling
nicety: without per-task status, progress is unrepresentable.

---

## Survive / demote / disappear

| Verdict | Modules |
|---|---|
| **Survive largely as-is** | `capabilities/{policy,registry,visibility,schemas,tool_schemas}.py`, `app/platforms/*`, observability, `memory_store`, `thread_service`, `budgets`/`state`, evaluation harness |
| **Survive, demoted** | `understanding.py` (router → planner prior), `action_execution.py` + `scheduling_execution.py` (nodes → Execution Engine), `platform_agents/*` (agents → adapter shells) |
| **Eventually disappear** | `main_routing.py` (G4.10), `routing_schemas.PlanStep`, `connection_intent.py`, `capabilities/routing.py`, `tools/*` |

Total marked for eventual deletion: **~4,600 lines**, of which `main_routing.py`
is 3,759 — and none of it is deleted before G12 validates the replacement.
