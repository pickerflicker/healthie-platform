# GitHub → Linear completion

Use the existing supported Linear GitHub integration for
`pickerflicker/healthie-platform` and Pickerflicker (PIC), project
`healthie-platform` (`c6cbdb1032a3`). No custom webhook, GitHub Action with a
Linear token, or second status writer is required.

Put `Closes PIC-<number>` in the PR description. Confirm the `linear-code`
linkback points to the intended issue. This is a closing reference; a plain
mention is not the completion contract. See [Linear's integration docs](https://linear.app/docs/github-integration).

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
