# Orchestrated Agents Context

## What We Are Building

This repository is getting a portable, Beads-centered orchestration system for AI software delivery work.

The goal is not to make Codex do every SDLC step. The goal is to make Codex act as a small orchestrator that invokes doer roles against a bead ID, while the configured model performs the actual role work: role selection, requirements analysis, design critique, implementation, QA, security review, documentation review, release/reliability review, and workflow improvement.

Beads is the durable control plane. BeadBox is the visual dashboard for the same Beads data. OpenCode is the execution surface for the active doer model.

## Operating Model

Codex should do the least possible task work:

- create or select the bead
- invoke the correct orchestration command
- report when a bead needs human input
- repair local infrastructure only when invoked roles cannot reasonably repair it

The active doer model performs the work through different role hats. Roles share the configured provider/model by default, but each role has its own prompt, permission profile, responsibility, and enforced thinking effort.

## Core Invariant

No bead should be completed by a single role in a single pass.

Every meaningful bead must go through:

1. role-selection debate
2. human-input debate
3. tailored SDLC gate coverage
4. maker work, if changes are needed
5. adversarial critique
6. QA/evidence review
7. security/privacy/release/docs review where applicable
8. convergence only after fixes or proof
9. workflow-scout check for process improvements

## Beads Discipline

Every role must assign the bead to itself before work:

```bash
bd update <bead-id> --assignee "<RoleName>" --status in_progress
```

Every role must add proper Markdown comments on the bead for each substep:

```markdown
### Commentor: <RoleName>

**Step/Subtask:** <specific step>

**Status:** <In Progress | Needs Fix | Blocked | Evidence Accepted | Approved | Escalate To Human>

**Findings:** <facts, critique, or work completed>

**Evidence:** <commands, files, sources, tests, logs, reasoning>

**Verified Evidence:** <required when the comment claims an on-disk state. See `.orchestrated-agents/workflows/bead-protocol.md` Approval-Comment Accuracy section for the rule and the citation format.>

- `bd show <id> --json at <ISO-timestamp from updated_at field>` -> <output slice>
- `bd list --json | rg <pattern> at <ISO-timestamp>` -> <count> matches: <sample slice>

**Required Next Action:** <next role/action, or none if complete>
```

The `**Verified Evidence:**` subsection is **required** whenever the
comment asserts an on-disk state (bead ID mapping, status transition,
ownership, parent/child, priority, label, dependency). The rule is
documented at
[`../workflows/bead-protocol.md`](../workflows/bead-protocol.md) under
"Approval-Comment Accuracy" and operationalized by the smoke test at
[`bd-cli-quirks.md`](./bd-cli-quirks.md) "Approval-Comment Accuracy
Smoke Test". A comment that violates this rule is approval-without-proof
per `../workflows/adversarial-convergence.md` Approval Rule.

The bead-protocol also enforces a **Comment-Discipline Self-Check**
(mandatory before `bd comment`): every role MUST run their draft
comment text through `.orchestrated-agents/bin/test-comment-check.ps1`
and only proceed if exit code is 0. The linter rejects probe comments
(`test probe`, `line1/line2/line3`, `hello world`, `Test line N`,
`lineA/lineB/lineC with <id>`, `test with <id>`, `scratch text`,
`placeholder text`, `formatting experiment`), missing required Markdown
structure (the `### Commentor:` header and the `**Status:**`,
`**Findings:**`, `**Required Next Action:**` fields), and short/sparse
comments (< 200 chars or <= 2 non-blank lines). The smoke test at
`./bd-cli-quirks.md` "Comment-Discipline Self-Check Smoke Test"
verifies the linter catches the six actual probe-comment patterns
posted on WFSC-bead-6 / socialhub-v8g.22.44 itself, which motivated
this rule. A comment that bypasses the self-check is approval-without-proof
plus a known audit-trail violation recorded in
`../workflows/bead-protocol.md` Known Audit-Trail Violations section.

The wrapper does NOT assign the bead or add comments at invocation time. The wrapper only sets `BEADS_ACTOR`, `OA_TARGET_BEAD`, and `OA_ROLE_NAME`, then spawns `opencode run`. The invoked role is solely responsible for assigning itself and writing every comment on the bead. This is by design - audit-trail integrity requires the role, not the wrapper, to write its own work record.

## Role Selection

Every bead starts with a Role Selector debate. The Role Selector must
simulate disagreement between at least these perspectives (these are
debate perspectives the Role Selector simulates, NOT roles - only the
13-role taxonomy in `WORKFLOW.md` Role Registry are real invoked roles):

- SDLC Process Architect (perspective, not a role)
- Requirements Skeptic (perspective, not a role)
- QA Strategist (perspective here; also a real invoked role in the
  registry - the only item in this list with this dual capacity)
