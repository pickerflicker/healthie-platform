# PIC-275 independent QA report

Status: **PASS**
Tested candidate: `d5c0565c3503e555c0d47ed3e37b336159fa8dbb`
Upstream main base: `d24424cc8a10c6210b3c372b3c5f11d3e511028e`
Operator-prepared start: `d997ecc8a7257f8022ad9195e94083dc99017104`
Workspace/branch: `/Users/smh/dev/healthie-platform-workspaces/PIC-275` / `pic-275-local-symphony`
PR: https://github.com/pickerflicker/healthie-platform/pull/3
QA session after operator restart: `01a159f0-3bb6-7031-a96b-ff68d5d06e62` (`/root/qa`)
QA session before operator restart: `01a159e2-0fd0-73e2-9f1c-13d22e9a7a25` (`/root/qa`)
QA model: workflow-inherited `gpt-5.6-sol`
Run time: 2026-10-20T15:33:41Z

## Conclusion

PIC-275 passes independent QA at `d5c0565`. The complete deterministic scheduler seam passes, the operator-restarted live scheduler is running the candidate gate and workflow with the same persisted PIC-275 owner/workspace, the private repository and pinned toolchains are reachable, and the required connected headed Chromium acceptance run passes with a real screenshot.

The live Linear queue did not contain a second Todo issue during this run. Therefore review, Blocked, pause, feedback-resume, Done-release, duplicate-owner and prerequisite behavior are proven by the deterministic tracker/process seam, while the live evidence is limited to the deliberately activated PIC-275 claim, restart preservation, one-owner/one-workspace state, preview persistence and safe queue observation. This distinction does not hide a live second-ticket test.

## Evidence

### Candidate and private-repository provenance

- The sandbox-safe Git view, `git --git-dir="$PWD/tmp/developer-git" --work-tree="$PWD" rev-parse HEAD`, returned `d5c0565c3503e555c0d47ed3e37b336159fa8dbb`.
- That Git view reported only `docs/qa/PIC-275/` as untracked QA evidence; it reported no application/orchestration source edits by QA.
- `git ls-remote --exit-code origin HEAD` succeeded against the private GitHub repository. The remote `pic-275-local-symphony` ref and PR #3 head both resolved to `d5c0565`; PR #3 was open, mergeable and had a successful `check` run.
- `gh auth status` reported an active keyring-backed GitHub account. No credential value was recorded.

### Deterministic lifecycle and application checks

- `mise exec -- bin/check-symphony` -> PASS: 9 tests, 0 failures, followed by `Nested shell toolchain uses Ruby 3.4.11 and Node 22.22.2`.
- The focused seam covers Todo claim without a readiness label and safe idle; In Review/Blocked owner reconstruction and second-ready hold; restart persistence; same-ticket feedback resume; explicit pause; duplicate ownership; missing/canceled owner fail-closed behavior; tracker failure; Done release; and prerequisite gating, including canceled-but-undelivered blockers.
- `mise exec -- bin/check` -> PASS: Zeitwerk check, RuboCop (25 files, no offenses), and Rails test (1 run, 5 assertions, 0 failures).
- Native tool probes selected Ruby 3.4.11, Node 22.22.2 and npm 10.9.7. The trusted Symphony source selected Elixir 1.19.5 / OTP 28, and the installed escript returned its CLI usage.

### Restarted native scheduler and source/build provenance

- The canonical candidate gate and installed live runtime gate had the same SHA-256: `2ba66d31652784adab0e62aef525f54420a5dc649ac88502ccf314c6af219895`.
- The candidate workspace workflow and canonical live workflow had the same SHA-256: `a1c05e2827327e802fe534151aa6e5634ced4d5aa0feb613362033748beea959`.
- The installed escript SHA-256 was `342db40540514a01db17b06802109f0c7d89576551f35a8b55109b4a15f85911`, matching the operator restart checkpoint. Its source, compiled gate module and escript timestamps preceded the restart PID-file timestamp.
- `lsof -nP -iTCP:4010 -sTCP:LISTEN` showed exactly one native `beam.smp` listener on `127.0.0.1:4010`; its current working directory was the canonical ignored Symphony runtime.
- The canonical owner file contained PIC-275's exact Linear UUID, `c6a99b59-ddd7-4677-b370-096b8b3c194e`; the pause marker was absent.
- The state API reported `running=1`, `retrying=0`, issue PIC-275, and workspace `/Users/smh/dev/healthie-platform-workspaces/PIC-275`. The workspace root contained only that ticket workspace.
- `WORKFLOW.md` pins project slug `c6cbdb1032a3`, a 10-second polling interval, one concurrent agent, and `gpt-5.6-sol`. The live scheduler's successful Linear poll/claim and active Codex session prove the hosted tracker/model shell boundary without exposing credentials.

