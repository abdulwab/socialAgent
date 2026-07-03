# NexLab Agent Architecture Design

| Field | Detail |
|---|---|
| Project | NexLab / SocialHub Agent-First System |
| Document Purpose | Explain how agents will be built, coordinated, designed, and how state and memory will be managed |

> **2026-07-03 architecture decision:** The target runtime is now LangGraph. The
> existing custom class registry/orchestrator is a legacy implementation to be replaced
> through a tested cutover. All eleven hidden domain agents will be LangGraph
> nodes/subgraphs, and existing SocialHub services/APIs will be exposed as typed,
> permissioned tools. Durable thread state will use a PostgreSQL LangGraph checkpointer;
> safe cross-thread memory will use a scoped persistent store. See
> `implementation-plan/NEXLAB_LANGGRAPH_FULL_REBUILD_PLAN.md` for the authoritative
> replacement sequence, safety gates, migration plan, and definition of done.
> The customer frontend remains the branded Next.js `/agent` application with optional
> `assistant-ui` primitives and typed SSE. Open WebUI is not the customer frontend.
> Step execution and test evidence follow
> `implementation-plan/NEXLAB_LANGGRAPH_TEST_GATED_EXECUTION_CHECKLIST.md`.
| Version | 1.0 |
| Last Updated | 2026-06-22 |
| Status | Planning / Architecture Design |

---

## 1. Executive Summary

NexLab ka final product agent-first hoga. User ko sirf **Main Agent** nazar aayega. Baqi subagents hidden/internal services ki tarah kaam karenge.

User command text ya voice se dega. Main Agent command samjhega, intent classify karega, required hidden agents ko kaam dega, unka result combine karega, safety check karwaye ga, aur user ko final clean output dikhaye ga.

Subagents user ke samne visible nahi honge. User ko yeh feel hoga ke woh ek single intelligent assistant se baat kar raha hai.

---

## 2. Core Agent Model

System mein agents ko independent UI tabs ki tarah nahi banaya jayega. Agents backend services honge.

Each agent ka role clear hoga:

| Agent | Responsibility |
|---|---|
| Main Agent / Orchestrator | User command samajhna, plan banana, hidden agents ko call karna, final answer dena |
| Connection Agent | Social apps connect/reconnect/disconnect/status handle karna |
| Content Strategy Agent | Campaign ideas, post angles, weekly/monthly content planning |
| Copywriting Agent | Captions, hashtags, rewrites, platform-specific copy |
| Image Generation Agent | Image prompt banana aur image generation service ko call karna |
| Media Agent | Uploaded/generated media save, attach, select, validate karna |
| Scheduling Agent | Post timing, timezone, queue, schedule preview, scheduled posts create karna |
| Publishing Agent | Publish now, retry failed posts, platform API response handle karna |
| Analytics Agent | Metrics summarize karna, best time/content insights dena |
| Autopilot Agent | Recurring automation setup aur recurring draft generation |
| Safety And Review Agent | Mutating actions, policy checks, duplicates, limits, confirmation rules |
| Web Search Agent | Fresh/latest web info fetch karna aur summarize karna |

---

## 3. Agent Design Principles

Agents ko design karte waqt yeh rules follow honge:

1. **Single visible assistant**
   User ko sirf Main Agent nazar aayega. Subagents hidden rahenge.

2. **One agent, one responsibility**
   Har hidden agent ka kaam limited aur clear hoga. For example, Scheduling Agent content nahi likhega, woh sirf schedule planning karega.

3. **Structured input/output**
   Agents free-form random text exchange nahi karenge. Data JSON contracts mein pass hoga.

4. **Main Agent owns context**
   Full conversation context sirf Main Agent ke paas hoga. Hidden agents ko sirf required limited context milega.

5. **Safety before mutation**
   Publish, schedule, delete, disconnect, autopilot enable jaisay actions pehle Safety And Review Agent se pass honge.

6. **No secrets in prompts**
   OAuth tokens, API keys, passwords, cookies, raw credentials LLM prompt mein nahi bheje jayenge.

7. **Z.AI GLM-only LLM gateway**
   All LLM and image-generation calls backend ke single Z.AI General API gateway
   se hongi. API key server `.env` aur model policy one backend JSON file se
   load hogi. User ko API key/provider/model settings nahi milengi.

---

## 4. Main Agent / Orchestrator

Main Agent system ka brain hoga.

Main responsibilities:

