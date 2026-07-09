# SocialHub — Complete Tools Analysis

**Generated:** 2026-07-09
**Project:** SocialHub (NexLab)
**Total Tools:** 56

---

## 🔹 A. REGISTRY TOOLS (21)

### READ Tools (4)

| Tool ID | Name / What It Does | Arguments | JSON Schema |
|---|---|---|---|
| `connections.list.v1` | List all connected social accounts (Facebook, Instagram, LinkedIn, X) with health status | None | `{}` |
| `content.ideas.list.v1` | List saved content ideas filtered by status | `status: string\|null`, `limit: integer (1-100, default 50)` | `{"status":{"type":"string","maxLength":20},"limit":{"type":"integer","minimum":1,"maximum":100,"default":50}}` |
| `autopilot.config.get.v1` | Read current autopilot configuration: active status, platforms, topics, tone, posting schedule | None | `{}` |
| `schedule.summary.get.v1` | Read schedule status summary: total posts + breakdown by status (pending/failed/published) | None | `{}` |

### MUTATION Tools (17)

| Tool ID | Name / What It Does | Arguments | JSON Schema |
|---|---|---|---|
| `connections.disconnect.v1` | Disconnect an OAuth social platform account | `resource_id: int\|null`, `payload: {platform: string}` | `{"resource_id":{"type":"integer","minimum":1},"payload":{"type":"object","default":{}}}` |
| `content.idea.create.v1` | Create a new saved content idea | `resource_id: int\|null`, `payload: {title, content, platform, tags}` | `{"resource_id":{"type":"integer","minimum":1},"payload":{"type":"object","default":{}}}` |
| `content.idea.update.v1` | Update an existing saved content idea | `resource_id: int`, `payload: {title?, content?, platform?, tags?}` | `{"resource_id":{"type":"integer","minimum":1},"payload":{"type":"object","default":{}}}` |
| `content.idea.delete.v1` | Delete a saved content idea | `resource_id: int`, `payload: {}` | `{"resource_id":{"type":"integer","minimum":1},"payload":{"type":"object","default":{}}}` |
| `image.generate.v1` | Generate an image from prompt and store it | `resource_id: int\|null`, `payload: {prompt: string}` | `{"resource_id":{"type":"integer","minimum":1},"payload":{"type":"object","default":{}}}` |
| `media.upload.v1` | Upload and store media file | `resource_id: int\|null`, `payload: {url: string, content_type: string}` | `{"resource_id":{"type":"integer","minimum":1},"payload":{"type":"object","default":{}}}` |
| `media.delete.v1` | Delete stored media by artifact ID | `resource_id: int\|null`, `payload: {artifact_id: string}` | `{"resource_id":{"type":"integer","minimum":1},"payload":{"type":"object","default":{}}}` |
| `schedule.create.v1` | Create a single scheduled post | `resource_id: int\|null`, `payload: {platform, scheduled_at, content}` | `{"resource_id":{"type":"integer","minimum":1},"payload":{"type":"object","default":{}}}` |
| `schedule.bulk_create.v1` | Create multiple scheduled posts at once | `resource_id: int\|null`, `payload: {items: [{platform, scheduled_at, content}]}` | `{"resource_id":{"type":"integer","minimum":1},"payload":{"type":"object","default":{}}}` |
| `schedule.update.v1` | Update an existing scheduled post | `resource_id: int`, `payload: {scheduled_at?, content?, platform?}` | `{"resource_id":{"type":"integer","minimum":1},"payload":{"type":"object","default":{}}}` |
| `schedule.delete.v1` | Delete a scheduled post | `resource_id: int`, `payload: {}` | `{"resource_id":{"type":"integer","minimum":1},"payload":{"type":"object","default":{}}}` |
| `publish.execute.v1` | Publish a post to a social platform immediately | `resource_id: int\|null`, `payload: {artifact_id, platform, account_id}` | `{"resource_id":{"type":"integer","minimum":1},"payload":{"type":"object","default":{}}}` |
| `publish.retry.v1` | Retry a previously failed publish | `resource_id: int\|null`, `payload: {scheduled_post_id, stale_version}` | `{"resource_id":{"type":"integer","minimum":1},"payload":{"type":"object","default":{}}}` |
| `autopilot.config.apply.v1` | Create or update autopilot configuration (platforms, topics, tone, schedule) | `resource_id: int\|null`, `payload: {config: {platforms, topics, tone, posting_times, posting_days, timezone}}` | `{"resource_id":{"type":"integer","minimum":1},"payload":{"type":"object","default":{}}}` |
| `autopilot.toggle.v1` | Enable or disable autopilot | `resource_id: int\|null`, `payload: {is_active: bool}` | `{"resource_id":{"type":"integer","minimum":1},"payload":{"type":"object","default":{}}}` |

