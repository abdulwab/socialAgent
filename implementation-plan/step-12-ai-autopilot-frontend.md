# Step 12 — AI Autopilot: Frontend

**Phase:** 3
**Effort:** High
**Estimated Time:** 3–4 hours
**Dependencies:** Step 11 (backend) complete hona chahiye

---

## Goal

`/autopilot` route pe ek configuration page banana jahan user:
- Autopilot on/off toggle kar sake
- Industry, topics, platforms, tone, timing set kar sake
- Status dekh sake (last published, next scheduled)

---

## UI Design

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

---

## Files to Create/Change

### File 1 (NEW): `fb_dash/app/autopilot/page.tsx`

```tsx
"use client";
import { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { AppDispatch, RootState } from "../../lib/store";
import { fetchAutopilotConfig, saveAutopilotConfig, toggleAutopilot } from "../../lib/features/agentSlice";
import { Zap, Settings, Pause, Play } from "lucide-react";

const TONES = ["Professional", "Casual", "Humorous", "Inspirational", "Educational"];
const PLATFORMS = ["Facebook", "Instagram", "LinkedIn", "X"];
const TIMES = ["06:00", "09:00", "12:00", "15:00", "17:00", "20:00"];

export default function AutopilotPage() {
  const dispatch = useDispatch<AppDispatch>();
  const { autopilotConfig, autopilotLoading } = useSelector((s: RootState) => s.agent);

  const [editMode, setEditMode] = useState(false);
  const [form, setForm] = useState({
    industry: "",
    topics: [] as string[],
    platforms: [] as string[],
    tone: "Professional",
    posting_times: [] as string[],
  });
  const [topicInput, setTopicInput] = useState("");

  useEffect(() => {
    dispatch(fetchAutopilotConfig());
  }, [dispatch]);

  useEffect(() => {
    if (autopilotConfig) {
      setForm({
        industry: autopilotConfig.industry || "",
        topics: autopilotConfig.topics || [],
        platforms: autopilotConfig.platforms || [],
        tone: autopilotConfig.tone || "Professional",
        posting_times: autopilotConfig.posting_times || [],
      });
    }
  }, [autopilotConfig]);

  const handleSave = async () => {
    await dispatch(saveAutopilotConfig(form));
    setEditMode(false);
  };

  const addTopic = () => {
    if (topicInput.trim() && !form.topics.includes(topicInput.trim())) {
      setForm(f => ({ ...f, topics: [...f.topics, topicInput.trim()] }));
      setTopicInput("");
    }
  };

  const removeTopic = (t: string) => setForm(f => ({ ...f, topics: f.topics.filter(x => x !== t) }));

  const togglePlatform = (p: string) => {
    const lower = p.toLowerCase();
    setForm(f => ({
      ...f,
      platforms: f.platforms.includes(lower)
        ? f.platforms.filter(x => x !== lower)
        : [...f.platforms, lower]
    }));
  };

  const toggleTime = (t: string) => {
    setForm(f => ({
      ...f,
      posting_times: f.posting_times.includes(t)
        ? f.posting_times.filter(x => x !== t)
        : [...f.posting_times, t]
    }));
  };

  return (
    <div className="p-6 max-w-2xl space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="bg-yellow-500/10 p-2 rounded-xl">
            <Zap className="w-6 h-6 text-yellow-400" />
          </div>
          <div>
            <h1 className="text-2xl font-bold flex items-center gap-2">
              AI Autopilot
              <span className="text-xs bg-yellow-500/20 text-yellow-400 px-2 py-0.5 rounded-full font-normal">BETA</span>
            </h1>
            <p className="text-gray-400 text-sm">Auto-generate and schedule posts</p>
          </div>
        </div>
        
        {/* Toggle */}
        <button
          onClick={() => dispatch(toggleAutopilot())}
          className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium text-sm ${
            autopilotConfig?.is_active
              ? "bg-green-500/20 text-green-400 hover:bg-red-500/20 hover:text-red-400"
              : "bg-gray-500/20 text-gray-400 hover:bg-green-500/20 hover:text-green-400"
          }`}
        >
          {autopilotConfig?.is_active ? <><Pause className="w-4 h-4" /> ON</> : <><Play className="w-4 h-4" /> OFF</>}
        </button>
      </div>

      {/* Status Card */}
      {autopilotConfig && (
        <div className="bg-card border border-border rounded-xl p-5 space-y-2 text-sm">
          <div className="flex justify-between text-gray-400">
            <span>Last published</span>
            <span>{autopilotConfig.last_generated_at ? new Date(autopilotConfig.last_generated_at).toLocaleString() : "Never"}</span>
          </div>
          <div className="flex justify-between text-gray-400">
            <span>Next scheduled</span>
            <span>{autopilotConfig.next_scheduled_at ? new Date(autopilotConfig.next_scheduled_at).toLocaleString() : "Not set"}</span>
          </div>
        </div>
      )}

      {/* Config Form */}
      <div className="bg-card border border-border rounded-xl p-5 space-y-5">
        <div className="flex items-center justify-between">
          <h2 className="font-semibold">Configuration</h2>
          {!editMode && (
            <button onClick={() => setEditMode(true)} className="flex items-center gap-1 text-sm text-primary">
              <Settings className="w-4 h-4" /> Edit
            </button>
          )}
        </div>

        {/* Industry */}
        <div>
          <label className="text-xs text-gray-400 mb-1 block">Industry / Niche</label>
          <input
            disabled={!editMode}
            value={form.industry}
            onChange={e => setForm(f => ({ ...f, industry: e.target.value }))}
            placeholder="e.g. Digital Marketing Agency"
            className="w-full bg-background border border-border rounded-lg px-3 py-2 text-sm disabled:opacity-50"
          />
        </div>

        {/* Topics */}
        <div>
          <label className="text-xs text-gray-400 mb-1 block">Topics</label>
          <div className="flex flex-wrap gap-2 mb-2">
            {form.topics.map(t => (
              <span key={t} className="flex items-center gap-1 bg-primary/10 text-primary text-xs px-2 py-1 rounded-full">
                {t}
                {editMode && <button onClick={() => removeTopic(t)} className="text-primary/60 hover:text-red-400 ml-1">×</button>}
              </span>
            ))}
          </div>
          {editMode && (
            <div className="flex gap-2">
              <input
                value={topicInput}
                onChange={e => setTopicInput(e.target.value)}
                onKeyDown={e => e.key === "Enter" && addTopic()}
                placeholder="Add topic..."
                className="flex-1 bg-background border border-border rounded-lg px-3 py-1.5 text-sm"
              />
              <button onClick={addTopic} className="text-sm text-primary">Add</button>
            </div>
          )}
        </div>

        {/* Platforms */}
        <div>
          <label className="text-xs text-gray-400 mb-2 block">Platforms</label>
          <div className="flex flex-wrap gap-2">
            {PLATFORMS.map(p => (
              <button
                key={p}
                disabled={!editMode}
                onClick={() => togglePlatform(p)}
                className={`px-3 py-1.5 rounded-lg text-sm font-medium border transition-colors ${
                  form.platforms.includes(p.toLowerCase())
                    ? "border-primary bg-primary/10 text-primary"
                    : "border-border text-gray-400"
                } disabled:cursor-default`}
              >
                {p}
              </button>
            ))}
          </div>
        </div>

        {/* Tone */}
        <div>
          <label className="text-xs text-gray-400 mb-2 block">Tone</label>
          <div className="flex flex-wrap gap-2">
            {TONES.map(t => (
              <button
                key={t}
                disabled={!editMode}
                onClick={() => setForm(f => ({ ...f, tone: t }))}
                className={`px-3 py-1.5 rounded-lg text-sm border transition-colors ${
                  form.tone === t ? "border-primary bg-primary/10 text-primary" : "border-border text-gray-400"
                } disabled:cursor-default`}
              >
                {t}
              </button>
            ))}
          </div>
        </div>

        {/* Posting Times */}
        <div>
          <label className="text-xs text-gray-400 mb-2 block">Posting Times (UTC)</label>
          <div className="flex flex-wrap gap-2">
            {TIMES.map(t => (
              <button
                key={t}
                disabled={!editMode}
                onClick={() => toggleTime(t)}
                className={`px-3 py-1.5 rounded-lg text-sm border transition-colors ${
                  form.posting_times.includes(t) ? "border-primary bg-primary/10 text-primary" : "border-border text-gray-400"
                } disabled:cursor-default`}
              >
                {t}
              </button>
            ))}
          </div>
        </div>

        {editMode && (
          <div className="flex gap-3 pt-2">
            <button onClick={handleSave} className="px-5 py-2 bg-[#ff6b00] text-white rounded-lg text-sm font-medium">
              Save Changes
            </button>
            <button onClick={() => setEditMode(false)} className="px-5 py-2 text-gray-400 text-sm">
              Cancel
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
```

---

### File 2: `fb_dash/lib/apiManager.ts`

```ts
async getAutopilotConfig(token: string) { ... }
async saveAutopilotConfig(token: string, config: any) { ... }
async toggleAutopilot(token: string) { ... }
```

### File 3: `fb_dash/lib/features/agentSlice.ts`

State, thunks, reducers for autopilot.

### File 4: `fb_dash/app/components/Sidebar.tsx`

```ts
{ href: "/autopilot", icon: Zap, label: "AI Autopilot" }
```

CREATE group mein add karo, ya naya AUTOMATION group banao.

---

## Implementation Process

1. Redux state + thunks add karo
2. `apiManager.ts` methods add karo
3. `/autopilot/page.tsx` create karo
4. Sidebar mein link add karo
5. Test: configure karo, save karo, toggle karo
6. `generate-now` backend endpoint se test karo

---

**Next Step:** [Step 13 — Bulk Post Upload](step-13-bulk-post-upload.md)
