# LangGraph Step 2 Graph Foundation Evidence

Date: 2026-07-03

Status: `PASS`

## Implementation

Added isolated target package:

```text
fb_agent/app/agent_graph/
  __init__.py
  budgets.py
  context.py
  errors.py
  graph.py
  llm.py
  reducers.py
  state.py
```

The package provides:

- typed `SocialHubGraphState`
- deterministic list/dictionary/integer reducers
- positive validated node/LLM/tool/token/recursion budgets
- request-scoped `GraphRuntimeContext`
- safe graph error classes
- strict JSON and secret/runtime-object state validation
- a thin adapter to the existing Z.AI gateway
- an isolated foundation graph and invocation configuration

## Feature Flag

Added:

```text
LANGGRAPH_ENABLED=false
```

as a backend setting with a code default of `False`.

No environment file was changed. No existing route reads or enables the graph. Calling
the graph factory without an explicit test override raises `GraphFeatureDisabled`.

The legacy `/api/v1/agent/*` runtime remains authoritative.

## Serialization Boundary

Checkpointable state permits strict JSON primitives, lists, and dictionaries.

It rejects:

- access/refresh tokens
- secrets, passwords, API keys, cookies, authorization headers
- DB sessions
- user ORM objects
- services, clients, and gateway objects
- datetimes and arbitrary Python objects
- NaN/non-strict JSON values

DB, user, and LLM dependencies live in `GraphRuntimeContext`, outside graph state.

Legitimate counters such as `total_tokens` and `prompt_tokens` are allowed; sensitive
singular/suffix keys such as `refresh_token` remain rejected.

## Z.AI Adapter

`ZAIAgentGraphAdapter` delegates only to:

- `run_agent_text`
- `run_agent_json`

from the existing `agent_llm_gateway.py`.

No provider, model ID, fallback, key, or client was added. A source scan found no second
provider references under `app/agent_graph/`.

## Tests

Added:

```text
fb_agent/tests/test_agent_graph_foundation.py
```

Targeted result:

```text
16 passed
```

Coverage:

- JSON round trip
- nested secret rejection
- runtime-object rejection
- reducer determinism and input immutability
- budget boundaries and invalid configuration
- default-disabled feature flag
- graph compile/invoke/stream/checkpoint
- recursion configuration
- node-step budget enforcement
- Z.AI gateway delegation
- unchanged compatibility API routes

An initial targeted failure exposed an over-broad token-key scanner. It was corrected
to distinguish safe token counters from credential keys, and the complete targeted
suite then passed.

## Regression

Commands:

```powershell
.\.venv\Scripts\python.exe -m compileall app\agent_graph
.\.venv\Scripts\python.exe -m pytest -q
```

Result:

```text
158 passed
168 warnings
```

Warnings are existing deprecation debt plus test collection of existing FastAPI/Pydantic
modules; no functional regression occurred.

## Gate Decision

Step 2 status: `PASS`.

Acceptance criteria met:

- deterministic typed foundation
- strict JSON-safe state
- secret-free checkpoint boundary
- runtime dependencies excluded from state
- validated budgets and recursion limit
- Z.AI-only adapter
- disabled feature flag
- no active API change
- full backend regression green

Next allowed gate: Step 3 — Thread API and development checkpointer.

