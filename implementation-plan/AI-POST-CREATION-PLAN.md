# SocialHub — AI-Powered Post Creation Plan
**Date:** 2026-06-04  
**Status:** Planning Phase  
**Goal:** Replace manual post creation with an AI-first conversational workflow

---

## Overview — Kya Banana Hai

Abhi post create karne ka flow:
```
User → Topic/Keywords manually type karo → Schedule → Done
```

Naya flow:
```
User → Project describe karo (1-2 lines) → AI post likhay → 
User approve/edit/retry kare → Schedule → Done
```

Yeh ek **AI Writing Partner** hai jo user ke saath baat karke post banata hai.

---

## PART 1 — Changes Jo Karne Hain (Cleanup)

### 1.1 Prompt Settings Page Remove
**Kya:** `/prompt-settings` page sidebar se hata do  
**Kyon:** User ko puri prompt page ki zaroorat nahi — sirf API key chahiye  
**Kahan jaayegi API key setting:**
- Post Queue form mein ek chota `⚙️ AI Settings` icon/button
- Click karne pe dropdown: Provider select + API key input
- Save on blur

**Files:**
- `app/components/Sidebar.tsx` — Prompt Settings link remove
- `app/prompt-settings/page.tsx` — Keep file but remove from navigation
- `app/scheduled-posts/page.tsx` — Add inline AI Settings dropdown

---

### 1.2 Topics / Keywords Section Remove
**Kya:** "Topics / Keywords (Enter up to 10)" section delete karo Post Queue se  
**Kyon:** AI khud keywords generate karega description se  
**Replace with:** AI-generated brief system (Part 2 mein detail)

---

### 1.3 Full World Timezones
**Kya:** Timezone dropdown mein sari duniya ki timezones  
**Abhi:** Sirf Pakistan Time dikhta hai  
**Fix:** `react-timezone-select` already installed hai — `timezones` prop hata do ya `allTimezones` use karo

```tsx
// Pehle (sirf Pakistan):
timezones={{ "Asia/Karachi": "Pakistan Time (Karachi)" }}

// Naya (sab timezones):
timezones={allTimezones}  // ya prop hi remove karo
```

**Files:**
- `app/scheduled-posts/page.tsx` — TimezoneSelect component update

---

## PART 2 — AI Post Description System (Core Feature)

### 2.1 Concept — "Describe Karo, AI Likhe"

**User experience:**

```
┌─────────────────────────────────────────────────────┐
│  PROJECT NAME                                        │
│  [Summer Campaign 2026                            ]  │
│                                                      │
│  DESCRIBE YOUR POST IDEA  ───────────────────────── │
│  ┌──────────────────────────────────────────────┐   │
│  │ What do you want to post about?              │   │
│  │ e.g. "Our new AI feature that saves 5hrs     │   │
│  │       per week for social media managers"    │   │
│  └──────────────────────────────────────────────┘   │
│  [Platform: LinkedIn ▾]   [Generate Post ✨]        │
│                                                      │
│  ══════════════ AI GENERATED ══════════════          │
│  ┌──────────────────────────────────────────────┐   │
│  │ 🚀 Tired of spending hours on social media?  │   │
│  │                                              │   │
│  │ Introducing SocialHub's AI Autopilot — the  │   │
│  │ tool that writes, schedules and publishes    │   │
│  │ your posts while you focus on what matters. │   │
│  │                                              │   │
│  │ ✅ Save 5+ hours weekly                     │   │
│  │ ✅ Never miss a posting time                │   │
│  │ ✅ Platform-optimized content               │   │
│  │                                              │   │
│  │ Ready to transform your social strategy? 👇 │   │
│  └──────────────────────────────────────────────┘   │
│  [✏️ Edit]  [🔄 Rewrite]  [💡 Different Tone]       │
│                                                      │
│  Auto-Keywords: social media, AI automation, ...    │
│                                                      │
│  [Schedule Post →]                                   │
└─────────────────────────────────────────────────────┘
```

---

### 2.2 Flow — Step by Step

