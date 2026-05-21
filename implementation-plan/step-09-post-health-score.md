# Step 09 — Post Health Score (AI Pre-Publish Check)

**Phase:** 2
**Effort:** Medium
**Estimated Time:** 2–3 hours
**Dependencies:** Existing AI/LLM integration kaam karna chahiye

---

## Goal

Jab user post schedule karne se pehle, ek AI-powered "Health Score" dikhao jo bataye:
- Post kitna effective hai
- Kya improve kar sakte hain
- Platform-specific suggestions

---

## Where It Shows

`/posts` (New Post) page pe — post content fill karne ke baad, schedule button se pehle.

---

## UI Design

```
┌──────────────────────────────────────┐
│ Post Health Score: 7.8/10  ✅ Good   │
│──────────────────────────────────────│
│ ✅ Good length for LinkedIn          │
│ ✅ Contains a call-to-action         │
│ ⚠️  No hashtags (LinkedIn needs 3-5) │
│ ⚠️  Best time: 9AM, not 3PM          │
│ ❌ Too formal for Facebook audience  │
│                                      │
│ [ Improve with AI ] [ Post Anyway ]  │
└──────────────────────────────────────┘
```

---

## Implementation Approach

**Frontend-only (no new backend endpoint needed)** — existing AI endpoint use karna hai jo already post generation ke liye exist karta hai. Ek special prompt bhejo jo scoring return kare.

---

## Backend (Minimal Change)

Existing `/generate-caption` ya similar AI endpoint ko reuse karo. Agar woh format restrict karta ho, toh ek simple endpoint add karo:

### `POST /ai/health-check` (optional naya endpoint)

```python
@router.post("/ai/health-check")
async def check_post_health(
    data: dict,  # { "content": "...", "platform": "linkedin", "scheduled_time": "..." }
    current_user: User = Depends(get_current_user)
):
    content = data.get("content", "")
    platform = data.get("platform", "")
    scheduled_time = data.get("scheduled_time", "")
    
    prompt = f"""
    Analyze this social media post for {platform} and return a JSON health score.
    
    Post: "{content}"
    Scheduled time: {scheduled_time}
    
    Return ONLY valid JSON:
    {{
      "score": 7.5,
      "grade": "Good",
      "checks": [
        {{ "status": "pass", "message": "Good length for {platform}" }},
        {{ "status": "warn", "message": "Consider adding 3-5 hashtags" }},
        {{ "status": "fail", "message": "No call-to-action detected" }}
      ]
    }}
    """
    
    # existing LLM call logic use karo
    result = await call_llm(prompt, current_user)
    return result
```

---

## Frontend Changes

### File: `fb_dash/app/posts/page.tsx`

Post form mein ek "Check Health" button add karo:

```tsx
// State
const [healthScore, setHealthScore] = useState<HealthScore | null>(null);
const [checkingHealth, setCheckingHealth] = useState(false);

// Handler
const handleHealthCheck = async () => {
  setCheckingHealth(true);
  const result = await apiManager.checkPostHealth(token, {
    content: postContent,
    platform: selectedPlatform,
    scheduled_time: scheduledAt
  });
  setHealthScore(result);
  setCheckingHealth(false);
};

// UI — form ke neeche dikhao
{healthScore && (
  <div className="border border-border rounded-xl p-5 space-y-3">
    <div className="flex items-center justify-between">
      <span className="font-semibold">Post Health Score</span>
      <span className={`text-2xl font-bold ${
        healthScore.score >= 7 ? "text-green-400" : 
        healthScore.score >= 5 ? "text-yellow-400" : "text-red-400"
      }`}>
        {healthScore.score}/10
      </span>
    </div>
    
    <div className="space-y-2">
      {healthScore.checks.map((check, i) => (
        <div key={i} className="flex items-center gap-2 text-sm">
          {check.status === "pass" && <span className="text-green-400">✅</span>}
          {check.status === "warn" && <span className="text-yellow-400">⚠️</span>}
          {check.status === "fail" && <span className="text-red-400">❌</span>}
          <span className="text-gray-300">{check.message}</span>
        </div>
      ))}
    </div>
    
    <div className="flex gap-3 pt-2">
      <button className="px-4 py-2 bg-primary/10 text-primary rounded-lg text-sm font-medium">
        Improve with AI
      </button>
      <button className="px-4 py-2 text-gray-400 text-sm">
        Post Anyway
      </button>
    </div>
  </div>
)}

<button
  onClick={handleHealthCheck}
  disabled={!postContent || checkingHealth}
  className="flex items-center gap-2 px-4 py-2 border border-border rounded-lg text-sm text-gray-300 hover:text-white"
>
  {checkingHealth ? "Checking..." : "Check Post Health"}
</button>
```

---

## Interface

```ts
interface HealthCheck {
  status: "pass" | "warn" | "fail";
  message: string;
}

interface HealthScore {
  score: number;
  grade: string;
  checks: HealthCheck[];
}
```

---

## Implementation Process

1. Backend AI endpoint approach decide karo (reuse existing ya new endpoint)
2. Endpoint test karo — JSON response aa raha hai?
3. `apiManager.ts` mein `checkPostHealth()` method add karo
4. `posts/page.tsx` mein state, handler, aur UI add karo
5. Test: content likho, platform select karo, "Check Health" click karo
6. Score aur suggestions dikhni chahiye
7. Different platforms pe test karo (LinkedIn vs Facebook — alag suggestions honi chahiye)

---

**Next Step:** [Step 10 — Media Library in Sidebar](step-10-media-library-sidebar.md)
