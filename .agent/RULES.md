# Development Rules

- Make the smallest correct change.
- Do not rewrite working code without clear need.
- Do not modify unrelated files.
- Reuse existing utilities, schemas, services, and patterns.
- Preserve backward compatibility unless user approves a breaking change.
- Do not add dependencies without explicit approval.
- Do not touch `.env`, secrets, migrations, lockfiles, or deployment config without approval.
- Do not run destructive commands.
- Keep diffs readable and focused.
- Validate user ownership for user-specific data.
- Keep internal routing, logs, model names, and tool traces out of normal UI.
- Prefer deterministic validation around LLM outputs.
- Tests should cover bug cause, not only happy path.
- Commit/deploy only within the repo/workflow authorized for the change.
