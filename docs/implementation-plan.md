# Interview pre-work implementation plan

The current repository is a stateless Rails 8.1.4 / Ruby 3.4.11 skeleton. The accepted scope is recorded in `CONTEXT.md`, `GLOSSARY.md` and `docs/adr/`; employer requirements are in `docs/interview-brief.md`.

1. Publish a spec and propose dependency-aware implementation tickets using `docs/agents/issue-tracker.md` and `docs/agents/triage-labels.md`. New tickets remain in Backlog until Steven authorizes them through Todo.
2. Provision the laptop-only base: Docker Desktop and one Compose stack for Rails, PostgreSQL and Redis. Run Symphony natively on macOS with 10-second polling.
3. Implement and validate exclusive scheduler ownership plus the one-ticket-through-review dispatch gate. The same ticket resumes after feedback or Blocked recovery; In Review keeps the app preview running without starting another ticket.
4. After initial base setup, connect the GitHub repository to Linear and verify merge-to-Done automation.
5. Implement the agreed User/profile model, Devise login, Pundit policies, enrollments, journals, indexes, intentional seeds and the four required queries in small end-to-end slices.
6. Add only the client provider-list Redis cache, with the agreed invalidation rules and authorization independent of cache contents.
7. Validate each ticket with Developer checks and independent headed Playwright Chromium QA. Publish the canonical report/screenshots on the PR and a concise result/commit/link in Linear. Steven manually merges each PR.

Board: https://linear.app/pickerflicker/project/healthie-platform-c6cbdb1032a3.
The initial skeleton setup and smoke were tracked in PIC-271/PIC-272; those do not prove the new local runtime is ready.

Implementation readiness requires actual local startup and workflow evidence. All application services and data run on the laptop; Linear, GitHub and the AI provider remain hosted dependencies.