- user command receive karna
- input mode detect karna: text, voice, CSV, file upload
- intent classify karna
- required hidden agents select karna
- execution plan banana
- agent calls sequence karna
- results merge karna
- safety checks run karna
- confirmation required ho to user se ask karna
- final response frontend ko dena

Main Agent direct database mutation nahi karega jab tak Safety And Review Agent approve na kare.

### Main Agent Flow

```txt
User Command
  -> Main Agent
  -> Intent Classification
  -> Workflow Plan
  -> Hidden Agent Calls
  -> Safety Review
  -> Final Response / Confirmation
  -> Execute Mutation After Confirmation
```

Example:

```txt
User: AI marketing ke liye 5 posts banao aur Monday se Friday 9 AM schedule karo.
```

Flow:

1. Main Agent detects: content creation + scheduling.
2. Content Strategy Agent creates 5 post angles.
3. Copywriting Agent writes final captions.
4. Scheduling Agent creates schedule preview.
5. Safety And Review Agent validates schedule.
6. Main Agent shows drafts and asks confirmation.
7. User confirms.
8. Scheduling Agent writes scheduled posts to database.

---

## 5. How Agents Get Triggered

Agent trigger command ke intent par based hoga.

| User Input Type | Triggered Agent |
|---|---|
| "LinkedIn connect karo" | Connection Agent |
| "5 posts banao" | Content Strategy Agent, then Copywriting Agent |
| "Post ko better likho" | Copywriting Agent |
| "Is post ke liye image banao" | Image Generation Agent, then Media Agent |
| "CSV upload kar ke schedule karo" | Scheduling Agent, then Safety And Review Agent |
| "Friday 9 AM schedule karo" | Scheduling Agent |
| "Abhi publish karo" | Publishing Agent, then Safety And Review Agent |
| "Last 30 days analytics batao" | Analytics Agent |
| "Latest AI trends search karo" | Web Search Agent |
| "Autopilot chala do" | Autopilot Agent, then Safety And Review Agent |
| "Disconnect Facebook" | Connection Agent, then Safety And Review Agent |

One command multiple agents trigger kar sakta hai.

Example:

```txt
User: Latest AI tools par 3 LinkedIn posts banao aur images bhi generate karo.
```

Triggered agents:

1. Web Search Agent
2. Content Strategy Agent
3. Copywriting Agent
4. Image Generation Agent
5. Media Agent
6. Safety And Review Agent

---

## 6. Agent Coordination Model

Agents direct ek dusray se uncontrolled call nahi karenge.

Allowed pattern:

```txt
User
  -> Main Agent
  -> Hidden Agent A
  -> Main Agent
  -> Hidden Agent B
  -> Main Agent
  -> User
```

Avoid pattern:

```txt
Agent A -> Agent B -> Agent C
```

Reason:

- Main Agent context owner rahega.
- Debugging simple hogi.
- Safety rules centralized rahenge.
- User ko single assistant experience milega.
- Agent loops aur duplicate actions avoid honge.

### Coordination Example

```txt
User: Latest AI marketing trends se Monday to Friday posts schedule karo.
```

Main Agent plan:

1. Web Search Agent ko latest trend research task.
2. Content Strategy Agent ko research se 5 content angles.
3. Copywriting Agent ko 5 final posts.
4. Scheduling Agent ko Monday-Friday 9 AM preview.
5. Safety Agent ko final validation.
6. User ko preview + confirm button.

No hidden agent user ko directly reply nahi karega.

---

## 7. Agent Communication Contract

All agent communication structured JSON mein hogi.

### Request Envelope

Main Agent hidden agent ko yeh format dega:

```json
{
  "request_id": "cmd_20260622_001",
  "workflow_id": "wf_001",
  "user_id": 123,
  "agent_key": "copywriting",
  "intent": "write_posts",
  "input_mode": "text",
  "command": "AI marketing ke liye 5 posts banao",
  "context": {
    "timezone": "Asia/Karachi",
    "platforms": ["linkedin"],
    "connected_apps": {
      "linkedin": {
        "connected": true,
        "account_id": "li_123"
      }
    },
    "user_preferences": {
      "tone": "professional",
      "language": "roman_urdu_english"
    },
    "previous_outputs": []
  },
  "constraints": {
    "requires_confirmation_for_mutations": true,
    "do_not_include_secrets": true,
    "max_posts": 5
  }
}
```

### Agent Response Envelope

