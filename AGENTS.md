# healthie-platform

Rails interview pre-work. Read `CONTEXT.md` for the agreed scope, architecture and interview-specific operating rules. Read `docs/operations.md` before local runtime setup. Validate the local runtime and single-ticket dispatch gate before activating implementation; documented plans are not proof that infrastructure is running.

Exactly two execution roles: Developer (parent and implementation owner) and one independent QA subagent. QA uses headed Playwright Chromium and may write tests/evidence, but does not edit application source. Developer repairs QA findings. Keep the same role sessions during a repair loop; no additional reviewer or recursive delegation.

Run one ticket through implementation, QA and human review before starting another, including independent work. Follow the status rules in `docs/agents/triage-labels.md`. Preserve the active ticket workspace, branch, PR, database and review preview. Steven manually merges PRs. After two unsuccessful repair cycles, record reproduction evidence and move the ticket to Blocked; resume the same ticket when Steven adds feedback and returns it to Todo. Use guarded Linear transitions during Symphony execution.

This project explicitly uses laptop-local infrastructure: Docker Desktop and Compose for Rails/Postgres/Redis, native macOS Symphony, and 10-second Linear polling. Hosted Linear/GitHub/AI connectivity remains required. Use the project's local database and test-data/cache isolation rules in `CONTEXT.md`. Verify that exactly one scheduler owns this Linear project before activation. Preserve unrelated projects and dirty user changes.

Current commands: `bin/bootstrap`, `bin/check`, `bin/preview`, `bin/acceptance`. Update their contracts during local setup. Keep validation focused; no coverage quota. Store the canonical QA report/screenshots on the PR, with only a result, tested commit and report link in Linear. Leave the tested preview running in In Review.

## Agent skills

### Issue tracker

Publish specs and implementation issues to the existing Linear project. Before publishing or fetching work, read `docs/agents/issue-tracker.md`.

### Triage labels

Read `docs/agents/triage-labels.md` for the mapping from skill triage roles to Linear states. Todo authorizes work; no readiness label is required.

### Domain docs

Single-context layout: `GLOSSARY.md` and `docs/adr/`. Before domain modeling, spec writing, ticketing or implementation, read `docs/agents/domain.md`.

## Current scoped delegation

Read `docs/overnight-delegation.md` before queueing, reviewing or merging PIC-274 through PIC-281. Steven explicitly delegated those actions to the coordinating operator for this batch; this overrides the normal Steven-only approval wording. Independent QA and passing acceptance checks remain required.
