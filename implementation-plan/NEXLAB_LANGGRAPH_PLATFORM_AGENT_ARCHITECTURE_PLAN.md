# NexLab LangGraph Platform-Agent Architecture Plan

| Item | Decision |
|---|---|
| Status | Gates A-I closed; next platform expansion ready |
| Visible agent | Main Agent only |
| Hidden agents | Facebook, Instagram, LinkedIn, and X platform agents |
| Tool schema visibility | Platform agents only; Main Agent receives route schemas only |
| Tool schema source | Strict Pydantic models exposed through LangGraph-compatible structured tools |
| Mutation safety | Code-owned confirmation interrupts before risky actions |

## 1. Objective

Refactor the existing LangGraph implementation into a platform-agent
architecture:

```text
Main Agent
  -> platform route decision
  -> exactly one hidden platform agent when the task is platform-specific
  -> platform agent receives only its own tools
  -> shared system tools are granted explicitly
  -> all risky actions converge on the same confirmation and execution boundary
```

The goal is not to discard working SocialHub services. The platform agents should wrap
existing OAuth, media, scheduling, publishing, analytics, and autopilot services behind
typed tools and strict ownership checks.

## 2. Non-Negotiable Boundaries

- The verified Clerk JWT determines `user_id`; route or tool inputs never authorize a
  client-provided user ID.
- OAuth tokens, cookies, API keys, authorization headers, DB sessions, ORM objects, and
  service clients never enter prompts, graph state, checkpoints, memory, SSE, traces, or
  user-visible responses.
- Main Agent does not receive platform tool schemas. It can produce only a typed route
  decision and safe task envelope.
- Platform agents do not call each other directly. Main Agent remains the coordinator.
- Publishing, scheduling, deletion, replies, disconnects, retries, autopilot mutations,
  and draft overwrites require explicit one-time confirmation.

## 3. Agent Responsibilities

### Main Agent

Main Agent owns understanding, validation, and routing:

- classify language, platform, task, and missing information
- resolve safe context keys such as latest artifact references
- create a typed `PlatformRouteDecision`
- route to the smallest necessary hidden platform agent
- never see provider credentials or platform tool argument schemas
- merge platform-agent output into one clean user-facing response

### Platform Agents

Each platform agent receives:

- one safe task envelope
- safe account metadata and artifact references only
- only that platform's structured tools
- selected shared tools only when explicitly allowed for the task

Each platform agent returns:

- safe artifacts
- tool proposals
- approval envelopes for risky actions
- user-safe errors and warnings

## 4. Platform Tool Names

```text
facebook.create_post.v1
facebook.edit_post.v1
facebook.delete_post.v1
facebook.reply_comment.v1

instagram.create_caption.v1
instagram.improve_caption.v1
instagram.schedule_post.v1

linkedin.create_draft.v1
linkedin.edit_draft.v1
linkedin.schedule_post.v1

x.create_post.v1
x.reply.v1
x.delete_post.v1
```

These names are stable capability names. Their execution handlers may internally call
shared services such as scheduling or publishing, but the agent-facing contract stays
platform-specific.

## 5. Shared System Tools

Shared tools stay outside platform namespaces and are granted by policy:

```text
artifact.latest.get.v1
connection.status.get.v1
schedule.summary.get.v1
analytics.summary.get.v1
image.generate.v1
media.attach.v1
media.inspect.v1
```

Shared tools are not global by default. A platform agent receives one only when the task
needs it and the policy grants it.

## 6. Route Contract

Main Agent output should stay small:

```json
{
  "platform": "instagram",
  "task": "improve_caption",
  "artifact_reference": "latest",
  "requires_confirmation": false,
  "context_keys": ["latest_instagram_caption", "brand_voice"]
}
```

This contract intentionally excludes provider tool JSON schemas. It tells the runtime
which hidden agent to invoke, not how to call the platform API.

## 7. Platform Agent Tool Contract

Platform tools are defined as:

- strict Pydantic input models
- stable `.v1` names
- read or mutation kind
- risk tier
- confirmation requirement
- allowed platform agent
- idempotency and audit metadata

LangGraph-compatible structured tools are built from those Pydantic schemas. The
runtime policy decides whether a tool can execute immediately, return a proposal, or
interrupt for confirmation.

