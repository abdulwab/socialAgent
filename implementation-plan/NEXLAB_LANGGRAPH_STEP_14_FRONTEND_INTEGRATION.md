# Step 14 Evidence - Frontend Integration

Date: 2026-07-04  
Status: PASS

## Delivered

- Added the explicitly approved `@assistant-ui/react@0.14.24` dependency.
- Integrated assistant-ui's External Store Runtime without replacing custom SocialHub
  chat, composer, progress, assets, connection, or confirmation components.
- Replaced the legacy React-owned `/agent/command` flow with backend thread APIs:
  - list;
  - create;
  - hydrate;
  - command;
  - authenticated SSE stream;
  - resume.
- Hydrates the newest owned backend thread on refresh and supports an owned `?thread=`
  selection for multi-device links.
- Added typed SSE parsing, bearer authentication, `Last-Event-ID` reconnect, bounded
  retries, abort handling, and event-ID deduplication.
- Resumes confirm/cancel using backend approval ID and immutable payload hash.
- Rejects expired hydrated approvals in the client while the backend remains authoritative.
- Removed React submission of conversation history and authoritative artifacts.
- Removed obsolete frontend prompt/provider API and Redux state for Gemini, OpenRouter,
  Claude, provider selection, and user system prompts.
- Added accessible conversation live-region and confirmation alert-dialog semantics.

## Backend thread contract

- Thread detail now returns sanitized:
  - messages;
  - public artifact collections;
  - pending approval resume fields;
  - checkpoint ID;
  - final reply and status.
- SSE `thread.snapshot` carries the same sanitized backend-owned thread.
- Internal artifact index, approval envelope, working context, active agents, tool
  proposals, credentials, and traces are not exposed.

## Gate results

Frontend:

```text
npm test -- --runInBand
3 suites / 10 tests passed

npm run lint
passed

npm run build
passed
```

Backend thread contract:

```text
7 passed
```

Full backend regression:

```text
231 passed, 1 skipped
```

Coverage includes hydration mapping, refresh persistence, newest/selected thread behavior,
backend-only command payloads, typed SSE parsing, unknown-event rejection, reconnect
cursor and deduplication logic, approval confirm/cancel contract, expiry suppression,
cross-user denial, restart survival, accessible dialog/live region, responsive layout
classes, and internal-state leakage checks.

## Dependency and visual audit

- `@assistant-ui/react` is pinned exactly at `0.14.24`.
- `npm audit` reports five existing/transitive advisories in Jest/jsdom/Babel tooling and
  Next's bundled PostCSS. None is introduced through the assistant-ui dependency path.
- No automatic audit fix was applied because it would change unrelated protected
  dependencies.
- Automated component/accessibility and production-render gates passed. The local in-app
  visual browser could not attach because of a browser-tool metadata error; therefore a
  signed-in live-device visual smoke remains recommended after deployment, not a code
  gate blocker.

## Rollout state

- No database migration or production deployment occurred.
- Backend changes were not pushed to GitHub.
- Frontend changes are committed locally for the approved GitHub/Vercel flow.

## Pass decision

PASS. Backend thread/checkpoint state is authoritative across refresh and devices, typed
SSE reconnect is deduplicated, approvals resume through backend contracts, and the custom
SocialHub experience remains intact with improved accessibility.
