# Step 04 — Failed Post Retry Button

**Phase:** 1 (Quick Win)
**Effort:** Low
**Estimated Time:** 1–2 hours
**Dependencies:** None (existing posts infrastructure use hogi)

---

## Goal

Jab koi post fail ho jaye, user ko ek "Retry" button dikhao jo post dobara publish karne ki koshish kare.

---

## Where It Shows

Post Queue page (`/scheduled-posts`) pe failed posts mein ek "Retry" button.

---

## Backend Changes

### File: `fb_agent/app/api/v1/` (naya route ya existing mein add)

Naya endpoint:
```
POST /posts/{post_id}/retry
```

Logic:
1. Post fetch karo — `user_id` match karo (security)
2. Check karo `status == "failed"` hai
3. Status reset karo: `status = "scheduled"`, `error_message = None`
4. Scheduler mein wapas add karo (ya existing scheduler automatically pick karega)
5. Response: `{ "success": true, "message": "Post re-queued" }`

```python
@router.post("/posts/{post_id}/retry")
async def retry_post(
    post_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    post = await db.get(ScheduledPost, post_id)
    if not post or post.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Post not found")
    if post.status != "failed":
        raise HTTPException(status_code=400, detail="Post is not in failed state")
    
    post.status = "scheduled"
    post.error_message = None
    await db.commit()
    
    return {"success": True, "message": "Post re-queued for publishing"}
```

---

## Frontend Changes

### File: `fb_dash/lib/apiManager.ts`

```ts
async retryPost(token: string, postId: number) {
  const res = await fetch(`${this.baseUrl}/posts/${postId}/retry`, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}` }
  });
  return res.json();
}
```

### File: `fb_dash/lib/features/agentSlice.ts`

```ts
export const retryPost = createAsyncThunk(
  "agent/retryPost",
  async (postId: number, { getState }) => {
    const state = getState() as RootState;
    const token = state.agent.appToken;
    return apiManager.retryPost(token!, postId);
  }
);
```

### File: `fb_dash/app/scheduled-posts/page.tsx`

Failed posts ke liye Retry button add karo:

```tsx
{post.status === "failed" && (
  <button
    onClick={() => handleRetry(post.id)}
    className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-red-500/10 hover:bg-red-500/20 text-red-400 text-xs font-medium transition-colors"
  >
    <RefreshCw className="w-3 h-3" />
    Retry
  </button>
)}
```

Handler:
```tsx
const handleRetry = async (postId: number) => {
  await dispatch(retryPost(postId));
  dispatch(fetchScheduledPosts()); // list refresh karo
};
```

---

## Visual Result

```
┌─────────────────────────────────────┐
│ Post about AI trends...             │
│ LinkedIn · May 21, 2026             │
│ ❌ Failed: Token expired            │
│                           [Retry]   │
└─────────────────────────────────────┘
```

---

## Implementation Process

1. Backend mein retry endpoint add karo
2. Backend test karo (Postman se `POST /posts/123/retry`)
3. `apiManager.ts` mein `retryPost()` add karo
4. `agentSlice.ts` mein `retryPost` thunk add karo
5. `scheduled-posts/page.tsx` mein failed posts ke saath Retry button add karo
6. Test karo — failed post pe Retry click karo, status change dekho

---

**Next Step:** [Step 05 — Token Expiry Banner](step-05-token-expiry-banner.md)
