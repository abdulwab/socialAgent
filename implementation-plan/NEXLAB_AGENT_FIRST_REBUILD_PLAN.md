# NexLab SocialHub Agent-First Rebuild Plan

| Field | Details |
|---|---|
| Project | NexLab SocialHub |
| Document Purpose | Client-ready implementation plan for rebuilding SocialHub into an agent-first product |
| Version | 1.0 |
| Last Updated | 2026-06-22 |
| Status | Planning / Ready for implementation review |

---

## Executive Summary

SocialHub will move from a traditional multi-tab dashboard into a single **Main Agent** experience. Users will give commands through text or voice, and the system will complete work through hidden backend agents/services.

The user will not see internal subagents, raw logs, or technical routing. They will only see the Main Agent conversation, generated drafts, media previews, app connection controls, confirmation prompts, and final scheduled/published results.

This document describes the product flow, UI behavior, hidden agent architecture, LLM strategy, backend and frontend changes, image generation, CSV upload, safety rules, migration phases, and testing plan.

## Terminology Note

This document uses the word **agent** for backend/internal services. In the final user interface, only **Main Agent** will be visible to the user.

All other agents are hidden behind the scenes. They may also be described as internal engines or services during implementation.

## Table of Contents

1. [Vision](#1-vision)
2. [High-Level Product Flow](#2-high-level-product-flow)
3. [Main Interface](#3-main-interface)
4. [Landing And Auth Changes](#4-landing-and-auth-changes)
5. [Connect Apps Flow](#5-connect-apps-flow)
6. [Hidden Subagents](#6-hidden-subagents)
7. [Agent Build And LLM Strategy](#7-agent-build-and-llm-strategy)
8. [Backend Agent Architecture](#8-backend-agent-architecture)
9. [Frontend Agent Architecture](#9-frontend-agent-architecture)
10. [Voice Command](#10-voice-command)
11. [AI Image Generation Flow](#11-ai-image-generation-flow)
12. [CSV Bulk Upload Flow](#12-csv-bulk-upload-flow)
13. [Safety Rules](#13-safety-rules)
14. [Migration Strategy](#14-migration-strategy)
15. [Test Plan](#15-test-plan)
16. [Assumptions](#16-assumptions)

---

## 1. Vision

**Client summary:** SocialHub ka main product experience ek single Main Agent interface hoga. User commands dega, aur system background mein kaam complete karega.

SocialHub ko current multi-page dashboard aur sidebar navigation se convert karna hai into a single agent-first product.

User app ke andar tabs ya multiple dashboard pages mein manually navigate nahi karega.

User sirf Main Agent ko text ya voice command dega. Main Agent command samjhega, behind the scenes relevant subagents ko kaam assign karega, phir final output user ko dega.

Target experience Claude Code jaisa hoga:

- User command deta hai.
- Main Agent plan banata hai.
- Subagents specialized kaam karte hain, lekin user ko subagent names, raw logs, ya internal statuses visible nahi honge.
- Main Agent result combine karke user ko deta hai.
- Risky actions par confirmation li jati hai.

## 2. High-Level Product Flow

**Client summary:** User login ke baad direct `/agent` par jayega. Wahan se har kaam command-based hoga.

1. User landing page par aata hai.
2. User login ya signup karta hai.
3. Auth success ke baad user direct `/agent` par land karta hai.
4. `/agent` page par koi sidebar ya dashboard tabs nahi honge.
5. User ke paas primary controls honge:
   - Connect Apps dropdown
   - Main Agent chat interface
   - simple "Working..." progress indicator, without subagent names
   - Text command input
   - Voice command button
   - Generated media / draft preview area
6. User kisi bhi kaam ke liye command deta hai:
   - "LinkedIn connect karo"
   - "AI marketing ke liye 5 posts banao"
   - "Har post ke liye image generate karo"
   - "In posts ko Monday se Friday 9 AM schedule karo"
   - "Last 30 days ki analytics batao"
7. Main Agent command classify karta hai aur hidden subagents ko kaam deta hai.
8. Mutating actions, jaise publish, delete, disconnect, enable autopilot, schedule bulk posts, pehle confirmation maangti hain.

## 3. Main Interface

**Client summary:** Main app screen ek clean command center hogi: Main Agent chat, Connect Apps dropdown, command input, voice button, aur generated drafts/media preview.

### Route

New authenticated route:

```txt
/agent
```

### UI Sections

The `/agent` page should contain:

- Top bar:
  - SocialHub / NexLab brand
  - Connect Apps dropdown
  - user/account menu
- Main chat:
  - user messages
  - Main Agent responses
  - generated drafts
  - confirmation prompts
- Background work indicator:
  - generic "Working..." or "Preparing drafts..." state
  - no visible subagent names
  - no raw internal logs
  - no technical routing details
- Composer:
  - text input
  - microphone button
  - send button
  - attachment/upload button for CSV and media files
- Preview area:
  - generated posts
  - generated images
  - scheduled plan previews
  - uploaded CSV preview and validation results

### Important UI Rule

The agent page must not depend on normal dashboard tabs. Existing pages can remain in codebase for fallback/internal use, but the primary user experience should be one agent interface.

### Hidden Subagents Rule

Subagents are an internal architecture only. User should feel like they are talking to one Main Agent.

Do not show:

- subagent names in the UI
- subagent status cards
- internal task routing
- raw tool logs
- "Copywriting Agent is running" style messages

Allowed visible wording:

- "Working on your request..."
- "Creating drafts..."
- "Generating image..."
- "Checking before scheduling..."
- "Ready for confirmation"

### Desktop And Mobile Layout

Desktop / laptop layout:

- full agent command center should be visible
- top bar with Connect Apps dropdown
- main chat area
- text and voice command input
- generated drafts/media preview area
- optional compact progress indicator

Mobile layout:

- only Main Agent chat interface should be primary
- Drafts / Generated media preview should be available under the chat
- Connect Apps can be a small icon/menu in the top bar
- CSV upload should be available from the composer attachment button
- hide desktop-only side panels
- do not show subagent/progress panels
- keep text input and mic button sticky at bottom

Responsive rule:

- `lg` and above: desktop command center layout
- below `lg`: single-column mobile layout with chat first and drafts second

## 4. Landing And Auth Changes

**Client summary:** Landing page signup/login ke liye rahegi. Auth ke baad user dashboard tabs par nahi, direct Main Agent screen par land karega.

### Landing Page

Landing page ka primary job signup/login conversion hoga.

Required behavior:

- Unauthenticated user:
  - sees login and signup CTAs
  - marketing sections can remain, but CTA should be clear
- Authenticated user:
  - CTA routes to `/agent`

### Redirect Updates

Update current redirects:

- `/login` success -> `/agent`
- `/signup` success -> `/agent`
- Google auth success -> `/agent`
- Landing authenticated CTA -> `/agent`

Current code redirects to `/scheduled-posts` or `/connect-apps`. Those should be changed to `/agent`.

## 5. Connect Apps Flow

**Client summary:** Social platforms official OAuth ke through connect honge. User passwords collect nahi kiye jayenge.

### UI

Inside `/agent`, top bar should include `Connect Apps` dropdown.

Dropdown apps:

- Facebook
- Instagram
- LinkedIn
- X / Twitter

Each app should show:

- connected/disconnected status
- account/page name if connected
- reconnect button if token is expired or expiring
- disconnect action behind confirmation

Coming-soon apps can be shown disabled:

- TikTok
- Pinterest
- YouTube

### Security Rule

Agent must not collect or store social media usernames/passwords.

Reason:

- unsafe for users
- platform policy risk
- OAuth already exists in the project
- password automation can break due to MFA, CAPTCHA, sessions, and policy limits

Correct flow:

- User says: "LinkedIn connect karo"
- Connection Agent starts OAuth flow
- User completes OAuth in official provider screen
- App stores token securely as it already does

## 6. Hidden Subagents

**Client summary:** Product user ko sirf Main Agent dikhayega. Specialized agents backend mein hidden services ke taur par kaam karenge.

Recommended total hidden subagents: 11.

Subagents are backend/internal workers. They should never become visible tabs, visible panels, or user-facing personalities. The user only sees Main Agent responses and final artifacts.

Each subagent should return structured internal output to Main Agent:

```json
{
  "agent_key": "copywriting",
  "status": "completed",
  "internal_summary": "Generated 5 LinkedIn draft posts",
  "user_visible_result": {
    "drafts": []
  },
  "requires_confirmation": false,
  "errors": []
}
```

Main Agent decides what to show. The UI should show polished final content, not internal subagent logs.

### 1. Connection Agent

Purpose:

- connect, reconnect, disconnect social platforms
- inspect current connected app status
- explain token or permission problems

Uses existing code:

- `fetchLoginUrl`
- `fetchLinkedInLoginUrl`
- `fetchXLoginUrl`
- Instagram login options
- disconnect thunks
- `/api/v1/user/channel-status`

Example commands:

- "Facebook connect karo"
- "LinkedIn reconnect karo"
- "Meri connected apps dikhao"

### 2. Content Strategy Agent

Purpose:

- user ka niche, business, audience, tone, goals samajhna
- campaign ideas banana
- weekly/monthly content plan banana
- content pillars suggest karna

Can reuse:

- Ideas Board backend as future memory/workspace
- existing LLM service

Example commands:

- "Mere digital marketing agency ke liye 1 week content plan banao"
- "AI niche ke liye post ideas do"

### 3. Copywriting Agent

Purpose:

- captions write karna
- platform-specific post versions banana
- hashtags and CTAs suggest karna
- post health score improve karna

Uses existing code:

- `/api/v1/post/generate`
- `/api/v1/post/ai-describe`
- `/api/v1/post/health-check`

Example commands:

- "LinkedIn ke liye professional caption likho"
- "Is post ko Facebook ke liye casual bana do"

### 4. Image Generation Agent

Purpose:

- AI image prompt banana
- prompt se image generate karna
- generated image ko Cloudinary/media storage mein save karna
- generated image post draft ya scheduled post ke sath attach karna

Required capability:

```python
generate_image_from_prompt(prompt: str, user_id: int) -> dict
```

Expected output:

```json
{
  "url": "https://res.cloudinary.com/...",
  "public_id": "socialhub/ai_generated/...",
  "prompt": "modern AI marketing dashboard image"
}
```

Existing code to reuse:

- `ApiManager.generateImageFromPrompt`
- `/api/v1/media/generate-image`
- `media_service.generate_and_upload_image`
- Cloudinary upload flow

Example commands:

- "Is LinkedIn post ke liye matching image banao"
- "Facebook ad style image generate karo"
- "3 posts aur har post ke liye image banao"

### 5. Media Agent

Purpose:

- user uploads handle karna
- screenshots handle karna
- media library manage karna
- existing image URLs attach karna
- reference images manage karna

Uses existing code:

- `/api/v1/media/upload`
- media library page/code
- Cloudinary assets

Example commands:

- "Meri media library se latest image attach karo"
- "Is screenshot ko post mein use karo"

### 6. Scheduling Agent

Purpose:

- posts schedule karna
- recurring schedule manage karna
- best time suggestions apply karna
- bulk CSV upload process karna
- calendar/queue logic handle karna

Uses existing code:

- `/api/v1/scheduled-posts`
- `/api/v1/post/bulk-upload`
- current timezone logic
- duplicate checks

Example commands:

- "Ye posts Monday se Friday 9 AM schedule karo"
- "Next week ke liye 10 posts queue mein daal do"
- "Ye CSV upload kar ke posts schedule karo"

### 7. Publishing Agent

Purpose:

- approved posts publish karna
- failed posts retry karna
- publishing errors explain karna
- platform-specific publishing constraints handle karna

Uses existing code:

- `/api/v1/post/publish`
- scheduled post executor
- retry endpoint
- Facebook, Instagram, LinkedIn, X services

Example commands:

- "Ye post abhi publish karo"
- "Failed posts retry karo"

### 8. Analytics Agent

Purpose:

- performance summary dena
- engagement explain karna
- best posting time suggest karna
- growth trends summarize karna

Uses existing code:

- `/api/v1/analytics/overview`
- `/api/v1/analytics/posts`
- `/api/v1/analytics/growth`
- `/api/v1/analytics/best-times`

Example commands:

- "Last 30 days ki performance batao"
- "Best posting time kya hai?"

### 9. Autopilot Agent

Purpose:

- autopilot setup karna
- topics, platforms, tone, frequency configure karna
- auto-generate and auto-schedule flow manage karna
- approval mode handle karna

Uses existing code:

- `/api/v1/autopilot`
- `/api/v1/autopilot/dry-run`
- `/api/v1/autopilot/generate-now`
- APScheduler autopilot job

Example commands:

- "Autopilot setup karo, LinkedIn aur Facebook ke liye daily 9 AM"
- "Autopilot pause karo"

### 10. Safety And Review Agent

Purpose:

- risky actions detect karna
- duplicate content/spam risk check karna
- hashtag limits enforce karna
- token expiry and missing permissions check karna
- final confirmation prompts create karna

Must require confirmation for:

- publish now
- schedule posts
- bulk schedule
- delete posts
- delete media
- disconnect social app
- enable autopilot
- change posting frequency

Example commands:

- "Is content mein koi issue hai?"
- "Publish karne se pehle check karo"

### 11. Web Search Agent

Purpose:

- web par ja kar fresh information collect karna
- trends, competitor info, latest news, platform rule changes, hashtags, current events, and market research la kar dena
- sources ko summarize karna
- outdated ya uncertain information ke liye fresh verification karna

Use cases:

- trending topics find karna
- current news based posts banana
- competitor comparison update karna
- latest social media platform rules check karna
- industry research karna
- product/service ke liye content angles find karna

Example commands:

- "AI marketing ke latest trends dhoond kar 5 posts banao"
- "LinkedIn algorithm ke latest best practices check karo"
- "Mere competitors ka content analyze karo"
- "Aaj ki tech news se post ideas banao"

Rules:

- Web Search Agent ka kaam behind the scenes hoga.
- User ko raw search process nahi dikhana.
- Main Agent final answer mein short source summary ya links de sakta hai jab useful ho.
- High-stakes ya current information ke liye Web Search Agent use karna mandatory hoga.
- Agar web search fail ho, Main Agent clearly bole: "Fresh web data fetch nahi ho saka, main stored knowledge se draft bana raha hoon."

## 7. Agent Build And LLM Strategy

**Client summary:** Har kaam LLM se nahi hoga. Exact/risky actions code and APIs se honge; LLM writing, reasoning, summaries, and explanations ke liye use hoga.

Agents ko separate UI personalities ki tarah nahi banana. Agents backend services honge jo Main Agent ke through call honge.

### How Agents Will Be Built

Create a common internal contract for every hidden agent:

```python
class AgentResult(BaseModel):
    agent_key: str
    status: str
    internal_summary: str
    user_visible_result: dict
    requires_confirmation: bool = False
    errors: list[str] = []


class BaseHiddenAgent:
    agent_key: str

    def run(self, *, user, db, command: str, context: dict) -> AgentResult:
        raise NotImplementedError
```

Main Agent / orchestrator ka flow:

1. User command receive kare.
2. Intent classify kare.
3. Required hidden agents select kare.
4. Har agent ko structured context de.
5. Agent result collect kare.
6. Safety And Review Agent se final validation karwaye.
7. User ko sirf clean final reply, drafts, images, previews, and confirmation buttons show kare.

### Agent Trigger Matrix

Main Agent user command ko classify karega. One command multiple hidden agents trigger kar sakta hai.

| User input / intent | Primary hidden agent | Supporting hidden agents | Example |
|---|---|---|---|
| connect, reconnect, disconnect, app status | Connection Agent | Safety And Review Agent for disconnect confirmation | "LinkedIn connect karo" |
| post ideas, content calendar, campaign plan | Content Strategy Agent | Web Search Agent when latest/trending info is needed | "AI niche ke liye 1 week plan banao" |
| write, caption, hashtags, rewrite, improve | Copywriting Agent | Safety And Review Agent for quality checks | "LinkedIn post likho" |
| image, visual, generate image, ad creative | Image Generation Agent | Media Agent to save/attach asset | "Is post ke liye image banao" |
| upload image, attach media, media library | Media Agent | Safety And Review Agent for file checks | "Meri latest image attach karo" |
| schedule, queue, calendar, time, recurring | Scheduling Agent | Safety And Review Agent before DB write | "Friday 9 AM schedule karo" |
| CSV, bulk upload, many posts from file | Scheduling Agent | Safety And Review Agent + Media Agent if files included | "Ye CSV upload kar ke schedule karo" |
| publish now, retry failed, failed posts | Publishing Agent | Safety And Review Agent before publish/retry | "Ye post abhi publish karo" |
| analytics, performance, best time, growth | Analytics Agent | Web Search Agent only if market context requested | "Last 30 days ki analytics batao" |
| autopilot, automatic posting, recurring AI | Autopilot Agent | Content Strategy + Scheduling + Safety | "Autopilot setup karo" |
| latest, current, news, trends, competitor, research | Web Search Agent | Content Strategy or Copywriting Agent | "Latest AI trends se 5 posts banao" |
| risky action, delete, disconnect, publish, schedule | Safety And Review Agent | relevant action agent after confirmation | "Sab failed posts delete karo" |

### Multi-Agent Trigger Examples

Example 1:

```txt
User: AI marketing ke liye 5 LinkedIn posts banao aur Friday se schedule karo.
```

Hidden flow:

1. Main Agent detects content + scheduling intent.
2. Content Strategy Agent creates post angles.
3. Copywriting Agent writes 5 LinkedIn drafts.
4. Scheduling Agent prepares schedule preview.
5. Safety And Review Agent checks duplicates, connection, time, and hashtag limits.
6. Main Agent shows drafts + schedule confirmation.

Example 2:

```txt
User: Latest AI marketing trends dhoond kar posts banao.
```

Hidden flow:

1. Main Agent detects latest/research intent.
2. Web Search Agent fetches sources.
3. Content Strategy Agent converts research into angles.
4. Copywriting Agent writes posts.
5. Safety And Review Agent checks output.
6. Main Agent shows final drafts with optional source summary.

Example 3:

```txt
User: Ye CSV upload kar ke posts schedule karo.
```

Hidden flow:

1. Main Agent detects CSV file.
2. Scheduling Agent parses rows.
3. Safety And Review Agent validates each row.
4. Main Agent shows preview and warnings.
5. User confirms.
6. Scheduling Agent creates scheduled posts.

### Agent-To-Agent Communication

Agents direct UI se baat nahi karenge. All communication Main Agent/orchestrator ke through hoga.

Allowed communication pattern:

```txt
User -> Main Agent -> Agent A -> Main Agent -> Agent B -> Main Agent -> User
```

Avoid:

```txt
Agent A -> Agent B direct uncontrolled call
```

Reason:

- Main Agent context owner rahega.
- Safety checks centralized rahenge.
- Debugging easier hogi.
- User ko one consistent assistant experience milega.

### Agent Message Envelope

Main Agent har hidden agent ko structured JSON envelope dega:

```json
{
  "request_id": "cmd_20260622_001",
  "user_id": 123,
  "intent": "schedule_posts",
  "command": "AI marketing ke liye 5 LinkedIn posts banao aur Friday se schedule karo",
  "input_mode": "text",
  "context": {
    "timezone": "Asia/Karachi",
    "connected_apps": {
      "linkedin": { "connected": true, "account_id": "li_123" }
    },
    "drafts": [],
    "uploaded_files": [],
    "preferences": {
      "tone": "professional",
      "language": "roman_urdu_english"
    }
  },
  "constraints": {
    "user_visible_subagents": false,
    "requires_confirmation_for_mutations": true,
    "do_not_include_secrets": true
  }
}
```

Hidden agent response format:

```json
{
  "request_id": "cmd_20260622_001",
  "agent_key": "scheduling",
  "status": "completed",
  "internal_summary": "Prepared schedule preview for 5 LinkedIn posts",
  "user_visible_result": {
    "schedule_preview": {
      "platform": "linkedin",
      "items": []
    }
  },
  "next_recommended_agent": "safety_review",
  "requires_confirmation": true,
  "errors": []
}
```

Main Agent final frontend response:

```json
{
  "reply": "5 LinkedIn posts ready hain. Friday se 9:00 AM schedule karne ke liye confirmation chahiye.",
  "artifacts": {
    "drafts": [],
    "images": [],
    "schedule_preview": {}
  },
  "progress_label": "Ready for confirmation",
  "requires_confirmation": true,
  "confirmation": {
    "label": "Schedule posts",
    "action": "schedule_posts",
    "payload_ref": "cmd_20260622_001"
  }
}
```

### Shared Data Forms

Agents data in common forms exchange karenge:

Draft post:

```json
{
  "draft_id": "draft_001",
  "platform": "linkedin",
  "content": "Final post text here",
  "hashtags": ["#AI", "#Marketing"],
  "image_url": null,
  "status": "draft"
}
```

Generated image:

```json
{
  "asset_id": "img_001",
  "prompt": "professional AI marketing visual",
  "url": "https://res.cloudinary.com/...",
  "public_id": "socialhub/ai_generated/...",
  "attached_to_draft_id": "draft_001"
}
```

Schedule preview:

```json
{
  "schedule_id": "preview_001",
  "timezone": "Asia/Karachi",
  "items": [
    {
      "draft_id": "draft_001",
      "platform": "linkedin",
      "scheduled_at": "2026-06-26T09:00:00+05:00"
    }
  ],
  "requires_confirmation": true
}
```

Safety result:

```json
{
  "passed": true,
  "warnings": [],
  "blocking_errors": [],
  "confirmation_required": true
}
```

### LLM Provider Strategy

Final product mein all agents ke liye direct **Z.AI General API** aur approved
GLM models use honge.

The API key will be managed internally by NexLab/SocialHub only:

- Raw Z.AI API key AWS Secrets Manager mein rahegi.
- User ko API key add karne ka option nahi milega.
- User ko API key settings, provider settings, ya model selector UI mein nazar nahi aayega.
- Existing user-facing AI provider settings must be removed or hidden from the final agent-first UI.

Existing multi-provider implementation replace ho chuki hai. Agent-first rebuild
ka target aur implemented policy Z.AI GLM-only hai.

Recommended rule:

- Exactly one Z.AI gateway use karo; second provider fallback na rakho.
- Model IDs agent ya gateway code mein hard-code na karo.
- Model names AWS SSM policy/catalog se control hon.
- User settings se provider select nahi hoga.
- Fallback models bhi internal config se control hon.

Add config options:

```txt
ZAI_BASE_URL=https://api.z.ai/api/paas/v4
ZAI_ACTIVE_KEY_PARAMETER=/socialhub/prod/zai/active-key-secret-id
ZAI_MODEL_POLICY_PARAMETER=/socialhub/prod/zai/model-policy
ZAI_MODEL_CATALOG_PARAMETER=/socialhub/prod/zai/model-catalog
AWS_REGION=ap-south-1
```

Example model mapping:

```txt
Main Agent / Orchestrator -> MAIN_AGENT_MODEL
Content Strategy Agent -> RESEARCH_AGENT_MODEL or MAIN_AGENT_MODEL
Copywriting Agent -> COPY_AGENT_MODEL
Image Prompt Agent -> IMAGE_PROMPT_AGENT_MODEL
Analytics Summary -> FAST_AGENT_MODEL
Web Search Summary -> RESEARCH_AGENT_MODEL
Safety Explanation -> SAFETY_AGENT_MODEL
```

Important: model IDs should be easy to update because LLM providers change versions frequently.

### Recommended LLM Per Agent

| Agent | Main Job | Recommended LLM | Why |
|---|---|---|---|
| Main Agent / Orchestrator | intent, planning, final response | GLM-5.2 with configured GLM-4.7 fallback | multi-step decisions and clean final answer |
| Connection Agent | OAuth action routing, status explanation | GLM-4.7-Flash/FlashX plus deterministic DB facts | fast grounded status handling |
| Content Strategy Agent | campaigns, ideas, planning | GLM-4.7 | creative planning and audience understanding |
| Copywriting Agent | captions, hashtags, platform variants | GLM-4.7 | reliable generation |
| Image Generation Agent | image prompt writing + image action | GLM-4.7-Flash/FlashX and GLM-Image | text model writes prompt; image model creates asset |
| Media Agent | upload/reference/media selection | GLM-4.7-Flash/FlashX plus deterministic media logic | low-cost interpretation |
| Scheduling Agent | schedule/timezone/queue planning | GLM-4.7-Flash/FlashX plus deterministic scheduling | rules execute; LLM interprets/explains |
| Publishing Agent | publish/retry error explanation | GLM-4.7-Flash/FlashX plus deterministic platform tools | mutations remain controlled |
| Analytics Agent | summarize metrics | GLM-4.7 | deeper grounded analysis |
| Autopilot Agent | recurring content automation | GLM-5.2 with GLM-4.7 fallback | stronger setup reasoning |
| Safety And Review Agent | validation, risk checks | deterministic rules plus GLM-4.7 | hard checks never rely only on LLM |
| Web Search Agent | fresh web research and summary | controlled fetch plus GLM-4.7 | LLM summarizes verified sources |

### Cost And Speed Tiers

Use 3 LLM tiers:

1. **Reasoning tier**
   - Used by Main Agent, Content Strategy, complex Autopilot setup.
   - Slower and more expensive, but better decisions.

2. **Fast generation tier**
   - Used by Copywriting, image prompt creation, simple summaries.
   - Cheaper and fast.

3. **Rule/deterministic tier**
   - Used by Connection, Scheduling, Publishing, Safety hard checks.
   - No LLM unless explanation is needed.

### Existing Code Changes Needed

Current file:

```txt
fb_agent/app/services/llm_service.py
```

Needs to be upgraded from generic post generation into reusable LLM gateway:

```python
def generate_agent_response(
    prompt: str,
    provider: str,
    model: str | None = None,
    temperature: float = 0.4,
    response_format: str = "text",
) -> str:
    ...
```

Add helper wrappers:

```python
def run_reasoning_llm(prompt: str) -> str:
    ...

def run_fast_llm(prompt: str) -> str:
    ...

def run_json_llm(prompt: str) -> dict:
    ...
```

### Agent Memory And Context

Main Agent should pass structured context to hidden agents:

```json
{
  "user_profile": {},
  "connected_apps": {},
  "drafts": [],
  "uploaded_files": [],
  "timezone": "Asia/Karachi",
  "previous_messages": []
}
```

Do not pass unnecessary secrets to LLM prompts. OAuth tokens, API keys, and raw credentials must never be included in model prompts.

### Web Search LLM Rule

Web Search Agent is two-part:

1. Search/fetch layer:
   - uses search API or controlled browser/server fetch
   - collects URLs, titles, snippets, and relevant text
2. Summarizer layer:
   - uses LLM to summarize sources
   - returns compact facts and source links to Main Agent

The LLM should not invent source data. If no source is found, it should say so.

## 8. Backend Agent Architecture

**Client summary:** Backend mein one command endpoint hoga jo Main Agent request receive karega, hidden services run karega, aur frontend ko clean result return karega.

### New Route Group

Add:

```txt
/api/v1/agent
```

### Core Endpoint

```txt
POST /api/v1/agent/command
```

Request:

```json
{
  "message": "Write 3 LinkedIn posts and generate images for them",
  "input_mode": "text",
  "context": {}
}
```

Response:

```json
{
  "reply": "I created 3 draft posts and generated matching image prompts.",
  "actions": [],
  "artifacts": {
    "drafts": [],
    "images": [],
    "schedule_preview": null
  },
  "progress_label": "Drafts ready",
  "requires_confirmation": false
}
```

Internal subagent execution details can be logged server-side for debugging, but should not be returned as user-visible UI state unless an admin/debug mode is explicitly enabled.

### Z.AI GLM Backend Integration

All agent LLM calls should go through one backend gateway:

```txt
fb_agent/app/services/agent_llm_gateway.py
```

Gateway responsibilities:

- load active key alias and model policy/catalog from AWS SSM
- read the raw Z.AI key from AWS Secrets Manager
- validate agent/model compatibility
- call Z.AI General API chat/image endpoints
- return text or JSON to hidden agents
- never expose API key to frontend
- never accept API key from user request

Frontend must not send any LLM provider or API key fields.

### Suggested Backend Files

Create:

```txt
fb_agent/app/api/v1/agent_routes.py
fb_agent/app/services/agent_orchestrator.py
fb_agent/app/services/agents/connection_agent.py
fb_agent/app/services/agents/content_strategy_agent.py
fb_agent/app/services/agents/copywriting_agent.py
fb_agent/app/services/agents/image_generation_agent.py
fb_agent/app/services/agents/media_agent.py
fb_agent/app/services/agents/scheduling_agent.py
fb_agent/app/services/agents/publishing_agent.py
fb_agent/app/services/agents/analytics_agent.py
fb_agent/app/services/agents/autopilot_agent.py
fb_agent/app/services/agents/safety_review_agent.py
fb_agent/app/services/agents/web_search_agent.py
```

Register router in:

```txt
fb_agent/app/main.py
```

### V1 Orchestration

V1 can use deterministic routing before deep autonomous AI:

- If command mentions connect/reconnect/disconnect -> Connection Agent
- If command mentions idea/plan/content calendar -> Content Strategy Agent
- If command mentions caption/post/write/hashtags -> Copywriting Agent
- If command mentions image/generate image/visual -> Image Generation Agent
- If command mentions upload/media/screenshot -> Media Agent
- If command mentions schedule/calendar/queue/bulk -> Scheduling Agent
- If command mentions publish/retry/failed -> Publishing Agent
- If command mentions analytics/performance/best time -> Analytics Agent
- If command mentions autopilot/automatic -> Autopilot Agent
- If command mentions latest/current/news/trends/research/competitor/web -> Web Search Agent
- Safety And Review Agent runs before any mutating action

### Internal Execution Visibility

Backend can keep full internal trace:

- selected agents
- timing
- tool calls
- errors
- safety checks

Frontend should receive only:

- Main Agent reply
- generated drafts/images/schedule previews
- confirmation requirements
- a simple progress label

Do not expose agent trace to normal users.

## 9. Frontend Agent Architecture

**Client summary:** Frontend mein `/agent` route primary app experience hoga. Existing pages fallback/internal use ke liye rahengi.

Final product mein old dashboard tabs/sidebar user-facing experience ka hissa nahi rahenge.

### New Route

Create:

```txt
fb_dash/app/agent/page.tsx
```

### Suggested Components

Create:

```txt
fb_dash/app/agent/components/AgentShell.tsx
fb_dash/app/agent/components/AgentTopBar.tsx
fb_dash/app/agent/components/ConnectAppsDropdown.tsx
fb_dash/app/agent/components/AgentChat.tsx
fb_dash/app/agent/components/AgentComposer.tsx
fb_dash/app/agent/components/WorkProgressIndicator.tsx
fb_dash/app/agent/components/GeneratedAssetsPanel.tsx
fb_dash/app/agent/components/ConfirmationModal.tsx
```

Do not create a visible `SubagentsPanel` for normal users. Subagent names and internal status should stay hidden.

### Remove Old Tabs And Sidebar

Current dashboard-style navigation remove/hide karni hogi.

User-facing final app should not show:

- Overview tab
- Post Queue tab
- Ideas Board tab
- AI Autopilot tab
- Calendar tab
- My Posts tab
- Bulk Upload tab
- Analytics tab
- Media Library tab
- Social Channels tab
- Prompt Settings tab
- Privacy Policy tab inside app navigation
- old Sidebar component as the main navigation

Implementation rule:

- `/agent` route becomes the only primary logged-in experience.
- Old pages can temporarily remain during migration for internal testing.
- Final client-facing app should not route users to old tabs.
- Remove old sidebar usage from final app shell.
- Remove or hide old navigation code once agent workflows are complete.

Existing old pages can be deleted only after equivalent agent workflows are working:

- `/posts` replaced by Main Agent draft/create flow
- `/scheduled-posts` replaced by Generated Drafts + schedule preview + queue summaries
- `/bulk-upload` replaced by CSV upload inside composer
- `/connect-apps` replaced by Connect Apps dropdown
- `/analytics` replaced by Analytics Agent command flow
- `/library` replaced by Media Agent and GeneratedAssetsPanel
- `/autopilot` replaced by Autopilot Agent setup flow
- `/prompt-settings` removed from user-facing product

### API Key And Provider UI Policy

Users must not see API key or provider configuration options.

Remove/hide from final UI:

- Gemini API key input
- Claude API key input
- OpenRouter API key input
- active provider selector
- Prompt Settings page from normal user navigation

Backend policy:

- NexLab/SocialHub owns and configures the Z.AI General API key.
- All hidden agents use the single Z.AI gateway through backend services.
- User requests never include provider/model choices.
- User cannot provide, view, or edit LLM API keys.

### Responsive Component Rules

Desktop:

- `AgentTopBar` visible
- `ConnectAppsDropdown` visible in top bar
- `AgentChat` visible as main center area
- `AgentComposer` visible at bottom of chat
- `GeneratedAssetsPanel` visible beside or below chat
- `WorkProgressIndicator` can be visible as a small generic label
- CSV upload button visible in composer

Mobile:

- `AgentChat` visible first
- `AgentComposer` sticky at bottom
- `GeneratedAssetsPanel` visible below chat or as a drawer
- `ConnectAppsDropdown` compressed into an icon/menu
- `WorkProgressIndicator` hidden or shown only as one-line text
- CSV upload remains available through the composer attachment button
- no desktop side panels

### Frontend API Methods

Add to `fb_dash/lib/apiManager.ts`:

```ts
static async runAgentCommand(token: string, data: {
  message: string;
  input_mode: "text" | "voice";
  context?: Record<string, unknown>;
})
```

### Redux State

Add agent state in `agentSlice.ts` or separate slice later:

- messages
- progressLabel
- generatedAssets
- pendingConfirmation
- agentLoading
- agentError
- internalTrace only in development/debug mode, never shown to normal users

## 10. Voice Command

**Client summary:** User text ke sath voice command bhi de sakta hai. V1 browser speech recognition use karega with graceful fallback.

### V1 Approach

Use browser Web Speech API.

Flow:

1. User clicks mic button.
2. Browser asks microphone permission.
3. Speech converts to text.
4. Text appears in composer.
5. User can edit or send.

Fallback:

- If browser does not support speech recognition, show:
  - "Voice input is not supported in this browser. Please type your command."

### Later Phase

Server-side transcription can be added later with a dedicated speech-to-text provider.

## 11. AI Image Generation Flow

**Client summary:** User command se post ke sath matching AI image generate ho sakegi, preview hogi, aur confirmation ke baad draft/schedule mein attach hogi.

### Command Example

User:

```txt
AI tools ke liye LinkedIn post likho aur image bhi generate karo.
```

Main Agent steps:

1. Copywriting Agent writes LinkedIn post.
2. Image Generation Agent creates image prompt.
3. Image Generation Agent calls backend image generation.
4. Media Agent stores returned image asset.
5. Safety And Review Agent checks draft.
6. Main Agent shows:
   - post draft
   - generated image preview
   - actions: schedule, edit, regenerate image, save draft

### Image Generation Requirements

- generated image URL should be stored
- user should be able to attach generated image to post
- user should be able to regenerate
- failed image generation should not block text draft
- generated image prompt should be visible or logged for debugging

## 12. CSV Bulk Upload Flow

**Client summary:** CSV upload bhi agent interface ke andar hoga. User CSV attach karega, Main Agent validation preview dikhayega, phir confirmation ke baad posts schedule honge.

CSV upload bhi agent-first interface ke andar hoga. User ko separate Bulk Upload tab open karne ki zaroorat nahi hogi.

### User Flow

User ke paas 3 options honge:

1. Chat composer ke attachment/upload button se `.csv` file select kare.
2. CSV file ko desktop par chat area ya drafts area mein drag and drop kare.
3. Command likhe:

```txt
Ye CSV upload kar ke posts schedule karo.
```

### Desktop Behavior

Desktop/laptop par:

- composer mein attachment icon hoga
- user CSV attach karega
- Main Agent bolega: "CSV received. I am checking the rows."
- generated preview area mein CSV validation summary show hogi
- user ko rows ka preview milega:
  - platform
  - content preview
  - scheduled date/time
  - validation status
- invalid rows highlighted honge
- duplicate/spam/hashtag warnings show hongi
- final button: `Schedule after confirmation`

### Mobile Behavior

Mobile par:

- composer attachment button se CSV select hogi
- CSV preview chat ke neeche Drafts / Generated area mein show hoga
- large table ki jagah compact row cards show honge
- user invalid rows expand karke dekh sakta hai
- confirmation button sticky bottom action ke form mein show hoga

### Required CSV Format

Initial v1 format:

```csv
platform,content,scheduled_at
facebook,"Your post content",2026-06-23 09:00
linkedin,"LinkedIn update",2026-06-24 12:00
x,"Short post for X",2026-06-25 15:00
instagram,"Instagram caption",2026-06-26 10:00
```

Supported platforms:

- facebook
- instagram
- linkedin
- x

### Main Agent Behavior

When CSV is uploaded:

1. Main Agent detects file type.
2. Scheduling Agent parses rows behind the scenes.
3. Safety And Review Agent validates:
   - required columns
   - supported platform
   - valid future scheduled time
   - connected account exists for each platform
   - duplicate content
   - spam risk
   - hashtag limits
4. Main Agent shows a clean summary:
   - total rows
   - valid rows
   - invalid rows
   - warnings
5. User confirms scheduling.
6. Only after confirmation, backend creates scheduled posts.

### Confirmation Rule

CSV upload never schedules silently.

Required confirmation text/action:

```txt
I found 24 valid posts and 3 rows with warnings. Schedule the valid posts?
```

Actions:

- `Schedule valid posts`
- `Fix CSV`
- `Cancel`

### Backend Reuse

Reuse existing backend endpoint:

```txt
POST /api/v1/post/bulk-upload
```

But agent flow should add a preview/validation step before final upload. If needed, add a new dry-run endpoint:

```txt
POST /api/v1/agent/csv-preview
```

Expected dry-run response:

```json
{
  "total_rows": 27,
  "valid_rows": 24,
  "invalid_rows": 3,
  "warnings": [],
  "preview": []
}
```

### Frontend Components

Add CSV support to:

```txt
fb_dash/app/agent/components/AgentComposer.tsx
fb_dash/app/agent/components/GeneratedAssetsPanel.tsx
```

Optional component:

```txt
fb_dash/app/agent/components/CsvUploadPreview.tsx
```

The preview component should show row cards/table, warnings, and confirmation actions.

## 13. Safety Rules

**Client summary:** System risky actions silently execute nahi karega. Publishing, scheduling, disconnecting, deleting, and autopilot changes confirmation ke baad honge.

Do not allow silent execution for risky actions.

Requires confirmation:

- publish post now
- schedule one or more posts
- run bulk upload scheduling
- delete post
- delete generated image/media
- disconnect app
- enable/disable autopilot
- change autopilot schedule

Does not require confirmation:

- generate content
- generate image preview
- summarize analytics
- check connected apps
- show queue
- inspect token status

## 14. Migration Strategy

**Client summary:** Rebuild phased hoga. Pehle `/agent` foundation, phir auth redirects, backend command endpoint, core workflows, advanced workflows, aur polish/testing.

### Phase 1: Plan And Foundation

- Add this plan file.
- Add `/agent` route.
- Add basic chat UI.
- Add connect apps dropdown.
- Keep subagents hidden from user interface.
- Keep old pages untouched.

### Phase 2: Auth Redirects

- Redirect login/signup/Google auth success to `/agent`.
- Landing authenticated CTA points to `/agent`.
- Old dashboard routes remain accessible manually.

### Phase 3: Agent Backend

- Add `/api/v1/agent/command`.
- Add simple intent router.
- Return only user-visible artifacts and generic progress labels.
- Keep subagent execution trace server-side only.
- Add confirmation structure.

### Phase 4: Core Subagent Workflows

Implement first workflows:

- connect app status and OAuth launch
- generate post
- generate image
- schedule post with confirmation
- analytics summary

### Phase 5: Advanced Workflows

- autopilot setup through agent
- bulk post planning and scheduling
- generated image attach-to-post flow
- retry failed posts
- Ideas Board as agent memory

### Phase 6: Polish And Production Readiness

- remove old tabs/sidebar code from final user-facing app
- remove user-facing API key/provider settings
- fix encoding/glyph issues in visible text
- improve mobile layout
- add loading, error, empty states
- verify mobile shows only Main Agent and Drafts/Generated area
- add tests

## 15. Test Plan

**Client summary:** Testing ka goal hai ke new agent-first UI, hidden execution, voice/text input, Connect Apps, image generation, CSV upload, scheduling, publishing, analytics, and web search all work safely.

### Frontend Commands

Run:

```txt
npm run lint
npm run build
npm test
```

### Backend Commands

Run:

```txt
pytest
```

### Manual Tests

Auth:

- signup redirects to `/agent`
- login redirects to `/agent`
- Google auth redirects to `/agent`
- unauthenticated `/agent` redirects to landing/login

Agent UI:

- text command sends successfully
- voice command fills text
- voice fallback appears on unsupported browser
- subagent names and raw statuses are not visible to normal users
- generic progress label appears during work
- generated image preview appears
- desktop shows full agent command center
- mobile shows Main Agent chat and Drafts/Generated area only
- old tabs/sidebar are not visible in final user flow
- API key/provider settings are not visible to users

Connect Apps:

- dropdown shows Facebook, Instagram, LinkedIn, X
- connected status is correct
- OAuth launch works
- disconnect asks confirmation

Content:

- generate one LinkedIn post
- generate multi-platform variants
- generate hashtags
- run post health check

Image:

- generate image from command
- image saves to media backend
- image preview renders
- image can attach to draft
- image failure does not break draft generation

Scheduling:

- schedule single post after confirmation
- schedule multiple posts after confirmation
- invalid schedule shows clear error

Publishing:

- publish requires confirmation
- failed post retry works
- publishing errors are explained by agent

Analytics:

- analytics summary command returns useful result
- missing connected apps state is explained clearly

Web Search:

- "latest trends" command routes through Web Search Agent internally
- Main Agent returns summarized research
- source links or source names appear when useful
- if web fetch fails, Main Agent shows a graceful fallback message

LLM / API Key Policy:

- all hidden agents use the backend Z.AI GLM gateway
- frontend never receives the Z.AI API key
- user cannot add or edit LLM API keys
- Prompt Settings page is not reachable from final app navigation

## 16. Assumptions

**Client summary:** Existing dashboard pages first phase mein delete nahi hongi. Agent-first UI primary experience banegi, aur OAuth remains required for social connections.

- Existing dashboard pages are kept during migration.
- Primary new experience is `/agent`.
- Social apps use OAuth, not username/password automation.
- Final user-facing tabs/sidebar will be removed after equivalent agent workflows are complete.
- Users will not manage LLM API keys; NexLab/SocialHub configures Z.AI internally.
- V1 voice uses browser speech recognition.
- V1 agent orchestration can be deterministic routing.
- Web Search Agent requires network-capable backend execution or a configured search provider.
- AI image generation should reuse existing media backend and Cloudinary flow where possible.
- Full autonomous multi-step execution can be improved after the stable agent command center is shipped.
