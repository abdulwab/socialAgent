# Step 14 — Mobile Responsive Sidebar

**Phase:** 3
**Effort:** Medium
**Estimated Time:** 2–3 hours
**Dependencies:** None (pure frontend)

---

## Goal

Mobile pe sidebar hamburger menu se open/close ho sake. Currently sidebar `hidden md:flex` hai — mobile pe bilkul nahi dikhta.

---

## Current Problem

`Sidebar.tsx` mein: `className="w-64 ... hidden md:flex ..."`

Mobile pe sidebar invisible hai — koi navigation nahi.

---

## Solution: Slide-Out Drawer

Mobile pe ek hamburger button show karo (top bar mein). Click pe sidebar slide in ho sidebar overlay ke saath.

---

## Files to Change

### File 1: `fb_dash/app/components/Sidebar.tsx`

**State add karo:**
```tsx
// Sidebar ko controlled banana hoga — ya global state ya local
// Simple approach: URL change pe auto-close ho
```

**Wrapper update:**
```tsx
// Mobile: full-screen overlay + slide-in panel
// Desktop: always visible (w-64 fixed)

<>
  {/* Mobile Overlay */}
  {mobileOpen && (
    <div
      className="fixed inset-0 bg-black/50 z-40 md:hidden"
      onClick={() => setMobileOpen(false)}
    />
  )}

  {/* Sidebar */}
  <aside className={`
    w-64 bg-card border-r border-border flex flex-col
    fixed md:sticky top-0 h-screen z-50
    transition-transform duration-300
    ${mobileOpen ? "translate-x-0" : "-translate-x-full"}
    md:translate-x-0
  `}>
    {/* Close button (mobile only) */}
    <button
      className="md:hidden absolute right-4 top-4 text-gray-400 hover:text-white"
      onClick={() => setMobileOpen(false)}
    >
      <X className="w-5 h-5" />
    </button>
    
    {/* existing sidebar content... */}
  </aside>
</>
```

**Local state:**
```tsx
const [mobileOpen, setMobileOpen] = useState(false);
```

**Auto-close on navigation:**
```tsx
const pathname = usePathname();
useEffect(() => {
  setMobileOpen(false);
}, [pathname]);
```

---

### File 2: `fb_dash/app/components/MobileTopBar.tsx` (NEW)

Mobile pe ek top bar — hamburger button aur brand name:

```tsx
"use client";
import { Menu, Globe } from "lucide-react";

interface Props {
  onMenuClick: () => void;
}

export default function MobileTopBar({ onMenuClick }: Props) {
  return (
    <div className="md:hidden flex items-center gap-3 px-4 py-3 border-b border-border bg-card sticky top-0 z-30">
      <button onClick={onMenuClick} className="p-2 rounded-lg hover:bg-white/5 text-gray-400">
        <Menu className="w-5 h-5" />
      </button>
      <div className="flex items-center gap-2">
        <Globe className="w-5 h-5 text-primary" />
        <span className="font-bold text-base">SocialHub</span>
      </div>
    </div>
  );
}
```

---

### File 3: `fb_dash/app/layout.tsx`

Problem: Sidebar state aur TopBar alag components hain — state share karna hoga.

**Option A (Simple):** Sidebar aur TopBar ko ek `SidebarWrapper` component mein wrap karo.

```tsx
// fb_dash/app/components/SidebarWrapper.tsx
"use client";
import { useState } from "react";
import Sidebar from "./Sidebar";
import MobileTopBar from "./MobileTopBar";

export default function SidebarWrapper() {
  const [mobileOpen, setMobileOpen] = useState(false);
  return (
    <>
      <MobileTopBar onMenuClick={() => setMobileOpen(true)} />
      <Sidebar mobileOpen={mobileOpen} setMobileOpen={setMobileOpen} />
    </>
  );
}
```

**Layout update:**
```tsx
// layout.tsx mein
<SidebarWrapper />
```

---

## Visual Result

**Mobile (< 768px):**
```
┌────────────────────────┐
│ ☰  SocialHub           │  ← top bar
├────────────────────────┤
│                        │
│    page content        │
│                        │
```

**After hamburger click:**
```
┌──────┬─────────────────┐
│ SB   │ × (close)       │
│──────│                 │
│ MANAGE               │  ← slide-in sidebar
│  Overview            │  + dark overlay behind
│  Post Queue          │
│  ...                 │
```

---

## Implementation Process

1. `Sidebar.tsx` mein `mobileOpen` prop accept karne ke liye update karo
2. Overlay aur slide-in CSS add karo
3. `MobileTopBar.tsx` create karo
4. `SidebarWrapper.tsx` create karo
5. `layout.tsx` update karo
6. Mobile viewport mein test karo (DevTools → 375px width)
7. Navigation pe sidebar auto-close test karo
8. Overlay click pe sidebar close test karo

---

**Next Step:** [Step 15 — Post Preview](step-15-post-preview.md)
