# bd CLI Quirks

Operational notes for the `bd` (Beads) CLI on this workstation. Modeled on
`.orchestrated-agents/docs/beadbox-windows.md`. Each quirk documents a
failure mode, the recommended pattern, and a sanity-check command the
filing role runs after the fact.

**Authoring scope note (2026-07-13).** This file was originally planned
by WFSC-bead-5 / socialhub-v8g.22.43 (parallel-create race documentation)
and WFSC-bead-6 / socialhub-v8g.22.44 (approval-comment accuracy smoke
test). Both sections are co-authored under WFSC-bead-6 because
WFSC-bead-5 is currently OPEN with no assignee, and WFSC-bead-6's AC
requires the smoke-test step to exist in this file. WFSC-bead-5's owner
can amend or supersede the parallel-race section without affecting the
smoke-test section.

## Parallel-Create Race Condition (parent-context prefix / priority loss)

**Failure mode.** `bd create --parent <parent-id>` honors parent-child
context for prefix inference and label inheritance when run sequentially.
In PARALLEL invocations the parent-lookup step loses context (race
condition between parallel bd-engine processes resolving the parent
prefix), falling back to the database default prefix (random short hash)
and default priority (P2).

The race is SILENT: `bd` does not warn; the issue only surfaces when
`bd list --json` shows wrong prefixes (e.g., `socialhub-cai` instead of
the expected `socialhub-v8g.22.7`).

**Evidence (socialhub-v8g.22.1, 2026-07-13).** Workflow Engineer filed 37
GAP-K/GAP-L follow-up beads per Codex-Orchestrator Option C. The first
batch was 5 parallel `bd create` invocations. 4 of 5 beads got
auto-generated short-prefix IDs (`socialhub-cai`, `socialhub-khd`,
`socialhub-771`, `socialhub-2bo`) instead of the expected
`socialhub-v8g.22.{7,8,9,10}` sequence, AND the same 4 beads got
priority 2 (P2 default) instead of priority 1 (P1 requested). The
remaining 32 beads were then filed SEQUENTIALLY to avoid the race. Total
corrective work: 4 `bd rename` invocations plus 4 `bd update --priority 1`
invocations.

**Recommended patterns.**

1. **SEQUENTIAL filing** when parent-context matters. Use this when the
   role's correctness depends on the parent-prefix + priority + labels
   propagating correctly from the parent bead.
2. **BATCH-FILE via `bd create --batch-file <jsonl>`** if the bd CLI
   supports it. As of `bd` v1.0.4, `--batch-file` is NOT in the
   `bd create --help` output; verify with `bd create --help` before
   relying on this.
3. **Parallel only when correctness does not depend on parent context**
   (e.g., independent root-level beads).

**Sanity-check after parallel batch.**

```bash
# 1. List recent beads and verify prefix.
bd list --json | rg '"created_at": "2026-07-13T1[01]:' | rg '"id":'

# 2. Find beads that have a short-prefix ID instead of the parent prefix.
#    Replace PARENT_PREFIX with the literal prefix (e.g., socialhub-v8g.22).
bd list --json | rg '"id": "socialhub-[a-z0-9]{3}"' \
  | rg -v '"id": "PARENT_PREFIX'

# 3. Find beads whose priority drifted from the requested value.
bd list --json | rg '"priority": 2' | rg '"id": "socialhub-v8g.22'
```

If any bead shows the wrong prefix or wrong priority, run corrective
invocations: `bd rename <old-id> <new-id>` and
`bd update <id> --priority 1`. Apply this rule before posting any
comment that cites the batch results; see Approval-Comment Accuracy
Smoke Test below.

<!-- smoke-test-section: do-not-remove -->
<!-- This marker anchors the Approval-Comment Accuracy Smoke Test section.
     WFSC-bead-6 / socialhub-v8g.22.44 AC requires this section to exist.
     A follow-up workflow-improvement bead (suggested stable ID: WFSC-bead-7)
     should add a Beads DB dependency that blocks on bd-cli-quirks.md
     containing this section, until then this HTML comment is the only
     do-not-remove guarantee. -->

## Approval-Comment Accuracy Smoke Test (claim-then-verify)

**Failure mode.** A role comment asserts an on-disk state (bead ID
mapping, status transition, ownership, parent/child, priority, label,
dependency) that does NOT match the actual on-disk state at write-time.
The audit trail ends up with conflicting tables or claims across
same-bead comments, and readers must reconcile.

