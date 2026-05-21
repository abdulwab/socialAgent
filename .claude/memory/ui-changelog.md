---
name: ui-changelog
description: UI changes made to SocialHub — sidebar branding, Social Channels page redesign, channel-status API, Coming Soon section
metadata:
  type: project
---

# UI Changelog

## Sidebar (fb_dash/app/components/Sidebar.tsx)

- **Brand renamed**: "FB Agent" → "SocialHub", icon `Bot` → `Globe`
- **Nav item renamed**: "Connect Apps" → "Social Channels" (route `/connect-apps` same hai)
- **Grouped navigation**: MANAGE (Dashboard, Calendar, Scheduled Posts) / INSIGHTS (Analytics) / SETTINGS (Social Channels, Prompt Settings, Privacy Policy)
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
