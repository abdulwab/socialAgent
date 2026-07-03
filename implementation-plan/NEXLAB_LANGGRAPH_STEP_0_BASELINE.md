# LangGraph Step 0 Baseline Evidence

Date: 2026-07-03

Status: `IN_PROGRESS`

Step 0 is not complete until missing golden behavior scenarios are added and pass.

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

- `112 passed`
- `0 failed`
- `140 warnings`
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

## Eleven-Agent Golden Coverage Audit

| Domain agent | Existing useful coverage | Golden status |
|---|---|---|
| Connection | connection intent and page-selection tests | partial |
| Content Strategy | indirect routing only | missing |
| Copywriting | agent output and tone tests | partial |
| Image Generation | agent and media-generation tests | partial |
| Media | upload/storage regression tests, not agent behavior | missing |
| Scheduling | planner/follow-up schedule tests | partial |
| Publishing | platform tool schemas and orchestrator paths | partial |
| Analytics | limited routing/summary tests | partial |
| Autopilot | image/config service tests | partial |
| Safety And Review | risky-action routing tests | partial |
| Web Search | agent success/fallback tests | partial |

Supporting Main Graph behavior:

- Assistant Chat language behavior: covered
- Product Help: no dedicated golden scenario
- Main routing/provider failures: covered partially
- Roman Urdu: limited coverage; needs a formal matrix
- user isolation/cross-user denial: missing for future thread/checkpoint APIs

## Missing Golden Scenarios

Before Step 0 can pass, add behavior-focused fixtures/tests for:

1. all eleven domain-agent routing decisions
2. Roman Urdu and English equivalents
3. multi-agent workflows and required order
4. missing-information clarification
5. follow-up references to existing drafts/images/pages
6. safe read versus risky mutation confirmation
7. cancellation, expiry, replay, and double-confirm behavior
8. provider timeout/degraded responses
9. platform constraints for Facebook, Instagram, LinkedIn, and X
10. no hidden agent/model/tool trace in user-visible responses
11. no secret markers in saved state or outputs
12. current artifact and confirmation response shapes

Tests must assert product behavior rather than internal class implementation so the same
golden cases can validate both legacy and LangGraph runtimes.

## Gate Decision

Status remains `IN_PROGRESS`.

Passed:

- clean repository baseline
- backend regression suite
- frontend lint/build/test
- compatibility API inventory
- initial eleven-agent coverage audit

Remaining:

- implement the missing behavior-focused golden suite
- capture representative artifact/confirmation fixtures
- record latency/token baseline using deterministic mocked calls where possible
- rerun all checks

Next allowed work: continue Step 0 golden characterization only. Do not begin LangGraph
dependency work yet.