**Evidence (socialhub-v8g.22.1, 2026-07-13 10:47:33Z).** Process
Engineer filing-announce comment on socialhub-v8g.22.1 contained a
per-bead ID mapping table that did NOT match the on-disk state at
write-time. The closing summary at 11:02:21Z corrected the table. Both
comments are part of the permanent bead audit trail with conflicting
ID-mapping tables.

The expected on-disk mapping (post-correction) for the cited bead IDs
is:

| Bead ID | On-disk title at write-time |
| --- | --- |
| `socialhub-v8g.22.6` | GAP-K-019 umbrella (not GAP-K-001 Frontend as claimed in 10:47Z comment) |
| `socialhub-v8g.22.7` | GAP-K-001 Frontend (not GAP-K-002 as claimed) |
| `socialhub-v8g.22.8` | GAP-K-002 Backend (not GAP-K-003 as claimed) |
| `socialhub-v8g.22.9` | GAP-K-003 Full-stack (not GAP-K-004 as claimed) |
| `socialhub-v8g.22.10` | GAP-K-004 API (not GAP-K-005 as claimed) |

The 2026-07-13 10:47Z filing-announce comment asserted a mapping that
was off-by-one across the board (parallel-create race caused the IDs
to drift; see Parallel-Create Race Condition section above).

**Smoke test.** Re-run `bd show <id> --json` against every bead ID cited
in a target comment, and flag any mismatch.

```bash
# 1. Pick a target comment (e.g., the 2026-07-13 10:47Z filing-announce
#    comment on socialhub-v8g.22.1). Extract every bead ID cited.

# 2. For each cited ID, run `bd show <id> --json` and compare against the
#    claim in the comment. The QA Strategist MUST run all 5 commands
#    for the socialhub-v8g.22.1 10:47Z filing-announce test case:
bd show socialhub-v8g.22.6 --json
bd show socialhub-v8g.22.7 --json
bd show socialhub-v8g.22.8 --json
bd show socialhub-v8g.22.9 --json
bd show socialhub-v8g.22.10 --json

# 3. Compare the `title` field of each result against the GAP-K mapping
#    the comment asserted. Flag any mismatch as a rule violation of
#    `.orchestrated-agents/workflows/bead-protocol.md` Approval-Comment
#    Accuracy section.
#
#    TITLE COMPARISON METHOD (mandatory): on-disk `title` is a descriptive
#    string of the form "GAP-K-NNN: <description>", not a bare GAP-K ID.
#    Use this PowerShell one-liner (or its bash/ripgrep equivalent) to
#    extract the canonical ID and compare:
#
#      For each cited bead ID X and asserted GAP-K-NNN:
#        bd show <X> --json \
#          | Select-String -Pattern '"title":\s*"([^"]+)"' \
#          | ForEach-Object { $_.Matches[0].Groups[1].Value }
#        # then apply regex GAP-K-\d+ to the title and compare against
#        # the asserted GAP-K-NNN. Mismatch = rule violation.
#
#    Equivalent ripgrep path:
#      bd show <X> --json | rg -o '"title":\s*"GAP-K-[0-9]+' | head -1
#
#    The regex GAP-K-\d+ is the canonical extractor because coverage-matrix
#    titles always begin with the GAP-K/GAP-L ID followed by a colon.

# 4. STALE-CITATION CHECK (mandatory). Diff the cited `updated_at`
#    timestamp in the target comment's Verified Evidence subsection
#    against the fresh `updated_at` from a fresh `bd show <id> --json`.
#    If the cited `updated_at` is OLDER than the current `updated_at`,
#    the citation is stale and the comment is in violation of the
#    adversarial-convergence.md Approval Rule stale-citation clause.
#
#    For each cited bead ID X, run this command and compare:
bd show <X> --json | rg -o '"updated_at":\s*"[^"]+"' | head -1
#
#    Detection criterion: the cited `updated_at` in the comment's
#    Verified Evidence must equal the fresh `updated_at` returned by
#    `bd show <X> --json`. If the cited value is older, the bead was
#    mutated after the comment was posted (e.g., another role updated
#    it, priority changed, status transitioned) and the comment's
#    evidence is no longer verifiable at write-time. Flag as violation.
#
#    NOTE: a fresh `updated_at` that is NEWER than the cited value is
#    NORMAL and NOT a violation; the cited value is what was on disk
#    at write-time, and downstream edits are expected. The violation
#    is only when the cited value is OLDER than the live value, which
#    is impossible if the verification was actually run (because the
#    fresh `updated_at` IS the cited value at write-time). Stale
#    citations therefore indicate a fabricated or post-hoc-edited
#    Evidence block.
```

