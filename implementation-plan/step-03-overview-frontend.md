# Step 03 — Overview Page: Frontend UI

**Phase:** 1
**Effort:** Medium
**Estimated Time:** 2–3 hours
**Dependencies:** Step 02 (backend endpoint ready hona chahiye)

---

## Goal

`/overview` route pe ek true dashboard page banana jo real stats show kare.

---

## UI Layout (Desktop)

```
┌─────────────────────────────────────────────────────────┐
│  Good morning, Abdul!        Today: Thursday, 21 May    │
└─────────────────────────────────────────────────────────┘

┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│ Published│  │Scheduled │  │  Failed  │  │  Total   │
│  Today   │  │This Week │  │  Posts   │  │Published │
│    2     │  │    8     │  │    1     │  │   47     │
└──────────┘  └──────────┘  └──────────┘  └──────────┘

┌──────────────────────┐  ┌──────────────────────────────┐
│ Platform Status      │  │ Upcoming Posts               │
│ Facebook   ● Active  │  │ 2:00 PM  — LinkedIn          │
│ Instagram  ● Active  │  │ 5:30 PM  — Facebook          │
│ LinkedIn   ⚠ 5d exp │  │ Tomorrow 9AM — X             │
│ X          ● Active  │  └──────────────────────────────┘
└──────────────────────┘

Quick Actions:
[ + New Post ]  [ View Queue ]  [ Open Calendar ]
```

---

## Files to Create/Change

### File 1 (NEW): `fb_dash/app/overview/page.tsx`

Naya file create karo. Basic structure:

```tsx
"use client";
import { useEffect } from "react";
import { useDispatch, useSelector } from "react-redux";
import { AppDispatch, RootState } from "../../lib/store";
import { fetchOverviewStats } from "../../lib/features/agentSlice";
import Link from "next/link";
import { LayoutDashboard, CheckCircle, Clock, AlertTriangle, TrendingUp, Plus, List, Calendar } from "lucide-react";

export default function OverviewPage() {
  const dispatch = useDispatch<AppDispatch>();
  const { overviewStats, overviewLoading } = useSelector((s: RootState) => s.agent);

  useEffect(() => {
    dispatch(fetchOverviewStats());
  }, [dispatch]);

  const today = new Date().toLocaleDateString("en-US", {
    weekday: "long", year: "numeric", month: "long", day: "numeric"
  });

  return (
    <div className="p-6 space-y-6">
      {/* Greeting */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">
            Good {getGreeting()}, {overviewStats?.greeting_name || "there"}!
          </h1>
          <p className="text-gray-400 text-sm mt-1">{today}</p>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard title="Published Today" value={overviewStats?.published_today ?? "—"} icon={CheckCircle} color="green" />
        <StatCard title="Scheduled This Week" value={overviewStats?.scheduled_this_week ?? "—"} icon={Clock} color="blue" />
        <StatCard title="Failed Posts" value={overviewStats?.failed_posts ?? "—"} icon={AlertTriangle} color="red" link="/scheduled-posts?filter=failed" />
        <StatCard title="Total Published" value={overviewStats?.total_published ?? "—"} icon={TrendingUp} color="purple" />
      </div>

      {/* Upcoming Posts */}
      <div className="bg-card border border-border rounded-xl p-5">
        <h2 className="font-semibold mb-4">Upcoming Posts</h2>
        {overviewStats?.upcoming_posts?.length === 0 ? (
          <p className="text-gray-500 text-sm">No upcoming posts scheduled.</p>
        ) : (
          <ul className="space-y-3">
            {overviewStats?.upcoming_posts?.map(post => (
              <li key={post.id} className="flex items-center gap-3 text-sm">
                <span className="text-gray-400 w-28 shrink-0">
                  {formatUpcomingTime(post.scheduled_at)}
                </span>
                <span className="capitalize text-primary">{post.platform}</span>
                <span className="text-gray-300 truncate">{post.content_preview}</span>
              </li>
            ))}
          </ul>
        )}
      </div>

      {/* Quick Actions */}
      <div className="flex gap-3 flex-wrap">
        <Link href="/posts" className="flex items-center gap-2 px-4 py-2 bg-[#ff6b00] text-white rounded-lg font-medium text-sm">
          <Plus className="w-4 h-4" /> New Post
        </Link>
        <Link href="/scheduled-posts" className="flex items-center gap-2 px-4 py-2 bg-card border border-border rounded-lg font-medium text-sm text-gray-300">
          <List className="w-4 h-4" /> View Queue
        </Link>
        <Link href="/calendar" className="flex items-center gap-2 px-4 py-2 bg-card border border-border rounded-lg font-medium text-sm text-gray-300">
          <Calendar className="w-4 h-4" /> Open Calendar
        </Link>
      </div>
    </div>
  );
}

function getGreeting() {
  const h = new Date().getHours();
  if (h < 12) return "morning";
  if (h < 17) return "afternoon";
  return "evening";
}

function formatUpcomingTime(iso: string) {
  const d = new Date(iso);
  const today = new Date();
  const isToday = d.toDateString() === today.toDateString();
  if (isToday) return d.toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" });
  return d.toLocaleDateString("en-US", { month: "short", day: "numeric" }) + " " +
    d.toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" });
}

function StatCard({ title, value, icon: Icon, color, link }: any) {
  const colors: any = {
    green: "text-green-400",
    blue: "text-blue-400",
    red: "text-red-400",
    purple: "text-purple-400"
  };
  const card = (
    <div className="bg-card border border-border rounded-xl p-5 space-y-2">
      <div className="flex items-center gap-2">
        <Icon className={`w-4 h-4 ${colors[color]}`} />
        <span className="text-xs text-gray-400">{title}</span>
      </div>
      <p className={`text-3xl font-bold ${colors[color]}`}>{value}</p>
    </div>
  );
  return link ? <Link href={link}>{card}</Link> : card;
}
```

