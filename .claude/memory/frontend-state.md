---
name: frontend-state
description: Redux store structure, agentSlice state shape, apiManager config, aur async thunk patterns
metadata:
  type: project
---

# Frontend State Management

## Files

- [fb_dash/lib/store.ts](../../../fb_dash/lib/store.ts) — Redux store configuration
- [fb_dash/lib/features/agentSlice.ts](../../../fb_dash/lib/features/agentSlice.ts) — Saari state + async thunks
- [fb_dash/lib/apiManager.ts](../../../fb_dash/lib/apiManager.ts) — HTTP client
- [fb_dash/lib/hooks.ts](../../../fb_dash/lib/hooks.ts) — Typed hooks

---

## Redux Store (store.ts)

```typescript
// store.ts — agentSlice combine hota hai
const store = configureStore({
  reducer: {
    agent: agentReducer,
  },
})
```

---

## agentSlice — State Shape

```typescript
interface AgentState {
  // Auth
  user: User | null
  token: string | null
  isAuthenticated: boolean
  loading: boolean
  error: string | null

  // Posts
  posts: Post[]
  savedPosts: Post[]
  scheduledPosts: ScheduledPost[]
  publishedPosts: Post[]

  // Social connections
  pages: FacebookPage[]
  linkedinAccounts: LinkedInAccount[]
  xAccounts: XAccount[]

  // Analytics
  postMetrics: PostMetric[]
  profileMetrics: ProfileMetric[]

  // AI generation
  generatedContent: string | null
  isGenerating: boolean
}
```

---

## apiManager.ts — HTTP Client

```typescript
// Base URL — Railway backend
const BASE_URL = "https://web-production-a02ea.up.railway.app/api/v1"

// Timeout: 12 seconds
// Auth: Authorization header automatically attach karta hai (localStorage token se)
```

**Usage pattern:**
```typescript
const response = await apiManager.post('/post/generate', { topic, platform })
const response = await apiManager.get('/user/me')
```

---

## Async Thunk Pattern

Har API call ek `createAsyncThunk` hai `agentSlice.ts` mein:

```typescript
export const generatePost = createAsyncThunk(
  'agent/generatePost',
  async (data: GeneratePostData, { rejectWithValue }) => {
    try {
      const response = await apiManager.post('/post/generate', data)
      return response.data
    } catch (error) {
      return rejectWithValue(error.response?.data?.detail)
    }
  }
)

// Slice mein extraReducers:
.addCase(generatePost.pending, (state) => { state.isGenerating = true })
.addCase(generatePost.fulfilled, (state, action) => {
  state.generatedContent = action.payload
  state.isGenerating = false
})
.addCase(generatePost.rejected, (state, action) => {
  state.error = action.payload as string
  state.isGenerating = false
})
```

---

## Custom Hooks (hooks.ts)

```typescript
export const useAppDispatch = () => useDispatch<AppDispatch>()
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector
```

**Use karne ka tarika component mein:**
```typescript
const dispatch = useAppDispatch()
const { user, loading } = useAppSelector((state) => state.agent)

// Action dispatch:
dispatch(generatePost({ topic: "AI trends", platform: "linkedin" }))
```

---

## StoreProvider (app/layout.tsx)

```tsx
// Root layout mein Redux Provider wrap hai
export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <StoreProvider>{children}</StoreProvider>
      </body>
    </html>
  )
}
```

---

## Token Storage

- JWT token `localStorage` mein store hota hai
- `apiManager.ts` automatically har request mein attach karta hai
- Logout par localStorage clear hota hai + Redux state reset

---

## Naya Feature Add Karne Ka Pattern

1. `agentSlice.ts` mein state field add karo
2. `createAsyncThunk` banao API call ke liye
3. `extraReducers` mein pending/fulfilled/rejected handle karo
4. Component mein `useAppSelector` aur `useAppDispatch` use karo
5. **Direct `fetch` ya `axios` mat use karo** — hamesha `apiManager` se karo

**Why:** Centralized state zaroori hai taaki auth token, loading states, aur data consistent rahein across pages.
**How to apply:** Naya component likhte waqt — Redux thunk + apiManager pattern follow karo, local state sirf UI-only chezon ke liye use karo.
