# Step 06 — Landing Page Redesign

**Phase:** 1
**Effort:** Medium
**Estimated Time:** 3–5 hours
**Dependencies:** None (pure frontend)

---

## Goal

`/` (home page) ko modern, attractive landing page banana jo:
- Visitors ko convert kare
- Social proof dikhaaye
- Features clearly explain kare
- Competitors se better lage

---

## File to Change

**Main File:** `fb_dash/app/page.tsx`

---

## New Page Structure (Sections in Order)

### Section 1: HERO

```
Background: animated dark gradient (dark blue → deep purple → near-black)

Headline:    "Your social media, on autopilot."
Sub:         "AI-powered publishing for Facebook, Instagram, LinkedIn & X.
              Schedule once, grow everywhere."

CTAs:        [ Get Started Free ]   [ Watch Demo ]  (orange primary button)

Visual:      Animated floating post cards flying toward platform icons
             (CSS animation ya Framer Motion)
```

**Code approach:**
- `bg-gradient-to-br from-[#0a0e1a] via-[#0d0a2e] to-[#0a0e1a]`
- Animated gradient via CSS `@keyframes`
- Floating cards: `absolute` positioned divs with `animate-bounce` ya custom keyframes

---

### Section 2: SOCIAL PROOF BAR

```
"10,000+ posts published  ·  4 platforms  ·  AI-powered scheduling"
[Facebook icon] [Instagram icon] [LinkedIn icon] [X icon]
```

Subtle divider, platform logos row mein.

---

### Section 3: HOW IT WORKS (3 Steps)

```
Step 1 — Connect (30 seconds)
  Icon: Plug/Link icon
  Desc: "Connect your Facebook, Instagram, LinkedIn, and X accounts securely."

Step 2 — Create or Generate
  Icon: Sparkles (AI)
  Desc: "Write your posts or let AI generate platform-optimized captions for you."

Step 3 — Schedule → Grow
  Icon: TrendingUp
  Desc: "Set it and forget it. Posts go live automatically at your chosen time."
```

3-column grid, numbered steps with connecting line.

---

### Section 4: FEATURES GRID (6 Cards)

```
⚡ AI Autopilot        | 📅 Post Queue        | 💡 Ideas Board
"Auto-generate posts   | "Visual queue of     | "Capture ideas, turn
and schedule them       all your upcoming      them into scheduled
automatically"          posts"                 posts"

📊 Analytics          | 🌐 Multi-Platform    | 🔒 Secure OAuth
"See what's working   | "Publish to 4        | "Your accounts
across all platforms"   platforms from        stay safe with
                        one dashboard"        OAuth 2.0"
```

Glassmorphism cards: `bg-white/5 backdrop-blur border border-white/10 rounded-2xl`

---

### Section 5: COMPARISON TABLE

| Feature | SocialHub | Buffer | Postoria | SocialBee |
|---|---|---|---|---|
| AI Autopilot | ✅ | ❌ | ❌ | ❌ |
| Ideas Board | ✅ | ❌ | ❌ | ❌ |
| Post Health Score | ✅ | ❌ | ❌ | ❌ |
| AI Captions | ✅ | ✅ | ✅ | ✅ |
| Post Queue | ✅ | ✅ | ✅ | ✅ |
| Price | Free | $6/mo | $25/mo | $29/mo |

SocialHub column highlight karo (orange border).

---

### Section 6: BOTTOM CTA

```
Large centered block:
  "Start free today — no credit card needed"
  [ Get Started Free ]
  
  "Join thousands of creators and businesses"
```

---

## Design System

| Element | Value |
|---|---|
| Primary color | `#ff6b00` (orange) |
| Background | `#0a0e1a` (near black) |
| Card bg | `rgba(255,255,255,0.05)` |
| Card border | `rgba(255,255,255,0.1)` |
| Font | Inter (already using) |
| Hero gradient | `from-[#0a0e1a] via-[#0d0a2e] to-[#0a0e1a]` |

---

## Animations

```css
/* Floating cards animation */
@keyframes float {
  0%, 100% { transform: translateY(0px); }
  50% { transform: translateY(-12px); }
}

/* Counter animation — use JS IntersectionObserver */
/* When section enters viewport, count from 0 to target */

/* Gradient shift */
@keyframes gradientShift {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}
```

---

## Stats to Update

Current landing mein generic stats hain. Replace karo:
```
OLD: "6 Platforms ready"
NEW: "4 Platforms Connected"

OLD: "AI Caption support"  
NEW: "10,000+ Posts Published"

OLD: "24/7 Workflow access"
NEW: "AI-Powered Autopilot"
```

---

## Implementation Process

1. Current `fb_dash/app/page.tsx` dhyan se padho (existing structure samjho)
2. Section by section replace karo (sab ek saath mat karo)
3. Pehle HERO section likho aur check karo
4. Phir HOW IT WORKS
5. Phir FEATURES GRID
6. Phir COMPARISON TABLE
7. Phir BOTTOM CTA
8. Animations add karo at the end
9. Mobile responsive check karo (320px, 768px, 1280px)
10. `npm run build` karo — koi type error nahi hone chahiye

---

**Next Step:** [Step 07 — Ideas Board Backend](step-07-ideas-board-backend.md)
