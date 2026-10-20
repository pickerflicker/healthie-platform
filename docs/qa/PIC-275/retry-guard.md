# PIC-275 retry guard QA

Independent QA of commit `6455711d6a33e34bfe7e758b246c56bbf07f8e92`, 2026-10-20.

Result: PASS for the focused retry repair and browser smoke acceptance.

- Runtime protocol regression: `mise exec -- mix test test/symphony_elixir/healthie_retry_protocol_test.exs` from `tmp/symphony/runtime`: 1 test, 0 failures. Fake app-server sends `turn/completed` with failed status; patched AppServer returns an error.
- `bin/check-symphony`: RunGuard 3 tests, 0 failures; project gate 9 tests, 0 failures; nested Ruby/Node toolchain passes.
- `HEALTHIE_QA_BROWSER_WS_FILE=/Users/smh/dev/healthie-platform/tmp/symphony/browser-ws mise exec -- bin/acceptance`: 1 Playwright test passed. Screenshot: `test-results/health-Rails-is-healthy-in-the-isolated-browser-test-server/test-finished-1.png`.
- Reviewed WORKFLOW.md, installer and isolated runtime call sites: failed/interrupted completions become errors, failures persist by issue, second consecutive error writes checkpoint and global pause, successful turns clear failure count, configured four total turns checkpoint when issue remains active.
- WORKFLOW config selects gpt-6.1-sol with low effort and instructs QA to inherit both. Playwright defaults to headless Chromium (`HEADED` must explicitly equal true to override).
- Runtime remains stopped and paused: `bin/symphony status` reported `PID=None paused=True`. QA did not resume, restart, merge, or change Linear.

Scope: focused fixture and unit checks plus existing Rails browser health acceptance. No live retry loop was started; no broad upstream suite was rerun. Module-redefinition warnings were non-fatal.

## Bounded aborted-session follow-up

Independent recheck of `6455711`: RunGuard 4 tests, 0 failures; focused runtime protocol regression 1 test, 0 failures. Reviewed installer and rebuilt runtime: `begin_attempt` executes before `run_on_worker_host`; the third attempt without a successful turn returns an error and persists a global pause/checkpoint, bounding killed or stalled sessions. Successful turn cleanup removes both failure and attempt counters. Runtime still reports `PID=None paused=True`.

The browser and gate evidence above was collected on the preceding repair commit; unchanged browser/gate sources were not rerun for this follow-up. No actionable findings in the added guard.
