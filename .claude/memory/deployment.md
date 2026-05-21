---
name: deployment
description: Frontend (Vercel) aur backend (Railway) deployment config, environment secrets, aur CORS setup
metadata:
  type: reference
---

# Deployment

## Production URLs

| Service | URL |
|---|---|
| Frontend | https://fb.nexlabai.com |
| Backend API | https://web-production-a02ea.up.railway.app/api/v1 |

---

## Frontend — Vercel

**Platform:** Vercel
**Framework:** Next.js (auto-detected)

**Deploy:**
- Main branch push hone par auto-deploy
- `npm run build` locally check karo pehle

**Config:** `fb_dash/next.config.ts` (minimal — mostly defaults)

**Environment Variables (Vercel Dashboard):**
- Koi special env vars nahi — frontend sirf backend API URL use karta hai jo `apiManager.ts` mein hardcoded hai

---

## Backend — Railway

**Platform:** Railway (primary)
**Procfile:** `web: uvicorn app.main:app --host 0.0.0.0 --port $PORT`

**Startup behavior (`main.py`):**
1. `Base.metadata.create_all(engine)` — tables create/check
2. `run_migrations()` — Alembic migrations auto-run
3. APScheduler start — scheduled posts + analytics jobs
4. FastAPI app serve

**Required Environment Variables (Railway Dashboard):**
```
DATABASE_URL=postgresql://...      # Railway PostgreSQL
FRONTEND_URL=https://fb.nexlabai.com/
SECRET_KEY=...
FACEBOOK_APP_ID, FACEBOOK_APP_SECRET
INSTAGRAM_APP_ID, INSTAGRAM_APP_SECRET, INSTAGRAM_REDIRECT_URI
LINKEDIN_CLIENT_ID, LINKEDIN_CLIENT_SECRET, LINKEDIN_REDIRECT_URI
X_CLIENT_ID, X_CLIENT_SECRET
GEMINI_API_KEY, OPENROUTER_API_KEY, ANTHROPIC_API_KEY
ACCESS_TOKEN_EXPIRE_MINUTES=43200
```

**Vercel Alternative (fb_agent/vercel.json):**
```json
{
  "builds": [{ "src": "app/main.py", "use": "@vercel/python" }],
  "routes": [{ "src": "/(.*)", "dest": "app/main.py" }]
}
```

---

## CORS Configuration

`fb_agent/app/main.py` mein:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://fb.nexlabai.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

**Local development ke liye** `http://localhost:3000` temporarily add karo.
**Production mein** sirf production URL rahni chahiye.

---

## OAuth Redirect URIs — Must Match Platform Console

OAuth callbacks platform developer dashboards mein register hain:

| Platform | Registered Redirect URI |
|---|---|
| Facebook | `https://web-production-a02ea.up.railway.app/api/v1/auth/callback` |
| Instagram | `https://web-production-a02ea.up.railway.app/api/v1/auth/instagram-callback` |
| LinkedIn | `https://web-production-a02ea.up.railway.app/api/v1/auth/linkedin-callback` |
| X/Twitter | Frontend callback: `https://fb.nexlabai.com/x-callback` |

**Agar backend URL change ho (e.g., Railway → other platform), saari redirect URIs update karni hongi developer consoles mein.**

---

## Database

**Production:** PostgreSQL on Railway
**Connection:** `DATABASE_URL` environment variable
**Migrations:** App startup par auto-run hoti hain (`main.py`)

---

## Health Check

```
GET https://web-production-a02ea.up.railway.app/health
```

Response: `{ "status": "healthy" }`

---

## Deployment Checklist (before deploy)

- [ ] `npm run build` frontend mein — TypeScript errors nahi hone chahiye
- [ ] New env vars Railway/Vercel dashboard mein add kiye
- [ ] Database migrations: `alembic revision --autogenerate` generate kiya
- [ ] OAuth redirect URIs change nahi kiye (ya update kiye developer console mein)
- [ ] CORS origins production URL par hain
- [ ] `.env` file git mein nahi hai

**Why:** Deployment constraints ka knowledge zaroori hai taaki production break na ho — especially OAuth URIs aur CORS.
**How to apply:** Koi bhi deployment-related change (URL, CORS, env var) suggest karte waqt checklist mention karo. Backend URL change karna risky hai — saari OAuth URIs update karni hongi.
