# Frontend

`fb_dash` uses Next.js 16, React 19, TypeScript, Tailwind 4, Redux Toolkit, Clerk, and
lucide-react.

- Keep the branded custom `/agent` product UI.
- Use `assistant-ui` chat/thread primitives.
- Hydrate backend-owned threads, stream typed SSE, reconnect/deduplicate events, and
  resume approvals with backend `payload_hash`.
- Preserve custom OAuth, draft, media, CSV, schedule, analytics, progress, and approval UI.
- Show conversation history controls for all logged-in users.

Important paths: `app/agent/`, `lib/apiManager.ts`, `lib/features/agentSlice.ts`, and
`lib/useFreshAuthToken.ts`.

React must not send authoritative conversation history, generated artifacts, hidden
agent names, traces, raw tool logs, provider settings, or API keys.