**Expected detection (WFSC-bead-6 acceptance criterion).** The QA
Strategist running the smoke test against the 2026-07-13 10:47Z
filing-announce comment on socialhub-v8g.22.1 MUST observe that the
`title` field of `bd show socialhub-v8g.22.6 --json` reports GAP-K-019
umbrella, NOT GAP-K-001 Frontend as the comment asserted. This is the
canonical detector for the failure mode that motivated WFSC-bead-6.

**Auditability Check (Security/Risk Architect debate-perspective mitigation).** A future
adversary verifying a cited `bd show --json` output should be able to
diff it against current `bd show <id> --json` to detect stale citations.
If `updated_at` in the cited output is older than the current
`updated_at`, the citation is stale and the comment must be re-verified
before approval. This mitigates the post-hoc Evidence-block edit risk:
the timestamp is sourced from the Beads DB, not the human's wall clock.

## See Also

- `.orchestrated-agents/docs/beadbox-windows.md` -- BeadBox setup
  notes (existing ops doc; long-comment `--file` workaround is covered
  in a sibling WFSC-bead-4 / socialhub-v8g.22.5 once that lands).
- `.orchestrated-agents/workflows/bead-protocol.md` Approval-Comment
  Accuracy section -- the rule this smoke test enforces.
- `.orchestrated-agents/workflows/bead-protocol.md` Comment-Discipline
  Self-Check section -- the prose rule plus the deterministic linter
  that enforces probe-comment rejection.
- `.orchestrated-agents/bin/test-comment-check.ps1` -- the linter
  invoked by the wrapper and by this smoke test.
- `.orchestrated-agents/workflows/adversarial-convergence.md` Approval
  Rule -- the higher-level rule that requires evidence verifiable at
  write-time.
- `.orchestrated-agents/docs/coverage-matrix-v3.md` -- canonical
  source-of-truth for GAP-K/GAP-L stable IDs; the socialhub-v8g.22.1
  filing should have used this as the cross-reference when citing bead
  IDs.

## Comment-Discipline Self-Check Smoke Test

**Failure mode.** A role posts a probe comment on a real bead:
content is `test probe`, `line1\nline2\nline3`, `hello world`, or any
short single-word / single-line text without the required Markdown
structure (`### Commentor:` header, `**Status:**` field,
`**Findings:**` field, `**Required Next Action:**` field). The bd CLI
has no comment-delete primitive, so the violation is permanent on the
bead audit trail.

**Evidence (socialhub-v8g.22.44, 2026-07-13).** This bead
(WFSC-bead-6: Approval-comment accuracy gate) itself has SIX probe
comments in its audit trail:

| # | Comment ID | Author | Timestamp (UTC) | Content |
| - | --- | --- | --- | --- |
| 1 | `019f5b33` | Role Selector | 2026-07-13T11:19:16Z | `test probe` |
| 2 | `019f5b34` | Role Selector | 2026-07-13T11:19:40Z | `line1\nline2\nline3` |
| 3 | `019f5b5d` | Adversarial Reviewer | 2026-07-13T12:05:14Z | `Test line 1\nTest line 2\nTest line 3` |
| 4 | `019f5b5f` | Adversarial Reviewer | 2026-07-13T12:06:57Z | `hello world` |
| 5 | `019f5b60-0214` | Adversarial Reviewer | 2026-07-13T12:07:26Z | `test with <id> and <pattern>` |
| 6 | `019f5b60-7488` | Adversarial Reviewer | 2026-07-13T12:07:56Z | `lineA`nlineB`nlineC with <id> literal` |

This is the canonical detector: the linter detects and rejects ALL
six of these probe patterns with exit code 1. The full violation
record is in
`.orchestrated-agents/workflows/bead-protocol.md` Known Audit-Trail
Violations section.

**Smoke test.** Run the linter against each of the six historical
probe-comment patterns AND against a known-good compliant comment
template. All six probe patterns MUST exit non-zero (1); the
compliant comment MUST exit zero (0).

```powershell
# 1. probe phrase: "test probe" (Role Selector 11:19Z)
.\.orchestrated-agents\bin\test-comment-check.ps1 `
  -text "test probe" `
  -bead-id socialhub-v8g.22.44 `
  -author "Role Selector"
# Expected: valid=false, violations contains "test probe", exit code 1.

