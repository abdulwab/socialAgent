# General Rules

- Match the user's Urdu/English/Roman Urdu style.
- Preserve unrelated changes and nested-repository boundaries.
- Follow the LangGraph test-gated checklist; stop on `FAIL` or `BLOCKED`.
- Never touch secrets or protected changes without explicit approval.
- Frontend commits/pushes occur only inside `socialUI` and pushes only when requested.
- Backend commits occur only inside `socialbackend`; never push backend to GitHub.
- Backend deployment follows `socialbackend/AWS-DEPLOY-GUIDE.md`.
- Root plans/instructions are committed only in the root repository.
- Record durable coding-agent knowledge with `bd remember` (surfaced by `bd prime`).
  Never create markdown memory files; `.claude/memory/` was migrated into Beads on 2026-08-26.
- Never expose secret values in docs, output, prompts, state, traces, or logs.
