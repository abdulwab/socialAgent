# SocialHub — Project Guide for Claude

## Project Overview

**SocialHub** ek AI-powered social media management platform hai jo users ko Facebook, Instagram, LinkedIn, aur X (Twitter) par posts schedule, generate, aur publish karne ki facility deta hai.

- **Frontend**: `fb_dash/` — Next.js 16, React 19, TypeScript, Tailwind CSS 4, Redux Toolkit
- **Backend**: `fb_agent/` — FastAPI (Python), SQLAlchemy, Alembic, APScheduler
- **Database**: PostgreSQL (production), SQLite (local/demo)
- **AI Providers**: Google Gemini, Anthropic Claude, OpenRouter (multi-provider support)
- **Deployment**: Frontend → Vercel (`https://fb.nexlabai.com`), Backend → Railway

---

## Directory Structure

```
socialhub/
├── fb_dash/                  # Next.js Frontend
│   ├── app/                  # Next.js App Router pages
│   │   ├── page.tsx          # Landing page
│   │   ├── login/            # Login
│   │   ├── signup/           # Registration
│   │   ├── posts/            # Post creation
│   │   ├── scheduled-posts/  # Schedule management
│   │   ├── saved-posts/      # Drafts
│   │   ├── published-posts/  # History
│   │   ├── calendar/         # Calendar view
│   │   ├── analytics/        # Analytics dashboard
│   │   ├── connect-apps/     # OAuth connections
│   │   ├── library/          # Media library
│   │   ├── prompt-settings/  # AI prompt config
│   │   └── users/            # Team management
│   ├── lib/
│   │   ├── store.ts          # Redux store
│   │   ├── features/agentSlice.ts  # Auth + posts + analytics state
│   │   ├── apiManager.ts     # HTTP client (base URL: Railway backend)
│   │   └── hooks.ts          # Custom Redux hooks
│   ├── package.json
│   └── tsconfig.json
│
└── fb_agent/                 # FastAPI Backend
    ├── app/
    │   ├── main.py           # App entry, route registration, scheduler
    │   ├── api/v1/
    │   │   ├── auth_routes.py         # Login, signup, OAuth flows
    │   │   ├── post_routes.py         # Generate & publish posts
    │   │   ├── scheduled_post_routes.py
    │   │   ├── saved_post_routes.py
    │   │   ├── user_routes.py
    │   │   └── analytics_routes.py
    │   ├── services/
    │   │   ├── llm_service.py         # Gemini, Claude, OpenRouter
    │   │   ├── facebook_service.py
    │   │   ├── linkedin_service.py
    │   │   ├── x_service.py
    │   │   ├── instagram_service.py
    │   │   ├── analytics_service.py
    │   │   └── scheduler_service.py
    │   ├── db/
    │   │   ├── models.py     # SQLAlchemy models
    │   │   ├── session.py    # DB connection
    │   │   └── crud.py       # CRUD operations
    │   ├── schemas/          # Pydantic request/response models
    │   └── core/
    │       ├── config.py     # Environment variables
    │       └── security.py   # JWT, password hashing
    ├── migrations/           # Alembic migrations
    └── requirements.txt
```

---

## Development Setup

### Frontend (fb_dash/)
```bash
cd fb_dash
npm install
npm run dev        # localhost:3000
npm run build      # Production build
npm run lint       # ESLint check
```

### Backend (fb_agent/)
```bash
cd fb_agent
python -m venv venv
venv\Scripts\activate          # Windows
pip install -r requirements.txt
alembic upgrade head           # Run DB migrations
uvicorn app.main:app --reload  # localhost:8000
```

### Environment Variables (fb_agent/.env)
```
DATABASE_URL=postgresql://...
FRONTEND_URL=https://fb.nexlabai.com/
SECRET_KEY=...
FACEBOOK_APP_ID, FACEBOOK_APP_SECRET
INSTAGRAM_APP_ID, INSTAGRAM_APP_SECRET, INSTAGRAM_REDIRECT_URI
LINKEDIN_CLIENT_ID, LINKEDIN_CLIENT_SECRET
X_CLIENT_ID, X_CLIENT_SECRET
GEMINI_API_KEY, OPENROUTER_API_KEY, ANTHROPIC_API_KEY
```

> `.env` file KABHI git mein push mat karo. Secrets sirf deployment env vars mein rakho.

---

## Key Technical Details

### Frontend State (Redux)
- Saari auth, posts, aur analytics state `lib/features/agentSlice.ts` mein hai
- API calls `lib/apiManager.ts` se karti hain — base URL Railway backend ka hai
- Custom hooks: `lib/hooks.ts` (`useAppDispatch`, `useAppSelector`)

