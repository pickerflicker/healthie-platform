# healthie-platform

Rails interview pre-work with laptop-local infrastructure. Use this repository's instructions and context; do not use Steven's second-brain skills for this project. Preserve secrets, unrelated projects and dirty user changes.

The execution team remains Developer (parent and sole application implementation owner) plus one independent QA subagent. One ticket holds the project slot through implementation, QA and human review.

## Required reading

- Before planning or changing scope, read [CONTEXT.md](CONTEXT.md) for accepted product decisions and interview boundaries.
- Before implementation, QA or reviewing delivery evidence, read [docs/agent-team.md](docs/agent-team.md). It owns role responsibilities, delegation, validation and reporting requirements.
- Before resuming a ticket or reviewing a feedback repair, read [docs/agents/pr-feedback.md](docs/agents/pr-feedback.md). PR comments, submitted reviews and inline threads are the review-feedback source.
- Before changing or reviewing authorization, record lookups or ownership parameters, read [docs/agents/authorization.md](docs/agents/authorization.md) for Pundit conventions and required denial checks.
- Before generating, publishing or reviewing QA evidence, read [docs/agents/qa-evidence.md](docs/agents/qa-evidence.md). Reports and uploaded screenshots belong in one PR comment; generated evidence must stay out of Git.
- Before publishing or fetching tracker work, read [docs/agents/issue-tracker.md](docs/agents/issue-tracker.md) for the existing Linear project and publishing conventions.
- Before authoring execution settings or changing the agent launcher, read [docs/agents/execution-settings.md](docs/agents/execution-settings.md) for the ticket format and fixed-model/effort/Fast contract.
- Before claiming work, changing status or handing off a ticket, read [docs/agents/triage-labels.md](docs/agents/triage-labels.md). It owns readiness, dependencies, slot ownership, repair limits and review/merge lifecycle.
- Before queueing, reviewing or merging work, read [docs/overnight-delegation.md](docs/overnight-delegation.md) for current authority. Overnight delegation is inactive.
- Before runtime setup, activation, recovery or browser acceptance, read [docs/operations.md](docs/operations.md). Validate actual runtime readiness and exclusive scheduler ownership before activation; documented plans are not running-system evidence.
- Before domain modeling, spec writing, ticketing, implementation or code review, read [docs/agents/domain.md](docs/agents/domain.md) for glossary and ADR requirements.

[WORKFLOW.md](WORKFLOW.md) owns Symphony configuration and the per-issue execution prompt; its launcher applies ticket execution settings. Follow its runtime limits when executing tickets.
