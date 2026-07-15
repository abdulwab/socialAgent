# Orchestrated Agents Workflow

This file explains, in plain language, how our AI-assisted work system is
supposed to run.

## The Simple Idea

| Thing | Plain Meaning |
| --- | --- |
| Beads / BeadBox | The shared task board. Every real task, blocker, and follow-up must be visible there. |
| Codex-Orchestrator | The coordinator. It chooses the next task, starts the right AI role, watches for failures, and updates Beads when tooling breaks. |
| Role | A job hat worn by the doer AI, such as `Planner`, `Maker Engineer`, or `QA Strategist` (quality/testing reviewer). |
| OpenCode | The command-line tool used to run a role. |
| Z.AI GLM-5.2 | The current default AI model used by roles. |
| MiniMax-M3 | Backup model option. |
| WORKFLOW.md | This shared reference. Update it whenever the workflow, roles, statuses, model rules, or comment rules change. |

## Current State

| Item | Current State |
| --- | --- |
| Active task | None after this update is closed. |
| Latest doc cleanup | `socialhub-46z`: simplified this file for non-engineers. |
| Blocked task | `socialhub-v8g.24.8`: role-name safety is mostly done, but final review is blocked. |
| Blocker | `socialhub-45g`: role runs sometimes stall or produce the wrong output. That must be fixed before blocked work can finish. |
| Commits | Do not commit or push until the workflow is finalized and the user explicitly allows it. |
| Current model | Use Z.AI GLM-5.2. |
| Thinking effort | `Researcher`, `Planner`, and `Architect` use max thinking. All other roles use high thinking. |
| BeadBox sync | Run `bd export -o .beads/issues.jsonl` after meaningful Beads updates. |

## Final Target

This is the intended end state, based on the open Beads:

1. Every user requirement is mapped to a Bead.
2. Only one task is marked `in_progress` unless work is truly happening in parallel.
3. If something is blocked, the blocking Bead is linked clearly.
4. Every task starts with role selection.
5. The right roles work on the task, not Codex.
6. Makers make changes.
7. Reviewers challenge the work until it is fixed or proven correct.
8. Human input is requested only when roles cannot decide with evidence.
9. Every role comments on the Bead in structured Markdown.
10. Workflow problems automatically become new workflow-improvement Beads.
11. The workflow becomes copyable to another repository.
12. Commits happen step by step only after the workflow is finalized and the user reauthorizes commits.

## Current Roles

These are the active role names. Use these exact names in comments and Beads.

| Role | Simple Job |
| --- | --- |
| Role Selector | Decides which roles are needed for a task. |
| Human Question Framer | Prepares a clear question for the human only when human input is truly needed. |
| Researcher | Finds evidence from docs, standards, source code, or trusted sources. |
| Planner | Makes the work plan and maps the task to the software lifecycle steps. |
| Architect | Checks design, structure, tradeoffs, boundaries, and long-term impact. |
| Maker Engineer | Makes normal product or repository changes. |
| Workflow Engineer | Changes only the orchestration/workflow files and role setup. |
| Adversarial Reviewer | Looks for mistakes and pushes back until the work is fixed or proven correct. |
| QA Strategist | Checks testing, acceptance criteria, and proof that the task works. QA means quality/testing. |
| Security Privacy Reviewer | Checks secrets, permissions, privacy, ownership, and security risk. |
| Release SRE Reviewer | Checks whether the change can run safely after release. SRE means site reliability. |
| Documentation Reviewer | Checks whether docs are accurate and understandable. |
| Workflow Scout | Finds workflow flaws and creates follow-up Beads. |

## Future Roles We Intend To Add

The current roles are not the final full company model. Open Beads say we still
intend to add or refine specialist roles such as:

| Future Area | Examples |
| --- | --- |
| Product and requirements | Product Manager, Requirements Engineer |
| Design | UX Designer |
| Engineering | Frontend Engineer, Backend Engineer, Integration Engineer, Data Engineer |
| Security | Security Engineer, Privacy Governance |
| Testing | Test Engineer, Performance Tester, Accessibility Tester |
| Operations | DevOps Engineer (deployment/tooling), Site Reliability Engineer (keeps the service running) |
| Documentation | Technical Writer |
| Later operational roles | Incident Commander, Change Manager, Capacity Planner, Build Engineer |

These future roles must be added through Beads before they are treated as active
roles.

## How A Task Should Move

| Step | What Happens |
| --- | --- |
| 1 | A Bead exists for the task. |
| 2 | The Bead is `open` until someone is actually working on it. |
| 3 | Role Selector decides the required roles. |
| 4 | Roles decide whether human input is needed. |
| 5 | Researcher, Planner, or Architect join if the task needs evidence, planning, or design. |
| 6 | A maker role does the actual change. |
| 7 | Reviewers challenge the change. |
| 8 | The maker fixes issues or proves the reviewer is wrong. |
| 9 | Quality/testing, security/privacy, release/reliability, and docs reviewers join when relevant. |
| 10 | Workflow Scout files follow-up Beads for workflow flaws. |
| 11 | The Bead closes only when the required evidence and approvals exist. |