# 2. literal lineN lines (Role Selector 11:19Z)
"line1`nline2`nline3" | .\.orchestrated-agents\bin\test-comment-check.ps1 `
  -stdin -bead-id socialhub-v8g.22.44 -author "Role Selector"
# Expected: valid=false, violations contains "lineN probe line", exit code 1.

# 3. Test line N pattern (Adversarial Reviewer 12:05Z)
"Test line 1`nTest line 2`nTest line 3" | .\.orchestrated-agents\bin\test-comment-check.ps1 `
  -stdin -bead-id socialhub-v8g.22.44 -author "Adversarial Reviewer"
# Expected: valid=false, violations contains "test line" and "Test line N", exit code 1.

# 4. hello world (Adversarial Reviewer 12:06Z)
.\.orchestrated-agents\bin\test-comment-check.ps1 `
  -text "hello world" `
  -bead-id socialhub-v8g.22.44 -author "Adversarial Reviewer"
# Expected: valid=false, violations contains "hello world", exit code 1.

# 5. test with id and pattern (Adversarial Reviewer 12:07Z)
.\.orchestrated-agents\bin\test-comment-check.ps1 `
  -text "test with <id> and <pattern>" `
  -bead-id socialhub-v8g.22.44 -author "Adversarial Reviewer"
# Expected: valid=false, exit code 1. The bare phrase `test with` was
# removed from the probe-phrase list (C4-delta: it false-positived on
# legitimate review prose). This probe is now caught by the structure
# (missing `### Commentor:` header), length (< 200 chars), and density
# (<= 2 non-blank lines) checks instead.

# 6. lineA/lineB/lineC with id literal (Adversarial Reviewer 12:07Z)
"lineA`nlineB`nlineC with <id> literal" | .\.orchestrated-agents\bin\test-comment-check.ps1 `
  -stdin -bead-id socialhub-v8g.22.44 -author "Adversarial Reviewer"
# Expected: valid=false, violations contains "lineA", "lineB", "lineC", exit code 1.

# 7. COMPLIANT control case -- a real formatted Markdown work record.
#    MUST exit 0 (no violations).
@'
### Commentor: Workflow Engineer

**Step/Subtask:** Comment-Discipline Self-Check smoke-test positive control

**Status:** Evidence Accepted

**Findings:** This comment is intentionally structured as a valid
Markdown work record with all required fields and sufficient length
to satisfy the linter. It serves as the positive control for the
smoke test above; the negative cases (1-6) MUST all fail, this case
MUST pass.

**Evidence:** Copy-paste this comment into a here-string and pipe
to .\.orchestrated-agents\bin\test-comment-check.ps1 -stdin.

**Required Next Action:** Confirm exit code is 0; if not, the linter
has regressed and the rule is no longer enforceable.
'@ | .\.orchestrated-agents\bin\test-comment-check.ps1 `
  -stdin -bead-id socialhub-v8g.22.44 -author "Workflow Engineer"
# Expected: valid=true, violations=[], exit code 0.
```

**Expected detection (WFSC-bead-6 acceptance criterion for C4).** All
six historical probe-comment patterns MUST exit code 1 with the
corresponding violation message. The compliant control case MUST
exit code 0. If any negative case passes (exit code 0) the linter has
regressed and the rule is no longer enforceable. If the positive
control fails (exit code 1) the linter is over-strict and is blocking
legitimate comments. Both regressions are Critical defects.

**Backtick-stripping exemption (positive documentation case).** The
linter strips backtick-delimited content (single-backtick code spans
and triple-backtick code fences) before checking for probe phrases.
This exempts legitimate documentation comments that reference probe
patterns as literal examples inside backticks. Probe violations are
NEVER inside backticks. To verify the exemption is not over-broad:

```powershell
# Documentation comment that mentions probe patterns inside backticks.
# MUST exit 0 (valid) because the probe phrases are inside backticks.
@'
### Commentor: Workflow Engineer

**Step/Subtask:** C4 documentation exemption smoke-test

**Status:** Evidence Accepted

**Findings:** This comment documents the C4 fix list and references
historical probe-comment patterns as literal examples inside backticks.
Specifically, it mentions the probe phrases `test probe`, `hello world`,
`lineA`, `lineB`, `lineC`, and the literal patterns `line1`, `line2`,
`line3`. All such references are inside backticks and MUST be exempted
from probe-phrase detection by the backtick-stripping logic in
test-comment-check.ps1. The Markdown-structure check and length/density
checks still apply to the full text (and this comment passes both).

**Evidence:** Direct invocation of the linter on this here-string.

**Required Next Action:** Confirm exit code is 0.
'@ | .\.orchestrated-agents\bin\test-comment-check.ps1 `
  -stdin -bead-id socialhub-v8g.22.44 -author "Workflow Engineer"
