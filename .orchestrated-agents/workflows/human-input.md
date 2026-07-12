# Human Input Protocol

Human input is expensive and should be requested only after role debate cannot converge.

## Before Asking

Roles must first try to resolve the issue with:

- repository evidence
- source documentation
- tests or command output
- architecture documents
- user-provided instructions
- Beads history and comments

## Human Question Packet

When a decision is still needed, Human Question Framer must comment the bead with:

```markdown
### Commentor: Human Question Framer

**Step/Subtask:** Human decision required

**Status:** Escalate To Human

**Question:** <one concise question>

**Options:**

| Option | Pros | Cons | Recommendation |
| --- | --- | --- | --- |
| A | ... | ... | Recommended |
| B | ... | ... | ... |

**Decision Matrix:**

| Factor | A | B | Notes |
| --- | --- | --- | --- |
| Correctness | ... | ... | ... |
| Risk | ... | ... | ... |
| Cost | ... | ... | ... |
| Maintainability | ... | ... | ... |
| Reversibility | ... | ... | ... |

**Required Next Action:** Wait for human answer.
```

The orchestrator reports only: "Bead <id> needs your input." Details are provided only if the human asks.
