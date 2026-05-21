# Step 08 — Ideas Board: Frontend (Kanban UI)

**Phase:** 2
**Effort:** High
**Estimated Time:** 4–6 hours
**Dependencies:** Step 07 (backend) complete hona chahiye

---

## Goal

`/ideas` route pe ek Kanban-style board banana jahan user ideas ko 3 columns mein manage kar sake:
- **IDEAS** — raw ideas
- **DRAFTS** — work in progress
- **QUEUE** — ready to schedule

---

## Files to Create/Change

### File 1 (NEW): `fb_dash/app/ideas/page.tsx`

Main Kanban board. 3-column layout.

**Structure:**
```tsx
"use client";
import { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { AppDispatch, RootState } from "../../lib/store";
import { fetchIdeas, createIdea, updateIdea, deleteIdea } from "../../lib/features/agentSlice";
import { Lightbulb, FileText, Layers, Plus, Trash2, ChevronRight } from "lucide-react";

const COLUMNS = [
  { key: "idea",   label: "IDEAS",  icon: Lightbulb, color: "text-yellow-400" },
  { key: "draft",  label: "DRAFTS", icon: FileText,  color: "text-blue-400" },
  { key: "queued", label: "QUEUE",  icon: Layers,    color: "text-green-400" },
];

export default function IdeasPage() {
  const dispatch = useDispatch<AppDispatch>();
  const { ideas, ideasLoading } = useSelector((s: RootState) => s.agent);
  const [newIdeaTitle, setNewIdeaTitle] = useState("");

  useEffect(() => {
    dispatch(fetchIdeas());
  }, [dispatch]);

  const handleAdd = async () => {
    if (!newIdeaTitle.trim()) return;
    await dispatch(createIdea({ title: newIdeaTitle, status: "idea" }));
    setNewIdeaTitle("");
  };

  const handleMove = (id: number, newStatus: string) => {
    dispatch(updateIdea({ id, status: newStatus }));
  };

  const handleDelete = (id: number) => {
    dispatch(deleteIdea(id));
  };

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center gap-3">
        <Lightbulb className="w-6 h-6 text-yellow-400" />
        <h1 className="text-2xl font-bold">Ideas Board</h1>
      </div>

      {/* Add idea input */}
      <div className="flex gap-3">
        <input
          value={newIdeaTitle}
          onChange={e => setNewIdeaTitle(e.target.value)}
          onKeyDown={e => e.key === "Enter" && handleAdd()}
          placeholder="Add a new idea..."
          className="flex-1 bg-card border border-border rounded-lg px-4 py-2.5 text-sm outline-none focus:border-primary"
        />
        <button
          onClick={handleAdd}
          className="flex items-center gap-2 px-4 py-2.5 bg-[#ff6b00] hover:bg-[#e85f00] text-white rounded-lg font-medium text-sm"
        >
          <Plus className="w-4 h-4" /> Add Idea
        </button>
      </div>

      {/* Kanban Columns */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {COLUMNS.map((col, colIdx) => {
          const colIdeas = ideas?.filter(i => i.status === col.key) ?? [];
          const nextCol = COLUMNS[colIdx + 1];
          return (
            <div key={col.key} className="bg-card border border-border rounded-xl p-4">
              <div className={`flex items-center gap-2 mb-4 ${col.color}`}>
                <col.icon className="w-4 h-4" />
                <span className="text-xs font-bold tracking-widest">{col.label}</span>
                <span className="ml-auto text-xs text-gray-500">{colIdeas.length}</span>
              </div>

              <div className="space-y-2 min-h-[120px]">
                {colIdeas.map(idea => (
                  <div key={idea.id} className="bg-background border border-border rounded-lg p-3 space-y-2">
                    <p className="text-sm font-medium">{idea.title}</p>
                    {idea.content && (
                      <p className="text-xs text-gray-500 line-clamp-2">{idea.content}</p>
                    )}
                    {idea.platform && (
                      <span className="text-xs capitalize text-primary bg-primary/10 px-2 py-0.5 rounded-full">
                        {idea.platform}
                      </span>
                    )}
                    <div className="flex items-center gap-2 pt-1">
                      {nextCol && (
                        <button
                          onClick={() => handleMove(idea.id, nextCol.key)}
                          className="flex items-center gap-1 text-xs text-gray-400 hover:text-white"
                        >
                          Move to {nextCol.label} <ChevronRight className="w-3 h-3" />
                        </button>
                      )}
                      <button
                        onClick={() => handleDelete(idea.id)}
                        className="ml-auto text-gray-600 hover:text-red-400"
                      >
                        <Trash2 className="w-3 h-3" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
```