---

## 🔹 B. LANGGRAPH SUBGRAPH TOOLS (11)

| Tool ID | Name / What It Does | Arguments | JSON Schema |
|---|---|---|---|
| `connection_subgraph` | Handle platform connect/disconnect/status/health/oauth guidance. Reads PageToken, LinkedInAccount, XAccount tables | `user_id: int`, `command: str`, `language: str`, `platform: str\|null`, `page_name: str\|null`, `connection_snapshot: dict`, `validated_connection_action: dict` | `{"user_id":{"type":"integer"},"command":{"type":"string"},"language":{"type":"string"},"platform":{"anyOf":[{"type":"string"},{"type":"null"}]},"page_name":{"anyOf":[{"type":"string"},{"type":"null"}]},"connection_snapshot":{"type":"object"},"validated_connection_action":{"type":"object"}}` |
| `strategy_subgraph` | Generate content strategy with angles/topics/goals via Z.AI LLM. Creates artifact type "strategy" | `thread_id: str`, `command: str`, `topic: str`, `platforms: list[str]`, `language: str`, `post_count: int`, `relevant_memories: list[dict]` | `{"thread_id":{"type":"string"},"command":{"type":"string"},"topic":{"type":"string"},"platforms":{"type":"array","items":{"type":"string"}},"language":{"type":"string"},"post_count":{"type":"integer"},"relevant_memories":{"type":"array","items":{"type":"object"}}}` |
| `copywriting_subgraph` | Generate platform-specific drafts with hashtags via Z.AI LLM. Validates + repairs output. Fallback safe draft on failure | `thread_id: str`, `command: str`, `topic: str`, `platforms: list[str]`, `language: str`, `post_count: int`, `relevant_memories: list[dict]`, `strategy_context: dict\|null` | `{"thread_id":{"type":"string"},"command":{"type":"string"},"topic":{"type":"string"},"platforms":{"type":"array","items":{"type":"string"}},"language":{"type":"string"},"post_count":{"type":"integer"},"relevant_memories":{"type":"array","items":{"type":"object"}},"strategy_context":{"anyOf":[{"type":"object"},{"type":"null"}]}}` |
| `scheduling_subgraph` | Validate timezone, platform connection, duplicate detection. Returns schedule preview with valid/invalid rows | `user_id: int`, `thread_id: str`, `candidates: list[{artifact_id, platform, scheduled_at, timezone}]`, `connection_snapshot: dict`, `existing_schedules: list[dict]` | `{"user_id":{"type":"integer"},"thread_id":{"type":"string"},"candidates":{"type":"array","items":{"type":"object"}},"connection_snapshot":{"type":"object"},"existing_schedules":{"type":"array","items":{"type":"object"}}}` |
| `safety_subgraph` | Deterministic safety review of schedule preview. Creates approval_envelope with hash for confirmation | `user_id: int`, `thread_id: str`, `preview: {items, errors, preview_id}` | `{"user_id":{"type":"integer"},"thread_id":{"type":"string"},"preview":{"type":"object"}}` |
| `image_subgraph` | Generate image prompt via LLM → call image API → store in Cloudinary. Returns artifact type "image" | `thread_id: str`, `user_id: int`, `command: str`, `language: str` | `{"thread_id":{"type":"string"},"user_id":{"type":"integer"},"command":{"type":"string"},"language":{"type":"string"}}` |
| `media_subgraph` | Validate media reference, attach to draft, or prepare deletion proposal. Checks content_type, size, URL | `thread_id: str`, `user_id: int`, `command: str`, `artifact_index: dict`, `artifact_reference: str\|null` | `{"thread_id":{"type":"string"},"user_id":{"type":"integer"},"command":{"type":"string"},"artifact_index":{"type":"object"},"artifact_reference":{"anyOf":[{"type":"string"},{"type":"null"}]}}` |
| `web_search_subgraph` | DuckDuckGo search → fetch top 5 URLs → extract text excerpts. Returns cited sources artifact | `thread_id: str`, `user_id: int`, `command: str` | `{"thread_id":{"type":"string"},"user_id":{"type":"integer"},"command":{"type":"string"}}` |
| `analytics_subgraph` | Read PostMetricsDaily + ProfileMetricsDaily from DB. Returns analytics summary by platform | `thread_id: str`, `user_id: int`, `platforms: list[str]`, `analytics_snapshot: {profiles, posts}` | `{"thread_id":{"type":"string"},"user_id":{"type":"integer"},"platforms":{"type":"array","items":{"type":"string"}},"analytics_snapshot":{"type":"object"}}` |
| `publishing_subgraph` | Validate draft → create publish or retry proposal with payload hash. Checks platform limits, image requirement | `thread_id: str`, `user_id: int`, `command: str`, `platforms: list[str]`, `artifact_index: dict`, `artifact_reference: str\|null`, `account_snapshot: dict`, `failed_publish_snapshot: list[dict]` | `{"thread_id":{"type":"string"},"user_id":{"type":"integer"},"command":{"type":"string"},"platforms":{"type":"array","items":{"type":"string"}},"artifact_index":{"type":"object"},"artifact_reference":{"anyOf":[{"type":"string"},{"type":"null"}]},"account_snapshot":{"type":"object"},"failed_publish_snapshot":{"type":"array","items":{"type":"object"}}}` |
| `autopilot_subgraph` | Parse command for enable/disable/config change. Creates autopilot toggle or config proposal | `thread_id: str`, `user_id: int`, `command: str`, `platforms: list[str]`, `autopilot_snapshot: dict` | `{"thread_id":{"type":"string"},"user_id":{"type":"integer"},"command":{"type":"string"},"platforms":{"type":"array","items":{"type":"string"}},"autopilot_snapshot":{"type":"object"}}` |