### Backend API Pattern
- Sab routes `/api/v1/` se shuru hote hain
- JWT authentication — `Authorization: Bearer <token>` header
- Background jobs: APScheduler har 5 minute mein scheduled posts check karta hai
- Analytics sync: Midnight par daily cron

### Database Models (Key Tables)
- **User** — email/password auth, per-user API keys, active AI provider
- **PageToken** — Facebook/Instagram page access tokens
- **LinkedInAccount** — LinkedIn OAuth tokens
- **XAccount** — X/Twitter OAuth tokens
- **ScheduledPost** — content, platform, scheduled_time, timezone, recurrence
- **PostMetricsDaily** / **ProfileMetricsDaily** — analytics data

### AI Provider Selection
- User apna API key set kar sakta hai (`/api/v1/user`)
- `active_provider` field decide karta hai kaun sa LLM use ho — gemini, claude, ya openrouter
- LLM logic: `fb_agent/app/services/llm_service.py`

---

## Common Tasks & Approach

### Naya Frontend Page Add Karna
1. `fb_dash/app/<route>/page.tsx` banao
2. `lib/features/agentSlice.ts` mein agar naya state chahiye toh add karo
3. `apiManager.ts` se API call karo
4. Redux thunk banao async operations ke liye

### Naya Backend Route Add Karna
1. `fb_agent/app/api/v1/` mein nayi route file banao
2. Pydantic schema `schemas/` mein define karo
3. CRUD logic `db/crud.py` mein
4. Router ko `main.py` mein register karo

### Database Schema Change
1. `db/models.py` mein model update karo
2. `alembic revision --autogenerate -m "description"` run karo
3. Migration file review karo
4. `alembic upgrade head` se apply karo
5. **Yeh breaking change hai — pehle user se confirm karo**

### Naya Social Platform Add Karna
1. `services/` mein nayi service file banao
2. `db/models.py` mein account model add karo (migration lazim hai)
3. `schemas/` mein Pydantic models
4. `api/v1/auth_routes.py` mein OAuth endpoints

---

## Important Constraints

- **CORS**: Backend sirf `https://fb.nexlabai.com` se requests accept karta hai (production mein). Local dev ke liye `main.py` mein CORS origins dekhna
- **OAuth Callbacks**: Redirect URIs social platform developer consoles mein registered hain — inhe change karne se OAuth toot sakta hai
- **APScheduler**: `main.py` mein scheduler start hota hai — scheduler logic `services/scheduler_service.py` mein hai
- **No test suite**: Project mein abhi koi formal tests nahi hain
- **TypeScript strict mode** frontend mein on hai — type errors se build fail hoga

---

## Code Conventions

### Frontend (TypeScript/React)
- Functional components with hooks
- Redux Toolkit async thunks for API calls
- Tailwind utility classes for styling — inline styles avoid karo
- `lucide-react` for icons
- Path alias: `@/` project root se point karta hai

### Backend (Python/FastAPI)
- Dependency injection via FastAPI `Depends()`
- `get_current_user` dependency JWT verify karta hai
- SQLAlchemy session: `Depends(get_db)` se milti hai
- Pydantic models request validation aur response serialization ke liye
- Async routes jahan possible ho

---

## Prohibited Without Explicit Permission

- `.env` ya kisi bhi secret file ko touch karna
- `alembic` migration run karna bina user ke confirm kiye
- `requirements.txt` ya `package.json` dependencies change karna
- OAuth redirect URIs ya CORS origins modify karna
- Production deployment trigger karna
---

## Developer Profile

- **Name**: Mutahier Shahzad
- **Language**: Urdu + English mix mein baat karta hoon — isi style mein respond karo
- **Experience Level**: [Junior / Mid / Senior]
- **Main Focus**: Frontend (Next.js) / Backend (FastAPI) / Full Stack

---

## My Working Preferences

- Pehle **problem explain karo**, phir code do
- Code mein **Roman Urdu comments** daal do jahan helpful ho
- Breaking changes se pehle **hamesha confirm karo**
- Choti fixes ke liye **seedha code do**, lamba explanation mat karo
- Agar kuch unclear ho toh **pehle pucho**, assume mat karo

---

## Current Active Work

- [ ] Jo abhi build/fix kar rahe ho yahan likho
- [ ] Example: Bets board feature add karna
- [ ] Example: Analytics page fix

---

## Known Issues / Tech Debt

- Abhi koi formal test suite nahi hai
- [Koi aur known bugs yahan add karo]

---

## Session Memory Hints

- Har naye kaam ki start mein mujhe batao: "Main [X] par kaam karna chahta hoon"
- Main context CLAUDE.md se automatically utha lunga