## 8. State Store Contract

The state store may keep:

- latest Instagram caption artifact reference and safe text
- latest LinkedIn draft artifact reference and safe text
- post history metadata
- scheduled-post metadata
- connected-account IDs and health summaries
- safe memory such as tone, brand voice, and platform defaults

The state store must not keep runtime-only objects or credentials:

- OAuth access or refresh tokens
- cookies or passwords
- API keys or authorization headers
- DB sessions, ORM objects, SDK clients, service clients
- raw provider responses containing sensitive fields

## 9. Confirmation Rules

No platform agent may execute these without an approval interrupt:

- create or publish a live post
- schedule a post
- edit a published post
- delete a published post
- reply to comments or posts
- overwrite an existing draft artifact
- disconnect or reconnect platform state
- retry failed publish
- enable, disable, or change autopilot

Approval envelope requirements:

- thread ID, workflow ID, and verified user ID
- tool name and version
- normalized immutable payload
- payload hash
- expiry timestamp
- idempotency key
- one-time claim on execution

## 10. Implementation Gates

### Gate A: Plan and Safe Scaffold

- Add this architecture plan.
- Add Pydantic route schemas and platform tool schemas.
- Add a platform tool catalog that can build LangGraph-compatible structured tools.
- Prove Main Agent cannot see platform tool schemas.

### Gate B: Platform Agent Subgraph Shells

- Add hidden Facebook, Instagram, LinkedIn, and X subgraph factories.
- Each shell receives a safe route envelope and selected safe context.
- Each shell has a tool node containing only platform-owned tools.
- No live mutation execution yet.

### Gate C: Shared Tool Policy

- Add policy that grants shared tools by agent and task.
- Replace broad `main` access to platform mutation manifests.
- Add tests for denied cross-platform calls.

### Gate D: State Store Alignment

- Add typed artifact keys for latest platform caption/draft/history/schedule references.
- Remove frontend-owned context assumptions from platform follow-ups.
- Add leakage tests for auth/session state.

### Gate E: Confirmed Execution Mapping

- Map platform tool proposals to existing exactly-once executors.
- Preserve current scheduling, publishing, disconnect, and autopilot safety guarantees.
- Add idempotency/replay/tamper tests for platform tool names.

### Gate F: Main Graph Routing Cutover

- Replace domain-first routing with platform-first routing for platform-specific tasks.
- Keep domain/shared subgraphs only for non-platform or cross-platform tasks.
- Preserve user-facing Main Agent behavior.

### Gate G: Cleanup and Deletion Manifest

- Generate a live-reference manifest before removing files.
- Delete only files whose behavior has passing platform-agent replacements.
- Keep services, model policy, OAuth, database models, migrations, and audit readers.
- Run targeted tests, full backend tests, frontend lint/build/test, and `git diff --check`.
- Gate G manifest: `fb_agent/docs/PLATFORM_AGENT_DELETION_MANIFEST.md`.

### Gate H: Facebook Connect Intent Handoff

- Ensure Facebook connect commands such as `connect Facebook`, `let's connect Facebook`,
  and `letsconnect with facebook` route to the connection subgraph.
- Return safe `connection_actions` for the frontend instead of generic assistant chat.
- Add regression coverage so LLM understanding cannot downgrade deterministic connect
  intent to a generic greeting.

### Gate I: Facebook Connect/Publish Flow

- Completed Bead: `socialhub-w0u`.
- Render backend `connection_actions` in the `/agent` frontend.
- Start the existing safe Facebook OAuth handoff from the Connect Facebook action.
- Use connected Facebook page/account context when routing publish commands.
- Route Facebook publish requests through the hidden Facebook platform agent and map
  them to `publish.execute.v1` confirmation.
- Execute confirmed publish through the existing ownership, idempotency, and audit
  boundary.

## 11. Initial Cleanup Candidates

These are candidates only after Gate F passes:

- domain-first tool names superseded by platform-specific names
- domain subgraph code that becomes unreachable after platform-agent routing
- docs that describe class-based or domain-first architecture as current state
- tests tied only to deleted implementation details

Do not delete working code just because it is old. Delete it only after replacement,
reference audit, tests, rollback notes, and approval conditions are satisfied.
