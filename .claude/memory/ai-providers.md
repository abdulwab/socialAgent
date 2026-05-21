---
name: ai-providers
description: LLM service architecture — Gemini, Claude, OpenRouter provider selection aur per-user API key system
metadata:
  type: project
---

# AI Providers

## Service File

[fb_agent/app/services/llm_service.py](../../../fb_agent/app/services/llm_service.py)

---

## Multi-Provider Architecture

SocialHub **per-user AI provider** support karta hai — har user apna API key set kar sakta hai.

**Supported Providers:**

| Provider | `active_provider` value | Env Var (fallback) | Notes |
|---|---|---|---|
| Google Gemini | `"gemini"` | `GEMINI_API_KEY` | Default provider |
| Anthropic Claude | `"claude"` | `ANTHROPIC_API_KEY` | |
| OpenRouter | `"openrouter"` | `OPENROUTER_API_KEY` | Multi-model gateway |

---

## Provider Selection Logic

```python
# llm_service.py — simplified flow
def generate_content(user: User, topic: str, platform: str) -> str:
    provider = user.active_provider  # "gemini" | "claude" | "openrouter"
    
    # Per-user key prefer karo, fallback to env var
    if provider == "gemini":
        api_key = user.gemini_api_key or settings.GEMINI_API_KEY
        return call_gemini(api_key, topic, platform)
    
    elif provider == "claude":
        api_key = user.claude_api_key or settings.ANTHROPIC_API_KEY
        return call_claude(api_key, topic, platform)
    
    elif provider == "openrouter":
        api_key = user.openrouter_api_key or settings.OPENROUTER_API_KEY
        return call_openrouter(api_key, topic, platform)
```

---

## User API Key Management

**Route:** `PUT /api/v1/user/api-keys`
**Route:** `PUT /api/v1/user/active-provider`

User ye keys `prompt-settings/page.tsx` se manage karta hai:
```json
{
  "gemini_api_key": "AIza...",
  "openrouter_api_key": "sk-or-...",
  "claude_api_key": "sk-ant-..."
}
```

Keys `User` table mein store hoti hain (per-user fields).

---

## System Prompt Customization

**Route:** `PUT /api/v1/user/system-prompt`

- Har user apna custom system prompt set kar sakta hai
- `User.system_prompt` field mein store hota hai
- `llm_service.py` is prompt ko LLM call mein inject karta hai
- Default prompts: `fb_agent/app/prompts/` directory mein industry-specific files hain

**Prompts Directory:**
```
fb_agent/app/prompts/
├── default.txt
├── ecommerce.txt
├── restaurant.txt
├── tech.txt
└── ...
```

---

## Content Generation Flow

```
POST /post/generate
    ↓
post_routes.py → llm_service.generate_content()
    ↓
User ka active_provider check karo
    ↓
User ka API key (ya env var fallback) use karo
    ↓
System prompt + topic + platform-specific instructions
    ↓
LLM response → frontend mein display
```

---

## Platform-Specific Prompting

`llm_service.py` platform ke hisaab se different instructions deta hai:
- **Facebook**: Long-form, conversational
- **Instagram**: Hashtags, visual descriptions
- **LinkedIn**: Professional tone, industry insights
- **X/Twitter**: Short, punchy, under 280 chars

---

## Adding a New AI Provider

1. `llm_service.py` mein nayi function likho
2. Provider selection logic mein add karo
3. `User` model mein nayi `_api_key` field add karo (migration!)
4. `config.py` mein env var add karo (fallback)
5. `user_routes.py` mein API key update endpoint update karo
6. Frontend `prompt-settings/` page mein new input field add karo

**Why:** AI provider system samajhna zaroori hai taaki content generation bugs debug ho sakein aur naye providers add kiye ja sakein.
**How to apply:** LLM errors debug karte waqt pehle check karo — user ka API key valid hai? `active_provider` correct set hai? Env var fallback kaam kar raha hai?
