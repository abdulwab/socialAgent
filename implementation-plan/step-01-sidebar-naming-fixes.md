# Step 01 — Sidebar Naming Fixes

**Phase:** 1 (Quick Win)
**Effort:** Low
**Estimated Time:** 30 minutes
**Dependencies:** None — yeh pehla step hai, koi cheez pehle karne ki zaroorat nahi

---

## Problem

Current sidebar mein naming confusing hai:
- **"Dashboard"** (`/scheduled-posts`) — sirf ek post list hai, koi stats nahi. Naam misleading hai.
- **"Scheduled Posts"** (`/posts`) — yeh actually POST CREATION form hai. Bilkul galat naam.

---

## Changes Required

### File 1: `fb_dash/app/components/Sidebar.tsx`

**Groups array update karna hai:**

```
MANAGE group mein:
  OLD: { href: "/scheduled-posts", label: "Dashboard",        icon: LayoutDashboard }
  NEW: { href: "/overview",        label: "Overview",         icon: LayoutDashboard }   ← route change + label change

  OLD: { href: "/posts",           label: "Scheduled Posts",  icon: CalendarClock }
  NEW: { href: "/posts",           label: "New Post",         icon: PlusSquare }         ← sirf label + icon change

  ADD: { href: "/scheduled-posts", label: "Post Queue",       icon: Layers }             ← yeh naya item hai
```

**Final MANAGE group:**
```
MANAGE
  Overview      → /overview          (new — Step 03 mein page banega)
  Post Queue    → /scheduled-posts   (renamed from "Dashboard")
  Calendar      → /calendar          (no change)
  New Post      → /posts             (renamed from "Scheduled Posts")
```

**Icon imports add karo (agar nahi hain):**
```ts
import { Layers, PlusSquare } from "lucide-react";
```

---

### File 2: `fb_dash/app/scheduled-posts/page.tsx`

Page heading update:
```
OLD: <h1>Dashboard</h1>  (ya jo bhi current heading hai)
NEW: <h1>Post Queue</h1>
```

---

### File 3: `fb_dash/app/posts/page.tsx`

Page heading update:
```
OLD: <h1>Scheduled Posts</h1>  (ya jo bhi current heading hai)
NEW: <h1>New Post</h1>
```

---

## Implementation Process

1. `Sidebar.tsx` kholo
2. `groups` array mein MANAGE section update karo (3 changes: rename Dashboard→PostQueue, rename ScheduledPosts→NewPost, add Overview entry)
3. Lucide icon imports adjust karo
4. `scheduled-posts/page.tsx` mein `<h1>` ya `<title>` update karo
5. `posts/page.tsx` mein `<h1>` ya `<title>` update karo
6. Browser mein check karo — sidebar correct labels dikha raha ho

---

## Note

`/overview` route Step 03 mein banega. Tab tak Overview link kaam nahi karega, lekin sidebar mein dikh sakta hai. Ya phir Overview entry Step 03 ke baad add karo.

---

**Next Step:** [Step 02 — Overview Backend](step-02-overview-backend.md)