---

## 🔹 C. LANGGRAPH FLOW NODES (19)

| Tool ID | Name / What It Does | Arguments | JSON Schema |
|---|---|---|---|
| `context_load` | Load safe context: owned Facebook pages, current drafts, latest draft ID | `user_id: int`, `artifacts: {artifact_index?}` | `{"user_id":{"type":"integer"},"artifacts":{"type":"object"}}` |
| `structured_understanding` | Hybrid LLM + rule-based intent classification. Returns intents, entities, language, confidence | `command: str`, `artifacts: {artifact_index?}` | `{"command":{"type":"string"},"artifacts":{"type":"object"}}` |
| `deterministic_validation` | Validate intents against available context. Detect missing entities (draft, platform, schedule_at, topic) | `understanding: {intents, entities}`, `working_context: {connection_snapshot?, has_current_draft?}` | `{"understanding":{"type":"object"},"working_context":{"type":"object"}}` |
| `clarification` | Generate clarifying question in English/Roman Urdu. Save pending_clarification in working context | `clarifying_question: str\|null`, `validation: {missing, invalid}` | `{"clarifying_question":{"anyOf":[{"type":"string"},{"type":"null"}]},"validation":{"type":"object"}}` |
| `planning` | Build ordered workflow plan from intents: WEB_SEARCH → STRATEGY → COPYWRITING → IMAGE → MEDIA → CONNECTION → ANALYTICS → SCHEDULING → PUBLISHING → AUTOPILOT | `understanding: {intents}`, `validation: {valid}` | `{"understanding":{"type":"object"},"validation":{"type":"object"}}` |
| `assistant_chat` | Return greeting or language capability reply. No subgraph execution | `understanding: {language, intents}` | `{"understanding":{"type":"object"}}` |
| `product_help` | Return SocialHub feature explanation. No subgraph execution | `understanding: {language, intents}` | `{"understanding":{"type":"object"}}` |
| `domain_routing` | Assemble final reply with artifacts (connection_actions, drafts, etc.). Terminal node | `artifacts: {connection_actions?, connected_apps?}`, `final_reply: str\|null` | `{"artifacts":{"type":"object"},"final_reply":{"anyOf":[{"type":"string"},{"type":"null"}]}}` |
| `connection_node` | Execute connection subgraph. Create disconnect approval envelope with payload hash | `user_id: int`, `command: str`, `working_context: {connection_snapshot?, valid ated_connection_action?}`, `understanding: {language, entities}` | `{"user_id":{"type":"integer"},"command":{"type":"string"},"working_context":{"type":"object"},"understanding":{"type":"object"}}` |
| `content_node` | Execute strategy + copywriting subgraphs. Handle artifact edits (improve/rewrite/add-line). Merge artifact_index | `command: str`, `understanding: {language, intents, entities}`, `working_context: {relevant_memories?, resolved_artifact_id?, artifact_edit_request?}`, `artifacts: {artifact_index?}` | `{"command":{"type":"string"},"understanding":{"type":"object"},"working_context":{"type":"object"},"artifacts":{"type":"object"}}` |
| `scheduling_node` | Execute scheduling subgraph. Resolve drafts from artifact_index. Returns schedule preview | `understanding: {entities, intents}`, `working_context: {connection_snapshot?, existing_schedules?, resolved_artifact_id?}`, `artifacts: {drafts?, artifact_index?}` | `{"understanding":{"type":"object"},"working_context":{"type":"object"},"artifacts":{"type":"object"}}` |
| `safety_node` | Execute safety subgraph. Create approval_envelope with schedule.bulk_create.v1 or schedule.create.v1 payload | `schedule_preview: dict`, `user_id: int`, `thread_id: str` | `{"schedule_preview":{"type":"object"},"user_id":{"type":"integer"},"thread_id":{"type":"string"}}` |
| `approval_interrupt` | LangGraph interrupt for scheduling confirmation. Waits for user resume with confirm/cancel | `approval_envelope: {approval_id, payload_hash, expires_at, payload: {items}}` | `{"approval_envelope":{"type":"object"}}` |
| `research_node` | Execute web search subgraph. Returns research artifact with cited sources | `command: str`, `thread_id: str`, `user_id: int` | `{"command":{"type":"string"},"thread_id":{"type":"string"},"user_id":{"type":"integer"}}` |
| `image_node` | Execute image generation subgraph. Returns image artifact with URL, public_id, metadata | `command: str`, `thread_id: str`, `user_id: int`, `understanding: {language}` | `{"command":{"type":"string"},"thread_id":{"type":"string"},"user_id":{"type":"integer"},"understanding":{"type":"object"}}` |
| `media_node` | Execute media subgraph. Handle attach/delete/inspect operations. Create deletion approval envelope | `command: str`, `thread_id: str`, `user_id: int`, `understanding: {entities}`, `working_context: {resolved_artifact_id?}`, `artifacts: {artifact_index?}` | `{"command":{"type":"string"},"thread_id":{"type":"string"},"user_id":{"type":"integer"},"understanding":{"type":"object"},"working_context":{"type":"object"},"artifacts":{"type":"object"}}` |
| `media_deletion_interrupt` | LangGraph interrupt for media delete confirmation. Waits for user resume | `approval_envelope: {approval_id, payload_hash, expires_at, payload: {target}}` | `{"approval_envelope":{"type":"object"}}` |
| `analytics_node` | Execute analytics subgraph. Returns analytics artifact with per-platform metrics | `understanding: {entities}`, `working_context: {analytics_snapshot?}`, `thread_id: str`, `user_id: int` | `{"understanding":{"type":"object"},"working_context":{"type":"object"},"thread_id":{"type":"string"},"user_id":{"type":"integer"}}` |
| `publishing_node` | Execute publishing subgraph. Create publish/retry proposal with approval envelope | `understanding: {entities}`, `working_context: {resolved_artifact_id?, publishing_account_snapshot?, failed_publish_snapshot?}`, `thread_id: str`, `user_id: int`, `command: str` | `{"understanding":{"type":"object"},"working_context":{"type":"object"},"thread_id":{"type":"string"},"user_id":{"type":"integer"},"command":{"type":"string"}}` |
| `autopilot_node` | Execute autopilot subgraph. Create toggle/config proposal with approval envelope | `understanding: {entities}`, `working_context: {autopilot_snapshot?}`, `thread_id: str`, `user_id: int`, `command: str` | `{"understanding":{"type":"object"},"working_context":{"type":"object"},"thread_id":{"type":"string"},"user_id":{"type":"integer"},"command":{"type":"string"}}` |
| `operational_interrupt` | LangGraph interrupt for publish/autopilot confirmation. Waits for user resume with confirm/cancel | `approval_envelope: {approval_id, payload_hash, expires_at, payload: {tool_name}}` | `{"approval_envelope":{"type":"object"}}` |