- Security/Risk Architect (perspective, not a role)

The output is a role matrix:

- required roles
- maker/adversary/meta classification
- required sign-offs
- SDLC gate coverage
- human input needed now: yes/no
- next role to invoke

No implementation should begin before this matrix exists.

## Human Input

Human input is requested only when roles cannot converge with evidence, tests, source docs, repo context, or logic.

When a human decision is needed, Human Question Framer creates a concise Markdown decision packet with:

- one question
- available options
- pros
- cons
- recommendation
- decision matrix across relevant factors

Codex should tell the user only that a specific bead needs input unless the user asks for details.

## Maker And Adversary Split

Maker roles are the only roles allowed to change files. In this framework, the general maker is `Maker Engineer`; workflow/control-plane changes use `Workflow Engineer`.

Adversarial roles do not edit files. They inspect, run allowed checks, critique, and comment on the bead. They approve only when Maker Engineer fixes the finding or provides evidence that the finding is invalid.

## Workflow Improvement

Whenever any role finds a process flaw, SDLC miss, role gap, weak evidence standard, bad comment discipline, or workflow discrepancy, Workflow Scout creates a new workflow-improvement bead.

That improvement bead goes through the same lifecycle:

1. role selection
2. human-input gate
3. maker implementation by Workflow Engineer
4. adversarial review
5. QA/evidence review
6. convergence

The system improves itself through tracked beads, not informal memory.

## Permission Precedence

OpenCode permission rules are evaluated per command and matched in **strict declaration order** as they appear in `opencode.json`. The **first rule that matches wins**; later rules are not consulted for that command. There is no specificity-based override - "more specific" patterns only win if they are listed earlier than a broader competing pattern. This is the single rule; do not read the file expecting a specificity ranking.

Two practical consequences of declaration-order matching:

1. **A deny that appears after an allow still overrides it for the commands the deny matches.** Example: `"*": "deny"` followed by `"bd *": "allow"` followed by `"bd dolt push*": "deny"` - `bd show` is allowed, `bd dolt push remote` is denied. The position of the deny rule matters; specificity does not.
2. **The `*` glob in OpenCode bash patterns is bounded by argument count**, not "match anything". Empirically (Adversarial Reviewer Part 2 on socialhub-v8g.4):
   - `bd *` allows `bd show socialhub-v8g.4` (two args after `bd`).
   - `bd *` denies `bd show socialhub-v8g.4 --json` (three args after `bd`).
   To allow a multi-argument `bd` subcommand, use `bd **` (multi-token glob) or repeat the wildcard per slot such as `bd * *`. Do not assume `*` matches arbitrary text including flags.

The package's current read-only/adversarial roles use:

- `bash: { "*": "deny", "bd *": "allow", ... }` - `*` is the fallback deny, then specific verbs are allowlisted.

This pattern allows single-arg bd subcommands (`bd show`, `bd ready`) but denies multi-arg forms (`bd show <id> --json`) per the bounded-glob behavior above. If a role genuinely needs multi-arg bd commands, add an explicit `bd **` allow rule **after** `bd *` and document the expansion via a workflow-improvement bead; do not silently widen permissions.

The Workflow Engineer uses:

- `edit: { "*": "deny", ".orchestrated-agents/**": "allow" }` - `*` deny + path allowlist.

Verification expectation: each role's permission block must be tested at least once with **both** a benign single-arg command **and** a benign multi-arg command (e.g., `bd show <id> --json`) in its allowlist, plus a benign denylist command, before the role is trusted on product-code beads. Add a follow-up workflow-improvement bead if a role is added with untested permissions.

## Current Local Setup

The package lives under:

```text
.orchestrated-agents/
```

The current repo also has a root OpenCode config:

```text
opencode.json
```

It configures:

- default provider: `zai`
- default model: `glm-5.2`
- Z.AI Coding Plan API base: `https://api.z.ai/api/coding/paas/v4`
- Z.AI secret source: `ZAI_API_KEY`
- fallback provider: `minimax`
- fallback model: `MiniMax-M3`
- MiniMax API base: `https://api.minimax.io/v1`
- MiniMax secret source: `MINIMAX_API_KEY`
- role agents named `oa-*`
- role-spelling canonicalization (ORCH-REQ-008 / socialhub-v8g.24.8): the wrapper's `Resolve-Role` accepts the canonical display name, the dash-slug, and the oa-agent-slug as equivalent inputs and resolves both to the canonical display role (used in the prompt, `BEADS_ACTOR`, and comment template) and the configured oa-* agent (used for `opencode run`); unrecognized spellings fail closed, which also catches a quoting split that would otherwise deliver only the first word of a space-containing role (the bug class that once truncated `Process Engineer` to `Process` as a bd comment author). The regression test is `.orchestrated-agents/bin/test-role-resolution.ps1`.
- role invocation effort through the wrapper:
  - `Researcher`, `Planner`, `Architect`: `--variant max --thinking`
  - every other role: `--variant high --thinking`
