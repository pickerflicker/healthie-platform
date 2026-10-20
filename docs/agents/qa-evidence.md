# QA evidence on the pull request

Publish one canonical PR Conversation comment with marker `<!-- healthie-qa-report -->`. Update that same comment after repairs rather than creating a report per feature revision. This policy supersedes older instructions that linked to committed `docs/qa` reports/screenshots.

## QA ownership and completion

QA owns the test-case table, captures and accurate results. If QA cannot publish through its available tools, return the complete report and ignored artifact paths to Developer for publication; retain QA's actual session identity and findings. Developer verifies publication before the review handoff.

Evidence publication is complete only when:

1. QA has inspected the actual local captures. The supported GitHub attachment upload succeeds for every required screenshot. Re-read the saved canonical comment through the authenticated CLI/API: confirm the tested revision, expected test rows, valid Markdown table structure, and embedded GitHub attachment URLs corresponding to every uploaded capture. No local image paths or unresolved upload placeholders remain.
2. The staged changes and final PR diff contain no generated QA evidence; run the repository guard for both applicable comparisons.
3. The PR description and Linear QA Workpad link directly to that comment. Repairs update the same report and identify the revision actually retested. Missing/failed uploads, a malformed table or a known broken attachment remain publication gaps to fix before handoff.

### Browser rendering is supplemental

Opening GitHub to inspect the rendered comment is optional when permitted browser access is already available. Unavailable or declined GitHub browser access alone does not block publication, make the PR stay draft or justify moving a ticket to Blocked when the checks above pass. Record `GitHub rendering: NOT RUN (supplemental)` if it was not checked; do not label it PASS or conflate successful upload/saved-body checks with visual rendering. An observed rendering/attachment defect still needs repair.

GitHub browser permission is separate from the application's required Playwright browser acceptance. This change does not relax feature testing or screenshot requirements. Respect a denied browser origin; do not retry it or use alternate browser/image-fetch routes to bypass the denial. Verify the permitted upload and saved-comment operations above instead, without claiming that they check rendering. This policy supersedes the earlier mandatory rendered-table/all-images check that blocked PIC-279.

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

GitHub CLI uploads the images and rewrites the local image references to GitHub attachment URLs. This preserves private repository access controls and adds no Git blobs. Verify the saved comment contains uploaded image URLs and all expected table rows before removing any old source-tree evidence. Do not use repository `blob`/`raw` image links, local paths, base64 images or expiring Actions download URLs as the inline screenshots.

Before publishing, find the existing comment by marker. To update it, upload new images in a temporary marked comment, replace the canonical comment's body using the resulting uploaded URLs, verify it, then delete only that temporary comment. Never edit/delete unrelated comments. `--edit-last` is appropriate only after verifying that the last comment is the canonical QA report.

CI artifacts may retain full HTML reports/traces as a secondary diagnostic download; they expire under the configured retention and are not the canonical report. The PR body and Linear QA workpad must link directly to the canonical comment. Linear keeps its concise result/tested revision/link and backend-check explanation. A missing screenshot upload is a publication gap; report it rather than silently putting evidence in Git or claiming completion.

## Repository guard

Run `bin/check-qa-artifacts` before committing to check staged additions/modifications. CI runs `bin/check-qa-artifacts --base BASE_SHA` against the PR/push diff. Generated QA directories are rejected, including forced additions that bypass `.gitignore`. Deleting old evidence after attachment publication is allowed. Intentional application assets and reusable test fixtures outside these output directories remain ordinary source files.

GitHub references: [attachments and private repository visibility](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/attaching-files), [GitHub CLI attachment handling](https://cli.github.com/manual/gh_pr_comment).
