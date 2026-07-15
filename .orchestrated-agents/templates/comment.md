### Commentor: <RoleName>

**Step/Subtask:** <specific step>

**Status:** <In Progress | Needs Fix | Blocked | Evidence Accepted | Approved | Escalate To Human>

**Findings:** <facts, critique, or work completed>

**Evidence:** <commands, files, sources, tests, logs, reasoning>

**Verified Evidence:** <required when the comment claims an on-disk state (bead ID mapping, status transition, ownership, parent/child, priority, label, dependency). See `.orchestrated-agents/workflows/bead-protocol.md` Approval-Comment Accuracy section for the rule and the citation format.>

- `bd show <id> --json at <ISO-timestamp from updated_at field>` -> <output slice>
- `bd list --json | rg <pattern> at <ISO-timestamp>` -> <count> matches: <sample slice>

**Required Next Action:** <next role/action, or none if complete>

---

**Pre-write lint (mandatory):** After drafting your comment text but
before piping it to `bd comment`, validate via
`.orchestrated-agents/bin/test-comment-check.ps1` (see
`.orchestrated-agents/workflows/bead-protocol.md` Comment-Discipline
Self-Check section for invocation patterns). Fix any flagged
patterns and re-validate until exit code is 0. Only then post.
