---
name: dev-workflow
description: Frontend aur backend locally kaise run karein, env vars setup, database migrations, aur common dev tasks
metadata:
  type: project
---

# Development Workflow

## Frontend Setup (fb_dash/)

```bash
cd fb_dash
npm install
npm run dev      # http://localhost:3000
```

**Scripts:**
```bash
npm run dev      # Dev server with hot reload
npm run build    # Production build (TypeScript errors yahan pakdte hain)
npm run start    # Production server locally
npm run lint     # ESLint check
```

**Important:** `npm run build` run karo kisi bhi naye code ke baad — TypeScript strict mode mein type errors build break karte hain.

---

## Backend Setup (fb_agent/)

### Pehli baar:
```bash
cd fb_agent
python -m venv venv
venv\Scripts\activate        # Windows
# source venv/bin/activate   # Mac/Linux

pip install -r requirements.txt

# .env file banao (neeche dekhein)
alembic upgrade head         # Database migrations run karo

uvicorn app.main:app --reload  # http://localhost:8000
```

### Roz ka workflow:
```bash
cd fb_agent
venv\Scripts\activate
uvicorn app.main:app --reload
```

---

## Environment Variables (.env)

`fb_agent/.env` file banao:

```env
# Database (local SQLite ke liye)
DATABASE_URL=sqlite:///./socialhub.db

# Ya PostgreSQL ke liye:
# DATABASE_URL=postgresql://user:password@localhost/socialhub

# Frontend URL (local development)
FRONTEND_URL=http://localhost:3000

# JWT
SECRET_KEY=your-secret-key-here-min-32-chars
ACCESS_TOKEN_EXPIRE_MINUTES=43200

# Facebook
FACEBOOK_APP_ID=your_app_id
FACEBOOK_APP_SECRET=your_app_secret
FACEBOOK_REDIRECT_URI=http://localhost:8000/api/v1/auth/callback

# Instagram
INSTAGRAM_APP_ID=your_app_id
INSTAGRAM_APP_SECRET=your_app_secret
INSTAGRAM_REDIRECT_URI=http://localhost:8000/api/v1/auth/instagram-callback

# LinkedIn
LINKEDIN_CLIENT_ID=your_client_id
LINKEDIN_CLIENT_SECRET=your_client_secret
LINKEDIN_REDIRECT_URI=http://localhost:8000/api/v1/auth/linkedin-callback

# X/Twitter
X_CLIENT_ID=your_client_id
X_CLIENT_SECRET=your_client_secret

# AI Providers (optional — user apna key set kar sakta hai)
GEMINI_API_KEY=AIza...
ANTHROPIC_API_KEY=sk-ant-...
OPENROUTER_API_KEY=sk-or-...
```

**NEVER `.env` ko git mein commit karo.**

---

## Database Migrations

```bash
# New migration generate karo (model change ke baad)
alembic revision --autogenerate -m "add column xyz to user"

# Migration file review karo (fb_agent/migrations/versions/)
# Phir apply karo:
alembic upgrade head

# Ek step rollback:
alembic downgrade -1

# Migration history dekhna:
alembic history
```

**Rule:** Schema change karna user se confirm karo pehle — production database affect hogi.

---

## Local Development Tips

### Frontend API URL change
`fb_dash/lib/apiManager.ts` mein base URL production Railway ka hai.
Local backend se connect karne ke liye:
```typescript
// apiManager.ts mein temporarily change karo:
const BASE_URL = "http://localhost:8000/api/v1"
// (Production deploy se pehle wapas karein!)
```

### CORS Error Fix (local)
`fb_agent/app/main.py` mein CORS origins mein add karo:
```python
allow_origins=["https://fb.nexlabai.com", "http://localhost:3000"]
```

### Database Reset (local only!)
```bash
# SQLite ke liye:
rm socialhub.db
alembic upgrade head

# Ya:
python -c "from app.db.session import engine; from app.db.models import Base; Base.metadata.drop_all(engine); Base.metadata.create_all(engine)"
```

---

## No Test Suite

**Project mein abhi formal test suite nahi hai.**
- Backend: No pytest tests
- Frontend: No Jest tests

Manual testing karo — browser mein feature use karke verify karo.

---

## Common Development Tasks

### Naya page add karna (Frontend)
```
fb_dash/app/<route-name>/page.tsx  banao
```

### Naya API endpoint add karna (Backend)
```
1. fb_agent/app/api/v1/<feature>_routes.py mein route likho
2. main.py mein router include karo
3. Pydantic schema schemas/ mein banao
```

### Dependency add karna
```bash
# Frontend:
cd fb_dash && npm install <package>

# Backend:
cd fb_agent && pip install <package> && pip freeze > requirements.txt
```
**Pehle user se confirm karo — dependencies change karna prohibited hai bina permission.**

**Why:** Workflow jaanna zaroori hai taaki development setup aur common tasks mein guide kar sakoon.
**How to apply:** Jab user koi feature implement karne ko kahe, suggest karo ke locally test karna chahiye: frontend build check + manual browser test.