---

## 🔹 D. Z.AI LLM AGENT KEYS (3)

| Tool ID | Name / What It Does | Arguments | JSON Schema |
|---|---|---|---|
| `main` | Intent classification + entity extraction. Receives user command, rule-based guess, and artifact context. Returns intents, language, platforms, topic | `command: str`, `rule_based: CommandUnderstanding`, `artifacts: {artifact_index?}` | `{"command":{"type":"string"},"rule_based":{"$ref":"CommandUnderstanding"},"artifacts":{"type":"object"}}` |
| `content_strategy` | Generate content strategy. Returns summary + content_angles array with title, topic, goal per angle | `command: str`, `platforms: list[str]`, `language: str`, `memories: [{scope, key, value}]` | `{"command":{"type":"string"},"platforms":{"type":"array","items":{"type":"string"}},"language":{"type":"string"},"memories":{"type":"array"}}` |
| `copywriting` | Generate platform-specific drafts. Returns drafts array with platform, content, hashtags per item | `command: str`, `topic: str`, `platforms: list[str]`, `language: str`, `memories: [{scope, key, value}]`, `strategy: dict\|null` | `{"command":{"type":"string"},"topic":{"type":"string"},"platforms":{"type":"array","items":{"type":"string"}},"language":{"type":"string"},"memories":{"type":"array"},"strategy":{"anyOf":[{"type":"object"},{"type":"null"}]}}` |