Hidden agent Main Agent ko yeh response dega:

```json
{
  "request_id": "cmd_20260622_001",
  "workflow_id": "wf_001",
  "agent_key": "copywriting",
  "status": "completed",
  "result": {
    "drafts": [
      {
        "draft_id": "draft_001",
        "platform": "linkedin",
        "content": "Draft post text here",
        "hashtags": ["#AI", "#Marketing"],
        "media_required": true
      }
    ]
  },
  "warnings": [],
  "errors": [],
  "next_recommended_agent": "image_generation",
  "requires_confirmation": false
}
```

### Final Frontend Response

Main Agent frontend ko yeh response dega:

```json
{
  "reply": "5 LinkedIn drafts ready hain. Images generate karne ke liye main proceed kar sakta hoon.",
  "artifacts": {
    "drafts": [],
    "images": [],
    "schedule_preview": null
  },
  "requires_confirmation": false,
  "progress_label": "Drafts ready"
}
```

---

## 8. State Management

System ko multiple levels par state manage karni hogi.

### State Levels

| State Type | Purpose |
|---|---|
| Conversation State | User aur Main Agent ki chat history |
| Workflow State | Current command ka full execution plan |
| Agent Run State | Har hidden agent call ka input/output/status |
| Artifact State | Drafts, generated images, CSV rows, schedule preview |
| Confirmation State | Pending user approvals |
| App Connection State | Connected social apps and account status |
| Memory State | User preferences and reusable context |

### Workflow State Machine

Each workflow ka status clear hoga:

```txt
created
  -> planning
  -> running
  -> waiting_for_confirmation
  -> confirmed
  -> executing_mutation
  -> completed
  -> failed
  -> cancelled
```

Example workflow record:

```json
{
  "workflow_id": "wf_001",
  "user_id": 123,
  "status": "waiting_for_confirmation",
  "intent": "schedule_posts",
  "created_at": "2026-06-22T10:00:00+05:00",
  "updated_at": "2026-06-22T10:01:00+05:00",
  "pending_confirmation": {
    "action": "schedule_posts",
    "payload_ref": "preview_001"
  }
}
```

### Agent Run State

Har agent call log hoga:

```json
{
  "agent_run_id": "run_001",
  "workflow_id": "wf_001",
  "agent_key": "copywriting",
  "status": "completed",
  "started_at": "2026-06-22T10:00:10+05:00",
  "finished_at": "2026-06-22T10:00:20+05:00",
  "input_ref": "agent_input_001",
  "output_ref": "agent_output_001",
  "error_message": null
}
```

Normal user ko agent run state show nahi hogi. Yeh admin/debugging ke liye rahegi.

---

## 9. Memory Management

Memory ka goal yeh hai ke Main Agent user ko better samjhe, lekin unnecessary private ya sensitive data store na kare.

### Memory Types

| Memory Type | Stored Data | Used By |
|---|---|---|
| Short-Term Memory | Current conversation, current workflow outputs | Main Agent |
| User Preference Memory | tone, language, preferred platforms, posting style | Main Agent, Copywriting Agent |
| Brand Memory | brand voice, product details, audience, banned words | Content Strategy, Copywriting |
| App Memory | connected app status, platform limits, account metadata | Connection, Scheduling, Publishing |
| Artifact Memory | generated drafts, images, schedule previews | Main Agent, Media, Scheduling |
| Analytics Memory | previous performance summaries | Analytics, Content Strategy |
| Audit Memory | who approved what and when | Safety, Publishing, Scheduling |

### What Should Not Go Into LLM Memory

Never store or pass these into LLM prompts:

- OAuth access tokens
- refresh tokens
- raw passwords
- Z.AI or any other LLM API key
- platform API secrets
- session cookies
- private credentials
- raw payment information

### Memory Flow

```txt
User preference saved
  -> Main Agent loads relevant preferences
  -> Main Agent creates limited context
  -> Hidden agent receives only needed memory
  -> Hidden agent returns result
  -> Main Agent decides what to save
```

Hidden agents should not write long-term memory directly. They can suggest memory updates, but Main Agent decides what gets saved.

Example:

```json
{
  "suggested_memory_update": {
    "type": "user_preference",
    "key": "tone",
    "value": "professional and concise",
    "reason": "User repeatedly requested short professional LinkedIn posts"
  }
}
```

Main Agent can save this only if it is safe and useful.

---

## 10. Database Design For Agents

