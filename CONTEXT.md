# Interview preparation context

Status: Steven confirmed the infrastructure design as agreed. The agreed pre-work scope has been synthesized into docs/spec.md and published as Linear spec parent PIC-273 in Backlog. The local infrastructure design is recorded here; runtime provisioning and GitHub/Linear integration remain pending. Repository configuration is not proof of a running local system.

## Confirmed intent

There are two phases: pre-work now, then live interview pairing to build a feature with AI. Demonstrating the AI development setup is part of the interview. Product scope follows infrastructure decisions.

Run application infrastructure and Symphony execution on Steven's laptop, use a local containerized PostgreSQL database, and manage project containers with Docker Compose. Rails CRUD app and Redis cache are requested. Linear and GitHub remain hosted services; AI execution still requires provider connectivity.

Runtime decision: Docker Desktop manages the local app containers; Symphony runs directly on macOS (Q1 accepted).

Polling decision: Symphony polls Linear every 10 seconds (interval_ms: 10000).

Seed-data requirement: intentional, realistic baseline records populate all entities so the app is useful to browse out of the box. This dataset is the baseline for new-feature testing, not a throwaway rehearsal reset. New entities and important feature states receive sensible seed records as part of feature delivery. Exact reload and test-isolation mechanics remain to be settled.

Redis requirement: provision local Redis now; the application will cache database query responses. Cache invalidation and seed/reload interaction must be designed with the chosen product behavior.

Confirmed workspace lifecycle: one persistent local Compose stack for Rails, Postgres and Redis; separate Git ticket branches/workspaces; exactly one ticket in flight through implementation, QA and human review. Keep Postgres and Redis running between tickets and restart Rails against the selected workspace. When switching tickets, restore the selected branch schema and intentional seed baseline, and clear the project cache. Automated tests use a separate test database in the same Postgres container so they cannot erase the browsing baseline. No per-ticket service stack is needed.

QA tooling decision: use Playwright for independent browser-driven acceptance. QA exercises the ticket acceptance criteria and captures real browser screenshots. Reports identify the tested commit, actions/assertions, results, and any failures. Browser runs are local to the laptop against the selected ticket app. Confirmed browser: Playwright Chromium only, headed by default for all local QA runs so Steven can always watch QA in action. Headless is not the local default. Diagnostic traces are proposed for failures. Confirmed evidence policy: the PR holds the single canonical QA report, including screenshots, acceptance results and tested commit. Linear contains only a concise QA passed/failed outcome, tested commit and link to the PR report. After feedback, QA updates the same report for the new tested commit; do not duplicate the full report in Linear. Final screenshot/report artifact storage mechanics remain to be settled.

Confirmed feedback flow: Steven adds feedback in Linear and moves the current ticket from In Review to Todo. Symphony resumes that same ticket, moves it to In Progress, and reuses its branch and PR. Developer repairs the feedback; independent QA retests and refreshes evidence; the ticket returns to In Review. The current ticket retains priority and ownership of the single in-flight slot until merged/Done or explicitly canceled/released by Steven. In Review is inactive for coding but is a project-wide dispatch gate; max_concurrent_agents: 1 alone does not enforce this gate.

Linear queue decision: Steven moves issues from Backlog into Todo to authorize agent implementation. Todo is the readiness signal; a second ready-for-agent label should not be required. Confirmed lifecycle: Backlog is pre-build human review/refinement; Todo authorizes implementation; In Progress is active Developer/QA execution; In Review is a QA-passed PR awaiting Steven; Done follows manual merge.

The project team has two roles: Developer implements and repairs QA findings, logging notable assumptions in the Linear issue; independent QA starts the application, exercises acceptance criteria, and publishes real browser-captured screenshot evidence in Linear and the PR. Steven manually merges PRs. One ticket remains in flight through human review. In Review releases the coding session but does not authorize another ticket to start. Symphony waits until Steven merges the PR and the ticket becomes Done, or adds feedback and returns the same ticket to Todo for rework. Dependency decision: no stacked PRs. A ticket with an explicit Linear blocker waits until that prerequisite is merged and marked Done. No other Todo ticket, including independent work, may start while the current ticket awaits human review. After Done, Symphony may select the next dependency-ready Todo ticket. Each new feature branch starts from current main.

Confirmed review preview: leave the app running on the tested ticket branch during In Review so Steven can browse it. Agent coding/QA sessions stop while awaiting human review; the app preview and its database stay available until merge or feedback.

## Infrastructure design confirmation

- Confirmed pause/failure behavior: provide an explicit pause command preserving current ticket ownership, workspace, database and preview state. After two unsuccessful Developer/QA repair cycles, stop and move the current ticket to Blocked with reproduction steps and failure evidence. Steven reviews, reproduces, adds feedback and returns it to Todo. Resume the same ticket/branch/PR before any new work. Neither pause nor Blocked may dispatch another ticket.
- Confirmed browser visibility: headed Chromium is the default for every local Playwright QA run, reflecting the small project scope and Steven’s desire to always observe QA. No separate routine-headless default.
- Steven confirmed the complete infrastructure design. No further infrastructure decisions block product scoping. Implementation follows the agreed design; verify actual local readiness before claiming completion.

