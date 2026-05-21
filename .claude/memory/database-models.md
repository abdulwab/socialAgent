---
name: database-models
description: SocialHub ke SQLAlchemy database tables, unke fields, aur relationships
metadata:
  type: project
---

# Database Models

File: [fb_agent/app/db/models.py](../../../fb_agent/app/db/models.py)

Migration tool: **Alembic** (`fb_agent/migrations/`)

---

## User

Main user table — har cheez isse related hai.

```python
id: int (PK)
fb_user_id: str (nullable)     # Facebook se login kiya toh populate hota hai
email: str (unique)
hashed_password: str (nullable)  # Email/password login ke liye
name: str

# Social tokens
access_token: str (nullable)   # Facebook user token

# AI Config (per-user)
system_prompt: str (nullable)  # Custom AI system prompt
gemini_api_key: str (nullable)
openrouter_api_key: str (nullable)
claude_api_key: str (nullable)
active_provider: str = "gemini"  # "gemini" | "claude" | "openrouter"
```

**Relationships:** pages, linkedin_accounts, x_accounts, scheduled_posts, metrics, sync_logs

---

## PageToken (Facebook/Instagram Pages)

Ek user ke multiple pages ho sakte hain.

```python
id: int (PK)
user_id: int (FK → User)
page_id: str
page_name: str
page_access_token: str
instagram_business_account_id: str (nullable)  # Agar Instagram linked hai
```

---

## LinkedInAccount

```python
id: int (PK)
user_id: int (FK → User)
linkedin_id: str
name: str
urn: str           # LinkedIn URN (posting ke liye zaroori)
access_token: str
expires_at: datetime (nullable)
```

---

## XAccount (Twitter/X)

```python
id: int (PK)
user_id: int (FK → User)
x_user_id: str
username: str
name: str
access_token: str
refresh_token: str (nullable)
expires_at: datetime (nullable)
```

---

## ScheduledPost

Core scheduling table.

```python
id: int (PK)
user_id: int (FK → User)
content: str
topic: str (nullable)
platform: str      # "facebook" | "instagram" | "linkedin" | "x" | "both" | "all"

# Timing
scheduled_time: datetime
timezone: str      # e.g., "Asia/Karachi"

# Recurrence
is_recurring: bool = False
recurrence_pattern: str (nullable)  # "daily" | "weekly" | "monthly"
cron_expression: str (nullable)

# Status
status: str = "pending"  # "pending" | "published" | "failed" | "cancelled"

# Platform specifics
image_url: str (nullable)
instagram_account_id: str (nullable)  # Which Instagram account
x_account_id: int (nullable)          # FK → XAccount
```

---

## PostMetricsDaily

Post-level analytics (daily snapshot).

```python
id: int (PK)
user_id: int (FK → User)
platform: str      # "facebook" | "instagram" | "linkedin" | "x"
post_id: str       # Platform ka native post ID
date: date
impressions: int
reach: int
engagement: int
likes: int
comments: int
shares: int
```

**Unique constraint:** `(user_id, platform, post_id, date)`

---

## ProfileMetricsDaily

Profile/page-level analytics (followers, reach etc.)

```python
id: int (PK)
user_id: int (FK → User)
platform: str
account_id: str    # Page ID ya LinkedIn URN
date: date
followers: int
reach: int
impressions: int
```

**Unique constraint:** `(user_id, platform, account_id, date)`

---

## SyncLog

Analytics sync operations ka audit trail.

```python
id: int (PK)
user_id: int (FK → User)
platform: str
sync_type: str     # "posts" | "profile"
synced_at: datetime
status: str        # "success" | "failed"
error_message: str (nullable)
records_synced: int
```

---

## Schema Change Rule

Database schema change karna ek **breaking operation** hai:

1. `db/models.py` update karo
2. `alembic revision --autogenerate -m "description"` — migration generate karo
3. Migration file manually review karo (autogenerate hamesha perfect nahi hota)
4. `alembic upgrade head` — apply karo

**User se confirm karo PEHLE** — schema changes production database affect karte hain.

**Why:** Models ka knowledge zaroori hai taaki CRUD queries, relationships, aur schema migrations sahi likhi jayein.
**How to apply:** Naya model add karne se pehle existing relationships dekhna. `unique` constraints ka khayal rakhna (duplicate data insert nahi honi chahiye).
