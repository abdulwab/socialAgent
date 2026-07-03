# Social Platforms

Supported: Facebook Pages, Instagram Business, LinkedIn, and X.

- Connections use OAuth only; never collect platform passwords.
- Existing backend platform services become typed LangGraph tools.
- OAuth tokens stay server-side and never enter prompts, state, memory, traces, or UI.
- Instagram requires compatible media; X length is validated.
- Every target account/page must belong to the authenticated user.
- Token expiry/health requires safe handling.
- OAuth redirects and production CORS require explicit approval.
- Publishing, scheduling, disconnect, deletion, retry, and autopilot mutations require
  central confirmation and idempotent execution.
