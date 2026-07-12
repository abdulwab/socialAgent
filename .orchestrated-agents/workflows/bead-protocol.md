# Bead Protocol

These rules apply to every role invocation.

## Mandatory First Actions

1. Read the target bead with `bd show <bead-id>`.
2. Assign the bead to the current role before doing work:

   ```bash
   bd update <bead-id> --assignee "<RoleName>" --status in_progress
   ```

3. Add a formatted Markdown comment announcing the substep.

The wrapper must not add comments on behalf of a role. The invoked role itself must run the Beads commands and create its own comments.

## No Test Comments On Real Beads

Do not write probe comments such as `TEST`, `Line 1`, scratch text, placeholder text, or formatting experiments on a real bead. If you need to validate comment mechanics, use a disposable test workspace outside the project or ask the orchestrator to run a tooling check. Every comment on a real bead must be a meaningful Markdown work record.

## Mandatory Comment Format

Every role comment must be valid Markdown and follow this shape:

```markdown
### Commentor: <RoleName>

**Step/Subtask:** <specific step>

**Status:** <In Progress | Needs Fix | Blocked | Evidence Accepted | Approved | Escalate To Human>

**Findings:** <facts, critique, or work completed>

**Evidence:** <commands, files, sources, tests, logs, reasoning>

**Required Next Action:** <next role/action, or none if complete>
```

## Actor Names

Use the role as the actor/commentor, for example:

- Role Selector
- Maker Engineer
- Adversarial Reviewer
- QA Strategist
- Security Privacy Reviewer
- Release SRE Reviewer
- Documentation Reviewer
- Workflow Scout
- Process Engineer
- Human Question Framer

## Forbidden Shortcuts

- Do not use local TODO files as the source of truth.
- Do not mark a bead complete because one role is satisfied.
- Do not approve without evidence.
- Do not skip SDLC gates silently.
- Do not put secrets in comments.
- Do not ask the human until role debate has failed to converge with evidence.
