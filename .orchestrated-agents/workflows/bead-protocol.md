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

See also: [Comment-Discipline Self-Check](#comment-discipline-self-check-mandatory-before-bd-comment) (mandatory pre-write lint), [Known Audit-Trail Violations](#known-audit-trail-violations-permanent-record) (documented violations on rule-codifying beads).

## Comment-Discipline Self-Check (mandatory before bd comment)

Before posting any comment to a real bead via `bd comment`, the invoking
role MUST run the comment text through the
`.orchestrated-agents/bin/test-comment-check.ps1` linter and confirm
exit code is `0`. If the linter exits non-zero, the comment MUST be
revised (or, if the test was unavoidable, posted with a
`claim pending verification: <reason>` Status note per the
Approval-Comment Accuracy section) until the linter accepts it.

### Why a self-check, not just a prose rule

The prose rule "Do not write probe comments" was insufficient: even
the Adversarial Reviewer on WFSC-bead-6 (the bead that codified this
self-check) posted four probe comments while validating PowerShell
escape sequences, and Role Selector posted two probe comments while
validating inline-string vs here-string support. The prose rule was
on the page; the LLM still violated it under tooling pressure. A
deterministic linter the role MUST self-invoke before posting makes
the rule checkable rather than a matter of memory: a role that skips
the linter cannot claim compliance, and an auditor can detect the
skip from the absence of a linter run. The linter is NOT a
wrapper-level gate -- the current architecture does not intercept
`bd comment` tool calls inside the agent subprocess, so invocation
remains the role's responsibility. True wrapper-level enforcement (a
pre-tool hook or shim that vetoes non-conforming comments) is
deferred to a follow-up bead; the residual risk is that a role under
tooling pressure may still post a probe comment without running the
linter, exactly as happened on this bead (see Known Audit-Trail
Violations).

### What the linter checks

The linter at `.orchestrated-agents/bin/test-comment-check.ps1`
flags any of the following:

1. **Required Markdown structure missing.** The text MUST contain:
   - `### Commentor:` header (line-prefix match)
   - `**Status:**` field (line-prefix match)
   - `**Findings:**` field (line-prefix match)
   - `**Required Next Action:**` field (line-prefix match)
2. **Explicit probe phrases.** Case-insensitive whole-word match
   against any of: `test probe`, `test line`,
   `hello world`, `lineA`, `lineB`, `lineC`, `scratch text`,
   `placeholder text`, `formatting experiment`. The historical probe
   `test with <id> and <pattern>` is no longer matched by a bare
   two-word phrase (it false-positived on legitimate review prose);
   it is still caught by the structure, length, and density checks.
3. **Literal `lineN` probe lines.** Lines matching `^line\d+\s*$`.
4. **`Test line N` probe lines.** Lines matching `^\s*test\s+line\s+\d+\s*$`.
5. **Short comments.** Comment text shorter than 200 characters.
6. **Sparse comments.** Two or fewer non-blank lines and shorter
   than 300 characters.

Violations 5 and 6 catch the category of probes that are neither
explicit-phrase matches nor literal line patterns but are still
clearly not meaningful Markdown work records. A real comment is
always longer and denser.

**Backtick-stripping exemption.** Before checking for probe phrases
(violations 2-4), the linter strips out backtick-delimited content:
code spans (single-backtick pairs `like this`) and code fences
(triple-backtick blocks). This exempts legitimate documentation
comments that reference probe patterns as literal examples inside
backticks (e.g., a table row showing `test probe` or `lineA`). Probe
violations are NEVER inside backticks; they are always raw prose.
The Markdown-structure check (violation 1) and the length/density
checks (violations 5-6) still apply to the full text.

### Invocation

All flags use single-dash PowerShell syntax. The `--` (double-dash)
prefix MUST NOT be used: in PowerShell 5.1, `--` is the stop-parsing
token, so `--text`, `--bead-id`, etc. do not bind to parameters.
Hyphenated names (`-bead-id`, `-comment-id`) bind via declared
`Alias` attributes on the camelCase parameters.

