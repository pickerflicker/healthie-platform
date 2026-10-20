# Local operations

Canonical checkout: `/Users/smh/dev/healthie-platform`.
Code/PR repository: https://github.com/pickerflicker/healthie-platform (private).
Tracker identity and publishing: [agents/issue-tracker.md](agents/issue-tracker.md). Ticket lifecycle and review gate policy: [agents/triage-labels.md](agents/triage-labels.md). Developer/QA validation and evidence: [agent-team.md](agent-team.md). Read [overnight-delegation.md](overnight-delegation.md) before queue/review/merge actions.

## Local runtime contract

Docker Desktop supplies Docker and Compose. One persistent local Compose stack contains Rails, PostgreSQL and Redis. Keep Postgres and Redis running between tickets; restart/rebind Rails against the selected ticket workspace rather than creating per-ticket service stacks. Keep database data in a persistent local named volume, with separate development and test databases/cache namespaces in the same services. When switching tickets, restore the selected branch's schema and intentional seed baseline and clear only the project cache. Rails preview binds to loopback; preserve it under the review lifecycle in [agents/triage-labels.md](agents/triage-labels.md).

Symphony runs natively on macOS using [WORKFLOW.md](../WORKFLOW.md), which owns polling, workspace and launch configuration. Configure runtime logs under this checkout's ignored `tmp/` tree. Configuration alone is not evidence of provisioned directories or a running system.

Use mise-managed tool versions. The current bootstrap/check/preview/acceptance commands are `bin/bootstrap`, `bin/check`, `bin/preview` and `bin/acceptance`; update their implementations as part of local Compose setup. Exact local start/pause/resume commands and the state API port must be recorded after validation.

## Activation prerequisites

Before activating any implementation ticket, verify local dependencies and authentication, ensure exactly one scheduler owns the Linear project, and prove the project-wide one-ticket gate. `max_concurrent_agents: 1` only limits executing tickets; it does not prevent dispatch during another ticket's In Review or Blocked state. The gate must survive restart and resume feedback on the same branch/PR.

Apply the readiness, dependency, feedback and repair rules in [agents/triage-labels.md](agents/triage-labels.md).

## Status

Skill configuration and candidate local workflow are documented. Docker Compose provisioning, native Symphony activation, review-gate implementation and end-to-end smoke remain pending. GitHub-to-Linear integration is a follow-up after base setup; verify it before assuming that merging a PR updates the ticket to Done.

## Verified Compose entry points

Use `bin/stack up` to build and start the single project stack, prepare both databases, and wait for health. `bin/stack status`, `bin/stack logs`, and `bin/stack stop` inspect or stop this project. Stop preserves the `healthie-platform_postgres_data` volume. `bin/preview` rebuilds/rebinds the web service to the current checkout, preserving the shared data services. The loopback preview is http://127.0.0.1:3000.

Native Ruby/Node tooling uses `mise exec -- bin/bootstrap`, `mise exec -- bin/check`, and `mise exec -- bin/acceptance`. PostgreSQL is at loopback port 55432 with separate `healthie_development` and `healthie_test` databases; Redis is at loopback 56379 with environment namespaces. Credentials in Compose are deliberately local development fixtures. Do not expose these ports publicly.

`mise exec -- bin/reset-test-data healthie_test` resets only the disposable local test database and its cache namespace. It rejects other target names and remote database hosts. Ordinary preview/start/check never reset development data. Do not remove the volume to rehearse or test a feature.

For when browser acceptance applies and its browser mode, follow [agent-team.md](agent-team.md). Set `HEADED=true` for an explicitly requested visible demonstration. Playwright's own test Rails server binds to 127.0.0.1:3100 with RAILS_ENV=test. Publish the canonical table and embedded screenshots as one PR comment under [agents/qa-evidence.md](agents/qa-evidence.md). CI HTML reports/traces are secondary downloads with 30-day retention, not the canonical report or inline image host. Domain seeds will be added with their entities.

When a managed worker cannot launch Chromium directly, the operator runs `bin/qa-browser-host start` from a native terminal. QA then runs `env -u CI HEALTHIE_QA_BROWSER_WS_FILE=/Users/smh/dev/healthie-platform/tmp/symphony/browser-ws mise exec -- bin/acceptance`. The file is a local control secret: it is mode 0600 under ignored runtime state and its contents must never be printed or published. Playwright still creates an isolated test context; `bin/qa-browser-host stop` remains an operator lifecycle action.

## Native Symphony controls