- switch controls:
  - `OA_MODEL_SPEC` overrides the full model string, e.g. `zai/glm-5.2` or `minimax/MiniMax-M3`
  - `OA_PROVIDER` + `OA_MODEL` override the pieces
  - thinking effort is role-policy controlled; `OA_THINKING_VARIANT` and role-specific thinking-variant variables are ignored when they conflict with the policy above
  - `OA_<ROLE>_MODEL_SPEC` overrides one role, e.g. `OA_QA_STRATEGIST_MODEL_SPEC=zai/glm-5.2`
  - `OA_MODEL_SPEC_<ROLE>` is accepted as the alternate per-role spelling
  - model precedence: role-specific env vars -> global env vars -> default `zai/glm-5.2`
  - `oa.cmd status` prints `role_model_map` for no-call verification of every role's resolved model and enforced thinking effort

The wrapper lives at:

```text
.orchestrated-agents/bin/oa.cmd
.orchestrated-agents/bin/oa.ps1
```

Useful commands:

```powershell
.\.orchestrated-agents\bin\oa.cmd status
.\.orchestrated-agents\bin\oa.cmd key-setup zai
.\.orchestrated-agents\bin\oa.cmd key-clear zai
.\.orchestrated-agents\bin\oa.cmd run <bead-id> <role-name>
```

The wrapper prefers `bd.exe`, `bd.cmd`, and `opencode.cmd` on Windows so PowerShell execution-policy shims do not block it. The wrapper does not write Beads comments on behalf of roles; it sets `BEADS_ACTOR`, `OA_TARGET_BEAD`, and `OA_ROLE_NAME`, then the invoked doer role must assign and comment for itself.

## BeadBox Context

BeadBox is a visual dashboard for Beads. It showed a welcome screen because it could not detect `bd`.

The shell already had npm shims (`bd`, `bd.cmd`), but `bd.exe` was absent. Because BeadBox asks for the Windows release, the setup installs the native stable `bd.exe` into:

```text
C:\Users\alvil\.local\bin\bd.exe
```

That directory is already on the user PATH. If BeadBox still does not detect Beads, fully restart BeadBox and click **Check again**.

Known limitation: BeadBox v0.24.1 with `bd` v1.1.0 can show comment counts without rendering comment bodies. Upstream issue: https://github.com/beadbox/beadbox/issues/27. This repository was downgraded to native `bd` v1.0.4 at `C:\Users\alvil\.local\bin\bd.exe`, and `.beads` was rebuilt from JSONL for v1.0.4 compatibility. After restarting BeadBox, its diagnostics detected `bd version 1.0.4`, and `/api/bd show socialhub-v8g.4 --json` returned 21 inline comments. If a future upgrade reintroduces missing comment bodies, verify role comments with `bd comments <bead-id>` or `bd comments <bead-id> --json`.

## Secret Handling

Never put API keys, tokens, cookies, credentials, or authorization headers in:

- repo files
- Beads descriptions
- Beads comments
- OpenCode prompts
- logs
- screenshots
- docs

Z.AI must use `ZAI_API_KEY` from the user/process environment. MiniMax must use `MINIMAX_API_KEY` from the user/process environment. The wrapper reports only whether a key is present; it never prints the value.

For safe setup, run:

```powershell
.\.orchestrated-agents\bin\oa.cmd key-setup zai
```

The command prompts twice, stores `ZAI_API_KEY` in the user environment, and does not print the key. Use a rotated key when any previous key has been pasted into chat, comments, logs, screenshots, or docs. To switch back to MiniMax, run `.\.orchestrated-agents\bin\oa.cmd key-setup minimax` and set `OA_MODEL_SPEC=minimax/MiniMax-M3`.

To remove user-scoped provider variables, run:

```powershell
.\.orchestrated-agents\bin\oa.cmd key-clear zai
.\.orchestrated-agents\bin\oa.cmd key-clear minimax
```

## Evaluation Opportunity

The first real evaluation should be low-risk and useful. A good initial evaluation bead is:

> Use the orchestrated workflow to review and harden the `.orchestrated-agents/` package itself.

This exercises:

- role selection
- human-input gate
- maker-only edits
- adversarial review
- QA evidence
- security/privacy review
- documentation review
- workflow-scout improvement creation

It also improves the framework before using it on SocialHub product code.