```powershell
# From a variable (after composing the comment text):
.\.orchestrated-agents\bin\test-comment-check.ps1 `
  -text $comment `
  -bead-id <bead-id> `
  -author "<RoleName>"
# Exit code 0 -> proceed with bd comment.
# Exit code 1 -> read the violations JSON, fix the comment, re-run.

# From a here-string (PREFERRED for long comments; works under the
# opencode permission model for every comment-posting role because
# the pipeline emits the text directly into the linter with no
# separate Get-Content subcommand that would need its own allow):
@'
### Commentor: Workflow Engineer
...full comment text...
'@ | .\.orchestrated-agents\bin\test-comment-check.ps1 -stdin `
  -bead-id <bead-id> -author "<RoleName>"

# From a file (NOT runnable by most roles; documented for completeness).
# This Get-Content pipe shape is permission-denied for the 9
# comment-posting roles whose bash block is `"*": "deny"` because
# `Get-Content -Raw <arbitrary path>` does not match the
# `*test-comment-check*` command-pattern allow. Only oa-maker-engineer
# (which carries `"*": "allow"`) can run this form. Prefer the
# here-string pipe above for long comments.
Get-Content -Raw .orchestrated-agents\logs\<bead-id>-<role>-<step>.md |
  .\.orchestrated-agents\bin\test-comment-check.ps1 -stdin `
  -bead-id <bead-id> -author "<RoleName>"
```

The linter emits a JSON object on stdout with the validation result,
violations, timestamp, and bead/author context. Exit code 0 means
`valid: true` and the comment may be posted. Exit code 1 means
`valid: false` with at least one violation listed; the comment MUST
be revised.

### Out-of-scope / known false-positive risks

- The linter uses PowerShell 5.1 regex which is .NET-style. Patterns
  are POSIX-compatible (no negative-lookahead used). Future
  porting to bash/ripgrep for non-Windows hosts should keep the
  same probe list and length/density thresholds.
- A legitimate short comment (e.g., a single-line "Approved" sign-off
  in a future workflow) WILL be flagged by violation 5. If the role
  has a justified short-comment use case, the role should call this
  out in the Status field as `claim pending verification: short
  comment justified per <reason>` and post anyway, OR amend the
  linter to allowlist a short-comment pattern. The latter is the
  preferred remediation and goes through the standard change-control
  path.

### Workflow integration

The wrapper at `.orchestrated-agents/bin/oa.ps1` includes the
self-check in the role-invocation prompt so every invoked role is
told to run the linter before posting. The role-permission blocks in
`opencode.json` grant a single narrow command-pattern allow,
`"*test-comment-check*": "allow"`, to the nine comment-posting roles.
This lets a role run any command whose string contains
`test-comment-check`; it does NOT grant general `powershell.exe`
execution. Consequently the documented `Get-Content -Raw <file> |
linter` pipe path is not runnable by most roles (see the Invocation
examples above); the here-string pipe is the portable form. This
matches the existing `bd **` / `bd.cmd **` command-pattern permission
model rather than granting a shell.

## Role Run Watchdog and Manual Exceptions

The wrapper monitors every `oa.cmd run` child process and writes local
runtime evidence under `.orchestrated-agents/logs/role-runs/` (ignored
by git). This is a workflow-control record, not a Beads comment. The
role still owns its own Beads comments.

### Runtime artifacts

| Artifact | Meaning |
| --- | --- |
| `*.meta.json` | bead id, role, agent, model, thinking variant, thresholds, stdout/stderr paths |
| `*.stdout.log` | child process stdout |
| `*.stderr.log` | child process stderr |
| `*.result.json` | exit code and output-byte counts when the child exits |
| `*.timeout.json` | timeout timestamp and stopped-role metadata when the wrapper kills a stale run |

### Thresholds

