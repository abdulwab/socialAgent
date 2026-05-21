---
paths:
  - "**/*.md"
---

# Markdown Documentation Standards

## Content Rules

- Har file ek topic par focused rakho — multiple topics alag files mein
- Relative links use karo between docs, absolute GitHub URLs nahi
- Headings hierarchical rakho — levels skip mat karo (e.g., `##` se `####` mat jaao)

## Formatting

- Structured comparisons ke liye tables use karo
- Code examples mein language specify karo (```python, ```typescript, etc.)
- Short, scannable content likhna — paragraphs chhote rakho

## SocialHub Documentation Rules

- Frontend changes: `fb_dash/` file paths mention karo
- Backend changes: `fb_agent/` file paths mention karo
- API routes document karte waqt HTTP method aur full path include karo
- Breaking changes (DB schema, OAuth URLs, CORS) **bold** mein highlight karo
- `.env` variables KABHI document mein actual values mat likho — sirf variable names

## File Locations

- `.claude/rules/` — Claude ke liye project rules
- `.claude/skills/` — Reusable skill definitions
- `.claude/memory/` — Project context memory
- `fb_dash/README.md` — Frontend setup guide
- `fb_agent/README.md` — Backend setup guide
