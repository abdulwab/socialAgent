# Step 05 — Token Expiry Alert Banner

**Phase:** 1 (Quick Win)
**Effort:** Low
**Estimated Time:** 1 hour
**Dependencies:** Channel Status API (already done — `GET /user/channel-status` exist karta hai)

---

## Goal

Jab LinkedIn ya X ka token expire hone wala ho (7 din ya kam), user ko ek warning banner dikhao app ke top pe.

---

## Why It Matters

- LinkedIn tokens 60 din mein expire hote hain
- X tokens bhi expire ho sakte hain
- Bina alert ke user ko pata nahi chalta — posts silently fail hote hain

---

## How It Works

Channel status API mein `health: "expiring"` field already hai (Step 02 memory se). Isko use karna hai.

`health` values:
- `"active"` — sab theek
- `"expiring"` — 7 din ya kam bacha hai
- `"expired"` — token khatam ho gaya
- `"disconnected"` — connected nahi

---

## Files to Change

### File 1: `fb_dash/app/layout.tsx` ya `fb_dash/app/components/TopBar.tsx`

Layout ya main wrapper mein ek `TokenExpiryBanner` component add karo jo globally dikhay.

---

### File 2 (NEW): `fb_dash/app/components/TokenExpiryBanner.tsx`

```tsx
"use client";
import { useSelector, useDispatch } from "react-redux";
import { RootState, AppDispatch } from "../../lib/store";
import { fetchChannelStatus } from "../../lib/features/agentSlice";
import { useEffect } from "react";
import { AlertTriangle, X, ExternalLink } from "lucide-react";
import Link from "next/link";

export default function TokenExpiryBanner() {
  const dispatch = useDispatch<AppDispatch>();
  const { channelStatus, appToken } = useSelector((s: RootState) => s.agent);

  useEffect(() => {
    if (appToken) dispatch(fetchChannelStatus());
  }, [appToken, dispatch]);

  if (!channelStatus) return null;

  const expiringPlatforms = Object.entries(channelStatus)
    .filter(([, info]: any) => info.health === "expiring" || info.health === "expired")
    .map(([platform, info]: any) => ({
      platform,
      health: info.health,
    }));

  if (expiringPlatforms.length === 0) return null;

  return (
    <div className="bg-yellow-500/10 border-b border-yellow-500/30 px-6 py-3 flex items-center justify-between gap-4">
      <div className="flex items-center gap-2 text-yellow-400 text-sm">
        <AlertTriangle className="w-4 h-4 shrink-0" />
        <span>
          {expiringPlatforms.map(p => (
            <span key={p.platform}>
              <strong className="capitalize">{p.platform}</strong>
              {p.health === "expired" ? " token expired" : " token expiring soon"}
              {" "}
            </span>
          ))}
          — reconnect to avoid post failures.
        </span>
      </div>
      <Link
        href="/connect-apps"
        className="shrink-0 flex items-center gap-1 text-yellow-400 hover:text-yellow-300 text-sm font-medium"
      >
        Reconnect <ExternalLink className="w-3 h-3" />
      </Link>
    </div>
  );
}
```

---

### File 3: `fb_dash/app/layout.tsx`

Sidebar ke baad, page content ke upar banner add karo:

```tsx
import TokenExpiryBanner from "./components/TokenExpiryBanner";

// layout mein:
<div className="flex-1 flex flex-col">
  <TokenExpiryBanner />   {/* ← yahan add karo */}
  <main className="flex-1 overflow-y-auto">
    {children}
  </main>
</div>
```

---

## Visual Result

```
┌─────────────────────────────────────────────────────┐
│ ⚠ LinkedIn token expiring soon — reconnect to      │
│   avoid post failures.              [Reconnect →]   │
└─────────────────────────────────────────────────────┘
```

Yellow background banner — app ke top pe, sidebar ke baad.

---

## Implementation Process

1. `TokenExpiryBanner.tsx` component create karo
2. `layout.tsx` mein import aur place karo
3. Test karo — LinkedIn ya X ka token manually expire marka test karo (ya DB mein `expires_at` purana date set karo)
4. Banner dikhna chahiye with reconnect link
5. `/connect-apps` pe redirect karo aur reconnect karo — banner gaayab ho jana chahiye

---

**Next Step:** [Step 06 — Landing Page Redesign](step-06-landing-page-redesign.md)