## Implementation and validation checklist

These implement settled requirements; they are not additional architecture choices.

- Reconcile repo instructions and workflow with local runtime, Todo readiness, shared Compose stack and one ticket in flight through review.
- Persist/reconstruct ticket ownership across Symphony restarts. Validate In Review, Blocked and pause dispatch gates; resume the same feedback branch/PR before any new work.
- Keep browser QA as well as unit tests on the test database and an isolated test Redis namespace; human preview retains its intentional development seed baseline. Use the same Postgres and Redis containers.
- Publish screenshot links that remain usable from the PR after the local workspace stops; choose a supported GitHub-hosted upload/artifact route and verify it. Do not introduce a separate hosting service merely for evidence.
- Add seed/schema handoff and project-scoped cache clearing. Product-specific cache keys and invalidation are decided with feature scope.
- Prove laptop Docker/Compose, native Symphony, browser, and required hosted-service authentication using one end-to-end setup smoke. Verify exclusive scheduler ownership of this Linear project before local activation.
- Connect the GitHub repository to Linear and verify merge-to-Done only after the initial base setup, as separately recorded below.

## Local setup readiness

The repo's operating instructions describe the laptop-only design. Before activating implementation, prove local Docker/Compose and native Symphony startup, database/cache isolation and the single-ticket review gate. Exactly one scheduler may own this Linear project. Preserve unrelated projects and user changes.

## Follow-up after initial base setup

- [ ] Connect pickerflicker/healthie-platform to Linear's GitHub integration after the initial local base setup is complete.
- [ ] Verify a closing PR link (for example, Fixes PIC-<number>) and configure/test PR merge to Linear Done. Until verified, do not assume merge-to-Done automation works; dependent tickets continue waiting for the prerequisite's Done status.

## Interview brief received

See docs/interview-brief.md and GLOSSARY.md. Two one-hour sessions each include a ~10-minute setup walkthrough, ~35-minute pairing segment and ~15-minute tradeoff discussion. Provided pre-work covers Session 1: Rails/ActiveRecord provider–client many-to-many relationships with per-relationship basic/premium plans, client journal entries and four working queries. Steven confirmed Session 2 is frontend-only and out of scope because he will not interview for it. Session 1 is not scheduled; finish pre-work as soon as possible so Steven can schedule afterward. The current skeleton disables ActiveRecord and will need it enabled with PostgreSQL during implementation. A browser CRUD UI and Redis caching are Steven's requested scope, not requirements stated by the provided Session 1 guide.

## Delivery priority

Session 1 only. Finish the pre-work as soon as possible, then Steven schedules the interview. No frontend-session preparation. Favor the required Rails models, relationship plans, journal entries, queries and useful seeds; keep optional browser UI and Redis demonstration narrow. The product baseline is synthesized in docs/spec.md and Linear PIC-273. The implementation-ticket breakdown is the next planning step.

## Confirmed authentication and role permissions

Steven requested login and role-specific provider/client experiences, and asked whether Devise or another Rails option is appropriate. This is additional product scope beyond the employer's Session 1 requirements. Confirmed: minimal Devise email/password login with seeded provider and client accounts, exactly one role per login account, and ordinary sign-out/sign-in to demonstrate different users. No admin impersonation or additional admin role in the initial baseline. No public self-registration or email workflows are included by this minimal login decision; any such feature requires separate scope agreement. Provider/client access rules must be enforced server-side, including direct record access and correctly scoped cache keys. Role permissions are defined by the confirmed journal and provider-selection decisions. Identity modeling is the confirmed explicit User role plus matching Provider/Client profile design below.

## Confirmed journal visibility

Journal entries are client-owned and client-wide. A client manages their own entries; providers may read entries belonging to their currently associated clients, including those clients' historical entries. Entries are not assigned to an individual provider or enrollment. Access to unrelated clients' entries is denied server-side, including direct URL access. The shared-visibility interpretation is an explicitly documented pre-work assumption: the employer brief specifies client ownership and provider-wide queries but does not explicitly define privacy/sharing permissions. Provider-specific entry sharing is deferred. Membership changes must be reflected in authorization. Provider journal feeds remain uncached under the revised cache scope below.

## Confirmed journal ordering

Order both client journal listings and provider journal feeds by creation time, with ID as the deterministic tie-breaker. Retain the proposed newest-first direction: created_at DESC, id DESC. Both direct ActiveRecord queries and cached results must preserve the same ordering. No separate editable journal date is required for the baseline.

## Provider selection and revised cache scope

