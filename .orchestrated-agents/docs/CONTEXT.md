# Orchestrated Agents Context

## What We Are Building

This repository is getting a portable, Beads-centered orchestration system for AI software delivery work.

The goal is not to make Codex do every SDLC step. The goal is to make Codex act as a small orchestrator that invokes MiniMax-M3 roles against a bead ID, while MiniMax roles perform the actual role work: role selection, requirements analysis, design critique, implementation, QA, security review, documentation review, release/reliability review, and workflow improvement.

Beads is the durable control plane. BeadBox is the visual dashboard for the same Beads data. OpenCode is the execution surface for MiniMax-M3.

## Operating Model

Codex should do the least possible task work:

- create or select the bead
- invoke the correct orchestration command
- report when a bead needs human input
- repair local infrastructure only when MiniMax roles cannot reasonably repair it

MiniMax-M3 performs the work through different role hats. Every role is the same model, but with a different role prompt, permission profile, and responsibility.

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

**Required Next Action:** <next role/action, or none if complete>
```

The wrapper does NOT assign the bead or add comments at invocation time. The wrapper only sets `BEADS_ACTOR`, `OA_TARGET_BEAD`, and `OA_ROLE_NAME`, then spawns `opencode run`. The invoked MiniMax role is solely responsible for assigning itself and writing every comment on the bead. This is by design - audit-trail integrity requires the role, not the wrapper, to write its own work record.

## Role Selection

Every bead starts with a Role Selector debate. The Role Selector must simulate disagreement between at least:

- SDLC Process Architect
- Requirements Skeptic
- QA Strategist
- Security/Risk Architect

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

Maker roles are the only roles allowed to change files. In this framework, the general maker is `Maker Engineer`; workflow/control-plane changes use `Process Engineer`.

Adversarial roles do not edit files. They inspect, run allowed checks, critique, and comment on the bead. They approve only when Maker Engineer fixes the finding or provides evidence that the finding is invalid.

## Workflow Improvement

Whenever any role finds a process flaw, SDLC miss, role gap, weak evidence standard, bad comment discipline, or workflow discrepancy, Workflow Scout creates a new workflow-improvement bead.

That improvement bead goes through the same lifecycle:

1. role selection
2. human-input gate
3. maker implementation by Process Engineer
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

The Process Engineer uses:

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

- provider: `minimax`
- model: `MiniMax-M3`
- MiniMax API base: `https://api.minimax.io/v1`
- secret source: `MINIMAX_API_KEY`
- role agents named `oa-*`
- role invocation effort: `--variant max --thinking` through the wrapper

The wrapper lives at:

```text
.orchestrated-agents/bin/oa.cmd
.orchestrated-agents/bin/oa.ps1
```

Useful commands:

```powershell
.\.orchestrated-agents\bin\oa.cmd status
.\.orchestrated-agents\bin\oa.cmd key-setup
.\.orchestrated-agents\bin\oa.cmd key-clear
.\.orchestrated-agents\bin\oa.cmd run <bead-id> <role-name>
```

The wrapper prefers `bd.exe`, `bd.cmd`, and `opencode.cmd` on Windows so PowerShell execution-policy shims do not block it. The wrapper does not write Beads comments on behalf of roles; it sets `BEADS_ACTOR`, `OA_TARGET_BEAD`, and `OA_ROLE_NAME`, then the invoked MiniMax role must assign and comment for itself.

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

MiniMax must use `MINIMAX_API_KEY` from the user/process environment. The wrapper reports only whether the key is present; it never prints the value.

For safe setup, run:

```powershell
.\.orchestrated-agents\bin\oa.cmd key-setup
```

The command prompts twice, stores `MINIMAX_API_KEY` in the user environment, and does not print the key. Use a rotated key when any previous key has been pasted into chat, comments, logs, screenshots, or docs. To remove user-scoped MiniMax variables, run:

```powershell
.\.orchestrated-agents\bin\oa.cmd key-clear
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

- `.orchestrated-agents/docs/CONTEXT.md` -- this file. Framework context, operating model, role split, permission precedence, secret handling, evaluation opportunity.
- `.orchestrated-agents/docs/beadbox-windows.md` -- BeadBox setup notes for Windows.
- `.orchestrated-agents/docs/coverage-matrix-v3.md` -- **SDLC and engineering-role coverage matrix** (bead `socialhub-v8g.22.1`). Canonical deliverable for the full SDLC and engineering-role coverage evaluation. Maps current `.orchestrated-agents/` coverage against ISO/IEC/IEEE 12207:2017, NIST SSDF SP 800-218 v1.1, OWASP SAMM v2, ISO/IEC 25010:2023, IEEE SWEBOK Guide V4.0, SFIA 9, Google SRE Book Part II, Scrum Guide 2020, plus the internal `.orchestrated-agents/` files. Stable gap IDs: `GAP-A-NNN` through `GAP-N-NNN`. Workflow Scout uses this file as the source of truth for filing follow-up beads; the bead comment thread is the audit history only.

For the current authoritative-workflow layer (rule docs that govern how beads are run), see `.orchestrated-agents/workflows/`:

- `.orchestrated-agents/workflows/bead-protocol.md` -- comment format, mandatory first actions, forbidden shortcuts.
- `.orchestrated-agents/workflows/sdlc-gates.md` -- 20 SDLC gates, per-bead applicability matrix.
- `.orchestrated-agents/workflows/adversarial-convergence.md` -- convergence rule, evidence standard, approval rule.
- `.orchestrated-agents/workflows/human-input.md` -- human-input protocol, decision packet format.

For role charters (what each role does and does not do), see `.orchestrated-agents/roles/`.
