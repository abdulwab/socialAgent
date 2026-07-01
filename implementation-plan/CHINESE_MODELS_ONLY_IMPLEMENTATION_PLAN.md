# SocialHub Chinese-Models-Only Implementation Plan

Research date: 2026-07-01

Implementation status: simplified backend implementation and local automated
verification completed on 2026-07-01. Production cutover remains gated by adding
a Z.AI General API key to the server environment and running live checks.

## 1. Objective

SocialHub ke Main Agent aur tamam hidden agents ko Chinese AI models par run
karna hai while preserving:

- Existing agent-first architecture.
- Database-backed memory and workflow state.
- Strict structured contracts between Main Agent and hidden agents.
- Confirmation before risky actions.
- OAuth-based social account access.
- Backend-owned models, Z.AI configuration, and API keys.
- A clean user experience in which only Main Agent is visible.

Target architecture:

```text
User
  -> Main Agent (GLM-5.2)
  -> Selected hidden agent only
       -> Complex task: GLM-4.7
       -> Simple task: GLM-4.7-Flash or FlashX
       -> Image task: GLM-Image
  -> Pydantic validation
  -> Deterministic SocialHub tool
  -> Confirmation where required
  -> Main Agent final response
```

User memory, workflows, connected accounts, drafts, confirmations, and scheduled
posts database mein rahenge. Model replace karne se memory lost nahi hogi.

## 2. Research Decisions

| Decision | Result |
|---|---|
| Model policy | Chinese models only |
| Only provider | Direct Z.AI General API |
| Coding Plan API | SocialHub product backend mein use nahi karna |
| Main Agent | GLM-5.2, with live key entitlement/billing verification before cutover |
| Complex hidden agents | GLM-4.7 |
| Small agents during testing | GLM-4.7-Flash |
| Small agents at launch | GLM-4.7-FlashX |
| Image generation | GLM-Image |
| Cross-provider fallback | None; OpenRouter and other provider gateways will be removed |
| Database migration | Required nahi |
| Frontend changes | Required nahi for gateway migration |
| Agent memory | Unchanged |

The Z.AI Coding Plan is restricted to supported coding tools and products.
SocialHub must use the General API endpoint and normal API balance:

```text
https://api.z.ai/api/paas/v4
```

Z.AI Chat Completion supports JSON output, function tools, tool calls, thinking
controls, token usage, and OpenAI-compatible request/response structures.

### 2.1 Implementation Verification Record

Completed:

- Single Z.AI-only text/JSON/tool/image gateway.
- Server `.env` key/base URL configuration.
- One JSON model catalog and per-agent model/fallback/thinking/token policy.
- Every registered agent and legacy AI route migrated to the same gateway.
- Keyword planner removed from the production orchestrator path.
- Strict Main Agent entity validation and unapproved native-tool rejection.
- Same-provider retry rules, request IDs, token, and latency logs.
- GLM-Image temporary URL validation and permanent Cloudinary copy.
- Existing state, memory, and confirmation architecture preserved.
- Local compile plus 102 backend tests passed.
- Simplified EC2 candidate image `socialhub-backend:zai-simple-20260701`
  passed isolated health/config checks and contains no boto3 dependency.
- Existing production container and database remained unchanged.

Production cutover gates:

- Add a paid/credited Z.AI General API key to the server `.env`.
- Run live text, JSON, image, routing, and workflow checks.
- Cut over only if model entitlement, JSON behavior, accuracy, latency, and
  observed billing pass.

## 3. GLM-5.2 Availability Gate

GLM-5.2 is the preferred Main Agent model because it is designed for long-horizon
agentic work, tool use, and large context. Official Z.AI General API documentation
now shows `glm-5.2`; the production key entitlement and observed billing still
need verification before cutover.

Implementation must therefore begin with a capability probe:

1. Call `glm-5.2` through the Z.AI General API.
2. Verify that the production API key is entitled to use it.
3. Verify `response_format={"type":"json_object"}`.
4. Verify tool-call response shape.
5. Inspect actual token usage and billing.
6. Record latency and error behavior.

Decision:

- If direct Z.AI General API access is available and pricing is acceptable, use
  it for Main Agent and Autopilot.
- If it is unavailable, use GLM-4.7 temporarily during testing.
- If GLM-5.2 is unavailable, use the configured GLM-4.7 fallback through the
  same Z.AI gateway.
- Production must not depend on an undocumented assumption.

## 4. Agent Model Mapping

