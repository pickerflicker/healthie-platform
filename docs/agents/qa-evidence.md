# QA evidence on the pull request

Publish one canonical PR Conversation comment with marker `<!-- healthie-qa-report -->`. Update that same comment after repairs rather than creating a report per feature revision. This policy supersedes older instructions that linked to committed `docs/qa` reports/screenshots.

## QA ownership and completion

QA owns creating and maintaining the test-case table, real captures, accurate results and screenshot uploads in the canonical PR comment. If QA cannot publish through its tools, return the report and ignored artifact paths to Developer for publication while retaining QA's actual session identity and findings. QA handles routine publishing corrections and reports genuine failures honestly.

Developer uses QA's outcome and report link for the existing handoff. There is no separate Developer/operator validation or approval of the report's table, test-case rows, image URLs or GitHub rendering. Do not add a publication-validation test case or workpad checkpoint, keep a PR draft, or mark a ticket Blocked merely while waiting for that extra check. GitHub browser access is not a prerequisite for publishing QA evidence. This supersedes the earlier publication-validation gates, including PIC-279's browser-rendering gate.

Required feature tests, honest QA outcomes, the report and screenshots remain QA responsibilities. Keep generated evidence out of Git and run the artifact guards. The PR description and Linear QA Workpad link directly to the report; repairs update the same report and identify the revision actually retested.

## Report contract

The comment contains the tested commit, actual QA session/model, overall result and a table with these columns:

| Test case | Expected and observed behavior | Result | Screenshot / evidence |
| --- | --- | --- | --- |
| A concrete user or API scenario | Input/action, expected outcome and what actually happened | PASS / FAIL / NOT RUN | Embedded uploaded screenshot when visual evidence applies; otherwise command/assertion evidence |

Use actual captures and honest outcomes. Screenshots supplement assertions; a picture alone does not prove database or authorization behavior. Include relevant backend checks and their rationale. Put longer commands, repair notes and limitations in a collapsible details block under the table. Migration of an earlier report must retain its actual tested revision/results and clearly distinguish evidence migration from a fresh test run.

Store generated reports, screenshots, videos and traces under ignored `test-results/`, `playwright-report/` or `tmp/qa-reports/`. In Playwright, use `testInfo.outputPath(name)` or `testInfo.attach()` instead of writing into `docs/qa` or another tracked directory. Version-control reusable test code and fixtures, never per-run QA evidence. Historical files already in Git need not be rewritten out of history; they are not a pattern for future reports.

## Publish images as comment attachments

Use an official GitHub CLI with `gh pr comment --attach` support. The existing system CLI 2.92 lacks it; the checksum-verified official 2.102 binary used for this project's first migration is at canonical `tmp/qa-tools/gh-2.102.0/gh_2.102.0_macOS_arm64/bin/gh`. An equivalent updated official CLI on PATH is fine. Check `gh pr comment --help` for `--attach` before publishing; if unavailable, obtain an official supported version or use GitHub's normal attachment UI. Do not fall back to committing files or making private evidence public.

Write the report to an ignored local Markdown file. Reference local images as `![Meaningful description](./provider-home.png)` in table cells, then run from that evidence directory:

```sh
gh pr comment PR_NUMBER --repo pickerflicker/healthie-platform \
  --body-file report.md --attach ./provider-home.png --attach ./client-home.png
```

GitHub CLI uploads the images and rewrites the local image references to GitHub attachment URLs. This preserves private repository access controls and adds no Git blobs. Do not use repository `blob`/`raw` image links, local paths, base64 images or expiring Actions download URLs as the inline screenshots.

Before publishing, find the existing comment by marker. To update it, upload new images in a temporary marked comment, replace the canonical comment's body using the resulting uploaded URLs, then delete only that temporary comment. Never edit/delete unrelated comments. `--edit-last` is appropriate only after verifying that the last comment is the canonical QA report.

CI artifacts may retain full HTML reports/traces as a secondary diagnostic download; they expire under the configured retention and are not the canonical report. The PR body and Linear QA workpad must link directly to the canonical comment. Linear keeps its concise result/tested revision/link and backend-check explanation. QA reports failed uploads honestly and handles corrections; screenshots still belong on the PR, never in Git.

## Repository guard

Run `bin/check-qa-artifacts` before committing to check staged additions/modifications. CI runs `bin/check-qa-artifacts --base BASE_SHA` against the PR/push diff. Generated QA directories are rejected, including forced additions that bypass `.gitignore`. Deleting old evidence after attachment publication is allowed. Intentional application assets and reusable test fixtures outside these output directories remain ordinary source files.

GitHub references: [attachments and private repository visibility](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/attaching-files), [GitHub CLI attachment handling](https://cli.github.com/manual/gh_pr_comment).
