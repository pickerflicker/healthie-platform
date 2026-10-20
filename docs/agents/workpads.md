# Concise Linear workpads

Maintain one Developer Workpad and one QA Workpad per ticket, updated in place. Their purpose is to show current progress, evidence and the next action at a glance. The detailed test-case table, commands, screenshots and repair evidence belong in the [canonical PR QA report](qa-evidence.md).

## Format

- Use Markdown headings, short bullets, descriptive links and a small check/result table. Put blank lines around headings, lists and tables. Use real newlines, never literal `\n` text.
- Start with **Status** and the current PR/tested commit. A blocker belongs near the top with its owner and exact unblock action.
- Aim for 150–250 words per workpad; use fewer when sufficient. Add detail only for a concrete unresolved finding or reproduction that cannot be conveyed by a direct evidence link.
- Keep **Changes / Findings** to three short bullets. Give **Checks** one row per meaningful check, with counts or the important observed result. Distinguish PASS, FAIL, NOT RUN and evidence reported by another role from checks actually performed by this role.
- End with one compact **Run** line: actual session identity, model, effort, Fast setting and base/tested commit. QA records its own session and parent identity. Long identifiers are metadata, not narrative.
- Replace stale status and resolved findings. Keep only unresolved actions and consequential decisions; a workpad is not an append-only activity log. Preserve necessary earlier evidence in the canonical PR report before shortening it.
- Link full PR feedback dispositions or backend evidence when long. For a backend check, briefly state the boundary checked, why it matters and expected versus observed results; link the report's commands and inputs. Preserve actionable reproduction steps, honest evidence gaps and the responsible person.

Skip repeated acceptance criteria, policy-reading inventories, routine gate checks, raw tool output and repeated claims that no feedback exists. Keep the issue description as the sole acceptance checklist. Follow [agent-team.md](../agent-team.md) for actual review, independent validation and handoff requirements; concise reporting does not waive them.

## Developer shape

```markdown
## Developer Workpad

**Status:** In progress / Blocked / Ready for review — one-sentence outcome.
**PR:** [PR link] · **Candidate:** `commit`
**Blocker:** Exact gap, owner and unblock action. Omit when clear.

### Changes

- Main behavior delivered or pending.
- Consequential decision or unresolved finding.

### Checks

| Check | Result |
| --- | --- |
| Self-review | PASS / concrete finding |
| Targeted checks | Counts and key result |
| Independent QA | Outcome · [report](url) |

**Next:** One concrete action and owner.
**Run:** Session · model · effort · Fast · base/candidate.
```

QA uses the same layout with **Findings** instead of Changes and its own checks, tested revision and session. State behavior and publication outcomes separately when one remains incomplete.
