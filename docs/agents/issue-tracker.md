# Issue tracker: Linear

Specs and implementation issues live in Linear. Use the connected Linear tools for tracker operations.

## Project identity

- Team: Pickerflicker (PIC), ID `df0e5e0b-e4fc-41ca-926b-1296b60ef7ba`.
- Project: healthie-platform, ID `f7ab5d2f-ebf7-4dad-b5b3-f17e8c9bf538`.
- Project URL: https://linear.app/pickerflicker/project/healthie-platform-c6cbdb1032a3.
- Symphony project slug: `c6cbdb1032a3`.
- Code/PR repository: https://github.com/pickerflicker/healthie-platform.

## Spec parent

Use PIC-273 as the parent for this pre-work's implementation tickets: https://linear.app/pickerflicker/issue/PIC-273/spec-healthie-session-1-pre-work-and-local-developerqa-workflow. The repository spec is `docs/spec.md`; update both copies together when scope changes. Keep the planning parent in Backlog.

## Publishing

1. Read `CONTEXT.md`, `docs/agents/domain.md` and `docs/agents/triage-labels.md`.
2. Create or reuse one parent Linear issue for the spec; keep that planning issue in Backlog. Create implementation tickets as its child issues in the same team/project.
3. Propose small, independently verifiable slices with acceptance criteria, validation, a cold-start Symphony handoff and the `Agent execution` section defined in [execution-settings.md](execution-settings.md). Recommend effort with a short reason and record Steven's Fast-mode request for that ticket/batch. Obtain Steven's approval of the breakdown before publication when the invoked skill requires it.
4. Publish blockers first; record native Linear blocking relationships and repeat the dependencies in each issue body. Dependent work waits for prerequisites to be merged and Done; no stacked PRs.
5. Publish implementation tickets to Backlog for Steven's review. Moving a ticket to Todo is Steven's execution authorization. Creating tickets or marking their descriptions complete does not authorize activation. No additional ready-for-agent label is required.
6. Report the issue identifiers/URLs and dependency-ready frontier. The single-ticket review gate still applies, even when several tickets are dependency-ready.

Use GitHub for code and PRs, and Linear for specs, issues, dependencies and status. Follow [../agent-team.md](../agent-team.md) for QA workpads, the acceptance checklist and canonical evidence publication. GitHub repository-to-Linear merge automation is a follow-up after initial base setup; verify it before assuming a merged PR changes status to Done.

## Fetching and execution

Read the issue's complete description, comments, parent and blockers. Follow [../agent-team.md](../agent-team.md) for Developer/QA execution, [triage-labels.md](triage-labels.md) for lifecycle and [../overnight-delegation.md](../overnight-delegation.md) for current authority. Symphony's tool contract is in [../../WORKFLOW.md](../../WORKFLOW.md).

Before activating tickets, complete the runtime and gate activation checks in [../operations.md](../operations.md).
