# Developer and QA interview team

Developer is Symphony's parent session and sole application implementation owner. Read the issue and relevant glossary/ADRs, log notable assumptions on the issue, implement, self-review and run focused checks. Then use exactly one persistent independent QA subagent in the same ticket workspace. Reuse the QA session for repairs. There is no additional reviewer or recursive delegation.

QA starts/exercises the app with headless Playwright Chromium, verifies acceptance criteria and denied-access boundaries, and captures real screenshots. QA may write tests and evidence; Developer owns application-source edits. Test runs use the isolated test database/cache while the human preview retains its seeded development data.

Maintain Developer and QA Workpads in Linear with actual session identity, commit, commands/results, findings and outstanding risks. The issue description owns the acceptance checklist; Developer checks it only after matching QA evidence. The PR owns the single canonical QA report/screenshots; Linear contains a concise outcome, tested commit and PR-report link. Recheck and refresh the report after feedback.

Read `docs/agents/triage-labels.md` for the full lifecycle. One ticket holds the slot through In Review or Blocked; another ticket must not start. Steven moves ready work to Todo, agents mark actual execution In Progress, and QA-passed work goes to In Review. Keep the tested preview running. Steven manually merges; Done releases the slot. Feedback in Todo resumes the same branch/PR. After two failed repair cycles, preserve work and record a concrete Blocked report for Steven to reproduce and provide feedback.

Use guarded status transitions during Symphony execution. Keep secrets out of reports. Preserve dirty work and keep all app infrastructure on the laptop. Focus tests on observable behavior, migrations/constraints and access boundaries; no coverage quota or broad browser matrix. Before runtime activation, validate the actual project-wide review gate rather than relying only on an agent prompt.
