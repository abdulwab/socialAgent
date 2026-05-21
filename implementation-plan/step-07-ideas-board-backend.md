# Step 07 — Ideas Board: Backend

**Phase:** 2
**Effort:** Medium
**Estimated Time:** 2–3 hours
**Dependencies:** Phase 1 steps complete hone chahiye

---

## Goal

Ideas Board ke liye backend infrastructure banana:
- Database model (`Idea` table)
- CRUD API endpoints
- Status flow: `idea` → `draft` → `queued`

---

## Database Model

### File: `fb_agent/app/db/models.py`

Naya model add karo existing models ke saath:

```python
class Idea(Base):
    __tablename__ = "ideas"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String(200), nullable=False)
    content = Column(Text, nullable=True)
    status = Column(String(20), default="idea")  # idea | draft | queued
    platform = Column(String(50), nullable=True)  # facebook | instagram | linkedin | x | None
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship("User", back_populates="ideas")
```

**User model mein add karo:**
```python
ideas = relationship("Idea", back_populates="user", cascade="all, delete-orphan")
```

---

## Database Migration

```bash
cd fb_agent
alembic revision --autogenerate -m "add ideas table"
alembic upgrade head
```

---

## API Endpoints

### File (NEW): `fb_agent/app/api/v1/idea_routes.py`

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel
from typing import Optional
from app.db.models import Idea, User
from app.core.deps import get_current_user, get_db

router = APIRouter(prefix="/ideas", tags=["ideas"])

class IdeaCreate(BaseModel):
    title: str
    content: Optional[str] = None
    platform: Optional[str] = None
    status: str = "idea"

class IdeaUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    platform: Optional[str] = None
    status: Optional[str] = None

# GET all ideas for user
@router.get("/")
async def get_ideas(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Idea).where(Idea.user_id == current_user.id).order_by(Idea.created_at.desc())
    )
    ideas = result.scalars().all()
    return [
        {
            "id": i.id,
            "title": i.title,
            "content": i.content,
            "status": i.status,
            "platform": i.platform,
            "created_at": i.created_at.isoformat() if i.created_at else None,
        }
        for i in ideas
    ]

# POST create idea
@router.post("/")
async def create_idea(
    data: IdeaCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    idea = Idea(user_id=current_user.id, **data.dict())
    db.add(idea)
    await db.commit()
    await db.refresh(idea)
    return {"id": idea.id, "status": idea.status}

# PATCH update idea (status, content, etc.)
@router.patch("/{idea_id}")
async def update_idea(
    idea_id: int,
    data: IdeaUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    idea = await db.get(Idea, idea_id)
    if not idea or idea.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Idea not found")
    
    for field, value in data.dict(exclude_unset=True).items():
        setattr(idea, field, value)
    
    await db.commit()
    return {"success": True}

# DELETE idea
@router.delete("/{idea_id}")
async def delete_idea(
    idea_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    idea = await db.get(Idea, idea_id)
    if not idea or idea.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Idea not found")
    
    await db.delete(idea)
    await db.commit()
    return {"success": True}
```

---

### File: `fb_agent/app/main.py` (ya router registration file)

```python
from app.api.v1 import idea_routes
app.include_router(idea_routes.router, prefix="/api/v1")
```

---

## API Endpoints Summary

| Method | URL | Description |
|--------|-----|-------------|
| GET | `/api/v1/ideas/` | Saari ideas fetch karo |
| POST | `/api/v1/ideas/` | Nai idea create karo |
| PATCH | `/api/v1/ideas/{id}` | Update (status move karna) |
| DELETE | `/api/v1/ideas/{id}` | Delete |

---

## Implementation Process

1. `models.py` mein `Idea` class add karo, `User` mein relationship add karo
2. Alembic migration run karo
3. `idea_routes.py` file create karo
4. `main.py` mein router register karo
5. Backend restart karo
6. Postman se test karo:
   - `POST /api/v1/ideas/` — nai idea banao
   - `GET /api/v1/ideas/` — list dekho
   - `PATCH /api/v1/ideas/1` body `{"status": "draft"}` — status change karo
   - `DELETE /api/v1/ideas/1` — delete karo

---

**Next Step:** [Step 08 — Ideas Board Frontend](step-08-ideas-board-frontend.md)