| Agent | Testing model | Production model | Thinking |
|---|---|---|---|
| Main routing | GLM-5.2 or GLM-4.7 fallback | GLM-5.2 | Medium |
| Main final response | GLM-4.7-Flash | GLM-4.7-FlashX | Disabled |
| Assistant Chat | GLM-4.7-Flash | GLM-4.7-FlashX | Disabled |
| Connection | GLM-4.7-Flash | GLM-4.7-FlashX | Disabled |
| Product Help | GLM-4.7-Flash | GLM-4.7-FlashX | Disabled |
| Scheduling | GLM-4.7-Flash | GLM-4.7-FlashX | Disabled |
| Publishing | GLM-4.7-Flash | GLM-4.7-FlashX | Disabled |
| Media | GLM-4.7-Flash | GLM-4.7-FlashX | Disabled |
| Image Prompt | GLM-4.7-Flash | GLM-4.7-FlashX | Disabled |
| Content Strategy | GLM-4.7 | GLM-4.7 | Low or medium |
| Copywriting | GLM-4.7 | GLM-4.7 | Low |
| Analytics | GLM-4.7 | GLM-4.7 | Medium |
| Web Search Summary | GLM-4.7 | GLM-4.7 | Medium |
| Autopilot | GLM-5.2 | GLM-5.2 | Medium |
| Safety Review | GLM-4.7 plus hard rules | GLM-4.7 plus hard rules | Disabled |
| Image Generation | GLM-Image | GLM-Image | Not applicable |

Testing and production both require four main models:

1. GLM-5.2
2. GLM-4.7
3. GLM-4.7-Flash during testing or GLM-4.7-FlashX in production
4. GLM-Image

## 5. Single Z.AI GLM Gateway Architecture

SocialHub will have exactly one LLM gateway:

```text
Agent
  -> Single Z.AI GLM Gateway
  -> Model Policy
  -> Z.AI General API
```

Suggested backend structure:

```text
fb_agent/app/services/
  agent_llm_gateway.py
  agent_model_policy.py
  agent_llm_errors.py
```

Stable gateway interface:

```python
def run_agent_text(agent_key, prompt): ...
def run_agent_json(agent_key, prompt): ...
def generate_agent_image(prompt): ...
```

Agents must not know provider URLs, API keys, model IDs, or provider-specific
response formats. They should call only the stable gateway interface:

```python
run_agent_json("connection", prompt)
run_agent_text("copywriting", prompt)
generate_agent_image(prompt)
```

OpenRouter removal scope:

- Remove OpenRouter URLs and headers.
- Remove `OPENROUTER_API_KEY` usage from agent workflows.
- Remove OpenRouter provider arguments.
- Remove OpenRouter-specific error classes and messages.
- Remove OpenRouter image endpoint integration.
- Remove non-GLM model IDs and fallback mappings.
- Update tests so they verify Z.AI-only behavior.
- Do not leave a second dormant gateway or hidden OpenRouter fallback.

All LLM traffic must pass through the one Z.AI gateway.

### 5.1 No Hardcoded Runtime Configuration

The following values must not be hardcoded inside agents or gateway logic:

- Z.AI API key.
- Z.AI base URL.
- Agent-to-model assignments.
- Fallback model assignments.
- Thinking mode.
- Maximum output tokens.
- Model pricing/free-paid labels.
- Model compatibility.

Runtime sources:

| Configuration | Source |
|---|---|
| Raw Z.AI API key | Backend/server `.env` |
| Z.AI base URL | Backend/server `.env` |
| Agent-to-model map | `app/config/glm_models.json` |
| GLM model catalog | `app/config/glm_models.json` |
| Thinking/token limits | `app/config/glm_models.json` |

There must be no silent hardcoded fallback. If required configuration cannot be
loaded and no last-known valid in-memory configuration exists, the gateway must
fail safely without executing any mutation.

Agent count must come from `AGENT_REGISTRY`; it must not be hardcoded.

## 6. Implementation Phases

### Phase 0: Baseline and Safety Freeze

Tasks:

- Capture current backend test result.
- Record the current model map.
- Record current workflow states.
- Verify existing Docker image and rollback method.
- Confirm no pending database migration is required.

Completion criteria:

- Current backend tests pass.
- Current production image is identifiable.
- Rollback commands are ready.

### Phase 1: Architecture Documentation Update

Update:

- `AGENTS_ARCHITECTURE_DESIGN.md`
- `implementation-plan/NEXLAB_AGENT_FIRST_REBUILD_PLAN.md`
- `implementation-plan/NEXLAB_AGENT_FIRST_COMBINED_IMPLEMENTATION_PLAN.md`
- `AGENTS.md` and `CLAUDE.md` where they enforce OpenRouter-only behavior