Suggested backend tables:

### `agent_workflows`

Stores one user command workflow.

Fields:

- `id`
- `user_id`
- `conversation_id`
- `intent`
- `status`
- `command`
- `input_mode`
- `created_at`
- `updated_at`
- `completed_at`

### `agent_runs`

Stores hidden agent execution details.

Fields:

- `id`
- `workflow_id`
- `agent_key`
- `status`
- `input_json`
- `output_json`
- `error_json`
- `started_at`
- `finished_at`

### `agent_artifacts`

Stores drafts, images, previews, generated outputs.

Fields:

- `id`
- `workflow_id`
- `artifact_type`
- `artifact_json`
- `visible_to_user`
- `created_at`

### `agent_confirmations`

Stores pending approvals.

Fields:

- `id`
- `workflow_id`
- `action`
- `payload_json`
- `status`
- `confirmed_by_user_id`
- `confirmed_at`
- `expires_at`

### `agent_memories`

Stores safe user/brand preferences.

Fields:

- `id`
- `user_id`
- `memory_type`
- `key`
- `value_json`
- `source`
- `created_at`
- `updated_at`

---

## 11. Agent Backend Design

Backend mein agents ko service classes ke form mein banaya jayega.

Example structure:

```txt
fb_agent/app/agents/
  orchestrator.py
  base.py
  registry.py
  schemas.py
  memory.py
  state_store.py
  connection_agent.py
  content_strategy_agent.py
  copywriting_agent.py
  image_generation_agent.py
  media_agent.py
  scheduling_agent.py
  publishing_agent.py
  analytics_agent.py
  autopilot_agent.py
  safety_review_agent.py
  web_search_agent.py
```

### Base Agent Interface

Each hidden agent same interface follow karega:

```python
class BaseAgent:
    agent_key: str

    async def execute(self, request: AgentRequest) -> AgentResponse:
        raise NotImplementedError
```

Optional methods:

```python
async def validate_input(self, request: AgentRequest) -> list[str]:
    ...

async def plan(self, request: AgentRequest) -> AgentPlan:
    ...

async def summarize_result(self, response: AgentResponse) -> str:
    ...
```

### Agent Registry

Registry agent lookup handle karegi:

```python
AGENT_REGISTRY = {
    "connection": ConnectionAgent,
    "content_strategy": ContentStrategyAgent,
    "copywriting": CopywritingAgent,
    "image_generation": ImageGenerationAgent,
    "media": MediaAgent,
    "scheduling": SchedulingAgent,
    "publishing": PublishingAgent,
    "analytics": AnalyticsAgent,
    "autopilot": AutopilotAgent,
    "safety_review": SafetyReviewAgent,
    "web_search": WebSearchAgent,
}
```

Main Agent registry se required agent call karega.

---

## 12. LLM Gateway Design

All LLM calls one backend gateway se hongi:

```txt
fb_agent/app/services/agent_llm_gateway.py
```

Gateway responsibilities:

- `ZAI_API_KEY` aur base URL backend environment se read karna
- one JSON file se validated per-agent GLM model policy resolve karna
- Z.AI General API call karna
- JSON mode / structured output enforce karna where possible
- retryable errors par configured same-provider GLM fallback use karna
- authentication/quota errors ko retry na karna
- timeout, request ID, token usage, latency, aur provider errors log karna
- API key frontend ko kabhi expose na karna

Example config:

```txt
ZAI_API_KEY=...
ZAI_BASE_URL=https://api.z.ai/api/paas/v4
ZAI_MODEL_CONFIG_PATH=app/config/glm_models.json
```

Model IDs, fallback order, thinking mode, aur token limits one JSON file mein rahenge;
individual agents mein hardcode nahi honge. User ko API key/provider/model ka koi
option nahi milega.

---

## 13. Tool And API Access

Agents tools directly use karenge, but controlled way mein.

| Agent | Tools / APIs |
|---|---|
| Connection Agent | OAuth service, social account database |
| Web Search Agent | Search API / browser fetch service |
| Image Generation Agent | Image generation service, media storage |
| Media Agent | Cloudinary/local media storage |
| Scheduling Agent | Post scheduler DB, APScheduler |
| Publishing Agent | Facebook/LinkedIn/Twitter/etc platform APIs |
| Analytics Agent | Existing analytics services and DB queries |
| Safety Agent | validation rules, policy checks, confirmation rules |

Important:

