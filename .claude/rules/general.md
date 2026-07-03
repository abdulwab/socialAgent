# General Rules

- Match the user's Urdu/English/Roman Urdu style.
- Preserve unrelated changes and nested-repository boundaries.
- Follow the LangGraph test-gated checklist; stop on `FAIL` or `BLOCKED`.
- Never touch secrets or protected changes without explicit approval.
- Frontend commits/pushes occur only inside `fb_dash` and pushes only when requested.
- Backend commits occur only inside `fb_agent`; never push backend to GitHub.
- Backend deployment follows `fb_agent/AWS-DEPLOY-GUIDE.md`.
- Root plans/instructions are committed only in the root repository.
- Update coding-agent memory when architecture or operational facts change.
- Never expose secret values in docs, output, prompts, state, traces, or logs.
