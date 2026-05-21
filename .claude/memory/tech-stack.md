---
name: tech-stack
description: SocialHub mein use hone wali saari technologies, versions, aur unka role
metadata:
  type: project
---

# Tech Stack

## Frontend (fb_dash/)

| Technology | Version | Role |
|---|---|---|
| Next.js | ^16.0.7 | React framework, App Router |
| React | 19.2.0 | UI library |
| TypeScript | Latest | Type safety (strict mode ON) |
| Tailwind CSS | ^4 | Styling (utility-first) |
| Redux Toolkit | ^2.11.0 | State management |
| react-redux | ^9.2.0 | React-Redux binding |
| lucide-react | ^0.556.0 | Icons |
| react-datepicker | Latest | Date selection UI |
| react-timezone-select | Latest | Timezone selector |
| date-fns | Latest | Date manipulation |

**TypeScript strict mode ON hai** — `tsconfig.json` mein strict: true. Type errors se `npm run build` fail hoga.

## Backend (fb_agent/)

| Technology | Role |
|---|---|
| FastAPI | Web framework, async routes |
| Python 3 | Language |
| SQLAlchemy | ORM (database models) |
| Alembic | Database migrations |
| APScheduler | Background jobs (scheduled posts, analytics) |
| Pydantic | Request validation, response serialization |
| python-jose | JWT token generation/verification |
| passlib + bcrypt | Password hashing |
| psycopg2-binary | PostgreSQL driver |
| httpx / requests | HTTP clients for external APIs |
| python-dotenv | Environment variable loading |
| uvicorn | ASGI server |

## Database

| Environment | Database |
|---|---|
| Production | PostgreSQL (Railway/Vercel) |
| Local/Demo | SQLite |

## AI Services

| Provider | Key Env Var | Notes |
|---|---|---|
| Google Gemini | `GEMINI_API_KEY` | Default provider |
| Anthropic Claude | `ANTHROPIC_API_KEY` | Per-user option |
| OpenRouter | `OPENROUTER_API_KEY` | Multi-model gateway |

## External APIs

- **Facebook Graph API** — pages, posts, insights
- **Instagram Business API** — via Facebook Business
- **LinkedIn API** — profile, posts
- **X (Twitter) API v2** — OAuth 2.0 + OAuth 1.0a

## Deployment

| Service | Platform |
|---|---|
| Frontend | Vercel |
| Backend | Railway (primary), Vercel option bhi hai |

**Why:** Stack awareness zaroori hai taaki import suggestions, type handling, aur framework-specific patterns sahi hon.
**How to apply:** Frontend mein Redux patterns use karo, backend mein FastAPI Depends() pattern follow karo, TypeScript strict types maintain karo.
