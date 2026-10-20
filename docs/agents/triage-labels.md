# Triage roles and Linear states

This project maps the skills' canonical triage roles to Linear states and explanatory comments. Role names are not required labels. Steven explicitly chose Todo as the readiness signal; do not introduce a ready-for-agent label gate.

| Skill role | Project mapping | Meaning |
| --- | --- | --- |
| needs-triage | Backlog | Awaiting Steven's scope/readiness review. |
| needs-info | Backlog for incoming work; Blocked for the current in-flight ticket | Comment with the missing information and exact unblock condition. |
| ready-for-agent | Todo | Steven has authorized the implementation ticket. |
| ready-for-human | Backlog with a human-action explanation | Requires human implementation or a decision before agent execution; this is distinct from completed-PR review. |
| wontfix | Canceled | Work deliberately declined or canceled. |

## Delivery lifecycle

- Todo: a dependency-ready implementation ticket can be claimed when the project's single-ticket slot is free. The current feedback ticket resumes before any new work.
- In Progress: Developer/QA is executing the claimed ticket.
- In Review: QA passed and the PR awaits Steven's review. Keep its preview running and hold the project slot; do not claim another ticket.
- Feedback: Steven adds comments and moves the same ticket from In Review to Todo. Resume its existing branch/PR and rerun QA.
- Blocked: after two unsuccessful repair cycles, preserve the current work and record reproduction steps, findings and the exact unblock condition. Hold the slot. Steven reproduces/adds feedback and moves it to Todo.
- Done: the PR has been manually merged by Steven. Release the slot; the next dependency-ready Todo ticket may start.
- An explicit pause preserves ticket ownership and closes the dispatch gate until resumed or released by Steven.

A generic skill instruction to apply ready-for-agent must not silently activate work: keep newly published tickets in Backlog until Steven moves them to Todo. Planning/spec parent issues remain outside the execution queue. Dependency completion means merged and Done; Canceled prerequisites require explicit resolution of their dependent tickets rather than an assumption that the prerequisite was delivered.