**Step 1: User describes the post**
- Simple textarea: "What do you want to post about?"
- Platform select (LinkedIn, Facebook, X, Instagram)
- Click "Generate Post ✨"

**Step 2: AI generates post**
- Backend AI call with description + platform + user's system prompt
- Response streams back (or quick load)
- Post appears in editable area below

**Step 3: User options**
| Button | Kya karta hai |
|--------|--------------|
| ✏️ Edit | Direct textarea mein edit karo |
| 🔄 Rewrite | "Isi topic par dobara likho" — new version |
| 💡 Different Tone | Tone change (Professional/Casual/Humorous) |
| ➕ Add Request | Free-text: "Add emojis", "Shorten it", "Add CTA" |

**Step 4: Schedule**
- AI-generated content locked in
- Keywords auto-generated (hidden from user, used internally)
- Schedule karo
- AI publishes at scheduled time

---

### 2.3 Backend — New Endpoints

#### `POST /post/generate-from-brief`
```
Input:
  - description: "Our AI tool saves 5 hours weekly"
  - platform: "linkedin"
  - tone: "professional" (optional)
  - refine_instruction: "make it shorter" (optional, for rewrites)
  - previous_content: "..." (optional, for context in rewrites)

Output:
  - content: "Generated post text..."
  - keywords: ["AI", "social media", "automation"]
  - word_count: 150
  - estimated_read_time: "45 seconds"
```

**File:** `fb_agent/app/api/v1/post_routes.py` — add new endpoint  
**Service:** `fb_agent/app/services/llm_service.py` — add `generate_from_brief()` function

---

### 2.4 Frontend — New Components

#### `AIPostComposer` component
**File:** `app/components/AIPostComposer.tsx` (new file)

**States:**
```ts
type ComposerState = "idle" | "generating" | "ready" | "editing"

- brief: string           // User ki description
- generatedContent: string  // AI ka output
- editedContent: string   // User ki edits
- keywords: string[]      // AI-generated keywords
- isGenerating: boolean
- generationHistory: string[]  // Previous versions for undo
```

**Props:**
```ts
interface AIPostComposerProps {
  platform: string
  onContentReady: (content: string, keywords: string[]) => void
  onClear: () => void
}
```

---

### 2.5 Rewrite / Refine — Conversation Mode

User "🔄 Rewrite" click kare:
```
AI: "Main isi topic par naya version likhta hoon..."
    [New version appears]
```

User "➕ Add Request" use kare:
```
Input: "Add 3 bullet points"
AI: [Updated version with bullets]
```

Yeh ek light conversational loop hai — full chat nahi, sirf refine karna.

**Backend:** Same `/post/generate-from-brief` endpoint, with `refine_instruction` + `previous_content`

---

## PART 3 — Implementation Order

### Phase A — Quick Wins (1-2 days)
```
[ ] Remove Prompt Settings from sidebar navigation
[ ] Remove Topics/Keywords input from Post Queue form  
[ ] Add full world timezones to timezone dropdown
[ ] Add inline AI Settings (provider + key) to Post Queue
```

### Phase B — AI Composer Core (3-4 days)
```
[ ] Backend: POST /post/generate-from-brief endpoint
[ ] Backend: update llm_service with generate_from_brief()
[ ] Frontend: AIPostComposer component (idle + generating + ready states)
[ ] Frontend: Integrate into Post Queue form (replace keywords section)
[ ] Frontend: "Generate Post" button with loading state
[ ] Frontend: Editable textarea after generation
```

### Phase C — Polish & Refine (2-3 days)
```
[ ] Frontend: "Rewrite" button with history
[ ] Frontend: "Different Tone" dropdown
[ ] Frontend: "Add Request" free-text refine input
[ ] Frontend: Auto-keyword display (small chips, readonly)
[ ] Frontend: Character/word count display
[ ] Smooth transitions between states
```

### Phase D — Integration (1-2 days)
```
[ ] Test full flow: brief → generate → schedule → publish
[ ] Handle errors (no API key, AI fails, etc.)
[ ] Mobile responsive AIPostComposer
[ ] Deploy backend + frontend
```

