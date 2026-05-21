---
name: architecture
description: SocialHub ki monorepo structure, frontend/backend split, aur key entry points
metadata:
  type: project
---

# Architecture

## Monorepo Structure

```
socialhub/
├── fb_dash/      # Next.js Frontend
├── fb_agent/     # FastAPI Backend
└── .claude/      # Claude instructions & memory
```

Dono (`fb_dash` aur `fb_agent`) alag deploy hote hain — shared code nahi hai.

## Frontend Architecture (fb_dash/)

**Next.js App Router** use hota hai — `pages/` directory nahi, `app/` hai.

```
fb_dash/app/
├── layout.tsx          # Root layout — Redux StoreProvider wrap karta hai
├── page.tsx            # Landing page (public)
├── login/page.tsx      # Auth pages
├── signup/page.tsx
├── posts/page.tsx           # Main features (auth required)
├── scheduled-posts/page.tsx
├── saved-posts/page.tsx
├── published-posts/page.tsx
├── calendar/page.tsx
├── analytics/page.tsx
├── connect-apps/page.tsx    # OAuth connection UI
├── library/page.tsx
├── prompt-settings/page.tsx
├── users/page.tsx
└── x-callback/page.tsx      # X/Twitter OAuth callback landing
```

**State Flow:**
```
User Action → Redux Thunk (agentSlice.ts) → apiManager.ts → Backend API
                    ↓
              Redux Store → React Component (re-render)
```

**Key Frontend Files:**
- [fb_dash/lib/store.ts](../../../fb_dash/lib/store.ts) — Redux store config
- [fb_dash/lib/features/agentSlice.ts](../../../fb_dash/lib/features/agentSlice.ts) — All state + async thunks
- [fb_dash/lib/apiManager.ts](../../../fb_dash/lib/apiManager.ts) — HTTP client, 12s timeout, base URL Railway
- [fb_dash/lib/hooks.ts](../../../fb_dash/lib/hooks.ts) — `useAppDispatch`, `useAppSelector`
- [fb_dash/app/layout.tsx](../../../fb_dash/app/layout.tsx) — StoreProvider wraps whole app

## Backend Architecture (fb_agent/)

**FastAPI** with layered structure:

```
Request → Route (api/v1/) → Service (services/) → DB (db/crud.py) → Response
```

```
fb_agent/app/
├── main.py              # App entry: routes register, scheduler start, DB init
├── api/v1/              # HTTP route handlers
├── services/            # Business logic (LLM, social APIs, scheduler)
├── db/
│   ├── models.py        # SQLAlchemy ORM models
│   ├── session.py       # DB connection + get_db dependency
│   └── crud.py          # Database operations
├── schemas/             # Pydantic request/response models
└── core/
    ├── config.py        # All env vars (Settings class)
    └── security.py      # JWT + password hashing
```

**Background Jobs (APScheduler in main.py):**
- Har 5 minute: pending scheduled posts check aur publish karo
- Roz midnight: analytics sync karo

**Key Backend Files:**
- [fb_agent/app/main.py](../../../fb_agent/app/main.py) — Entry point, scheduler, CORS config
- [fb_agent/app/db/models.py](../../../fb_agent/app/db/models.py) — All DB tables
- [fb_agent/app/services/llm_service.py](../../../fb_agent/app/services/llm_service.py) — AI provider logic
- [fb_agent/app/core/config.py](../../../fb_agent/app/core/config.py) — Environment settings

## Authentication Flow

```
Frontend Login → POST /api/v1/auth/login → JWT token return
→ Token localStorage mein store (agentSlice)
→ Har request mein: Authorization: Bearer <token>
→ Backend: get_current_user dependency JWT verify karta hai
```

**Why:** Architecture samajhna zaroori hai taaki naya code sahi layer mein likha jaye.
**How to apply:** Route handlers mein business logic mat likho — services/ mein rakho. Frontend mein direct fetch mat karo — apiManager aur Redux thunks use karo.
