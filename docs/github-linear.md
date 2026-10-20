# GitHub → Linear completion

Use the existing supported Linear GitHub integration for
`pickerflicker/healthie-platform` and Pickerflicker (PIC), project
`healthie-platform` (`c6cbdb1032a3`). No custom webhook, GitHub Action with a
Linear token, or second status writer is required.

## Authoritative delivery rule

For this project's one-delivery-PR-per-ticket workflow, a verified merge into this repository's `main` completes the associated implementation ticket. Squash merge counts as delivery; completion must not depend on an agent remembering a description keyword. A closed unmerged PR does not count.

[Complete merged Linear ticket](../.github/workflows/linear-completion.yml) runs on GitHub after merge, independently of the laptop, Symphony and model turns. It re-reads the PR, verifies the merged state/destination, derives the ticket from the established `pic-<number>-...` delivery branch and ensures a standalone `Closes PIC-<number>` line in the saved body. Existing description/evidence stays intact; replays are idempotent. This repairs missing or non-closing references and lets the existing Linear integration remain the sole issue-state writer. No Linear token or team-wide settings change is used.

The hook processes only `pickerflicker/healthie-platform` merges into `main`. It ignores branches without a PIC delivery identifier, such as dependency updates, and never derives delivery from incidental parent/dependency mentions in the description. Conflicting closing directives for another ticket fail visibly rather than automatically closing multiple issues. Keep the ticket branch identifier when creating implementation PRs. It executes only trusted workflow code and PR metadata, with no checkout of PR files and only repository-scoped pull-request write permission.

The inserted line precedes the existing body so unfinished Markdown examples cannot hide it. A second read detects metadata/body changes before writing and fails for a fresh replay; workflow runs for the same PR are serialized. GitHub does not document conditional PATCH for this endpoint, so this is not an atomic append against simultaneous human edits. Avoid description rewrites while merge reconciliation is running and inspect/replay a reported conflict.

An Action success proves the GitHub closing relation was saved, not that Linear has already processed its webhook. Verify actual Done before releasing the project slot. On a failed hook, fix the reported cause and replay the same merge using `gh workflow run linear-completion.yml --ref main -f pr_number=PR_NUMBER`; GitHub merge state is checked again. If the native integration remains unavailable, use the documented completion reconciliation below rather than restarting implementation on delivered work. Closed/unmerged or wrong-destination PRs are rejected even on manual replay.

Put `Closes PIC-<number>` in the PR description. Confirm the `linear-code`
linkback points to the intended issue. This is a closing reference; a plain
mention is not the completion contract. See [Linear's integration docs](https://linear.app/docs/github-integration).

After creating or editing a delivery PR description, re-read the saved body and verify its closing reference still names the correct implementation ticket. Preserve that reference during summaries/evidence rewrites. `Refs PIC-<number>` is a non-closing link: a linkback or successful CI does not prove merge-to-Done is enabled. Developer verifies the saved reference before handoff, and QA checks it as part of delivery evidence.

## PIC-277 regression and verified repair — 2026-10-20

PR #5 contained `Refs PIC-277` when Steven merged it at 18:12:48 UTC, merge `fe163b8808fd3cc546c35e6615f73af6979cc9bc`. Linear changed In Review to In Progress at 18:12:50; Symphony dispatched it at 18:12:57. The state regression therefore preceded worker execution. The extra worker recognized the merge and made no application changes before the operator stopped it. Moving an issue to Todo also makes it eligible for execution; use the operator's pause/stop controls to interrupt dispatch.

The operator corrected the merged PR description to `Closes PIC-277`; Linear then moved the issue to Done automatically, completedAt 18:15:15.675 UTC. No manual issue-state write or integration-setting change was made. This is direct evidence that correcting the closing relation repaired synchronization after merge. The non-closing reference was already present before the manual repair and was mistakenly retained during the PR description rewrite.

Before any resumed application edit, inspect the associated PR's actual merge state under [agents/pr-feedback.md](agents/pr-feedback.md). A merged PR with a stale active Linear status needs completion reconciliation, not implementation or another QA/model loop.

## Verified existing configuration — 2026-10-20

Read-only Linear `team.gitAutomationStates` inspection returned these existing
team-wide defaults, with no target-branch override:

| Event | State |
| --- | --- |
| start | In Progress |
| review | In Review |
| merge | Done |

No team conventions or repository permissions were changed. Private repository
access was verified with `gh pr view 3`. The GitHub installations endpoint was
not accessible to this credential (404); installation scope was not inferred
from that endpoint. The Linear bot's actual linkback verifies repository linking.

[PR #3](https://github.com/pickerflicker/healthie-platform/pull/3) contained
`Closes PIC-275` and a [Linear bot linkback](https://github.com/pickerflicker/healthie-platform/pull/3#issuecomment-6294251859).
The operator reviewed passing independent QA/CI and merged under Steven's scoped
overnight delegation at `2026-10-20T16:12:12Z`, commit
`383892f12099974e752d3c04c31a7ab1d733b5d1`.
[The operator's review](https://github.com/pickerflicker/healthie-platform/pull/3#issuecomment-6295474590)
records the review gate. Linear PIC-275 was observed Done with updatedAt
`2026-10-20T16:12:14.138Z`; the operator explicitly recorded that no manual Done
write was made in the PIC-276 issue comment. This is an operator-observed
integration transition, not a new observation of Steven personally merging.

## Review and completion contract

Todo remains the execution authorization; no readiness label is needed. One
ticket owns the slot through review or Blocked. Opening a linked PR can change
Linear status through the existing team automation: keep implementation PRs
draft until independent QA passes, and verify the actual issue status at handoff.
The Developer stops In Review. Steven reviews and merges. The earlier
[overnight delegation](overnight-delegation.md) was revoked on 2026-10-20; its
use for PR #3 above is historical evidence only. Developer never self-merges.

A closed **unmerged** PR is not delivered. Inspect GitHub `mergedAt` and
`mergeCommit`, not just `state=CLOSED`. Never mark Done or release ownership
because a PR was closed. Preserve the ticket/branch and resolve the closed PR
with the operator. Symphony reads actual Linear state; it does not infer Done
from GitHub. A merge should update Linear automatically, but verify the actual
Done status before allowing the next ticket to run.

## Delayed or unavailable synchronization

1. Verify the correct closing reference/linkback, the actual merged PR and
   merge SHA, independent QA report/tested commit, and passing required checks.
2. Refresh the issue after allowing for hosted synchronization and the local
   ten-second poll. A fixed wait is not proof of success. Keep the slot held
   while the issue is not Done; do not queue another ticket as a workaround.
3. If still unsynchronized, the authorized operator records the PR URL, merge
   timestamp/SHA and observed Linear status, then uses the guarded
   `linear_transition_issue` tool for a verified manual Done transition. Report
   this explicitly as a fallback, never as proof of automatic synchronization.
4. If integration access/consent is unavailable, request the account owner check
   Linear Settings → Integrations → GitHub and Pickerflicker Workflow automation.
   Reuse the installation and inspect scope before changing anything. Team-wide
   changes affect unrelated PIC projects and require separate agreement.

This documentation PR is the selected non-product smoke for PIC-276. Its QA
report records the pre-merge and close-unmerged observations. Steven must merge it; the operator must
then record its actual Linear transition; the Developer leaves it
awaiting review and does not claim future merge success.