- LLM should not directly call platform APIs.
- Backend agent service should call APIs after validation.
- Mutating API calls require confirmation unless action is explicitly safe.

---

## 14. Confirmation And Safety Design

Mutating actions confirmation ke baghair execute nahi hongi.

Confirmation required for:

- publish now
- schedule posts
- bulk schedule
- delete posts
- disconnect app
- enable autopilot
- retry failed posts in bulk
- overwrite drafts

Safety Agent checks:

- app connected hai ya nahi
- duplicate content
- missing media
- invalid schedule time
- timezone issue
- platform character limit
- hashtag limits
- unsafe prompt or private data
- bulk action size
- user confirmation required

Safety response:

```json
{
  "passed": true,
  "blocking_errors": [],
  "warnings": [
    "2 posts have similar opening lines"
  ],
  "confirmation_required": true
}
```

---

## 15. Example Full Workflow

Command:

```txt
User: Latest AI marketing trends par 5 posts banao, har post ke liye image generate karo, aur Monday se Friday 9 AM schedule karo.
```

Execution:

1. Main Agent creates workflow.
2. Web Search Agent gets latest trend data.
3. Content Strategy Agent creates 5 angles.
4. Copywriting Agent writes 5 posts.
5. Image Generation Agent creates 5 image prompts.
6. Image service generates images.
7. Media Agent stores image URLs and attaches them to drafts.
8. Scheduling Agent creates Monday-Friday schedule preview.
9. Safety And Review Agent validates content, images, schedule, and app connection.
10. Main Agent shows final preview.
11. User confirms.
12. Scheduling Agent writes scheduled posts to database.
13. Main Agent replies with completion summary.

Frontend user sees only:

- Main Agent chat
- generated drafts
- generated images
- schedule preview
- confirm button

Frontend user does not see:

- agent names
- internal agent logs
- model names
- API keys
- backend trace

---

## 16. Error Handling

Errors ko user-friendly way mein handle kiya jayega.

Agent failure categories:

| Error Type | Handling |
|---|---|
| LLM timeout | retry once, then fallback message |
| Web search failed | continue with existing knowledge or ask user |
| Image generation failed | keep text drafts and offer retry |
| Platform API failed | show readable error and retry option |
| Schedule validation failed | show exact rows/posts with issue |
| Missing connection | ask user to connect app |
| Safety block | explain why action cannot proceed |

Hidden error logs backend mein rahenge. User ko clean message milega.

---

## 17. Observability And Debugging

Normal users ko subagent activity visible nahi hogi, but engineering/admin ke liye logs honge.

Track:

- workflow ID
- agent run ID
- agent key
- duration
- status
- token usage
- model used
- API/tool used
- error reason
- confirmation status

Admin/debug mode later add kiya ja sakta hai, but client-facing product mein hidden agents visible nahi honge.

---

## 18. Implementation Phases

### Phase 1: Agent Foundation

- agent schemas
- base agent interface
- agent registry
- workflow state store
- single Z.AI GLM gateway and SSM model policy

### Phase 2: Main Agent

- intent classifier
- workflow planner
- orchestration flow
- final response builder

### Phase 3: Core Agents

- Connection Agent
- Copywriting Agent
- Scheduling Agent
- Safety And Review Agent

### Phase 4: Creative And Research Agents

- Content Strategy Agent
- Image Generation Agent
- Media Agent
- Web Search Agent

### Phase 5: Advanced Agents

- Analytics Agent
- Publishing Agent
- Autopilot Agent

### Phase 6: Memory And Production Polish

- user preference memory
- brand memory
- analytics memory
- audit logs
- retries
- admin debugging

---

## 19. Final Architecture Summary

NexLab agents backend mein hidden services honge. User sirf Main Agent se baat karega. Main Agent command ko understand karega, agents ko structured JSON tasks dega, state and memory manage karega, aur final result user ko clean interface mein show karega.

Agents direct uncontrolled coordination nahi karenge. Main Agent orchestrator rahega. State database mein workflow, agent runs, artifacts, confirmations, and memories ke form mein save hogi.

LLM access sirf backend Z.AI GLM gateway se hoga. OpenRouter ya koi second
provider gateway nahi hoga. User API key, provider, model, ya subagent internals
nahi dekh sakega.

This design gives:

- simple user experience
- controlled backend execution
- safer publishing/scheduling
- scalable agent architecture
- easier debugging
- future-ready memory and automation
