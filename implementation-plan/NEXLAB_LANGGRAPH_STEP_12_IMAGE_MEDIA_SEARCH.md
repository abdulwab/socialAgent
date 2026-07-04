# Step 12 Evidence - Image, Media, and Web Search Subgraphs

Date: 2026-07-04  
Status: PASS

## Delivered

- Added typed LangGraph subgraphs for image generation, media handling, and web research.
- Reused the existing Z.AI image prompt/image service and Cloudinary storage adapters.
- Added deterministic, stable artifact IDs and checkpoint-backed artifact references.
- Validated HTTPS references, supported MIME types, ownership, and the 20 MB size limit.
- Attached validated media to the latest draft without accepting frontend-owned objects.
- Added immutable media-deletion proposals and a durable LangGraph interrupt.
- Kept media deletion execution disabled after confirmation.
- Added approved search/fetch adapters with graceful degraded results.
- Stored citations and source provenance with every research artifact.
- Marked fetched text as untrusted, bounded excerpts, ignored instruction-like content,
  and prohibited external content from changing policy.

No dependency, database model, or migration change was required. Durable artifacts and
interrupt state use the existing LangGraph checkpoint store.

## Safety and isolation guarantees

- Artifact resolution is limited to the authenticated user's current thread checkpoint.
- Unknown or foreign artifact IDs are rejected.
- ORM objects, sessions, credentials, and service clients are not serialized.
- Generated and fetched outputs are scanned for credential-shaped content.
- Unsupported formats, non-HTTPS URLs, and oversized references are rejected.
- Search failures return a cited-research-unavailable artifact instead of escalating.
- External instructions remain data and produce no tool, policy, or approval effects.
- Deletion confirmation cannot call the scheduling executor or delete an artifact.

## Gate results

Focused Step 12 suite:

```text
5 passed
```

Focused Step 12 plus adjacent graph regression:

```text
39 passed
```

Full backend regression:

```text
python -m compileall -q app/agent_graph
python -m pytest -q
218 passed, 1 skipped
```

Coverage includes image success/failure, stable IDs, storage and format validation,
ownership denial, large media rejection, attachment, durable deletion interrupt,
confirm-without-delete, search degradation, citations, prompt injection, excerpt
truncation, routing integration, and scheduling approval regression.

The skipped test is the existing opt-in disposable PostgreSQL integration test.
Existing deprecation warnings remain non-blocking.

## Rollout state

- Existing APIs remain unchanged and LangGraph stays behind its feature flag.
- No production deployment, dependency edit, migration, frontend change, or backend
  GitHub push occurred.

## Pass decision

PASS. Image, media, and cited research artifacts survive through checkpoint state,
ownership cannot be bypassed, media deletion remains proposal-only, and untrusted
external content cannot escalate policy or tool authority.
