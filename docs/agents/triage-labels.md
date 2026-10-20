# Triage roles and Linear states

This project maps the skills' canonical triage roles to Linear states and explanatory comments. Role names are not required labels. Steven explicitly chose Todo as the readiness signal; do not introduce a ready-for-agent label gate.

This document owns the ticket lifecycle. Read [../overnight-delegation.md](../overnight-delegation.md) for current queue/review/merge authority and [../agent-team.md](../agent-team.md) for role responsibilities and evidence requirements. During Symphony execution, use the guarded transition tool specified in [../../WORKFLOW.md](../../WORKFLOW.md).

| Skill role | Project mapping | Meaning |
| --- | --- | --- |
| needs-triage | Backlog | Awaiting Steven's scope/readiness review. |
| needs-info | Backlog for incoming work; Blocked for the current in-flight ticket | Comment with the missing information and exact unblock condition. |
| ready-for-agent | Todo | Steven has authorized the implementation ticket. |
| ready-for-human | Backlog with a human-action explanation | Requires human implementation or a decision before agent execution; this is distinct from completed-PR review. |
| wontfix | Canceled | Work deliberately declined or canceled. |


## Agent processing labels

Workflow status still governs readiness, dependencies, review and completion. While a healthie-platform ticket is executing, show its current role phase using the single-select Linear label group **Healthie Agent Phase**. These labels are display metadata, not execution authorization or a replacement for status.

| Label | Label ID | Apply while |
| --- | --- | --- |
| Developer Agent Processing | `0a1209f1-6b3c-4234-8902-d9b9e688f0c9` | Developer plans, implements, self-reviews or repairs findings. |
| QA Agent Processing | `c3cc2d7d-2764-4f4b-b065-4895cfff38c1` | The independent QA agent validates the candidate and publishes evidence. |

Developer owns these updates through Linear label operations:

1. After claiming/resuming authorized work in In Progress, reconcile the label with the actual current role and apply Developer Agent Processing before implementation or repair.
2. When independent QA starts, replace Developer Agent Processing with QA Agent Processing. Keep QA selected while Developer waits for QA; changing a workpad alone is not a role handoff.
3. On a QA finding that requires Developer changes, switch back to Developer Agent Processing. Switch to QA again for the same QA session's retest.
4. Remove both processing labels before moving to In Review or Blocked, or when execution otherwise stops. Backlog, waiting Todo, human-review In Review and terminal tickets have neither label. Preserve the ticket slot and preview according to the lifecycle below.
5. On an unexpected worker exit, the operator clears stale processing labels once execution has stopped; the next resume reconciles them before work. Labels describe agent-reported phase, not a runtime heartbeat.

Keep at most one phase label. Use label add/remove operations (native `issueAddLabel` / `issueRemoveLabel` through `linear_graphql` are suitable), preserving all unrelated labels. Continue to use the guarded transition tool for status changes. The existing scheduler-owned `symphony-execution` label is separate; agents must not treat it as a Developer/QA phase or manipulate its ownership.

## Delivery lifecycle

- Todo: a dependency-ready implementation ticket can be claimed when the project's single-ticket slot is free. The current feedback ticket resumes before any new work.
- In Progress: Developer/QA is executing the claimed ticket.
- In Review: acceptance criteria are checked after independent QA evidence; the PR is open, marked ready for review (not draft), and required checks pass before the ticket enters this state. Developer verifies GitHub reports `isDraft: false`; if needed, run `gh pr ready` before the Linear transition. The PR then awaits Steven's review. Stop coding and agent execution while waiting. Preserve the current workspace, branch, PR, database, seeded development preview and ticket-slot ownership; no other ticket, including independent work, may start.
- Feedback: Steven leaves feedback on the PR and moves the same ticket from In Review to Todo. Resume its existing branch/PR using [pr-feedback.md](pr-feedback.md), then rerun the affected QA. No Linear feedback copy is required.
- Blocked: after two unsuccessful repair cycles, preserve the current work and record a checkpoint with reproduction steps, failure evidence, findings, owner and the exact unblock condition. Hold the slot and preview. Steven reproduces/adds feedback and moves it to Todo.
- Done: the PR has been manually merged by Steven and acceptance criteria are checked. Release the slot; the next dependency-ready Todo ticket may start from current merged main, on a separate ticket branch/workspace. Do not mark Done before merge.
- An explicit pause preserves ticket ownership and closes the dispatch gate until resumed or released by Steven.

A generic skill instruction to apply ready-for-agent must not silently activate work: keep newly published tickets in Backlog until Steven moves them to Todo. Planning/spec parent issues remain outside the execution queue. Dependency completion means merged and Done; Canceled prerequisites require explicit resolution of their dependent tickets rather than an assumption that the prerequisite was delivered.

Backlog, Blocked and In Review are inactive for coding. Current feedback work resumes before new work. Preserve or reconstruct the slot after a scheduler restart; a running-agent concurrency limit alone does not enforce it.