## Bead Statuses

| Status | Use It When |
| --- | --- |
| `open` | The work exists but nobody is actively working on it. |
| `in_progress` | A role or Codex is actively working on it right now. |
| `blocked` | Work cannot continue until another Bead, a tool issue, or a human answer is resolved. |
| `deferred` | Work is intentionally postponed until a later trigger. |
| `closed` | The work is truly done. |

Rules:

- Do not use `backlog` for this workflow.
- Do not leave many Beads `in_progress` unless they are actually being worked in parallel.
- If a task depends on another task, link the dependency in Beads.
- If a role stalls or a tool breaks, make the problem visible in Beads.

## Comment Rules

Every role must comment on the Bead itself. Codex should not pretend to be a
role.

Every role comment should include:

| Field | Meaning |
| --- | --- |
| `### Commentor:` | The exact role name. |
| `**Step/Subtask:**` | What this comment is about. |
| `**Status:**` | Current result, such as In Progress, Needs Fix, Approved, or Blocked. |
| `**Findings:**` | What the role found or did. |
| `**Evidence:**` | Files, commands, tests, links, or reasoning. |
| `**Required Next Action:**` | What should happen next. |

Do not post test comments, placeholder comments, scratch comments, or tiny
one-line approvals.

## Role Name Rules

| Rule | Plain Meaning |
| --- | --- |
| Use exact role names | Comments must say `Workflow Engineer`, not a shortcut or old name. |
| Role command shortcuts are allowed | The command may accept shortcuts like `workflow-engineer`, but comments must use the full role name. |
| Quote role names with spaces | Use `"Workflow Engineer"` in shell commands so the name does not split. |
| Old role names | Old comments may contain role names we no longer use. Do not copy them into new comments. |

## Model Rules

| Role | Model | Thinking |
| --- | --- | --- |
| Researcher | Z.AI GLM-5.2 | max |
| Planner | Z.AI GLM-5.2 | max |
| Architect | Z.AI GLM-5.2 | max |
| All other roles | Z.AI GLM-5.2 | high |

MiniMax-M3 can be used as a backup by changing the model setting, but the same
thinking rules still apply.

## When Codex May Step In

Codex should normally coordinate, not do the role's job.

Codex may step in only when:

| Situation | What Codex Must Do |
| --- | --- |
| A role process stalls or fails | Stop or block it, then record what happened in Beads. |
| A role cannot do something because of tool permissions | Make the smallest necessary infrastructure fix and record it as `Codex-Orchestrator`. |
| A workflow problem is discovered | Create or link a workflow-improvement Bead. |
| A manual file change is unavoidable | Keep it minimal, explain it in Beads, and require review before closing the related work. |

Codex must not secretly act as a role.

## Five-Minute Watch Rule

If a role appears stuck for more than five minutes:

1. Check whether the process is still running.
2. Check whether logs, files, or Beads changed.
3. If it is making progress, keep waiting with evidence.
4. If it is stuck, stop or retry it.
5. If this reveals a workflow flaw, create or link a follow-up Bead.
6. Do not leave a stale task marked `in_progress`.

## Important Open Work

| Bead | Plain Meaning |
| --- | --- |
| `socialhub-45g` | Fix stalled or wrong-output role runs. |
| `socialhub-v8g.24.1` | Finish the five-minute watchdog workflow. |
| `socialhub-v8g.24.3` | Build the full user-requirement to Bead map. |
| `socialhub-v8g.24.5` | Clean up status, dependency, and label rules. |
| `socialhub-v8g.24.7` | Finalize commit policy. |
| `socialhub-v8g.24.8` | Finish role-name safety review after the runner issue is fixed. |
| `socialhub-v8g.22` | Complete the full software lifecycle and role coverage model. |
| `socialhub-v8g.17` | Require audits for Codex changes to sensitive workflow files. |
| `socialhub-v8g.10` | Add a future macOS/Linux wrapper. |
| `socialhub-v8g.13` | Record why Beads is pinned to version 1.0.4. |

## What Must Update This File

Update this file whenever any of these change:

- roles
- role names
- AI service and model rules
- Bead status rules
- comment rules
- human-input rules
- watchdog/stall handling
- commit policy
- software lifecycle steps
- specialist role plans
- current blockers or active workflow exceptions

## Files With More Detail

| File | What It Is For |
| --- | --- |
| `.orchestrated-agents/README.md` | Quick setup and commands. |
| `.orchestrated-agents/docs/CONTEXT.md` | Longer project context. |
| `.orchestrated-agents/workflows/bead-protocol.md` | Detailed Beads and comment rules. |
| `.orchestrated-agents/workflows/sdlc-gates.md` | Full software lifecycle gate list. |
| `.orchestrated-agents/workflows/adversarial-convergence.md` | Detailed pushback-and-approval rules. |
| `.orchestrated-agents/workflows/human-input.md` | How to ask the human for decisions. |
| `.orchestrated-agents/bin/oa.ps1` | Small Windows script that starts role runs. |
| `opencode.json` | Role and permission setup for OpenCode. |