---

### File 2: `fb_dash/lib/apiManager.ts`

Naya method add karo:
```ts
async getOverviewStats(token: string) {
  const res = await fetch(`${this.baseUrl}/user/overview-stats`, {
    headers: { Authorization: `Bearer ${token}` }
  });
  return res.json();
}
```

---

### File 3: `fb_dash/lib/features/agentSlice.ts`

**New interface add karo:**
```ts
interface UpcomingPost {
  id: number;
  platform: string;
  scheduled_at: string;
  content_preview: string;
}

interface OverviewStats {
  published_today: number;
  scheduled_this_week: number;
  failed_posts: number;
  total_published: number;
  upcoming_posts: UpcomingPost[];
  greeting_name: string;
}
```

**State mein add karo:**
```ts
overviewStats: OverviewStats | null;
overviewLoading: boolean;
```

**Initial state mein add karo:**
```ts
overviewStats: null,
overviewLoading: false,
```

**New thunk:**
```ts
export const fetchOverviewStats = createAsyncThunk(
  "agent/fetchOverviewStats",
  async (_, { getState }) => {
    const state = getState() as RootState;
    const token = state.agent.appToken;
    return apiManager.getOverviewStats(token!);
  }
);
```

**Reducers mein handle karo:**
```ts
.addCase(fetchOverviewStats.pending, (state) => {
  state.overviewLoading = true;
})
.addCase(fetchOverviewStats.fulfilled, (state, action) => {
  state.overviewLoading = false;
  state.overviewStats = action.payload;
})
.addCase(fetchOverviewStats.rejected, (state) => {
  state.overviewLoading = false;
});
```

---

### File 4: `fb_dash/app/components/Sidebar.tsx`

Step 01 mein jo Overview entry add ki thi, woh confirm karo:
```ts
{ href: "/overview", icon: LayoutDashboard, label: "Overview" }
```

---

## Implementation Process

1. `agentSlice.ts` update karo — interfaces, state, thunk, reducers
2. `apiManager.ts` mein `getOverviewStats()` method add karo
3. `fb_dash/app/overview/` folder banao
4. `fb_dash/app/overview/page.tsx` create karo
5. Frontend run karo: `npm run dev`
6. `/overview` visit karo — stats cards dikhni chahiye
7. Loading state test karo (slow network simulate karo)
8. Failed posts card pe click karo — `/scheduled-posts?filter=failed` par jaana chahiye

---

**Next Step:** [Step 04 — Failed Post Retry](step-04-failed-post-retry.md)
