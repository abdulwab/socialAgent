# SocialHub — Product Improvement Plan
> Competitor analysis + missing features + unique ideas + UI roadmap
> Date: May 2026

---

## 1. Competitor Analysis Summary

| Feature | Buffer | Postoria | SocialBee | SocialHub (Current) |
|---|---|---|---|---|
| Platforms supported | 11 | 12 | 10 | 4 |
| AI caption generation | ✅ | ✅ | ✅ (1000+ prompts) | ✅ |
| True Dashboard/Overview | ✅ | ✅ | ✅ | ❌ (just a list) |
| Content ideas board | ✅ (Create tab) | ❌ | ❌ | ❌ |
| Unified inbox | ✅ | ❌ | ✅ | ❌ |
| Analytics | ✅ | ✅ | ✅ | ✅ (basic) |
| Team collaboration | ✅ | ❌ | ✅ | ❌ |
| Bulk post upload | ❌ | ✅ | ✅ | ❌ |
| RSS feed → posts | ❌ | ✅ | ✅ | ❌ |
| Hashtag organizer | ❌ | ❌ | ✅ | ❌ |
| Auto-reshare top posts | ❌ | ❌ | ✅ | ❌ |
| Landing page quality | ✅✅ | ✅ | ✅✅ | ⚠️ |
| Post health/preview | ✅ | ❌ | ❌ | ❌ |
| Content categories | ❌ | ❌ | ✅ | ❌ |
| Coming Soon platforms | — | — | — | ✅ (we added) |

---

## 2. Current Site Problems (Existing)

### Navigation / Naming Confusion
- **"Dashboard"** tab (`/scheduled-posts`) — sirf ek list hai, koi stats nahi, koi overview nahi. Real dashboard nahi hai.
- **"Scheduled Posts"** tab (`/posts`) — yeh actually **Post CREATION** form hai. Naam bilkul galat hai.
- **"Calendar"** aur **"Scheduled Posts"** dono se post ho sakti hai — Dashboard ki koi alag value nahi.

### Missing Pages / Features
- Koi true Overview page nahi (stats cards, upcoming posts, quick actions)
- Koi Content Ideas / Drafts section nahi
- Koi Inbox / Comments management nahi
- Media Library page exist karta hai (`/library`) lekin sidebar mein hidden hai
- Landing page modern nahi — stats purani hain, social proof nahi, animations nahi

### Technical Gaps
- Token expiry alerts nahi hain (LinkedIn 60-day, X token)
- Failed post retry button nahi
- Post preview (how it will look on platform) nahi
- Mobile responsive sidebar nahi (hidden on mobile)

---

## 3. Sidebar Rework Plan

### Current (Confusing)
```
Dashboard          → /scheduled-posts  (shows post list)
Calendar           → /calendar
Scheduled Posts    → /posts            (post creation form ← WRONG NAME)
Analytics          → /analytics
Social Channels    → /connect-apps
Prompt Settings    → /prompt-settings
```

### New (Clear + Attractive)
```
MANAGE
  Overview         → /overview         ← NEW true dashboard
  Post Queue       → /scheduled-posts  ← rename from "Dashboard"
  Calendar         → /calendar

CREATE
  New Post         → /posts            ← rename from "Scheduled Posts"
  Ideas Board      → /ideas            ← NEW feature

INSIGHTS
  Analytics        → /analytics
  Media Library    → /library          ← unhide this

SETTINGS
  Social Channels  → /connect-apps
  Prompt Settings  → /prompt-settings
```

---

## 4. "Dashboard" Ki Jaga — New "Overview" Page

**Route:** `/overview`
**Sidebar label:** Overview  
**Icon:** `LayoutDashboard`

### What it shows:

```
┌─────────────────────────────────────────────────────────┐
│  Good morning, Abdul!        Today: Thursday, 21 May    │
│  You have 3 posts scheduled today                       │
└─────────────────────────────────────────────────────────┘

┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│ Published│  │Scheduled │  │  Failed  │  │ Total    │
│  Today   │  │This Week │  │          │  │ Posts    │
│    2     │  │    8     │  │    1     │  │   47     │
│ ↑ +1 vs  │  │          │  │ Fix →   │  │          │
│ yesterday│  │          │  │          │  │          │
└──────────┘  └──────────┘  └──────────┘  └──────────┘

┌──────────────────────┐  ┌──────────────────────┐
│ Platform Status      │  │ Upcoming Posts        │
│ 🔵 Facebook  ● Active│  │ 2:00 PM — LinkedIn   │
│ 🎀 Instagram ● Active│  │ 5:30 PM — Facebook   │
│ 🔷 LinkedIn  ⚠ 5d   │  │ Tomorrow 9AM — X     │
│ ✖ X         ● Active│  │                      │
└──────────────────────┘  └──────────────────────┘

Quick Actions:
[ + New Post ]  [ View Queue ]  [ Open Calendar ]
```