---

## PART 4 — Backend LLM Prompt Design

### System Prompt for `generate_from_brief`:
```python
BRIEF_SYSTEM_PROMPT = """
You are a professional social media content writer.

Given a brief description of what the user wants to post, 
write a platform-optimized post that:
- Matches the platform's style (LinkedIn: professional, X: concise, etc.)
- Has a strong hook in the first line
- Includes a clear call-to-action
- Uses appropriate emojis for the platform
- Is the right length for the platform

Also generate 3-5 relevant keywords for this post.

Return in this exact JSON format:
{
  "content": "The full post text...",
  "keywords": ["keyword1", "keyword2", "keyword3"]
}
"""
```

### Refine Prompt:
```python
REFINE_PROMPT = """
Here is an existing social media post:
---
{previous_content}
---

User instruction: {refine_instruction}

Rewrite the post following the instruction while keeping 
the same topic, platform, and core message.

Return same JSON format: {"content": "...", "keywords": [...]}
"""
```

---

## PART 5 — UI Mockup (Detailed)

### Post Queue Form — Naya Layout:

```
┌── PROJECT DETAILS ─────────────────────────────────┐
│  Project Name: [Campaign name...                 ]  │
│                                                     │
│  ⚙️ AI Provider: [Gemini ▾]  [API Key: ••••••••]   │
└─────────────────────────────────────────────────────┘

┌── DESCRIBE YOUR POST ──────────────────────────────┐
│  Platform: [f] [in] [X] [📷]  (select one)         │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │ Describe what you want to post...            │  │
│  │ (e.g. "Announce our new product launch      │  │
│  │  targeting small business owners")           │  │
│  └──────────────────────────────────────────────┘  │
│                                    [✨ Generate]    │
└─────────────────────────────────────────────────────┘

┌── AI GENERATED POST ───────────────────────────────┐  ← appears after generate
│  ┌──────────────────────────────────────────────┐  │
│  │ [Editable text area with AI content]         │  │
│  │                                              │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  [🔄 Rewrite] [💡 Change Tone ▾] [✏️ Edit Mode]    │
│                                                     │
│  Refine: [Add emojis / Make shorter / Add CTA... ] │
│          [Apply →]                                  │
│                                                     │
│  Keywords: #AI  #socialmedia  #automation           │
└─────────────────────────────────────────────────────┘

┌── SCHEDULE ────────────────────────────────────────┐
│  Frequency | Date | Time | Timezone (all world)    │
│  Target End Date                                    │
└─────────────────────────────────────────────────────┘

┌── SOCIAL MEDIA PLATFORM ───────────────────────────┐
│  Account selector (Facebook page / LinkedIn / X)   │
└─────────────────────────────────────────────────────┘

[GENERATE & SCHEDULE POSTS]
```

---

## PART 6 — Kya NAYA hai is plan mein

| Feature | Industry Standard | Hamara |
|---------|-----------------|--------|
| Content creation | User likhay | User describe kare, AI likhay |
| Keywords | User manually type kare | AI auto-generate kare |
| Refinement | Edit only | Chat-like refine loop |
| Prompt settings | Separate page | Inline, contextual |
| Timezone | Limited | Full world coverage |
| Workflow | Create → Schedule → Publish | Describe → Generate → Approve → Schedule → Publish |

**Unique selling point:** User ko ab content likhna nahi padega — sirf ek line mein idea do, AI sab handle karega. Fir agar pasand nahi toh refine karo — seedha chat ki tarah.

---

## Files To Change (Summary)

### Backend (fb_agent):
```
app/api/v1/post_routes.py          → Add /post/generate-from-brief
app/services/llm_service.py        → Add generate_from_brief()
```

### Frontend (fb_dash):
```
app/components/Sidebar.tsx         → Remove Prompt Settings link
app/components/AIPostComposer.tsx  → NEW component
app/scheduled-posts/page.tsx       → Major redesign
lib/apiManager.ts                  → Add generateFromBrief()
```

---

## Estimated Total Effort: 8-10 days