`bin/setup-symphony` copies the installed Symphony source into ignored project runtime storage, applies the checked-in dispatch gate, builds it, and runs focused gate tests. The original source checkout remains untouched. Supply SYMPHONY_SOURCE_DIR to use another compatible source; installation refuses an unknown tracker interface. Stop before rebuilding. LINEAR_API_KEY is inherited in memory, never written by the launcher.

Run `bin/check-symphony` for the complete deterministic gate seam without rebuilding or interrupting the live scheduler. It covers Todo claim and safe idle, review/Blocked reconstruction, persistent pause, same-ticket feedback resume, duplicate ownership, Done release, tracker failure and prerequisite states (including canceled-but-undelivered blockers).

The focused check also enters the project from a cold login shell, activates mise, and verifies that a nested Bash child resolves the pinned Ruby and Node. Symphony's create/before-run hooks and Codex launcher activate mise before invoking child scripts so a login shell cannot fall back to system Ruby or an unrelated Node installation.

`bin/symphony start|status|stop` controls the native process and records its PID under ignored tmp/symphony. Dashboard/state API: http://127.0.0.1:4010/ and /api/v1/state. Logs are under tmp/symphony. `pause` and `resume` persistently close/open **new dispatch**; stop the process as well to interrupt existing execution.

The operator owns scheduler lifecycle. Workers must not stop or restart their own scheduler. The gate owner UUID is stored in this checkout's ignored `tmp/symphony/gate/owner` file. Use `mise exec --` for native Ruby/Node tools; Docker CLI is `/Applications/Docker.app/Contents/Resources/bin/docker`. Private git/gh and existing LINEAR_API_KEY authentication are inherited; never print credential contents.

Native creation, before-run and Codex launch all source canonical `script/native_bundle_env` from the ticket workspace. This selects host gems under `tmp/bundle` and isolates native Bundler configuration under `tmp/native-bundle-config`; worker commands inherit both settings. Keep workspace `.bundle/config` free of host-only paths because Docker bind-mounts the workspace and uses its own Linux bundle. The before-run hook installs missing dependencies when its check fails, including gems added during an earlier feature turn. Hook errors still fail preflight and remain subject to the bounded recovery gate. For manual native work, source the same helper before invoking Bundler/Rails.

The gate polls Linear for project review/blocked/active ownership and persists the selected issue UUID atomically to enforce [agents/triage-labels.md](agents/triage-labels.md). Feedback Todo can only resume that UUID; canceled/missing owners fail closed for operator resolution. The pause marker and owner survive runtime restart. Tracker errors fail closed. Queue/review/merge authority is defined in [overnight-delegation.md](overnight-delegation.md).

## Token and retry bounds

Model/effort/Fast selection is defined in [agents/execution-settings.md](agents/execution-settings.md); QA responsibilities are in [agent-team.md](agent-team.md). A completed notification with failed/interrupted status is a failure, never a success continuation. One automatic recovery is allowed; a second consecutive worker failure writes a persistent dispatch pause and a concise `tmp/symphony/gate/checkpoint.json`. Successful turns clear consecutive failures. Four continuation turns without leaving active state also pause dispatch. The operator diagnoses the checkpoint, fixes the underlying cause and uses `bin/symphony resume`; it must not blindly clear an unchanged checkpoint on every heartbeat. Ticket ownership and preview remain intact.

## Ticket launcher validation

Run `bin/check-codex-launcher` for deterministic parsing, identity/ownership, request-failure and process-handoff checks using synthetic ticket data. Run `bin/check-codex-launcher --codex` before enabling or changing launch settings: it also starts the installed Codex app-server for all three effort levels with Fast on/off, reads effective configuration and QA defaults, then terminates each probe. It creates no threads, starts no model turns, changes no tickets and does not control the live Symphony process.

From the selected issue workspace, `/Users/smh/dev/healthie-platform/bin/codex-for-ticket --check` validates the real owner/ticket and prints only the non-secret selection without starting Codex or writing a receipt. It requires the inherited Linear credential and a valid active owner. Avoid copying or printing the credential to run this check.

The workflow invokes the canonical launch adapter by absolute path, so an existing ticket clone does not need a newer script before it can launch. The per-issue prompt also names the canonical team/execution policy for the same reason. Keep the canonical checkout available. `codex.read_timeout_ms` is 20000: Symphony starts its initialization timer before the adapter's ten-second total lookup deadline, so the additional time covers shell/Codex startup. The deterministic launcher suite checks this cross-configuration budget. No Symphony rebuild is needed; workflow reload affects future launches. Do not restart an existing worker merely to apply a new ticket setting. Store the adapter, policies and workflow in version control together before using the setup on another machine.

GitHub/Linear completion convention and verified fallback: [github-linear.md](github-linear.md).