---

## 🔹 E. INTERNAL EXECUTORS (2)

| Tool ID | Name / What It Does | Arguments | JSON Schema |
|---|---|---|---|
| `ExactlyOnceSchedulingExecutor` | Idempotent schedule execution. FOR UPDATE lock on AgentConfirmation → revalidate → insert ScheduledPost → write AgentRun audit | `db: connection`, `user_id: int`, `checkpoint_state: {approval_envelope, artifacts}`, `resume: {action, approval_id, payload_hash}` | `{"checkpoint_state":{"type":"object"},"resume":{"type":"object","properties":{"action":{"type":"string"},"approval_id":{"type":"string"},"payload_hash":{"type":"string"}}}}` |
| `ExactlyOnceActionExecutor` | Idempotent action execution. Handles publish.execute.v1, publish.retry.v1, connections.disconnect.v1, autopilot.toggle.v1, autopilot.config.apply.v1 | `db: connection`, `user_id: int`, `checkpoint_state: {approval_envelope, artifacts}`, `resume: {action, approval_id, payload_hash}` | `{"checkpoint_state":{"type":"object"},"resume":{"type":"object","properties":{"action":{"type":"string"},"approval_id":{"type":"string"},"payload_hash":{"type":"string"}}}}` |

---

## Quick Count

| Section | Count |
|---|---|
| A. Registry Tools (READ) | 4 |
| A. Registry Tools (MUTATION) | 17 |
| B. LangGraph Subgraph Tools | 11 |
| C. LangGraph Flow Nodes | 19 |
| D. Z.AI LLM Agent Keys | 3 |
| E. Internal Executors | 2 |
| **Total** | **56** |
