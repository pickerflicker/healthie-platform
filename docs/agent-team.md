# Developer and QA interview team

This is the canonical role, delegation, validation and evidence policy. Before execution, read [triage-labels.md](agents/triage-labels.md) for the ticket lifecycle and [overnight-delegation.md](overnight-delegation.md) for current queue/review/merge authority. Read [operations.md](operations.md) for local commands, database/cache isolation and runtime recovery.

These agreed role and execution policies supersede older generic ticket boilerplate requiring fixed low effort or browser QA for every backend-only change. Preserve feature-specific acceptance requirements.

## Developer and delegation

Developer is Symphony's parent session and sole application implementation owner. Read the complete issue and the domain documents required by [AGENTS.md](../AGENTS.md). State the approach and log notable assumptions on the issue before editing; implement only its acceptance criteria with small, explainable changes.

On resume, Developer must complete [the PR feedback sequence](agents/pr-feedback.md) before editing or declaring that no changes are needed. Include its feedback disposition list in the QA assignment; QA verifies every actionable request against the candidate and appropriate evidence before handoff.

For authorization changes, Developer and QA follow [authorization.md](agents/authorization.md); include that policy in the QA assignment and use its focused access checks during self-review and independent validation.

Write the smallest useful set of tests for changed observable behavior and consequential failure cases. Test through real public interfaces with independently known expected results; avoid tests that mirror the implementation, mocks of internal collaborators and duplicate coverage. Existing tests or a targeted executable check can suffice when they already establish the behavior; explain that choice. TDD is optional: use test-first when helpful, but test ordering is not a delivery requirement.

Run `bin/check` and the targeted behavior check required by the issue. Before creating the PR, perform one explicit self-review of the complete diff against (1) acceptance criteria and scope and (2) repository conventions, correctness, authorization, data constraints/migrations and test quality. Fix concrete findings and rerun affected checks. After feedback, review the repair delta; avoid repeated broad review cycles or speculative refactors. Record a concise self-review result in the Developer Workpad.

After implementation and self-review, spawn exactly one independent direct QA subagent in the same ticket workspace. Developer repairs application-source findings; QA may write tests and evidence but must not edit application source. Keep the same Developer and QA sessions during repair loops. There is no additional coordinator, builder, reviewer, planner, other subagent or recursive delegation. If delegation tools are unavailable, record the concrete prerequisite and stop as Blocked under the ticket lifecycle.

Give QA the exact workspace, issue, acceptance source, base commit, relevant diff, test commands and evidence assignment, including the canonical [QA evidence policy](agents/qa-evidence.md) and its completion criteria. Keep its context focused on the current issue and changed behavior rather than the full planning history. Both roles use the fixed model and ticket-selected effort/Fast settings in [execution-settings.md](agents/execution-settings.md); QA inherits those settings without overrides. Read only documents needed for the current slice and reuse passing evidence when the source it covers is unchanged.

Borrow useful behavioral-testing and requirements/conventions-review principles from Matt Pocock's guidance. Do not automatically invoke the full TDD, implement or code-review skill workflows: their mandatory test ordering, automatic commits or extra reviewer agents are outside this project's agreed contract.

## Validation and repair

QA begins with the acceptance criteria and exact candidate diff, independently checks the Developer's conclusions, and chooses validation appropriate to the changed behavior. Verify expected outputs with independently chosen inputs and relevant failure/authorization boundaries. Check that the tests could detect incorrect behavior; passing tests alone do not establish that the requirements are right. Report concrete failures with reproduction steps; avoid adding tests that duplicate sufficient existing evidence.

For backend-only query, model or validation changes, use focused Rails/query/request checks with intentional fixtures and expected results. Browser checks are required when browser-visible behavior is affected, not for every backend change. For browser acceptance, start/exercise the app and capture actual screenshots using Playwright Chromium only, headless by default locally and in CI. Steven's 2026-10-20 decision supersedes older headed-browser ticket wording. A visible demonstration requires an explicit request. Commands and isolated test database/cache mechanics are in [operations.md](operations.md); preserve the development preview throughout validation.

Keep checks focused on observable behavior, migrations/constraints and access boundaries, with no coverage quota or broad browser matrix. Developer repairs findings and returns the same QA agent to verify the changed behavior and refresh the report. Apply the repair limit and feedback/resume rules in [triage-labels.md](agents/triage-labels.md).

## Workpads and evidence

Maintain one Developer Workpad and one QA Workpad in Linear, updated in place with actual model/session identity, selected effort/Fast settings, base/tested commit, concise decisions, findings, commands/results and outstanding risks. Record QA's actual session identifier and conclusions; independent QA evidence must be real. Keep private reasoning and secrets out of reports and Linear.

The main issue description is the sole acceptance checklist. Only Developer checks criteria, after matching independent QA evidence. Before generating or publishing evidence, read [qa-evidence.md](agents/qa-evidence.md). The canonical report is one PR Conversation comment with a test-case/results table and embedded GitHub-uploaded screenshots when visual evidence applies. Keep generated reports, screenshots and traces out of Git; committed report/image links do not satisfy this contract. Linear gets a concise QA outcome, tested commit and direct comment link. When using backend validation, explain in the QA Workpad what was checked, why that check fits, the command/query and inputs, and expected versus actual results. Update the same comment after feedback. A runtime checkpoint is not a passed QA result.

Complete the Developer Handoff with the QA report link, then follow [triage-labels.md](agents/triage-labels.md) for In Review, preview preservation and human review.
