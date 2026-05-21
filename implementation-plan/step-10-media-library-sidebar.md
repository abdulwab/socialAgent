# Step 10 — Media Library in Sidebar

**Phase:** 2
**Effort:** Low
**Estimated Time:** 30 minutes
**Dependencies:** `/library` page already exist karta hai

---

## Goal

Media Library page (`/library`) already exist karta hai lekin sidebar mein hidden hai. Isko sidebar mein add karna hai.

---

## Problem

`/library` route exist karta hai lekin user ko pata nahi — sidebar mein nahi dikhta. Easy fix.

---

## File to Change

### `fb_dash/app/components/Sidebar.tsx`

INSIGHTS group mein Media Library link add karo:

**Current:**
```ts
{
  label: "INSIGHTS",
  items: [
    { href: "/analytics", icon: BarChart3, label: "Analytics" },
  ],
},
```

**Updated:**
```ts
{
  label: "INSIGHTS",
  items: [
    { href: "/analytics",  icon: BarChart3,  label: "Analytics" },
    { href: "/library",    icon: ImageIcon,  label: "Media Library" },
  ],
},
```

**Icon import add karo:**
```ts
import { Image as ImageIcon } from "lucide-react";
```

(Note: `Image` directly import mat karo — Next.js ka `Image` component se conflict ho sakta hai. `ImageIcon` alias use karo.)

---

## Optional: Library Page Improvement

Agar `/library` page basic hai, ek simple improvement:
- Page title "Media Library" ho
- Upload button dikhe
- Uploaded images grid mein dikhen

Yeh Step 10 ka optional part hai — sidebar fix required hai, page redesign optional.

---

## Implementation Process

1. `Sidebar.tsx` kholo
2. Lucide import mein `Image as ImageIcon` add karo
3. INSIGHTS group mein Media Library item add karo
4. Save karo
5. Browser mein sidebar check karo — Media Library link dikha chahiye
6. Click karo — `/library` page khulna chahiye

---

**Done! Phase 2 complete.**

**Next Step:** [Step 11 — AI Autopilot Backend](step-11-ai-autopilot-backend.md)