### Live tracker state and queue boundary

- Linear reported project `healthie-platform`, slug `c6cbdb1032a3`; PIC-275 was `In Progress`; prerequisite PIC-274 was `Done`; parent PIC-273 remained `Backlog` and outside execution.
- PIC-276 through PIC-281 were Backlog, not Todo. PIC-271, PIC-272 and PIC-274 were explicitly observed as Done; no historical review/canceled state was silently treated as delivered.
- There was no second live Todo issue to mutate through review/pause/Blocked. Its non-dispatch guarantee is the deterministic seam's evidence; the live observation proves no other issue was queued or activated after restart.
- The same PIC-275 owner, branch, PR and workspace survived the operator rebuild/restart. The operator lifecycle comment records the initial paused restart, zero running/retrying work while paused, and resumption of PIC-275 only.

### Required actual headed Chromium acceptance

Command:

```sh
env -u CI HEALTHIE_QA_BROWSER_WS_FILE=/Users/smh/dev/healthie-platform/tmp/symphony/browser-ws mise exec -- bin/acceptance
```

Result: **PASS** — 1 Playwright test passed in 1.6 seconds; the browser action took 385 ms. Playwright connected to the operator-owned loopback headed Chromium host through the ignored mode-0600 endpoint file, created an isolated browser context, navigated to the isolated Rails test server's `/up`, asserted HTTP 200 and verified the rendered green health page.

The run produced `test-results/health-Rails-is-healthy-in-the-isolated-browser-test-server/test-finished-1.png`. Its SHA-256 exactly matched the retained canonical screenshot, [`health-headed.png`](health-headed.png): `a9070a5182ad2c6ac2ce770ca3506506c82cf7a9a431b7354dea7b7af972bc2f`. QA visually inspected the 1280x720 PNG and confirmed the expected solid green Rails health page. The private browser control endpoint was neither printed nor published.

### Preserved preview and role handoff

- `curl http://127.0.0.1:3000/up` returned HTTP 200 after the scheduler restart.
- PostgreSQL, Redis and web containers were healthy on loopback-only ports. Container inspection showed the web preview mounts `/Users/smh/dev/healthie-platform-workspaces/PIC-275` at `/app`.
- The preview remained running throughout QA and was not restarted or stopped by QA.
- Developer and QA Workpads identify the sole Developer session(s), this sole independent QA role/session(s), exact candidate/base, shared workspace, commands, repair-cycle findings and outstanding risk. The operator explicitly recorded that a scheduler restart cannot preserve in-memory LLM sessions; persisted workpads/evidence preserved the role handoff without authorizing a concurrent replacement team.
- QA changed only this report/evidence area and did not change Linear state or application/orchestration source.

## Acceptance assessment

- Native macOS Symphony authentication, 10-second polling, Todo/In Progress claim without a readiness label and exclusive ownership: **PASS**. Private Git/Linear access, one scheduler listener, persisted owner and candidate runtime provenance are evidenced.
- Exactly one Developer plus one independent QA role, shared workspace, logged assumptions and real headed Chromium evidence: **PASS**. Actual session identities are recorded above and in the workpads; the parent spec remains Backlog.
- Durable project slot during In Review, Blocked, pause and restart; same-ticket feedback resume; two-cycle Blocked contract: **PASS at the deterministic boundary**, with live restart preservation of PIC-275 independently observed. No second live Todo existed, so no broader live claim is made.
- Deliberate end-to-end smoke, role handoff, preserved preview, feedback resume, safe idle/release and prerequisite handling: **PASS with split evidence**. Live evidence covers the deliberate PIC-275 claim, restart-only resume, role handoff, preview and no unintended run. Feedback, lifecycle holds, safe idle/Done release and blocker branches pass deterministically.
- Required deterministic tracker/process validation: **PASS** (9 tests, 0 failures, plus nested-shell regression).
- Private clone/toolchain/model shell and actual headed browser execution: **PASS**.
- Second-ready hold, preview persistence, explicit merged/Done release and finish without unintended active work: **PASS with evidence boundary**. The hold/release branches are deterministic; the preview and single intended live PIC-275 run are direct observations.

## Outstanding risk

No QA blocker remains for PIC-275. The operator should review this report and CI, commit/push the refreshed evidence, transition the ticket to In Review, preserve the running preview and project owner, and merge only under the scoped overnight authority. The project slot must not release until verified merge and Done.