| Variable | Default | Rule |
| --- | --- | --- |
| `OA_ROLE_RUN_POLL_SECONDS` | `30` | wrapper poll interval |
| `OA_ROLE_RUN_STALE_SECONDS` | `300` | emit warning after five minutes without log output |
| `OA_ROLE_RUN_TIMEOUT_SECONDS` | `720` | hard-stop a single role invocation |
| `OA_ROLE_RUN_LOG_DIR` | `.orchestrated-agents/logs/role-runs` | local ignored runtime-evidence directory |

### Beads state after a role-run failure

| Failure | Required Beads Handling |
| --- | --- |
| role exits non-zero | add structured failure comment; decide whether to reopen, retry, or block |
| role times out | stop stale child process; add structured failure comment; create/link workflow-flaw bead if repeated |
| role produces wrong output | do not treat as reviewer approval; comment the mismatch and retry with narrower prompt or block |
| reviewer cannot run required evidence | record limitation; use maker/wrapper/orchestrator evidence only if reviewer explicitly accepts the boundary |

### Manual orchestrator exception

Codex-Orchestrator may patch files only after a role-run failure or
permission/tooling barrier makes the role path impossible. The
exception MUST be visible in Beads:

| Before patch | After patch |
| --- | --- |
| stop stale processes, capture log paths, and identify failed role attempts | comment as `Codex-Orchestrator`, not as the failed role |
| keep the edit minimal and scoped to infrastructure/control-plane need | create/link a workflow-flaw bead when the pattern can recur |
| do not bypass maker roles for normal product work | require downstream adversarial review before closing dependent work |

### See also

- `.orchestrated-agents/bin/test-comment-check.ps1` -- the linter.
- `.orchestrated-agents/docs/bd-cli-quirks.md` Comment-Discipline
  Self-Check Smoke Test -- detector that proves the linter catches
  the actual probe patterns that violated this rule on
  socialhub-v8g.22.44.
- `.orchestrated-agents/workflows/bead-protocol.md` Known
  Audit-Trail Violations section -- documents the six probe comments
  on socialhub-v8g.22.44 that motivated this section.

## Mandatory Comment Format

Every role comment must be valid Markdown and follow this shape:

```markdown
### Commentor: <RoleName>

**Step/Subtask:** <specific step>

**Status:** <In Progress | Needs Fix | Blocked | Evidence Accepted | Approved | Escalate To Human>

**Findings:** <facts, critique, or work completed>

**Evidence:** <commands, files, sources, tests, logs, reasoning>

**Verified Evidence:** <include when the comment claims an on-disk state; see Approval-Comment Accuracy section below for the rule and citation format>

- `bd show <id> --json at <ISO-timestamp from updated_at field>` -> <output slice>
- `bd list --json | rg <pattern> at <ISO-timestamp>` -> <count> matches: <sample slice>

**Required Next Action:** <next role/action, or none if complete>
```

The `**Verified Evidence:**` subsection is **required** whenever the comment
asserts an on-disk state (bead ID mapping, status transition, ownership,
parent/child, priority, label, dependency). When the comment makes no
on-disk-state claim (e.g., pure design critique, open question to a peer),
the `**Verified Evidence:**` subsection may be omitted. The decision rule
is documented in the Approval-Comment Accuracy section below.

## Approval-Comment Accuracy

A comment that asserts an on-disk state (bead ID mapping, status transition,
ownership, parent/child, priority, label, dependency) MUST verify that state
with `bd show` or `bd list` BEFORE the comment is posted, and the Evidence
section MUST cite the verifiable output.

This rule extends the Mandatory Comment Format section above. Where that
section requires "evidence" in every comment, this section requires the
evidence to be **verified at write-time**, not merely cited.

### Claim shapes covered by this rule

A "future or current on-disk state" claim includes any of the following
shapes (the list is itself non-exhaustive; any assertion that claims
on-disk state is covered):

