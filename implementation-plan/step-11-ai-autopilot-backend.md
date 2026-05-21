# Step 11 — AI Autopilot: Backend

**Phase:** 3
**Effort:** Very High
**Estimated Time:** 1–2 weeks
**Dependencies:** Phase 1 & 2 complete hone chahiye. Existing scheduler service working hona chahiye.

---

## Goal

AI Autopilot feature — user ek baar configure kare, AI automatically posts generate kare aur schedule kare. Zero manual work.

---

## Database Model

### File: `fb_agent/app/db/models.py`

```python
class AutopilotConfig(Base):
    __tablename__ = "autopilot_configs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, unique=True)
    
    is_active = Column(Boolean, default=False)
    industry = Column(String(200), nullable=True)
    topics = Column(JSON, default=list)           # ["AI trends", "productivity", ...]
    platforms = Column(JSON, default=list)         # ["facebook", "linkedin"]
    tone = Column(String(50), default="professional")
    posting_times = Column(JSON, default=list)     # ["09:00", "17:00"]
    posting_days = Column(JSON, default=list)      # ["monday", "tuesday", ..., "sunday"]
    
    last_generated_at = Column(DateTime(timezone=True), nullable=True)
    next_scheduled_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship("User", back_populates="autopilot_config")
```

**User model mein:**
```python
autopilot_config = relationship("AutopilotConfig", back_populates="user", uselist=False)
```

---

## API Endpoints

### File (NEW): `fb_agent/app/api/v1/autopilot_routes.py`

```python
@router.get("/autopilot")
async def get_autopilot(current_user, db): ...  # config fetch karo

@router.post("/autopilot")
async def create_or_update_autopilot(data, current_user, db): ...  # save config

@router.post("/autopilot/toggle")
async def toggle_autopilot(current_user, db): ...  # is_active flip karo

@router.post("/autopilot/generate-now")
async def generate_now(current_user, db): ...  # manual trigger
```

---

## Scheduler Service

### File: `fb_agent/app/services/autopilot_service.py`

Yeh service periodically (har ghante ya har scheduling cycle mein) run kare aur:

```python
async def run_autopilot_cycle(db: AsyncSession):
    """
    Active autopilot configs fetch karo.
    Next scheduled time check karo — abhi publish karna hai?
    Agar haan: LLM se post generate karo, ScheduledPost banao.
    """
    now = datetime.now(timezone.utc)
    
    # Active configs fetch karo
    result = await db.execute(
        select(AutopilotConfig).where(
            AutopilotConfig.is_active == True,
            AutopilotConfig.next_scheduled_at <= now
        )
    )
    configs = result.scalars().all()
    
    for config in configs:
        # Platform choose (round-robin ya random)
        platform = random.choice(config.platforms)
        
        # Topic choose
        topic = random.choice(config.topics)
        
        # LLM prompt
        prompt = f"""
        Write a {config.tone} social media post for {platform} about: {topic}
        Industry: {config.industry}
        Platform-specific best practices:
        - Max length, hashtags count, emoji usage for {platform}
        Return ONLY the post text, nothing else.
        """
        
        post_content = await call_llm(prompt, config.user)
        
        # Next post time calculate
        next_time = calculate_next_posting_time(config, now)
        
        # ScheduledPost create karo
        new_post = ScheduledPost(
            user_id=config.user_id,
            platform=platform,
            content=post_content,
            scheduled_at=next_time,
            status="scheduled",
            source="autopilot"
        )
        db.add(new_post)
        
        # Config update karo
        config.last_generated_at = now
        config.next_scheduled_at = calculate_next_posting_time(config, next_time)
    
    await db.commit()
```

---

### APScheduler Integration

```python
# In main.py startup
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from app.services.autopilot_service import run_autopilot_cycle

scheduler = AsyncIOScheduler()
scheduler.add_job(run_autopilot_cycle, "interval", minutes=30, args=[db_session])
scheduler.start()
```

---

## Migration

```bash
alembic revision --autogenerate -m "add autopilot_configs table"
alembic upgrade head
```

---

## Implementation Process

1. `models.py` mein `AutopilotConfig` add karo
2. Migration run karo
3. `autopilot_routes.py` create karo (CRUD endpoints)
4. `main.py` mein router register karo
5. `autopilot_service.py` create karo
6. APScheduler job register karo (existing scheduler se integrate karo)
7. Test: config save karo, `generate-now` endpoint trigger karo — ek post ban jaani chahiye
8. DB mein `ScheduledPost` check karo — autopilot ka post wahan hona chahiye

---

**Note:** Yeh complex feature hai. Step by step karo. Pehle CRUD endpoints, phir service logic, phir scheduler.

**Next Step:** [Step 12 — AI Autopilot Frontend](step-12-ai-autopilot-frontend.md)