# Expected: valid=true, violations=[], exit code 0.
```

**Auditability.** The linter outputs JSON on stdout with `valid`,
`violations`, `checked_at`, `bead_id`, `comment_id`, `author`,
`script_version`, and `script_path` fields. A future auditor can
diff `script_version` against the version recorded in this smoke test
to detect linter regressions. The smoke-test commands above are the
canonical reference; if they are amended, the corresponding test
cases in this section MUST be re-run and a new comment posted
referencing the fresh `checked_at`.

## Role-Name Split / Author Truncation (ORCH-REQ-008 / socialhub-v8g.24.8)

**Failure mode.** A space-containing role name passed on the command
line without quotes is split by the shell into separate arguments.
Only the first word reaches the wrapper as the role argument, so the
wrapper resolves the wrong (or nonexistent) agent AND sets
`BEADS_ACTOR` to the truncated first word. The bd comment then lands
on the audit trail with an `author` field that is only the first word
of the intended role, even though the comment body's
`### Commentor:` line may show a different name. This corrupts the
visible BeadBox comment author and the role-audit trail.

**Evidence (socialhub-v8g.22.44, 2026-07-13).** Comment
`019f5bd7-f15c-7cee-b4f9-5d616fc46de5` at
`2026-07-13T14:18:27Z` has `author: "Process"` but a body that
begins `### Commentor: Process Engineer`. The role was still named
**Process Engineer** at that time (it was renamed to **Workflow
Engineer** later under ORCH-REQ-004 / socialhub-v8g.24.4). The
space-split truncated `Process Engineer` to `Process`, which became
the bd comment author. The bead description for socialhub-v8g.24.8
contains a minor anachronism (it says the body read `Commentor:
Workflow Engineer`); the verified on-disk record shows
`Commentor: Process Engineer`. AC6 of socialhub-v8g.24.8 requires the
real record, not the anachronism. The mutable-field migration audit
in socialhub-v8g.24.9 covers a SEPARATE concern (wholesale field
rewrites across 56 beads) and must not be confused with this
author-truncation event.

**Why this is a permanent record.** The bd CLI has no comment-delete
primitive (verified by `bd comments --help`). The truncated-author
comment is therefore permanent on the socialhub-v8g.22.44 audit
trail. It is documented here so future readers reconcile the
`author: "Process"` row against the `Commentor: Process Engineer`
body without assuming the audit trail was tampered with.

**Mitigation.** `oa.ps1` now resolves every accepted role spelling
(canonical display name, dash-slug, oa-agent-slug) to BOTH the
canonical display role and the configured agent before any role run,
and FAILS CLOSED on unrecognized spellings. The fail-closed guard
also catches the quoting-split bug class: if only the first word of a
space-containing role arrives, `Resolve-Role` throws instead of
silently running the wrong agent. See `oa.ps1` `Resolve-Role` and
the `Role Invocation` section of `WORKFLOW.md`.

**Smoke test.** The canonical detector is
`.orchestrated-agents/bin/test-role-resolution.ps1`. It asserts that
all 13 configured roles resolve correctly across the three accepted
spellings, that `Resolve-Role` and `Get-AgentName` agree, and that
unrecognized spellings -- including the truncated first words that
reproduce the original bug -- fail closed.

```powershell
# Run the canonical regression. Exit code 0 = all assertions pass.
.\.orchestrated-agents\bin\test-role-resolution.ps1
# Expected: JSON summary with pass=68, fail=0, exit code 0.

# Reproduce the original bug class directly: a truncated first word
# MUST throw, not resolve to a garbage agent.
. .\.orchestrated-agents\bin\oa.ps1
try { Resolve-Role "Workflow" | Out-Null } catch { "threw (expected)" }
# Expected: threw (expected) -- the quoting-split defense works.
```

**Operator requirement.** The orchestrator/operator MUST quote
space-containing role names, e.g.
`oa.cmd run <bead-id> "Workflow Engineer"`. The fail-closed guard is
the safety net, not a substitute for correct quoting.

**See also.**
- `.orchestrated-agents/workflows/bead-protocol.md` Known Audit-Trail
  Violations section -- permanent-record index that cross-references
  this section.
- `.orchestrated-agents/WORKFLOW.md` Role Invocation section -- the
  accepted-spellings and quoting rules.
- socialhub-v8g.24.9 -- the mutable-field migration audit (distinct
  concern; do not conflate with this author-truncation event).