- per-bead ID mapping (e.g., "filed socialhub-v8g.22.7 = GAP-K-001 Frontend")
- status transition (e.g., "moved to in_progress", "closed socialhub-v8g.22.5")
- owner / assignee change (e.g., "assigned to QA Strategist")
- parent / child relationship (e.g., "child of socialhub-v8g.22")
- priority or label set (e.g., "priority P1", "label `blocker`")
- dependency (e.g., "blocked by socialhub-v8g.22.43")
- coverage-matrix row matched to a bead ID (e.g., "GAP-K-001 -> socialhub-v8g.22.6")
- any "filed / created / closed / merged / shipped / renamed / updated / implemented / tested / deployed / rolled back / verified / in CI" assertion
- any other assertion of on-disk state not enumerated above

If a comment contains any of these claim shapes, the rule applies.

### Required pre-write verification

Before posting a comment that contains one of the claim shapes above, the
role MUST:

1. Run `bd show <id> --json` (single-bead) and capture the relevant slice
   (title, status, priority, assignee, labels, parent, updated_at).
2. For multi-bead / batch claims, run `bd list --json | rg <pattern>`
   filtered by parent or stable-ID prefix, then run `bd show <id> --json`
   for each individual bead cited in the comment.
3. Confirm the cited field matches what the comment is about to assert.

The Evidence section MUST include:

- the exact `bd show <id> --json` or `bd list --json | rg <pattern>`
  output slice (cited fields must be a literal copy of the JSON field
  values, not a paraphrase), AND
- the `updated_at` field from that output, used as the audit timestamp.
  This is the **mandatory** timestamp source: the Beads DB owns the
  timestamp so a future auditor can detect stale citations by diffing
  the cited `updated_at` against a fresh `bd show <id> --json` value.

The Evidence section MAY also include:

- a short note of when the role ran the command in wall-clock time
  (ISO-8601). This is OPTIONAL context and is NOT the auditable
  timestamp; never cite wall-clock time as proof of the on-disk state.
  If both wall-clock and `updated_at` are cited, the `updated_at` is
  authoritative and the wall-clock note must be clearly labeled
  "wall-clock (informational)" so an auditor cannot mistake it for the
  audit timestamp.

### Citation format

```
**Verified Evidence:**
- `bd show <id> --json at <ISO-timestamp from updated_at field>` -> <output slice>
- `bd list --json | rg <pattern> at <ISO-timestamp>` -> <count> matches: <sample slice>
```

Example:

```
**Verified Evidence:**
- `bd show socialhub-v8g.22.7 --json at 2026-07-13T11:17:29Z` -> `{ "id": "socialhub-v8g.22.7", "title": "GAP-K-001 Frontend Engineer", "status": "open", "priority": 1, "updated_at": "2026-07-13T11:17:29Z" }`
- `bd list --json | rg "socialhub-v8g.22\\.[6-9]|10" at 2026-07-13T11:17:29Z` -> 5 matches
```

### Pending-verification escape hatch

If the role cannot run `bd show` before writing the comment (e.g., the bead
does not exist yet due to a parallel-create race, a transient CLI failure,
or the role is part of a multi-step action whose next step is the actual
creation), the role MUST:

1. NOT assert the fact. The comment MUST NOT claim an on-disk state that
   has not been verified.
2. Set the Status field to one of:
   - `In Progress` with a note `claim pending verification: <reason>`
   - `Blocked` if the missing verification blocks downstream work
