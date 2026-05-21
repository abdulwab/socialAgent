# Step 02 — Overview Page: Backend Endpoint

**Phase:** 1
**Effort:** Medium
**Estimated Time:** 1–2 hours
**Dependencies:** Step 01 (optional — backend independent hai)

---

## Goal

Ek naya API endpoint banana: `GET /user/overview-stats`

Yeh endpoint Overview dashboard ke liye saari stats return karega.

---

## Response Format

```json
{
  "published_today": 2,
  "scheduled_this_week": 8,
  "failed_posts": 1,
  "total_published": 47,
  "upcoming_posts": [
    {
      "id": 123,
      "platform": "linkedin",
      "scheduled_at": "2026-05-21T14:00:00Z",
      "content_preview": "Excited to share our latest..."
    },
    {
      "id": 124,
      "platform": "facebook",
      "scheduled_at": "2026-05-21T17:30:00Z",
      "content_preview": "Join us this weekend for..."
    }
  ],
  "greeting_name": "Abdul"
}
```

---

## Files to Change

### File 1: `fb_agent/app/api/v1/user_routes.py`

Naya route add karo existing routes ke saath:

```python
@router.get("/user/overview-stats")
async def get_overview_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    from datetime import datetime, timezone, timedelta
    
    now = datetime.now(timezone.utc)
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    week_end = now + timedelta(days=7)
    
    # Published today
    published_today = await db.scalar(
        select(func.count(ScheduledPost.id)).where(
            ScheduledPost.user_id == current_user.id,
            ScheduledPost.status == "published",
            ScheduledPost.published_at >= today_start
        )
    )
    
    # Scheduled this week
    scheduled_this_week = await db.scalar(
        select(func.count(ScheduledPost.id)).where(
            ScheduledPost.user_id == current_user.id,
            ScheduledPost.status == "scheduled",
            ScheduledPost.scheduled_at >= now,
            ScheduledPost.scheduled_at <= week_end
        )
    )
    
    # Failed posts
    failed_posts = await db.scalar(
        select(func.count(ScheduledPost.id)).where(
            ScheduledPost.user_id == current_user.id,
            ScheduledPost.status == "failed"
        )
    )
    
    # Total published ever
    total_published = await db.scalar(
        select(func.count(ScheduledPost.id)).where(
            ScheduledPost.user_id == current_user.id,
            ScheduledPost.status == "published"
        )
    )
    
    # Upcoming posts (next 5, sorted by scheduled_at)
    upcoming_result = await db.execute(
        select(ScheduledPost).where(
            ScheduledPost.user_id == current_user.id,
            ScheduledPost.status == "scheduled",
            ScheduledPost.scheduled_at >= now
        ).order_by(ScheduledPost.scheduled_at).limit(5)
    )
    upcoming = upcoming_result.scalars().all()
    
    return {
        "published_today": published_today or 0,
        "scheduled_this_week": scheduled_this_week or 0,
        "failed_posts": failed_posts or 0,
        "total_published": total_published or 0,
        "upcoming_posts": [
            {
                "id": p.id,
                "platform": p.platform,
                "scheduled_at": p.scheduled_at.isoformat(),
                "content_preview": (p.content or "")[:80]
            }
            for p in upcoming
        ],
        "greeting_name": current_user.name.split()[0] if current_user.name else "there"
    }
```

---

## Implementation Process

1. `fb_agent/app/api/v1/user_routes.py` kholo
2. Existing channel-status endpoint dekho (pattern same hai)
3. `get_overview_stats` function add karo uske baad
4. Required imports check karo (`func`, `ScheduledPost`, etc.) — jo already hain use mat dobara import karo
5. Backend run karo: `uvicorn app.main:app --reload`
6. Postman ya browser se test karo: `GET http://localhost:8000/user/overview-stats` (auth token ke saath)
7. Response verify karo — sab fields aa rahi hain

---

## Imports Check

Yeh pehle se hone chahiye (existing imports se check karo):
```python
from sqlalchemy import select, func
from app.db.models import ScheduledPost, User
from app.core.deps import get_current_user, get_db
from sqlalchemy.ext.asyncio import AsyncSession
```

---

**Next Step:** [Step 03 — Overview Frontend](step-03-overview-frontend.md)
