# LangGraph Step 0 Baseline Evidence

Date: 2026-07-03

Status: `PASS`

## Repository Baseline

| Repository | Revision at start | Starting state |
|---|---|---|
| Root | `b7d93f7` | clean |
| Frontend | `ff36708` | clean |
| Backend | `f47c44a` | clean |

Environment:

- Node.js `v24.15.0`
- npm `11.12.1`
- Python `3.14.5`
- pytest `9.0.3`

PowerShell blocks `npm.ps1`; use `npm.cmd` for project commands on this machine.

## Backend Verification

Command:

```powershell
cd fb_agent
$env:DATABASE_URL="sqlite:///./test_local.db"
.\.venv\Scripts\python.exe -m pytest
```

Result:

- initial baseline: `112 passed`
- final baseline with golden suite: `139 passed`
- `0 failed`
- final warning baseline: `162 warnings`
- test runtime: `2.25s`

Warning baseline:

- most warnings are timezone-naive `datetime.utcnow()` deprecations
- one Pydantic v2 class-based `Config` deprecation is present
- warnings are migration debt, not a Step 0 functional failure

## Frontend Verification

Commands and results:

| Command | Result |
|---|---|
| `npm.cmd run lint` | pass, clean output |
| `npm.cmd run build` | pass |
| `npm.cmd test -- --runInBand` | 2 suites, 4 tests passed |

Production build routes:

- `/`
- `/agent`
- `/forgot-password`
- `/login/[[...login]]`
- `/privacy-policy`
- `/reset-password`
- `/signup/[[...signup]]`
- `/sso-callback`
- `/x-callback`

## Agent API Snapshot

| Method | Path |
|---|---|
| POST | `/api/v1/agent/command` |
| POST | `/api/v1/agent/confirm` |
| POST | `/api/v1/agent/csv-preview` |
| POST | `/api/v1/agent/csv-schedule` |
| GET | `/health` |

This is the compatibility contract to preserve while new thread APIs are developed
behind a feature flag.

## Eleven-Agent Golden Coverage

| Domain agent | Golden coverage | Status |
|---|---|---|
| Connection | English/Roman Urdu routing contracts and existing page tests | pass |
| Content Strategy | English/Roman Urdu routing contract | pass |
| Copywriting | bilingual contract, draft artifact, existing output/tone tests | pass |
| Image Generation | bilingual contract and existing generation tests | pass |
| Media | bilingual contract and existing upload/storage regressions | pass |
| Scheduling | bilingual contract, follow-up, preview, confirmation | pass |
| Publishing | bilingual contract, confirmation, platform tool schemas | pass |
| Analytics | bilingual contract and existing summary behavior | pass |
| Autopilot | bilingual contract, confirmation, existing service tests | pass |
| Safety And Review | bilingual risky cases and safety convergence | pass |
| Web Search | bilingual contract and existing success/fallback tests | pass |

Supporting Main Graph behavior:

- Assistant Chat language behavior: covered
- Product Help: no dedicated golden scenario
- Main routing/provider failures: covered partially
- Roman Urdu: formal bilingual scenario matrix added
- user isolation/cross-user denial: missing for future thread/checkpoint APIs

New reusable golden assets:

- `fb_agent/tests/fixtures/agent_golden_scenarios.json`
- `fb_agent/tests/test_agent_golden_baseline.py`

Targeted result: `27 passed`.

The suite locks all eleven domain capabilities in English and Roman Urdu, registry
membership, structured routing contracts, multi-agent order, artifact propagation,
safety convergence, confirmation response shape, and nested secret redaction. Existing
tests continue to cover clarification, follow-up drafts/pages, cancellation, provider
failure/timeout, platform constraints, and confirmation claiming.

The JSON scenario set is implementation-independent and can be reused against the
LangGraph router.

## Gate Decision

Status: `PASS`.

Passed:

- clean repository baseline
- backend regression suite
- frontend lint/build/test
- compatibility API inventory
- reusable bilingual eleven-agent golden suite
- multi-agent artifact and confirmation fixture
- secret-redaction regression
- final backend and frontend regression rerun

Manual testing is not required for Step 0. Live OAuth, real Z.AI semantic quality, and
production provider behavior belong to later integration/canary gates.

Next gate: Step 1 dependency and compatibility proof. It remains blocked until explicit
approval to edit `fb_agent/requirements.txt`.