**Backend needed:** New endpoint `/user/overview-stats` returning:
- Published today count
- Scheduled this week count
- Failed posts count
- Total posts ever published

---

## 5. Rename "Scheduled Posts" → "Post Queue"

**File:** `fb_dash/app/components/Sidebar.tsx`
- Label change: "Scheduled Posts" → **"Post Queue"**
- Icon: `CalendarClock` → `List` ya `Layers`

**File:** `fb_dash/app/scheduled-posts/page.tsx`
- Page `<h1>` update karo

**Why attractive:** "Post Queue" sounds like a professional publishing pipeline — like a newsroom queue. Competitors don't use this term.

---

## 6. Rename `/posts` (Post Creation) → "New Post"

**File:** `fb_dash/app/components/Sidebar.tsx`
- Label: "Scheduled Posts" → **"New Post"**

**File:** `fb_dash/app/posts/page.tsx`
- Page heading update

This fixes the naming confusion where a CREATION form was called "Scheduled Posts".

---

## 7. New Feature: "Ideas Board" (Unique — Competitors Don't Have This Well)

**Route:** `/ideas`
**Sidebar label:** Ideas Board
**Icon:** `Lightbulb`

### Concept:
Kanban-style board jahan user ideas capture kar sakta hai. Posts directly schedule nahi hote — pehle "Ideas" mein aate hain, phir "Draft" mein, phir "Queue" mein.

```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  IDEAS      │  │   DRAFTS    │  │   QUEUE     │
│─────────────│  │─────────────│  │─────────────│
│ AI trends   │→ │ LinkedIn    │→ │ Facebook    │
│ for 2025    │  │ post about  │  │ AI post     │
│             │  │ AI trends   │  │ ✓ Scheduled │
│ + Add idea  │  │             │  │ May 22 2pm  │
└─────────────┘  └─────────────┘  └─────────────┘
```

**Backend needed:** New `ideas` table — `id, user_id, title, content, status (idea/draft/queued), platform, created_at`

**Why unique:** Buffer has "Create" but it's just a saved posts list. SocialBee has categories. None have a full Kanban-style idea-to-publish pipeline. **This is our differentiator.**

---

## 8. Unique Feature #2: "AI Autopilot" (No Competitor Does This)

**Concept:** User sets:
- Industry/niche: e.g., "Digital Marketing Agency"
- Topics list: e.g., ["AI trends", "productivity tips", "client stories"]
- Platforms: Facebook, LinkedIn
- Frequency: Daily 9AM + 5PM
- Tone: Professional

AI automatically generates posts, schedules them, and publishes — **zero manual work**.

**Route:** `/autopilot`
**Sidebar label:** AI Autopilot (with lightning bolt badge — "BETA")

```
┌─────────────────────────────────────────┐
│ ⚡ AI Autopilot                  ● ON  │
│─────────────────────────────────────────│
│ Industry: Digital Marketing             │
│ Topics: AI trends, Productivity, ...   │
│ Posting: Daily at 9AM + 5PM             │
│ Platforms: LinkedIn, Facebook           │
│ Tone: Professional                      │
│                                         │
│ Next post: Tomorrow 9AM (generating...) │
│ Last published: Today 5PM ✅            │
│                                         │
│ [ Configure ] [ Pause Autopilot ]       │
└─────────────────────────────────────────┘
```

**Backend needed:** APScheduler extension — job reads autopilot config per user, generates content via LLM, schedules post automatically.

---

## 9. Unique Feature #3: "Post Health Score" (Pre-publish AI Check)

Before publishing/scheduling a post, AI scores it:

```
┌──────────────────────────────────────┐
│ Post Health Score: 7.8/10  ✅ Good   │
│──────────────────────────────────────│
│ ✅ Good length for LinkedIn          │
│ ✅ Contains a call-to-action         │
│ ⚠️  No hashtags (LinkedIn needs 3-5) │
│ ⚠️  Best time: 9AM, not 3PM          │
│ ❌ Too formal for Facebook audience  │
│                                      │
│ [ Improve with AI ] [ Post Anyway ]  │
└──────────────────────────────────────┘
```

**Frontend only initially** — prompt-based scoring using existing LLM integration.

---

## 10. Landing Page Redesign Plan

### Current Problems:
- Stats section: "6 Platforms ready", "AI Caption support", "24/7 Workflow access" — boring, generic
- No social proof (no user count, no posts published counter)
- No animated hero visual
- Features section text is too generic ("Post everywhere", "Schedule smarter")
- No pricing section
- No "How it works" section (3-step visual)
- CTA buttons not prominent enough

### New Landing Page Structure:

