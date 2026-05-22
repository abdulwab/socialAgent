---
name: ui-changelog
description: UI changes made to SocialHub — sidebar naming fixes, Overview page, overview-stats API, Social Channels redesign, channel-status API
metadata:
  type: project
---

# UI Changelog

## Step 01 — Sidebar Naming Fixes (fb_dash/app/components/Sidebar.tsx)

- **"Dashboard"** → **"Overview"** — route changed `/scheduled-posts` → `/overview`, icon `LayoutDashboard`
- **"Scheduled Posts"** → **"Post Queue"** — route stays `/scheduled-posts`, icon changed to `Layers`
- **"Scheduled Posts" (creation form)** → **"New Post"** — route stays `/posts`, icon changed to `PlusSquare`
- Calendar unchanged
- `CalendarClock` import removed, `Layers` + `PlusSquare` added

**posts/page.tsx:**
- `<h1>Posts</h1>` → `<h1>New Post</h1>`
- Subtext updated
- "Go to Dashboard" link → "Go to Home"

**Why:** Old naming was confusing — post creation form was called "Scheduled Posts", stats list was called "Dashboard". Fixed to match actual function.

## Step 02 — Overview Stats Endpoint (fb_agent/app/api/v1/user_routes.py)

- **New endpoint**: `GET /api/v1/user/overview-stats`
- **Returns**: `published_today`, `scheduled_this_week`, `failed_posts`, `total_published`, `upcoming_posts` (next 5), `greeting_name`
- **Datetime**: Uses `datetime.utcnow()` (naive) — DB columns are timezone-naive, NOT `datetime.now(timezone.utc)`
- **Status values used**: `"published"`, `"pending"` (not "scheduled"), `"failed"`
- **Field names**: `scheduled_time` (not `scheduled_at`), `published_at`

## Step 03 — Overview Page Frontend (fb_dash/app/overview/page.tsx)

- **New page**: `/overview` route — stats dashboard replacing old confusing "Dashboard"
- **Stats cards**: Published Today (green), Scheduled This Week (blue), Failed Posts (red + link to queue), Total Published (purple)
- **Upcoming Posts**: Next 5 pending posts with platform icon, time, content preview
- **Quick Actions**: New Post, View Queue, Open Calendar buttons
- **Redux**: `fetchOverviewStats` thunk dispatched on mount (auth-gated)
- **Empty state**: "No upcoming posts" with link to create

**agentSlice.ts additions:**
- Interfaces: `UpcomingPost`, `OverviewStats`
- State: `overviewStats: OverviewStats | null`, `overviewLoading: boolean`
- Thunk: `fetchOverviewStats` — calls `ApiManager.getOverviewStats(token)`
- Reducers: pending/fulfilled/rejected cases

**apiManager.ts additions:**
- `getOverviewStats(token)` → `GET /user/overview-stats`

---

## Previous — Sidebar Branding (fb_dash/app/components/Sidebar.tsx)

- **Brand renamed**: "FB Agent" → "SocialHub", icon `Bot` → `Globe`
- **Nav item renamed**: "Connect Apps" → "Social Channels" (route `/connect-apps` same hai)
- **Grouped navigation**: MANAGE / INSIGHTS / SETTINGS groups
- **Quick button**: "+ New Post" orange button sidebar top mein, `/posts` par redirect karta hai

## Social Channels Page (fb_dash/app/connect-apps/page.tsx)

- **Page title**: "Connect Apps" → "Social Channels" with `Radio` icon
- **Card design**: Platform gradient top border, health badge (Active/Expiring/Expired/Disconnected), posts-last-30d stat row
- **Custom SVGs**: `FacebookIcon`, `InstagramIcon`, `LinkedinIcon` — lucide-react deprecated icons replace kiye
- **Coming Soon section**: TikTok, Pinterest, YouTube — grey disabled cards
- **On disconnect**: `fetchChannelStatus()` auto-refresh karta hai

**Why:** competitors (Buffer, Postoria) ka UI modern aur platform-specific tha. Ours generic tha.
**How to apply:** `/connect-apps` URL change nahi kiya — sirf display label changed. Future mein agar route rename karna ho, sidebar.tsx aur page.tsx dono update karna hoga.

## Channel Status API (fb_agent/app/api/v1/user_routes.py)

- **New endpoint**: `GET /user/channel-status`
- **Returns**: per-platform `{ connected, account_name, health, posts_last_30d }`
- **Health logic**: LinkedIn/X ke `expires_at` se calculate — `active` / `expiring` (≤7 days) / `expired`
- **Facebook health**: PageToken rows exist karte hain toh `active`
- **Posts count**: Last 30 days mein published ScheduledPost count

## Redux (fb_dash/lib/features/agentSlice.ts)

- **New interfaces**: `ChannelInfo`, `ChannelStatus`
- **New state**: `channelStatus: ChannelStatus | null`, `channelStatusLoading: boolean`
- **New thunk**: `fetchChannelStatus` — `GET /user/channel-status` call karta hai

## ApiManager (fb_dash/lib/apiManager.ts)

- **New method**: `getChannelStatus(token)` → `/user/channel-status`
