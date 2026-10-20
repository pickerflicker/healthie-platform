# Local operations

Canonical checkout: `/Users/smh/dev/healthie-platform`.
Code/PR repository: https://github.com/pickerflicker/healthie-platform (private).
Tracker conventions: `docs/agents/issue-tracker.md` and `docs/agents/triage-labels.md`.

## Local runtime contract

Docker Desktop supplies Docker and Compose. The intended single Compose stack contains Rails, PostgreSQL and Redis. Keep database data in a persistent local named volume; separate development and test databases/cache namespaces. Rails preview binds to loopback and remains running on the tested branch while In Review. Use the selected ticket's schema and seeds when changing workspaces.

Symphony runs natively on macOS using the repository `WORKFLOW.md`. Proposed isolated workspace root: `/Users/smh/dev/healthie-platform-workspaces`. Configure runtime logs under this checkout's ignored `tmp/` tree. The workspace paths are design handles, not evidence of provisioned directories.

Use mise-managed tool versions. The current bootstrap/check/preview/acceptance commands are `bin/bootstrap`, `bin/check`, `bin/preview` and `bin/acceptance`; update their implementations as part of local Compose setup. Exact local start/pause/resume commands and the state API port must be recorded after validation.

## Activation prerequisites

Before activating any implementation ticket, verify local dependencies and authentication, ensure exactly one scheduler owns the Linear project, and prove the project-wide one-ticket gate. `max_concurrent_agents: 1` only limits executing tickets; it does not prevent dispatch during another ticket's In Review or Blocked state. The gate must survive restart and resume feedback on the same branch/PR.

Only Steven's move to Todo authorizes work. Agent execution moves the selected issue to In Progress, then In Review after independent QA. In Review keeps the preview and holds the project slot. Feedback returns the same ticket to Todo. After two failed repair cycles, record evidence and Blocked; Steven adds feedback and returns it to Todo. Done follows Steven's manual merge. Dependencies wait for merged/Done prerequisites.

## Status

Skill configuration and candidate local workflow are documented. Docker Compose provisioning, native Symphony activation, review-gate implementation and end-to-end smoke remain pending. GitHub-to-Linear integration is a follow-up after base setup; verify it before assuming that merging a PR updates the ticket to Done.

## Verified Compose entry points

Use `bin/stack up` to build and start the single project stack, prepare both databases, and wait for health. `bin/stack status`, `bin/stack logs`, and `bin/stack stop` inspect or stop this project. Stop preserves the `healthie-platform_postgres_data` volume. `bin/preview` rebuilds/rebinds the web service to the current checkout, preserving the shared data services. The loopback preview is http://127.0.0.1:3000.

Native Ruby/Node tooling uses `mise exec -- bin/bootstrap`, `mise exec -- bin/check`, and `mise exec -- bin/acceptance`. PostgreSQL is at loopback port 55432 with separate `healthie_development` and `healthie_test` databases; Redis is at loopback 56379 with environment namespaces. Credentials in Compose are deliberately local development fixtures. Do not expose these ports publicly.

`mise exec -- bin/reset-test-data healthie_test` resets only the disposable local test database and its cache namespace. It rejects other target names and remote database hosts. Ordinary preview/start/check never reset development data. Do not remove the volume to rehearse or test a feature.

Playwright runs headed Chromium by default on this Mac. Its own test Rails server binds to 127.0.0.1:3100 with RAILS_ENV=test. CI uses headless Chromium and uploads its HTML report, trace and actual screenshots as the PR's durable QA artifact. Artifact retention is 30 days; retain/reupload required interview evidence before expiry. Domain seeds will be added with their entities.

When a managed worker cannot launch macOS GUI processes, the operator runs `bin/qa-browser-host start` from a native terminal. QA then runs `env -u CI HEALTHIE_QA_BROWSER_WS_FILE=/Users/smh/dev/healthie-platform/tmp/symphony/browser-ws mise exec -- bin/acceptance`. The file is a local control secret: it is mode 0600 under ignored runtime state and its contents must never be printed or published. Playwright still creates an isolated test context and drives the headed Chromium process; `bin/qa-browser-host stop` remains an operator lifecycle action.

## Native Symphony controls

`bin/setup-symphony` copies the installed Symphony source into ignored project runtime storage, applies the checked-in dispatch gate, builds it, and runs focused gate tests. The original source checkout remains untouched. Supply SYMPHONY_SOURCE_DIR to use another compatible source; installation refuses an unknown tracker interface. Stop before rebuilding. LINEAR_API_KEY is inherited in memory, never written by the launcher.

Run `bin/check-symphony` for the complete deterministic gate seam without rebuilding or interrupting the live scheduler. It covers Todo claim and safe idle, review/Blocked reconstruction, persistent pause, same-ticket feedback resume, duplicate ownership, Done release, tracker failure and prerequisite states (including canceled-but-undelivered blockers).

The focused check also enters the project from a cold login shell, activates mise, and verifies that a nested Bash child resolves the pinned Ruby and Node. Symphony's create/before-run hooks and Codex launcher activate mise before invoking child scripts so a login shell cannot fall back to system Ruby or an unrelated Node installation.

`bin/symphony start|status|stop` controls the native process and records its PID under ignored tmp/symphony. Dashboard/state API: http://127.0.0.1:4010/ and /api/v1/state. Logs are under tmp/symphony. `pause` and `resume` persistently close/open **new dispatch**; stop the process as well to interrupt existing execution.

The gate polls Linear for project review/blocked/active ownership, persists the selected issue UUID atomically, and releases it only after Done. Feedback Todo can only resume that UUID; canceled/missing owners fail closed for operator resolution. Blockers must explicitly be Done, including before resuming In Progress. The pause marker and owner survive runtime restart. Tracker errors fail closed. A separate operator reviews QA/CI and merges under the scoped overnight delegation.