```
[HERO]
  Headline: "Your social media, on autopilot."
  Sub: "AI-powered publishing for Facebook, Instagram, LinkedIn & X.
        Schedule once, grow everywhere."
  CTAs: [ Get Started Free ]  [ Watch Demo ]
  Hero visual: animated post cards flying to platform icons

[SOCIAL PROOF BAR]
  "10,000+ posts published · 4 platforms · AI-powered"
  Platform logos row

[HOW IT WORKS — 3 steps]
  1. Connect your accounts (30 seconds)
  2. Create or let AI generate your posts
  3. Schedule → Publish → Grow

[FEATURES GRID — 6 cards]
  ⚡ AI Autopilot    | 📅 Post Queue      | 💡 Ideas Board
  📊 Analytics       | 🌐 Multi-Platform  | 🔒 Secure OAuth

[COMPARISON TABLE]
  SocialHub vs Buffer vs Postoria vs SocialBee

[CTA BOTTOM]
  "Start free — no credit card needed"
```

### Design Changes:
- Hero background: animated gradient (dark blue → deep purple → dark)
- Glassmorphism cards for features
- Floating post cards animation in hero
- Counter animations for stats
- Modern Inter/Geist font (already using)
- Orange CTA buttons (brand color #ff6b00)

---

## 11. Missing Features (Full List)

### High Priority (3-4 weeks)
| Feature | Description | Effort |
|---|---|---|
| Overview Page | True stats dashboard replacing current "Dashboard" | Medium |
| Post Queue Rename | Naming fix for scheduled posts list | Low |
| Ideas Board | Kanban pipeline idea→draft→queue | High |
| Failed Post Retry | One-click retry for failed posts | Low |
| Token Expiry Alert | Banner when LinkedIn/X token expiring | Low |
| Landing Page Redesign | Modern hero, how-it-works, social proof | Medium |

### Medium Priority (1-2 months)
| Feature | Description | Effort |
|---|---|---|
| AI Autopilot | Auto-generate + auto-schedule posts | High |
| Post Health Score | AI pre-publish scoring | Medium |
| Bulk Post Upload | CSV upload for multiple posts at once | Medium |
| Media Library full | Upload, tag, and reuse images | Medium |
| Mobile Sidebar | Hamburger menu for mobile | Medium |
| Post Preview | See post as it looks on each platform | High |

### Lower Priority (3+ months)
| Feature | Description | Effort |
|---|---|---|
| Unified Inbox | Comments + DMs from all platforms | Very High |
| Team Collaboration | Roles, approval workflow, invite members | Very High |
| RSS Feed → Posts | Auto-convert RSS articles to posts | Medium |
| Auto-Reshare | Re-publish top posts automatically | Medium |
| More Platforms | TikTok, Pinterest, YouTube | Very High |
| Hashtag Engine | Smart hashtag suggestions by niche | Medium |

---

## 12. Implementation Order (Recommended)

```
Phase 1 — Quick Wins (1 week)
  ✅ Social Channels redesign          DONE
  □ Overview page (stats dashboard)
  □ Sidebar naming fixes (Post Queue, New Post)
  □ Landing page redesign
  □ Failed post retry button
  □ Token expiry banner

Phase 2 — New Features (2-3 weeks)
  □ Ideas Board (Kanban)
  □ Post Health Score
  □ Media Library in sidebar

Phase 3 — Big Differentiators (1-2 months)
  □ AI Autopilot
  □ Bulk Post Upload
  □ Mobile responsive sidebar
  □ Post preview (platform mockup)

Phase 4 — Enterprise (3+ months)
  □ Team Collaboration
  □ Unified Inbox
  □ More Platforms (TikTok, Pinterest)
```

---

## 13. Files Affected Per Phase

### Phase 1
| File | Change |
|---|---|
| `fb_dash/app/overview/page.tsx` | NEW — Overview dashboard |
| `fb_dash/app/components/Sidebar.tsx` | Group rename, new Overview link |
| `fb_dash/app/page.tsx` | Landing page redesign |
| `fb_agent/app/api/v1/user_routes.py` | `/user/overview-stats` endpoint |
| `fb_dash/lib/apiManager.ts` | `getOverviewStats()` method |
| `fb_dash/lib/features/agentSlice.ts` | `fetchOverviewStats` thunk |

### Phase 2
| File | Change |
|---|---|
| `fb_agent/app/db/models.py` | `Idea` model add |
| `fb_agent/app/api/v1/` | `idea_routes.py` NEW |
| `fb_dash/app/ideas/page.tsx` | NEW — Kanban board |
| `fb_dash/lib/apiManager.ts` | Ideas CRUD methods |

### Phase 3
| File | Change |
|---|---|
| `fb_agent/app/db/models.py` | `AutopilotConfig` model |
| `fb_agent/app/services/scheduler_service.py` | Autopilot job |
| `fb_dash/app/autopilot/page.tsx` | NEW — Autopilot config UI |

---

*Plan created by Claude Code — SocialHub Product Roadmap*
*Last updated: 2026-05-21*