Steven requested that clients can add a provider from a dropdown. Offer seeded providers not already associated with that client and reject duplicate relationships server-side and in the database. Confirmed: clients select Basic or Premium when adding a provider, with Basic preselected. Clients may remove an existing provider relationship; removal immediately revokes that provider’s journal access while preserving the client’s entries and invalidates the provider-list cache after commit. Relationship management is client-driven only; providers view their associated clients and do not add/remove clients or change relationship plans in this baseline. Billing and a separate plan-editing flow are outside the agreed scope. Adding a provider grants that provider access to the client's existing and future journal entries under the agreed client-wide visibility rule; the action should make this clear.

Confirmed revised cache scope: cache only the list of providers for a given client in Redis, superseding the earlier proposed provider-journal-feed cache. Keep provider-client listings, client journals and provider journal feeds directly queried from PostgreSQL. Use a per-client key; invalidate after successful committed provider-association changes. If the cached payload includes plan or provider display fields, changes to those fields must also invalidate affected entries. Cache serializable values/IDs rather than live ActiveRecord objects; exact payload is an implementation detail. Keep authorization checks independent of the cached display list. Include targeted QA evidence for cache hits and refresh after membership changes.

## Confirmed schema indexing and query style

Enrollment indexes: unique composite (provider_id, client_id) enforces one enrollment per pair and supports provider-to-clients lookups; a separate client_id index supports client-to-providers lookups. Do not add a redundant standalone provider_id index when the composite already serves that leading-column access path. When migrations use t.references, account for automatically created indexes so no duplicate indexes are generated.

Journal index: composite (client_id, created_at, id) supports a client's journal filtering and deterministic newest-first ordering. It does not guarantee global ordering across multiple clients in a provider feed; inspect the actual query plan before introducing further indexes.

Steven prefers explicit .order(created_at: :desc, id: :desc) in the two journal queries rather than a separate recent_first scope.

These indexes are agreed schema requirements, not evidence of implemented migrations; ActiveRecord and database migrations remain pending.

## Confirmed authorization library

Use Pundit for authorization alongside Devise authentication. Policies express the agreed role, ownership and enrollment rules; policy scopes restrict listings. Clients manage only their own journal entries and provider relationships. Providers have read-only access to their currently associated clients and those clients' journal entries. Enforce authorization server-side as well as using policy predicates for UI controls. Cache contents do not establish access rights. Policy predicates return booleans; controller authorization enforces them, with access-denied errors handled centrally. Cover allowed and denied requests, including access after provider removal, in focused tests. Identity modeling is independently confirmed below as an explicit User role with matching Provider/Client profiles.

## Confirmed account and profile model

Use the original composition approach: User stores name, email, Devise login fields and a required role (provider or client). Define role as a string-backed Rails enum, providing user.provider? and user.client? predicates. Provider and Client are separate ApplicationRecord models, each with a required, unique user_id foreign key to users. User has_one :provider and has_one :client; each profile belongs_to :user and delegates name/email to User to avoid duplicated identity data. No STI or polymorphic profile association.

The role predicate and profile accessor are different: user.client? returns a boolean derived from role; user.client returns the Client profile. Create user and its matching profile atomically and validate role/profile consistency. Unique user_id indexes enforce at most one profile per type; they do not by themselves prevent one user from having both profile types. Keep role out of ordinary user-editable parameters. Enrollment foreign keys reference actual providers/clients tables, and journal entries reference clients.

## Final design audit

No consequential product or infrastructure choices remain unresolved. Accepted architectural decisions are preserved in docs/adr/0001-explicit-user-role-and-domain-profiles.md and docs/adr/0002-client-wide-journal-visibility.md. The to-spec step synthesized the confirmed decisions into docs/spec.md and published PIC-273. Next step: propose and approve a dependency-aware implementation-ticket breakdown, publish the child tickets in Backlog, then execute the selected local base-setup work only after its activation prerequisites are satisfied. Routine choices such as seed counts, basic page layout, serializable cache payload and supported screenshot upload path are implementation details. This audit does not indicate that local infrastructure or application features have been implemented.

## Published spec

Canonical Linear parent: PIC-273 — https://linear.app/pickerflicker/issue/PIC-273/spec-healthie-session-1-pre-work-and-local-developerqa-workflow. Repository copy: docs/spec.md. Both cover the accepted application scope, local infrastructure, agent lifecycle, and previously agreed browser-first testing approach with focused Rails/cache/scheduler checks. The parent stays in Backlog without a readiness label. No implementation tickets were created or activated by to-spec. The Linear project description was updated to match the accepted conventions. Repository changes remain uncommitted.

## Implementation ticket draft

The to-tickets step prepared eight proposed child issues under PIC-273 in docs/ticket-plan.md, with complete acceptance/validation/handoff text. Publication awaits Steven's approval of granularity and blocking edges. Ticket 1 is the initial local-stack frontier; ticket 2 establishes local Symphony/review-gate execution, and ticket 3 handles post-base GitHub/Linear integration. App slices cover login, client journals, relationships, provider journal reads and the narrowly scoped Redis cache. No child issues have been published or activated, and the parent spec was not modified.
