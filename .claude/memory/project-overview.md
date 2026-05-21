---
name: project-overview
description: SocialHub kya hai — product goals, production URLs, aur current feature status
metadata:
  type: project
---

# SocialHub — Project Overview

**SocialHub** ek AI-powered social media management platform hai.

## Core Purpose

Users apne social media accounts (Facebook, Instagram, LinkedIn, X/Twitter) ko ek jagah se manage kar sakte hain:
- AI se post content generate karna
- Posts schedule karna (timezone-aware, recurring support ke saath)
- Analytics dekhna (daily metrics sync)
- Multiple team members ke liye multi-user support

## Production URLs

- **Frontend**: https://fb.nexlabai.com
- **Backend API**: https://web-production-a02ea.up.railway.app/api/v1

## Current Feature Status

| Feature | Status |
|---|---|
| Facebook OAuth + Posting | Live |
| Instagram OAuth + Posting | Live |
| LinkedIn OAuth + Posting | Live |
| X/Twitter OAuth + Posting | Live |
| AI Content Generation | Live (multi-provider) |
| Post Scheduling | Live (5-min checks) |
| Analytics Dashboard | Live (daily sync) |
| Media Library | In progress |
| TikTok Support | Planned |
| Pinterest Support | Planned |

## Business Model Notes

- Per-user API keys — har user apna Gemini/Claude/OpenRouter key use kar sakta hai
- Multi-tenant: ek account mein multiple social pages connect ho sakti hain
- Team management: users page se team members manage hoti hain

**Why:** Yeh context important hai taaki Claude samjhe ki yeh ek production platform hai — changes carefully karni chahiye.
**How to apply:** Har feature request mein production impact sochna — OAuth redirect URIs, CORS, scheduler behavior toot sakti hai.