Replace the OpenRouter-only rule with:

```text
All LLM calls go through one backend-owned Z.AI GLM gateway.
Only approved GLM models may be selected by the model policy.
OpenRouter and other LLM gateways are not used.
Model/API-key settings remain hidden from normal users.
Runtime model mappings are configuration-driven, not hardcoded in agent code.
```

Root documentation changes must remain separate from backend deployment work.

### Phase 2: Z.AI Runtime Configuration

Primary file:

```text
fb_agent/app/core/config.py
```

Add backend-owned configuration pointers:

```env
ZAI_BASE_URL=https://api.z.ai/api/paas/v4
ZAI_API_KEY=...
ZAI_MODEL_CONFIG_PATH=app/config/glm_models.json
```

Rules:

- Raw Z.AI key stays in the backend/server `.env`.
- Do not expose keys or model settings to the frontend.
- Do not commit real keys.
- Do not log keys.

### Phase 3: Z.AI Gateway Errors

Replace OpenRouter-specific errors with gateway-level categories:

```text
missing_api_key
invalid_or_unauthorized_key
credits_or_quota_exhausted
rate_limited
timeout
network_error
provider_unavailable
invalid_provider_response
invalid_json_response
content_filtered
```

Requirements:

- Provider messages must be sanitized.
- Secrets and key-management URLs must not enter user responses.
- Retry only retryable failures.
- Never retry authentication or quota failures.
- A retry must never duplicate a publishing or scheduling mutation.

### Phase 4: Convert the Existing Gateway to Z.AI Only

Chat endpoint:

```text
POST https://api.z.ai/api/paas/v4/chat/completions
```

Image endpoint:

```text
POST https://api.z.ai/api/paas/v4/images/generations
```

The adapter must support:

- Bearer authentication.
- Text responses.
- JSON object responses.
- Thinking enabled/disabled controls.
- Token usage extraction.
- Tool-call extraction for future native tools.
- Request IDs.
- Timeouts.
- Z.AI HTTP and business error codes.
- Image URL responses.

Also remove every OpenRouter-specific branch, URL, header, model, key, and test
fixture from the agent gateway. The completed backend must expose only one LLM
gateway implementation.

The `requests` package is already available, so a new SDK dependency is not
required unless later justified.

### Phase 5: Configuration-Driven Model Policy

The model policy must be the only component that resolves an agent to a model.
The actual mapping must be loaded from one backend JSON configuration, not
embedded in agent source files.

The reviewed model configuration lives in:

```text
fb_agent/app/config/glm_models.json
```

Do not duplicate model IDs inside individual agent files.

The gateway must validate JSON values against the approved GLM catalog before
using them.

### Phase 6: Main Agent Migration

Main Agent remains responsible for:

- Understanding Roman Urdu, English, mixed language, and spelling mistakes.
- Selecting the minimum required hidden agents.
- Extracting platforms, page names, dates, and requested actions.
- Asking one direct question when required information is missing.
- Deciding whether confirmation is required.
- Combining verified hidden-agent results.
- Producing a clean final answer.

Main routing output must remain a strict Pydantic model:

```text
extra="forbid"
```

Behavior:

- Unknown fields are rejected.
- Missing fields lead to a user question.
- Invalid structured output triggers one safe retry or fallback.
- If routing cannot be trusted, no action is executed.
- Keyword-based production fallback must not be reintroduced.

### Phase 7: Hidden Agent Migration

Every registered agent must use the central gateway:

- Assistant Chat
- Connection
- Content Strategy
- Copywriting
- Product Help
- Web Search
- Image Generation
- Media
- Scheduling
- Publishing
- Analytics
- Autopilot
- Safety Review

Rules:

- Only Main Agent invokes hidden agents.
- Hidden agents do not invoke each other directly.
- Only selected agents run and consume tokens.
- Deterministic business logic remains deterministic.
- LLMs explain and interpret; they do not silently mutate data.

### Phase 8: Structured JSON and Tool Safety

Execution pipeline:

```text
GLM decision
  -> Strict Pydantic validation
  -> Unknown fields rejected
  -> Missing fields become a question
  -> Deterministic safety rules
  -> User confirmation if required
  -> Exact backend function
```

Risky actions requiring confirmation:

- Publish now.
- Schedule posts.
- Bulk schedule.
- Disconnect social app.
- Delete posts or media.
- Enable or disable Autopilot.
- Change Autopilot schedule/frequency.
- Bulk retry.
- Overwrite drafts.

