# Step 9 Evidence — Strategy and Copywriting Subgraphs

Date: 2026-07-03  
Status: PASS

## Delivered

- Added separate compiled LangGraph subgraphs for Content Strategy and Copywriting.
- Both subgraphs use the existing single backend Z.AI structured-output gateway in
  production and injectable fake generators in tests.
- Added strict provider-output schemas with undeclared-field rejection.
- Added read-only strategy artifacts containing:
  - summary;
  - validated content angles;
  - platforms and language;
  - applied tone;
  - scoped memory provenance keys.
- Added platform draft artifacts for Facebook, Instagram, LinkedIn, and X.
- Added deterministic platform limits:
  - Facebook: 63,206 characters;
  - Instagram: 2,200 characters;
  - LinkedIn: 3,000 characters;
  - X: 280 characters.
- Added Instagram media-required metadata.
- Added numeric and English/Roman-Urdu small-number draft-count extraction.
- Added deterministic backend artifact IDs derived from thread, command, platform, and
  draft slot.
- Integrated both subgraphs into the feature-gated Main Graph and checkpoint artifacts.
- Added assistant checkpoint messages for successful or rejected content generation.

## Scoped context behavior

- Strategy receives only `user_preference`, `brand`, and `analytics` memory.
- Copywriting receives only `user_preference` and `brand` memory.
- Connection/app memory is excluded.
- Analytics memory is excluded from copywriting.
- Explicit tone preferences are applied to artifact metadata and generation instructions.
- Memory keys used for generation are recorded without copying provenance secrets.

## Failure behavior

- Malformed JSON shape creates no artifact.
- Missing, extra, or out-of-order platform slots create no draft.
- Unsupported platforms create no draft.
- Any platform-limit violation rejects the complete generated draft batch.
- Credential-shaped generated text is rejected and never copied into an artifact or error.
- Failed output creates a safe graph error and user message.
- Strategy and draft artifacts never create a tool or mutation proposal.

## Gate results

Focused Strategy/Copywriting/Main Graph/memory/connection suite:

```text
26 passed
```

It proves:

- all four platforms;
- English and Roman Urdu artifact behavior;
- tone and brand preference application;
- strategy-only analytics memory;
- irrelevant-memory exclusion;
- malformed provider-output rejection;
- platform count/order enforcement;
- platform character limits;
- stable artifact IDs across repeated runs;
- multiple deterministic draft slots;
- golden strategy and copywriting commands;
- read-only Main Graph checkpoint artifacts.

Full backend regression:

```text
python -m compileall -q app
python -m pytest -q
199 passed, 1 skipped
```

The skipped test is the existing opt-in disposable PostgreSQL integration test. Existing
deprecation warnings remain non-blocking.

## Rollout state

- `LANGGRAPH_ENABLED` remains the runtime gate.
- Legacy `/api/v1/agent/command` remains unchanged.
- No dependency, migration, environment, production data, deployment, or frontend change
  occurred.
- Generated strategies and drafts are read-only artifacts.

## Pass decision

PASS. Golden content scenarios, scoped memory, all platform constraints, malformed-output
handling, deterministic IDs, and safe read-only artifacts pass.