3. Set the Required Next Action to name the verification step that must
   happen in the same role turn (e.g., "re-run `bd show <id> --json` and
   post a follow-up comment that cites the matching output").

A follow-up comment in the same role turn that confirms the cited output is
acceptable and is treated as the canonical record. A claim that is left
pending across two separate role turns is a violation of this rule.

### Worked example

WFSC-bead-6 was filed because a Workflow Engineer filing-announce comment on
socialhub-v8g.22.1 (2026-07-13 10:47:33Z) embedded a per-bead ID mapping
table that did not match on-disk state at write-time. The closing summary
at 11:02:21Z had to correct the table. With this rule, the original comment
would have been required to:

- run `bd show <id> --json` for each cited bead and include the slice in
  Evidence, OR
- declare `claim pending verification: parallel-create race, \`bd show\`
  returned default-prefix IDs` and post the mapping table only after
  re-verifying after the corrective `bd rename` invocations.

The audit trail would then have one consistent record instead of two
conflicting ones. The QA Strategist's smoke-test in
`.orchestrated-agents/docs/bd-cli-quirks.md` Approval-Comment Accuracy
Smoke Test section is the canonical detector for this failure mode.

**Compliant comment example** (positive template, copy-pasteable):

```markdown
### Commentor: Workflow Engineer

**Step/Subtask:** Filing GAP-K-001 follow-up bead

**Status:** Evidence Accepted

**Findings:** GAP-K-001 Frontend filed as socialhub-v8g.22.7, status open,
priority 1, parent socialhub-v8g.22. Verified via `bd show --json` before
posting this comment.

**Evidence:** sequential `bd create --parent socialhub-v8g.22 --priority 1`
invocation followed by `bd show socialhub-v8g.22.7 --json` for verification.

**Verified Evidence:**

- `bd show socialhub-v8g.22.7 --json at 2026-07-13T11:17:29Z` -> slice:
  `{ "id": "socialhub-v8g.22.7", "title": "GAP-K-001: Frontend Engineer specialist hat (Next.js 16 / fb_dash/ stack-tagged edits)", "status": "open", "priority": 1, "updated_at": "2026-07-13T11:17:29Z" }`

**Required Next Action:** Hand off to Adversarial Reviewer.
```

Notice: the `**Verified Evidence:**` subsection cites the slice with the
`updated_at` field as the audit timestamp (2026-07-13T11:17:29Z). The
wall-clock time the role ran the command is intentionally NOT cited,
because `updated_at` is the auditable timestamp. A future auditor can
diff this citation against a fresh `bd show socialhub-v8g.22.7 --json`
to detect staleness or post-hoc edits.

### Auditability

A future auditor verifying a cited `bd show --json` output should diff it
against a fresh `bd show <id> --json` to detect stale citations. If the
`updated_at` field in the cited output is older than the current
`updated_at`, the citation is stale and the comment must be re-verified
before approval. This is the Security/Risk Architect debate-perspective
mitigation against post-hoc Evidence-block edits: the mandatory timestamp is sourced from
the Beads DB, not the human's wall clock, so a future auditor can detect
tampering by comparing the cited `updated_at` against the live value.
Wall-clock time, when cited, is informational context only and is not
treated as proof of on-disk state.

### References

- socialhub-v8g.22.1 Workflow Engineer filing-announce comment at
  2026-07-13 10:47:33Z (the in-violation comment).
- socialhub-v8g.22.1 Workflow Engineer closing summary at 2026-07-13
  11:02:21Z (the corrective comment).
- `.orchestrated-agents/workflows/adversarial-convergence.md` Approval
  Rule section (this rule's higher-level extension).
- `.orchestrated-agents/templates/comment.md` Verified Evidence
  subsection (template that mirrors this rule).
- `.orchestrated-agents/docs/bd-cli-quirks.md` Approval-Comment Accuracy
  Smoke Test section (canonical detector).
- `.orchestrated-agents/docs/bd-cli-quirks.md` Comment-Discipline
  Self-Check Smoke Test section (canonical detector for probe-comment
  violations).
- `.orchestrated-agents/bin/test-comment-check.ps1` (the deterministic
  pre-write linter that enforces the Comment-Discipline Self-Check).
- `.orchestrated-agents/docs/coverage-matrix-v3.md` (the canonical
  source-of-truth for GAP-K/GAP-L stable IDs).
- WFSC-bead-5 socialhub-v8g.22.43 (parallel-create race; the root cause
  amplifier for this rule).
- WFSC-bead-6 socialhub-v8g.22.44 (this bead; the audit trail contains
  six probe-comment violations that motivated the
  [Comment-Discipline Self-Check](#comment-discipline-self-check-mandatory-before-bd-comment)
  and [Known Audit-Trail Violations](#known-audit-trail-violations-permanent-record)
  sections; see those sections for the canonical record).

## Known Audit-Trail Violations (Permanent Record)

The bd CLI has no comment-delete primitive (verified by `bd comments --help`),
so violations of the rules in this document are PERMANENT on the audit trail
of the bead on which they occurred. Future readers must reconcile by reading
the corrective comments that follow.

The canonical record of every known violation is preserved here so that:

- the violation is NOT silently forgotten;
- future roles can recognize the failure pattern when they see it in a bead;
- the rule codification includes an honest record of the failures that
  motivated the rule.

### Violations on socialhub-v8g.22.44 (WFSC-bead-6: Approval-comment accuracy gate)

This bead codifies the Approval-Comment Accuracy rule. It is itself the
bead on which six violations of the [No Test Comments On Real
Beads](#no-test-comments-on-real-beads) rule occurred:

| # | Comment ID | Author | Timestamp (UTC) | Probed content | Violation category |
| - | --- | --- | --- | --- | --- |
| 1 | `019f5b33` | Role Selector | 2026-07-13T11:19:16Z | `test probe` | probe phrase (`test probe`) |
| 2 | `019f5b34` | Role Selector | 2026-07-13T11:19:40Z | `line1\nline2\nline3` | literal `lineN` lines + missing structure |
| 3 | `019f5b5d` | Adversarial Reviewer | 2026-07-13T12:05:14Z | `Test line 1\nTest line 2\nTest line 3` | `Test line N` pattern + probe phrase |
| 4 | `019f5b5f` | Adversarial Reviewer | 2026-07-13T12:06:57Z | `hello world` | probe phrase + length < 200 chars |
| 5 | `019f5b60-0214` | Adversarial Reviewer | 2026-07-13T12:07:26Z | `test with <id> and <pattern>` | probe phrase (`test with`) |
| 6 | `019f5b60-7488` | Adversarial Reviewer | 2026-07-13T12:07:56Z | `lineA`nlineB`nlineC with <id> literal` | probe phrases (`lineA`, `lineB`, `lineC`) + missing structure |

All six comments are visible in the bead's audit trail and are not
deletable. The rule codified in this document was prompted by these
specific violations; the [Comment-Discipline Self-Check](#comment-discipline-self-check-mandatory-before-bd-comment)
linter (`.orchestrated-agents/bin/test-comment-check.ps1`) detects and
rejects all six patterns with exit code 1.

**Self-disclosure provenance:** Comments 3-6 were posted by Adversarial
Reviewer on 2026-07-13 between 12:05Z and 12:07Z while validating PowerShell
backtick-n and `--%` stop-parsing behavior for the C4 follow-up. The
Adversarial Reviewer disclosed these violations transparently in the
2026-07-13T12:09Z review comment. Comments 1-2 were posted by Role Selector
on 2026-07-13 at 11:19Z while validating `bd comment` inline-string vs
here-string support prior to the role-selection debate.

**Mitigation that the violation motivates:** The wrapper prompt template
at `.orchestrated-agents/bin/oa.ps1` Run-Role prompt section now
explicitly instructs every invoked role to run the comment text through
`.orchestrated-agents/bin/test-comment-check.ps1` and only proceed if
exit code is 0. The linter invocation remains the role's
responsibility (it is a self-check, not a wrapper-level gate): the
current architecture does not intercept `bd comment` tool calls inside
the agent subprocess, so the absence of a linter run is detectable by
an auditor but cannot be programmatically vetoed. True wrapper-level
interception (a pre-tool hook or shim) is deferred to a follow-up
bead. The residual risk -- a role under tooling pressure posting a
probe comment without running the linter -- is documented in the
Known Audit-Trail Violations table above.

**Future audit-trail guidance:** When a future auditor reviews any bead
that contains a similar probe-comment pattern, the auditor SHOULD:

1. Confirm the comment is a violation per the rules in this document.
2. Note the comment ID in the bead's Known Audit-Trail Violations table.
3. Confirm the corrective comment (which must follow in the same bead)
   applies the [Comment-Discipline Self-Check](#comment-discipline-self-check-mandatory-before-bd-comment)
   or applies the pending-verification escape hatch from the
   Approval-Comment Accuracy section.
4. Do not attempt to "clean" the audit trail; bd has no comment-delete
   primitive and retroactive edits are themselves a violation per the
   Approval-Comment Accuracy Auditability section.

### Author-Truncation Violation on socialhub-v8g.22.44 (ORCH-REQ-008)

This is a SEPARATE class of audit-trail violation from the probe
comments above: a role-name quoting split that corrupted the bd
comment `author` field rather than the comment body. It is recorded
here because ORCH-REQ-008 / socialhub-v8g.24.8 AC6 requires the
existing mismatch to be documented as a known historical violation,
not silently normalized.

| # | Comment ID | Bead | Timestamp (UTC) | author field | Comment body Commentor | Class |
| - | --- | --- | --- | --- | --- | --- |
| 1 | `019f5bd7-f15c-7cee-b4f9-5d616fc46de5` | socialhub-v8g.22.44 | 2026-07-13T14:18:27Z | `Process` | `Process Engineer` | role-name quoting split -> truncated author |

At the time of this comment the role was still named **Process
Engineer** (renamed to **Workflow Engineer** later under ORCH-REQ-004
/ socialhub-v8g.24.4). The space-split truncated the name to its
first word, which became the `BEADS_ACTOR` and the bd comment
`author`. The bead description for socialhub-v8g.24.8 contains a
minor anachronism (it says the body read `Commentor: Workflow
Engineer`); the verified on-disk record (re-confirmed via
`bd show socialhub-v8g.22.44 --json`) shows `author: "Process"` with
body `### Commentor: Process Engineer`. The corrective code change
(`oa.ps1` `Resolve-Role` canonicalization plus fail-closed guard) is
documented in
[`.orchestrated-agents/docs/bd-cli-quirks.md`](../docs/bd-cli-quirks.md)
"Role-Name Split / Author Truncation (ORCH-REQ-008 / socialhub-v8g.24.8)"
section, which is the canonical detailed record. Do not conflate this
with the mutable-field migration audit in socialhub-v8g.24.9, which
is a distinct concern.

## Actor Names

Use the role as the actor/commentor, for example. This list is the canonical
13-role taxonomy, ordered to match `Get-RequiredRoleNames` in
`.orchestrated-agents/bin/oa.ps1`; it must stay in sync with the
`opencode.json` agent registry and the `WORKFLOW.md` Role Registry.

- Role Selector
- Human Question Framer
- Researcher
- Planner
- Architect
- Maker Engineer
- Workflow Engineer
- Adversarial Reviewer
- QA Strategist
- Security Privacy Reviewer
- Release SRE Reviewer
- Documentation Reviewer
- Workflow Scout

Names such as "SDLC Process Architect", "Requirements Skeptic", and
"Security/Risk Architect" are debate **perspectives** the Role Selector
simulates, not roles; see `.orchestrated-agents/roles/role-selector.md`
Required Debate section. Do not use a perspective name as an actor/commentor.

## Forbidden Shortcuts

- Do not use local TODO files as the source of truth.
- Do not mark a bead complete because one role is satisfied.
- Do not approve without evidence.
- Do not skip SDLC gates silently.
- Do not put secrets in comments.
- Do not ask the human until role debate has failed to converge with evidence.
- Do not post a `bd comment` invocation whose text fails the
  [Comment-Discipline Self-Check](#comment-discipline-self-check-mandatory-before-bd-comment)
  unless the comment carries `claim pending verification: short comment
  justified per <reason>` in the Status field.