Safe read-only actions:

- Connected app status.
- Facebook Page listing.
- Token health status without exposing tokens.
- Content generation.
- Image preview.
- Analytics summary.
- Queue preview.

OAuth tokens, passwords, cookies, API keys, and raw credentials must never be
included in prompts.

### Phase 9: Facebook Page Selection Workflow

Per-workflow selection:

```text
User: Authentic World par post banao
  -> Main Agent detects Facebook and the Page name
  -> Connection Agent reads synced Pages
  -> Backend deterministically matches exact page_id
  -> Copywriting Agent creates the post
  -> Main Agent shows Page name and preview
  -> User confirms publishing
  -> Publishing service receives exact page_id
```

Follow-up:

```text
User: Ab MS Collection par post karo
```

The next workflow selects MS Collection. No permanent default change is implied.

Permanent preference only changes when the user explicitly says:

```text
MS Collection ko default Facebook Page bana do
```

If persistent default Page support is later implemented, that work requires a
separate database migration approval.

### Phase 10: GLM Image Integration

Use:

```text
model=glm-image
```

Flow:

1. Image Prompt Agent writes a concise prompt.
2. GLM-Image generates the asset.
3. Validate the Z.AI image URL and content type.
4. Upload/copy the image immediately to Cloudinary.
5. Store only the permanent Cloudinary URL in artifacts.
6. Do not depend on the temporary provider URL.

The Z.AI URL may expire, so permanent storage is mandatory.

### Phase 11: Web Search Strategy

Initial implementation keeps the existing search-fetch path:

```text
Search service
  -> Verified sources/content
  -> GLM-4.7 grounded summary
```

Do not enable Z.AI built-in web search initially because:

- It has an additional per-use cost.
- Existing fetch behavior already exists.
- Source validation must remain under application control.

Later, compare the built-in search behind a feature flag.

### Phase 12: Single-Gateway GLM Fallback Policy

All fallback models must use the same Z.AI General API gateway:

```text
GLM-5.2
  -> GLM-4.7
  -> GLM-4.7-FlashX
```

The order is loaded from `glm_models.json` and is not hardcoded in gateway code.

Limitation: a complete Z.AI outage affects all models. In that case the request
must fail safely, preserve workflow state, keep the user logged in, and execute
no mutation.

### Phase 13: Cost and Latency Controls

- Disable thinking for simple agents.
- Use medium reasoning only for Main Agent and complex Autopilot setup.
- Cap conversation history and artifact context.
- Run only selected agents.
- Set per-agent maximum output tokens.
- Do not web-search unless the request requires fresh data.
- Retry once only for retryable failures.
- Do not retry authentication or quota errors.
- Generate images only when requested.
- Log input/output tokens, latency, model, gateway, and agent key server-side.
- Use free Flash during controlled testing.
- Use paid FlashX in production.
- Never expose model names or cost traces in the normal user interface.

## 7. Required Tests

### 7.1 Unit Tests

- Z.AI authentication headers.
- Text response parsing.
- JSON response parsing.
- Invalid JSON rejection.
- Unknown-field rejection.
- Missing-field question behavior.
- Timeout classification.
- Rate-limit handling.
- Quota exhaustion handling.
- Provider-unavailable handling.
- Content-filter handling.
- Image URL validation.
- Cloudinary copy/upload.
- Model mapping for every registered agent.
- No secrets in prompts.
- No internal model/provider details in user responses.

### 7.2 Routing Evaluation

Maintain representative routing tests covering:

- Roman Urdu.
- English.
- Mixed Roman Urdu and English.
- Common spelling mistakes.
- Follow-up commands.
- Facebook Page switching.
- Connected app questions.
- Web-search capability questions.
- Product-help questions.
- Greetings versus actual commands.
- Draft generation.
- Scheduling and publishing confirmation.
- Autopilot configuration.
- Analytics requests.

### 7.3 Workflow State Tests

| Scenario | Expected state |
|---|---|
| Normal answer | `completed` |
| Missing information | `completed` with one question |
| Publish/schedule preview | `waiting_for_confirmation` |
| Confirmed mutation | `executing_mutation` then `completed` |
| Rejected confirmation | `cancelled` |
| Provider unavailable | `failed` without logout |
| Invalid LLM JSON | Retry/fallback, no mutation |

### 7.4 Agent Isolation Tests

Copywriting:

```text
main -> copywriting -> main_final
```

Only those runs should exist.

