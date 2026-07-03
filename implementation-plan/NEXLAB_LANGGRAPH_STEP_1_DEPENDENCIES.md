# LangGraph Step 1 Dependency Compatibility Evidence

Date: 2026-07-03

Status: `PASS`

## Approved Dependency Changes

Added to `fb_agent/requirements.txt`:

```text
langgraph==1.2.7
langgraph-checkpoint-postgres==3.1.0
psycopg[binary]==3.3.4
```

The selected LangGraph packages require Python 3.10 or newer. Compatibility was proven
with:

- local Python `3.14.5`
- Docker `python:3.11-slim`

`psycopg[binary]` is explicitly pinned because the PostgreSQL saver import initially
failed on Windows without a local `libpq` wrapper. The explicit binary package made the
install reproducible on Windows while remaining compatible with the Linux image.

## Compatibility Test

Added:

```text
fb_agent/tests/test_langgraph_compatibility.py
```

It verifies:

- `StateGraph` compilation
- invoke behavior
- update streaming
- in-memory checkpoint snapshot retrieval by `thread_id`
- PostgreSQL `PostgresSaver` import

Targeted result:

```text
3 passed
```

## Full Backend Regression

Command:

```powershell
$env:DATABASE_URL="sqlite:///./test_local.db"
.\.venv\Scripts\python.exe -m pytest -q
```

Result:

```text
142 passed
162 warnings
```

Existing FastAPI, Pydantic, SQLAlchemy, Z.AI gateway, agent, platform, and service tests
remain green.

## Clean Docker Install

Candidate image:

```text
socialhub-backend:langgraph-step1
```

Build result: `PASS`

The clean Docker build installed all requirements under Python 3.11. Additional checks:

```text
python -m pip check
No broken requirements found.
```

An isolated in-image graph invocation and update stream also passed.

## Container Health

Temporary container:

```text
socialhub-langgraph-step1
```

It ran on local port `18000`, returned:

```json
{"status":"ok","message":"API is running"}
```

The container also imported `PostgresSaver` successfully. Logs showed normal FastAPI
startup and scheduler startup. The temporary container was stopped and removed after
verification.

No production deployment, environment, database, or container was touched.

## Gate Decision

Step 1 status: `PASS`.

Acceptance criteria met:

- exact LangGraph/checkpointer pins
- local compatibility
- clean Docker dependency installation
- invoke and stream behavior
- checkpoint API availability
- PostgreSQL saver availability
- zero legacy test regression
- Docker candidate build
- isolated `/health` response

Next allowed gate: Step 2 — Graph Foundation behind a disabled feature flag.

