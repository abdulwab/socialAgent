# Adversarial Convergence

No real work is accepted after a single pass.

## Required Pattern

1. Maker Engineer performs scoped work.
2. At least one adversarial role critiques it.
3. QA Strategist checks acceptance and test evidence.
4. Security Privacy Reviewer joins when data, auth, secrets, permissions, user isolation, network, or deployment are touched.
5. Release SRE Reviewer joins when runtime, deployment, reliability, migrations, observability, or rollback are touched.
6. Documentation Reviewer joins when user-facing or operator-facing instructions are changed.
7. Maker Engineer fixes issues or provides proof that the critique is not valid.
8. Adversaries re-check.
9. Convergence requires explicit approval comments from required non-maker roles.

## Disagreement Rule

If two roles cannot converge after evidence-backed arguments, Human Question Framer prepares a human decision packet. The human receives only the simplest actionable question unless they ask for detail.

## Approval Rule

Approval comments must name the evidence accepted, AND the evidence must be
verifiable at write-time.

When a comment claims an on-disk state (bead ID mapping, status transition,
ownership, parent/child, priority, label, dependency), the Evidence section
must cite a `bd show <id> --json` or `bd list --json | rg <pattern>` slice
taken BEFORE the comment was posted, with the `updated_at` field from that
output as the auditable timestamp. If the verification fails, the comment
must declare `pending verification: <reason>` and must not assert the fact.
See `.orchestrated-agents/workflows/bead-protocol.md` Approval-Comment
Accuracy section for the full rule.

A follow-up comment in the same role turn that cites the verified output is
treated as the canonical record. Comments with pending-verification claims
must be closed out (verified or rescinded) within the same role turn; a
claim that is left pending across two separate role turns is a violation
of this rule and a violation of the Approval-Comment Accuracy section.

Approval of a comment that does not satisfy this rule (no `bd show`
citation for an on-disk-state claim, OR a citation whose `updated_at` field
is older than the current `updated_at`) is a violation of the
approval-without-proof pattern.

A role may approve with residual risk only if the risk is documented and
accepted by the role-selection council or human.
