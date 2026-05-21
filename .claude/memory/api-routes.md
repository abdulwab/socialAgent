---
name: api-routes
description: SocialHub backend ke saare API endpoints, auth pattern, aur route file locations
metadata:
  type: project
---

# API Routes

**Base URL (Production):** `https://web-production-a02ea.up.railway.app/api/v1`
**Base URL (Local):** `http://localhost:8000/api/v1`

## Authentication Pattern

- **JWT Bearer token** — `Authorization: Bearer <token>`
- Token `POST /auth/login` ya `GET /auth/callback` se milta hai
- Backend mein `get_current_user` FastAPI dependency use hoti hai
- Token expiry: `ACCESS_TOKEN_EXPIRE_MINUTES` env var se control hota hai

---

## Auth Routes — `/api/v1/auth`

File: [fb_agent/app/api/v1/auth_routes.py](../../../fb_agent/app/api/v1/auth_routes.py)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/auth/signup` | No | Email/password registration |
| POST | `/auth/login` | No | Email/password login → JWT return |
| GET | `/auth/login-url` | No | Facebook OAuth URL generate |
| GET | `/auth/callback` | No | Facebook OAuth callback, code exchange |
| GET | `/auth/instagram-login-url` | Yes | Instagram OAuth URL |
| GET | `/auth/instagram-callback` | Yes | Instagram OAuth callback |
| GET | `/auth/linkedin-login-url` | Yes | LinkedIn OAuth URL |
| GET | `/auth/linkedin-callback` | Yes | LinkedIn OAuth callback |
| GET | `/auth/x-login-url` | Yes | X/Twitter OAuth URL |
| GET | `/auth/x-callback` | Yes | X/Twitter OAuth callback |

---

## Post Routes — `/api/v1/post`

File: [fb_agent/app/api/v1/post_routes.py](../../../fb_agent/app/api/v1/post_routes.py)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/post/generate` | Yes | AI se content generate karo |
| POST | `/post/publish` | Yes | Platform par publish karo |

**Generate Request:**
```json
{ "topic": "string", "platform": "facebook|instagram|linkedin|x|both|all" }
```

**Publish Request:**
```json
{ "content": "string", "platform": "string", "page_id": "string (optional)" }
```

---

## Scheduled Post Routes — `/api/v1/scheduled-posts`

File: [fb_agent/app/api/v1/scheduled_post_routes.py](../../../fb_agent/app/api/v1/scheduled_post_routes.py)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/scheduled-posts` | Yes | Naya scheduled post banao |
| GET | `/scheduled-posts` | Yes | Saare scheduled posts list |
| PUT | `/scheduled-posts/{id}` | Yes | Post update karo |
| DELETE | `/scheduled-posts/{id}` | Yes | Post cancel/delete karo |

**Scheduler behavior:** `main.py` mein APScheduler har 5 minute mein pending posts check karta hai aur publish karta hai.

---

## Saved Post Routes — `/api/v1/saved-posts`

File: [fb_agent/app/api/v1/saved_post_routes.py](../../../fb_agent/app/api/v1/saved_post_routes.py)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/saved-posts` | Yes | Draft save karo |
| GET | `/saved-posts` | Yes | Saare drafts list |
| PUT | `/saved-posts/{id}` | Yes | Draft update karo |
| DELETE | `/saved-posts/{id}` | Yes | Draft delete karo |

---

## User Routes — `/api/v1/user`

File: [fb_agent/app/api/v1/user_routes.py](../../../fb_agent/app/api/v1/user_routes.py)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/user/me` | Yes | Current user profile |
| PUT | `/user/api-keys` | Yes | Gemini/Claude/OpenRouter keys save |
| PUT | `/user/active-provider` | Yes | AI provider change karo |
| PUT | `/user/system-prompt` | Yes | Custom system prompt set karo |
| GET | `/user/pages` | Yes | Connected Facebook pages list |
| GET | `/user/linkedin-accounts` | Yes | Connected LinkedIn accounts |
| GET | `/user/x-accounts` | Yes | Connected X accounts |

---

## Analytics Routes — `/api/v1`

File: [fb_agent/app/api/v1/analytics_routes.py](../../../fb_agent/app/api/v1/analytics_routes.py)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/analytics/posts` | Yes | Post metrics list |
| GET | `/analytics/profile` | Yes | Profile growth metrics |
| POST | `/analytics/sync` | Yes | Manual analytics sync trigger |

---

## Utility Endpoints

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/health` | No | Health check |
| GET | `/init-db` | No | DB init aur schema migration (startup use) |

---

## Error Response Format

```json
{ "detail": "Error message string" }
```

HTTP status codes:
- `401` — Unauthorized (invalid/expired JWT)
- `403` — Forbidden (resource belongs to another user)
- `404` — Not found
- `422` — Validation error (Pydantic)
- `500` — Internal server error

**Why:** Route knowledge zaroori hai taaki frontend API calls sahi URL aur method se karein.
**How to apply:** Naya frontend feature likhte waqt pehle dekhna ki route exist karta hai ya nahi. Auth-required routes mein `Authorization` header automatically `apiManager.ts` lagate hai.