## Authoritative Documents

Canonical framework docs are co-located under `.orchestrated-agents/docs/` (this directory) and `.orchestrated-agents/workflows/`. Beads comments are work records; the canonical deliverable for each evaluation lives as a file in this tree.

Current canonical docs:

- `.orchestrated-agents/WORKFLOW.md` -- **top-level shared reference** for the current operating shape, active workflow exceptions, role registry, role authority, model-effort policy, SDLC stages, status/dependency policy, comment format, watchdog/manual-fallback rule, provider/model switching, and mandatory update rule. Update this file whenever a workflow, SDLC gate, role, status rule, provider/model policy, watchdog/manual-fallback rule, or comment rule changes.
- `.orchestrated-agents/docs/CONTEXT.md` -- this file. Framework context, operating model, role split, permission precedence, secret handling, evaluation opportunity.
- `.orchestrated-agents/docs/beadbox-windows.md` -- BeadBox setup notes for Windows.
- `.orchestrated-agents/docs/bd-cli-quirks.md` -- bd CLI quirks and operator-facing failure modes. Sections: parallel-create race condition (WFSC-bead-5 / socialhub-v8g.22.43), approval-comment accuracy smoke test (WFSC-bead-6 / socialhub-v8g.22.44), and comment-discipline self-check smoke test (WFSC-bead-6 / socialhub-v8g.22.44 C4 follow-up). The approval-comment smoke test re-runs `bd show <id> --json` against every bead ID cited in a target comment and flags mismatches; the comment-discipline smoke test runs the linter against the six historical probe-comment patterns and a known-good compliant control case.
- `.orchestrated-agents/docs/coverage-matrix-v3.md` -- **SDLC and engineering-role coverage matrix** (bead `socialhub-v8g.22.1`). Canonical deliverable for the full SDLC and engineering-role coverage evaluation. Maps current `.orchestrated-agents/` coverage against ISO/IEC/IEEE 12207:2017, NIST SSDF SP 800-218 v1.1, OWASP SAMM v2, ISO/IEC 25010:2023, IEEE SWEBOK Guide V4.0, SFIA 9, Google SRE Book Part II, Scrum Guide 2020, plus the internal `.orchestrated-agents/` files. Stable gap IDs: `GAP-A-NNN` through `GAP-N-NNN`. Workflow Scout uses this file as the source of truth for filing follow-up beads; the bead comment thread is the audit history only.

For the current authoritative-workflow layer (rule docs that govern how beads are run), see `.orchestrated-agents/workflows/`:

- `.orchestrated-agents/workflows/bead-protocol.md` -- comment format, mandatory first actions, **No Test Comments On Real Beads**, **Comment-Discipline Self-Check** (mandatory pre-write lint via `.orchestrated-agents/bin/test-comment-check.ps1`), **Role Run Watchdog and Manual Exceptions**, **Approval-Comment Accuracy** rule (evidence verified at write-time via `bd show` / `bd list` citation), **Known Audit-Trail Violations** (permanent record of probe-comment violations on rule-codifying beads), forbidden shortcuts.
- `.orchestrated-agents/workflows/sdlc-gates.md` -- 20 SDLC gates, per-bead applicability matrix.
- `.orchestrated-agents/workflows/adversarial-convergence.md` -- convergence rule, evidence verifiable at write-time, approval rule (extends to require `bd show` citation for on-disk-state claims).
- `.orchestrated-agents/workflows/human-input.md` -- human-input protocol, decision packet format.

For the executable enforcement layer (scripts invoked by the wrapper and by the smoke tests), see `.orchestrated-agents/bin/`:

- `.orchestrated-agents/bin/oa.cmd` / `oa.ps1` -- orchestration wrapper. Canonicalizes role names, runs `Test-WrapperSelf`, sets `BEADS_ACTOR` + `OA_TARGET_BEAD` + `OA_ROLE_NAME`, then spawns a monitored `opencode run` with a per-role prompt that includes the Comment-Discipline Self-Check instruction and the no-test-comments reminder. Role-run runtime evidence is written under `.orchestrated-agents/logs/role-runs/` (ignored by git) as meta/stdout/stderr/result/timeout files.
- `.orchestrated-agents/bin/test-comment-check.ps1` -- the deterministic pre-write linter. Rejects probe comments, missing Markdown structure, and short/sparse comments. Exit code 0 means proceed with `bd comment`; exit code 1 means revise and re-validate. See bead-protocol.md Comment-Discipline Self-Check section for invocation patterns and bd-cli-quirks.md Comment-Discipline Self-Check Smoke Test for the canonical detector.

For role charters (what each role does and does not do), see `.orchestrated-agents/roles/`.