Risky publishing:

```text
main -> publishing -> safety_review -> main_final
```

Unrelated agents must not run or consume tokens.

### 7.5 Security Tests

- No OAuth token in prompts.
- No refresh token in prompts.
- No cookies or passwords in prompts.
- No API keys in prompts/logs/responses.
- No cross-user Page/account access.
- Model cannot choose an unapproved tool.
- Model cannot bypass confirmation.
- Model cannot add unknown action fields.

## 8. Acceptance Criteria

| Metric | Required result |
|---|---:|
| Intent-routing accuracy | At least 95% |
| Valid structured JSON | At least 99% |
| Correct hidden-agent selection | At least 97% |
| Connected-app/Page facts against DB fixtures | 100% |
| Risky actions requiring confirmation | 100% |
| Mutation without confirmation | 0 |
| Secret leakage | 0 |
| Roman Urdu human-review score | At least 4/5 |
| Simple command p95 latency | Under 8 seconds |
| Complex command p95 latency | Under 15 seconds |
| Login/logout regression | 0 |
| Existing backend tests | 100% pass |
| Frontend lint/build/tests if frontend touched | 100% pass |

## 9. Deployment Plan

1. Run the current backend baseline tests.
2. Convert the existing gateway to the single Z.AI implementation locally.
3. Run the Z.AI General API capability probe.
4. Run unit and contract tests.
5. Run representative Roman Urdu and mixed-language routing checks.
6. Verify workflow states and confirmation behavior.
7. Verify no secrets enter prompts.
8. Verify cost and latency logs.
9. Use controlled test accounts for integration tests.
10. Do not publish real content without explicit confirmation.
11. Run full backend `pytest`.
12. Do not push backend code to GitHub.
13. Transfer approved backend files to EC2 through SCP.
14. Build a new Docker image on the server.
15. Restart the `socialhub-api` container using:

```text
/home/ubuntu/fb_agent/.env
```

16. Verify:

```bash
sudo docker ps
sudo docker logs socialhub-api
curl http://localhost:8000/health
```

17. Run authenticated agent smoke tests.
18. Start with controlled users.
19. Monitor error rate, latency, token use, and costs.
20. Expand rollout only after acceptance criteria remain green.

Backend deployment remains Docker-only. Backend changes must not be pushed to
GitHub.

## 10. Rollback Plan

- Keep the previous Docker image available.
- Keep model and Z.AI configuration reversible.
- Restore the previous container if the GLM rollout fails.
- Preserve database state.
- Do not alter workflow or memory schemas for this migration.
- Keep the previous Docker image for rollback; do not keep a second live LLM
  gateway in the completed code.
- A Z.AI failure must never log the user out.
- A Z.AI failure must never execute a pending mutation.

Because no database migration is planned, rollback risk is low. User accounts,
connected apps, memory, drafts, posts, schedules, and confirmations remain
unchanged.

## 11. Final Testing and Launch Configuration

Testing:

```text
Main/Autopilot   -> GLM-5.2 if General API verified, otherwise GLM-4.7
Complex agents   -> GLM-4.7
Small agents     -> GLM-4.7-Flash
Images           -> GLM-Image
```

Production:

```text
Main/Autopilot   -> GLM-5.2
Complex agents   -> GLM-4.7
Small agents     -> GLM-4.7-FlashX
Images           -> GLM-Image
Fallback         -> Approved GLM models through the same Z.AI gateway only
```

This architecture provides:

- Cheap testing.
- Stronger models where reasoning matters.
- Lower-cost models for routine tasks.
- Safe model replacement.
- Preserved memory and workflow state.
- Strict tool validation.
- Confirmation before mutations.
- Chinese-model-only enforcement.
- Long-term GLM model flexibility through configuration.

## 12. Research Sources

- Z.AI Chat Completion:
  <https://docs.z.ai/api-reference/llm/chat-completion>
- Z.AI GLM-5.2 release:
  <https://z.ai/blog/glm-5.2>
- Z.AI General HTTP API:
  <https://docs.z.ai/guides/develop/http/introduction>
- Z.AI GLM-4.7:
  <https://docs.z.ai/guides/llm/glm-4.7>
- Z.AI pricing:
  <https://docs.z.ai/guides/overview/pricing>
- Z.AI GLM-Image:
  <https://docs.z.ai/guides/image/glm-image>
- Z.AI Coding Plan FAQ:
  <https://docs.z.ai/devpack/faq>
- Z.AI error codes:
  <https://docs.z.ai/api-reference/api-code>
