# Frontend

`fb_dash` uses Next.js 16, React 19, TypeScript, Tailwind 4, Redux Toolkit, Clerk, and
lucide-react.

- Keep the branded custom `/agent` product UI.
- Use `assistant-ui` chat/thread primitives after dependency approval.
- Use typed SSE initially.
- Preserve custom OAuth, draft, media, CSV, schedule, analytics, progress, and approval UI.

Important paths: `app/agent/`, `lib/apiManager.ts`, `lib/features/agentSlice.ts`, and
`lib/useFreshAuthToken.ts`.

Legacy: AgentShell sends the last eight messages/artifacts, and removed provider-setting
code remains in API manager/Redux. Remove it through tested checklist work.