---

### File 2: `fb_dash/lib/apiManager.ts`

```ts
async getIdeas(token: string) {
  const res = await fetch(`${this.baseUrl}/ideas/`, {
    headers: { Authorization: `Bearer ${token}` }
  });
  return res.json();
}

async createIdea(token: string, data: { title: string; status?: string; content?: string; platform?: string }) {
  const res = await fetch(`${this.baseUrl}/ideas/`, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify(data)
  });
  return res.json();
}

async updateIdea(token: string, id: number, data: Partial<{ title: string; status: string; content: string; platform: string }>) {
  const res = await fetch(`${this.baseUrl}/ideas/${id}`, {
    method: "PATCH",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify(data)
  });
  return res.json();
}

async deleteIdea(token: string, id: number) {
  const res = await fetch(`${this.baseUrl}/ideas/${id}`, {
    method: "DELETE",
    headers: { Authorization: `Bearer ${token}` }
  });
  return res.json();
}
```

---

### File 3: `fb_dash/lib/features/agentSlice.ts`

**Interface:**
```ts
interface Idea {
  id: number;
  title: string;
  content: string | null;
  status: "idea" | "draft" | "queued";
  platform: string | null;
  created_at: string;
}
```

**State:**
```ts
ideas: Idea[];
ideasLoading: boolean;
```

**Thunks:**
```ts
export const fetchIdeas = createAsyncThunk("agent/fetchIdeas", async (_, { getState }) => {
  const { appToken } = (getState() as RootState).agent;
  return apiManager.getIdeas(appToken!);
});

export const createIdea = createAsyncThunk("agent/createIdea", async (data: any, { getState, dispatch }) => {
  const { appToken } = (getState() as RootState).agent;
  await apiManager.createIdea(appToken!, data);
  dispatch(fetchIdeas());
});

export const updateIdea = createAsyncThunk("agent/updateIdea", async ({ id, ...data }: any, { getState, dispatch }) => {
  const { appToken } = (getState() as RootState).agent;
  await apiManager.updateIdea(appToken!, id, data);
  dispatch(fetchIdeas());
});

export const deleteIdea = createAsyncThunk("agent/deleteIdea", async (id: number, { getState, dispatch }) => {
  const { appToken } = (getState() as RootState).agent;
  await apiManager.deleteIdea(appToken!, id);
  dispatch(fetchIdeas());
});
```

---

### File 4: `fb_dash/app/components/Sidebar.tsx`

Ideas Board link add karo (Step 01 se related, CREATE group):
```ts
{
  label: "CREATE",
  items: [
    { href: "/posts",  icon: PlusSquare, label: "New Post" },
    { href: "/ideas",  icon: Lightbulb,  label: "Ideas Board" },
  ]
}
```

---

## Implementation Process

1. Step 07 backend endpoints verify karo (working hain?)
2. `agentSlice.ts` — Idea interface, state, 4 thunks add karo
3. `apiManager.ts` — 4 methods add karo
4. `fb_dash/app/ideas/` folder banao
5. `page.tsx` create karo
6. Sidebar mein Ideas Board link add karo
7. `npm run dev` — `/ideas` visit karo
8. Test: idea add karo, "Move to DRAFTS" click karo, "Move to QUEUE" click karo
9. Delete test karo
10. Refresh karo — ideas persist honi chahiye (DB se aa rahi hain)

---

**Next Step:** [Step 09 — Post Health Score](step-09-post-health-score.md)
