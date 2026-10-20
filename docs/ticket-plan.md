# Approved implementation tickets for PIC-273

Status: approved and published as PIC-274 through PIC-281. All were published in Backlog with native blocking edges. Steven explicitly delegated serial queueing, QA review and passing PR merges for this batch; see `docs/overnight-delegation.md`. The parent stays in Backlog.

The first two tickets are bootstrap/operator work. Full cold-start Symphony execution cannot truthfully precede installation and validation of the local runtime. Other product slices are executable after their blockers are merged; the connection ticket includes human account and manual-merge steps. Actual execution remains serial even where the dependency graph branches.

## 1. Start the laptop Rails stack with isolated test data

**Blocked by:** None.

**Symphony-ready:** Bootstrap/operator-led; this ticket establishes the execution environment.

## Parent

PIC-273 — https://linear.app/pickerflicker/issue/PIC-273/spec-healthie-session-1-pre-work-and-local-developerqa-workflow

## What to build

One local Compose startup brings up Rails, PostgreSQL and Redis; a visible Chromium smoke proves the running app without changing review data.

## Acceptance criteria

- [ ] Docker Desktop and a project-scoped Compose stack run Rails 8.1.4/Ruby 3.4.11, local PostgreSQL and Redis on the laptop, with loopback preview access and useful readiness/log output.
- [ ] ActiveRecord connects to local PostgreSQL. Development and test use separate databases and isolated Redis namespaces. A test-only write/clear cannot change development records or cache, and ordinary stop/start preserves the local database volume.
- [ ] Repeatable bootstrap/check/preview/acceptance and scoped stop/reset capabilities work from the project checkout. Existing planning/spec/glossary/ADRs are preserved and included in a reviewable code branch without resetting dirty user changes.
- [ ] A headed Playwright Chromium health acceptance captures a real screenshot, with an accessible canonical PR report identifying the tested commit and a concise Linear result/link. Leave the tested development preview running for Steven.

## Validation

- [ ] Build and start the Compose services from a clean project configuration, inspect readiness, load the health page in headed Chromium and run the focused Rails framework/style checks.
- [ ] Use disposable development/test sentinel records and cache values to prove isolation; stop/start the project and confirm persistence. Guard destructive commands by the exact local project/database/cache target.
- [ ] Verify browser evidence is accessible from the PR and that the preview remains available after QA exits; record the actual setup commands and environment requirements.

## Blocked by

None

## Symphony handoff

- Parent PRD/spec: PIC-273 — https://linear.app/pickerflicker/issue/PIC-273/spec-healthie-session-1-pre-work-and-local-developerqa-workflow
- Suggested starting point: the merged deliverable of the blocking tickets and the relevant existing application/runtime behavior.
- Notes for the orchestrator: Direct infrastructure bootstrap is appropriate because the local orchestrator does not yet exist. Use the canonical project checkout or a temporary feature workspace, preserve existing changes, and prepare one PR for Steven to merge. The local environment is the deliverable; creating this ticket is not installation or execution authorization.
- Project contract: Parent spec: PIC-273. Team/project: Pickerflicker (PIC) / healthie-platform. Code/PR repository: https://github.com/pickerflicker/healthie-platform. Read the accepted spec, project instructions, glossary and ADRs before editing. Newly published implementation tickets stay in Backlog; Steven moving one to Todo authorizes work. All dependencies must be merged and Done. Maintain a separate ticket branch/workspace from current main, no stacked PRs, and one shared local stack. Exactly one ticket remains in flight through human review. Developer owns application edits and records notable assumptions; independent QA runs headed Chromium against isolated test data/cache. The PR holds the canonical QA report with actual screenshots/results/tested commit; Linear gets only an outcome/commit/link. Keep the seeded development preview running in In Review. Feedback in Todo resumes the same branch/PR. After two unsuccessful repair cycles, preserve work and record Blocked for Steven. Steven alone merges. No public deployment or additional agent roles.
- Symphony-ready: Bootstrap/operator-led; this ticket establishes the execution environment.

---

## 2. Run one local Developer/QA ticket through human review

**Blocked by:** #1: Start the laptop Rails stack with isolated test data.

**Symphony-ready:** Bootstrap/operator-led; verify the native runtime before handing future product work to Symphony.

## Parent

PIC-273 — https://linear.app/pickerflicker/issue/PIC-273/spec-healthie-session-1-pre-work-and-local-developerqa-workflow

## What to build

A selected Todo ticket is handled locally by Developer plus independent visible-browser QA, pauses for human review, and resumes on feedback without starting another ticket.

## Acceptance criteria

- [ ] Native macOS Symphony authenticates to the existing Linear project and private repository, polls every ten seconds and claims Todo/In Progress implementation work without a readiness label. Verify exclusive scheduler ownership before activation.
- [ ] Exactly one Developer parent and one persistent independent QA session share the selected ticket workspace; log notable assumptions and publish real headed Chromium evidence. QA edits tests/evidence only. The parent spec stays outside execution.
- [ ] A durable project-scoped slot blocks other Todo tickets during In Review, Blocked and explicit pause, including after scheduler restart. Feedback in Todo resumes the same ticket/branch/PR. After two unsuccessful repair cycles, record Blocked with reproduction evidence and wait for Steven.
- [ ] An intentionally selected end-to-end smoke proves claim, role handoff, preserved running review preview, feedback resume and safe idle state. Done follows verified manual merge; unfinished dependencies and canceled-but-undelivered prerequisites do not dispatch. Reconcile historical bootstrap review states with Steven rather than silently treating them as delivered.

## Validation

- [ ] Run deterministic tracker/process-boundary checks for each lifecycle state, restart recovery, duplicate ownership, same-ticket resume and prerequisite gating before using the live Linear queue.
- [ ] Prove private clone/toolchain/model shell access and headed browser execution in the actual native sandbox, then record one deliberately activated local smoke and actual Developer/QA session identities.
- [ ] Check a second ready ticket remains unclaimed during review/pause/Blocked, that the preview persists, and that explicit release after merged/Done permits only the next eligible ticket. Finish with no unintended active run.

## Blocked by

#1: Start the laptop Rails stack with isolated test data

## Symphony handoff

- Parent PRD/spec: PIC-273 — https://linear.app/pickerflicker/issue/PIC-273/spec-healthie-session-1-pre-work-and-local-developerqa-workflow
- Suggested starting point: the merged deliverable of the blocking tickets and the relevant existing application/runtime behavior.
- Notes for the orchestrator: This is orchestration setup/repair, not a product feature. Reuse the existing Symphony implementation and an opt-in project-scoped gate; preserve other projects and avoid a new generic orchestration platform. Retain auditable source/build provenance for any runtime change. Keep the existing PR and workspace during feedback. Merge automation may still be unconfigured, so use an accurately verified manual Done transition when necessary.
- Project contract: Parent spec: PIC-273. Team/project: Pickerflicker (PIC) / healthie-platform. Code/PR repository: https://github.com/pickerflicker/healthie-platform. Read the accepted spec, project instructions, glossary and ADRs before editing. Newly published implementation tickets stay in Backlog; Steven moving one to Todo authorizes work. All dependencies must be merged and Done. Maintain a separate ticket branch/workspace from current main, no stacked PRs, and one shared local stack. Exactly one ticket remains in flight through human review. Developer owns application edits and records notable assumptions; independent QA runs headed Chromium against isolated test data/cache. The PR holds the canonical QA report with actual screenshots/results/tested commit; Linear gets only an outcome/commit/link. Keep the seeded development preview running in In Review. Feedback in Todo resumes the same branch/PR. After two unsuccessful repair cycles, preserve work and record Blocked for Steven. Steven alone merges. No public deployment or additional agent roles.
- Symphony-ready: Bootstrap/operator-led; verify the native runtime before handing future product work to Symphony.

---

## 3. Connect GitHub merges to Linear completion

**Blocked by:** #1: Start the laptop Rails stack with isolated test data.

**Symphony-ready:** Operator-assisted; account installation/permissions and Steven’s manual smoke merge may require human action.

## Parent

PIC-273 — https://linear.app/pickerflicker/issue/PIC-273/spec-healthie-session-1-pre-work-and-local-developerqa-workflow

## What to build

After base setup, merging a linked PR updates its Linear ticket to Done automatically, leaving Symphony to read the actual Linear status.

## Acceptance criteria

- [ ] Connect pickerflicker/healthie-platform to the existing Linear project using the supported GitHub integration, with a closing issue reference and merge automation mapped to Done.
- [ ] A deliberately selected linked PR remains awaiting review before merge, and Steven’s manual merge triggers the linked ticket’s Done transition. Closing an unmerged PR must not be treated as delivered work.
- [ ] Record evidence of the linked PR, manual merge and Linear transition, plus an accurately documented manual-status fallback if synchronization is delayed or unavailable. Preserve the project’s Todo readiness and one-ticket-through-review rules.

## Validation

- [ ] Verify repository access and the relevant Linear team’s merge rule, checking effects on this project without changing unrelated team conventions.
- [ ] Use a non-product smoke change approved for this verification, have Steven merge it, and inspect the linked ticket’s actual transition. Do not merge on Steven’s behalf or report success from configuration alone.

## Blocked by

#1: Start the laptop Rails stack with isolated test data

## Symphony handoff

- Parent PRD/spec: PIC-273 — https://linear.app/pickerflicker/issue/PIC-273/spec-healthie-session-1-pre-work-and-local-developerqa-workflow
- Suggested starting point: the merged deliverable of the blocking tickets and the relevant existing application/runtime behavior.
- Notes for the orchestrator: Perform after local base setup as requested. This integration does not itself require the Developer/QA runtime; manual merge verification and human account consent are legitimate operator steps. If a human-only step is unavailable, preserve the setup evidence and exact next action. Product tickets are not forced to depend on this automation because verified manual Done remains possible.
- Project contract: Parent spec: PIC-273. Team/project: Pickerflicker (PIC) / healthie-platform. Code/PR repository: https://github.com/pickerflicker/healthie-platform. Read the accepted spec, project instructions, glossary and ADRs before editing. Newly published implementation tickets stay in Backlog; Steven moving one to Todo authorizes work. All dependencies must be merged and Done. Maintain a separate ticket branch/workspace from current main, no stacked PRs, and one shared local stack. Exactly one ticket remains in flight through human review. Developer owns application edits and records notable assumptions; independent QA runs headed Chromium against isolated test data/cache. The PR holds the canonical QA report with actual screenshots/results/tested commit; Linear gets only an outcome/commit/link. Keep the seeded development preview running in In Review. Feedback in Todo resumes the same branch/PR. After two unsuccessful repair cycles, preserve work and record Blocked for Steven. Steven alone merges. No public deployment or additional agent roles.
- Symphony-ready: Operator-assisted; account installation/permissions and Steven’s manual smoke merge may require human action.

---

## 4. Sign in as seeded provider and client accounts

**Blocked by:** #2: Run one local Developer/QA ticket through human review.

**Symphony-ready:** Yes, after prerequisite merges and local Symphony readiness.

## Parent

PIC-273 — https://linear.app/pickerflicker/issue/PIC-273/spec-healthie-session-1-pre-work-and-local-developerqa-workflow

## What to build

Seeded users sign in and out through Devise and land on the correct role-specific home screen using explicit User roles and separate domain profiles.

## Acceptance criteria

- [ ] User stores canonical name/email, Devise login data and a required provider/client string role. Provider and Client reference User with required unique foreign keys and delegate identity fields. Creating a user/profile is atomic and rejects missing, mismatched or duplicate profiles through the normal application path.
- [ ] Normal email/password sign-in, logout and role-specific navigation work for deterministic seeded provider/client accounts. Repeatable seeds preserve the intentional account baseline without duplicates.
- [ ] Pundit establishes server-side role boundaries and scoped access, with meaningful authentication/access-denied handling. A provider cannot open client-only actions or vice versa, and request parameters cannot change role. No signup, admin, impersonation or email recovery workflow is added.
- [ ] Headed Playwright QA demonstrates both seeded identities, invalid/unauthenticated access and successful logout; the canonical PR report is linked from Linear, and the seeded development preview remains running in review.

## Validation

- [ ] Apply migrations in the isolated test database, test required/unique identity and profile invariants plus transactional failure, and repeat seed loading to verify useful account records remain stable.
- [ ] Run focused authentication/role request-policy tests and headed Chromium sign-in/navigation/logout acceptance for both roles, including direct unauthorized requests.
- [ ] Verify the review preview’s development data/cache remain intact after test runs.

## Blocked by

#2: Run one local Developer/QA ticket through human review

## Symphony handoff

- Parent PRD/spec: PIC-273 — https://linear.app/pickerflicker/issue/PIC-273/spec-healthie-session-1-pre-work-and-local-developerqa-workflow
- Suggested starting point: the merged deliverable of the blocking tickets and the relevant existing application/runtime behavior.
- Notes for the orchestrator: Honor the explicit-role/profile ADR: no STI or polymorphic identity. The first role pages may be intentionally minimal; enrollment and journal features arrive in later slices. New feature branches start from current merged main; Developer implements and independent QA verifies the same ticket workspace before In Review.
- Project contract: Parent spec: PIC-273. Team/project: Pickerflicker (PIC) / healthie-platform. Code/PR repository: https://github.com/pickerflicker/healthie-platform. Read the accepted spec, project instructions, glossary and ADRs before editing. Newly published implementation tickets stay in Backlog; Steven moving one to Todo authorizes work. All dependencies must be merged and Done. Maintain a separate ticket branch/workspace from current main, no stacked PRs, and one shared local stack. Exactly one ticket remains in flight through human review. Developer owns application edits and records notable assumptions; independent QA runs headed Chromium against isolated test data/cache. The PR holds the canonical QA report with actual screenshots/results/tested commit; Linear gets only an outcome/commit/link. Keep the seeded development preview running in In Review. Feedback in Todo resumes the same branch/PR. After two unsuccessful repair cycles, preserve work and record Blocked for Steven. Steven alone merges. No public deployment or additional agent roles.
- Symphony-ready: Yes, after prerequisite merges and local Symphony readiness.

---

## 5. Manage a client’s journal end to end

**Blocked by:** #4: Sign in as seeded provider and client accounts.

**Symphony-ready:** Yes, after prerequisite merges and local Symphony readiness.

## Parent

PIC-273 — https://linear.app/pickerflicker/issue/PIC-273/spec-healthie-session-1-pre-work-and-local-developerqa-workflow

## What to build

A signed-in client can create, browse, edit and delete their own persisted freeform journal entries, with deterministic newest-first ordering and ownership enforcement.

## Acceptance criteria

- [ ] JournalEntry belongs to Client with required valid ownership and freeform text. Add the agreed client/creation-time/ID composite index without a duplicate client-only index. Keep journals independent of Provider and Enrollment ownership.
- [ ] Client journal create/read/update/delete screens persist changes and order entries by creation time descending then ID descending, expressed directly in the query. Text edits preserve creation-based position.
- [ ] The client’s journal ownership is derived from the signed-in profile. Other clients and providers cannot mutate entries through direct requests or submitted ownership identifiers. Unauthenticated access is denied.
- [ ] Extend intentional seeds with entries across dates, tied timestamps and empty/unrelated clients; verify the required ordered client-journal ActiveRecord query. Headed QA captures the complete CRUD journey and leaves the development preview available.

## Validation

- [ ] Run focused migration/model/query tests for ownership constraints, required content, same-timestamp tie-breaking, empty results and creation-based ordering after edit.
- [ ] Exercise create/edit/delete in headed Chromium; verify persistence and direct foreign-record/ownership-tampering denials through request tests.
- [ ] Publish QA outcomes and screenshots against the tested commit without changing development records during destructive acceptance.

## Blocked by

#4: Sign in as seeded provider and client accounts

## Symphony handoff

- Parent PRD/spec: PIC-273 — https://linear.app/pickerflicker/issue/PIC-273/spec-healthie-session-1-pre-work-and-local-developerqa-workflow
- Suggested starting point: the merged deliverable of the blocking tickets and the relevant existing application/runtime behavior.
- Notes for the orchestrator: Follow the client-wide-journal ADR and the explicit ordering preference; do not introduce a recent-first scope, provider ownership, rich text or editable entry dates. Provider reads will be delivered after enrollments exist. Implement in a separate ticket branch from merged main, preserve the branch/PR on feedback and stop in In Review.
- Project contract: Parent spec: PIC-273. Team/project: Pickerflicker (PIC) / healthie-platform. Code/PR repository: https://github.com/pickerflicker/healthie-platform. Read the accepted spec, project instructions, glossary and ADRs before editing. Newly published implementation tickets stay in Backlog; Steven moving one to Todo authorizes work. All dependencies must be merged and Done. Maintain a separate ticket branch/workspace from current main, no stacked PRs, and one shared local stack. Exactly one ticket remains in flight through human review. Developer owns application edits and records notable assumptions; independent QA runs headed Chromium against isolated test data/cache. The PR holds the canonical QA report with actual screenshots/results/tested commit; Linear gets only an outcome/commit/link. Keep the seeded development preview running in In Review. Feedback in Todo resumes the same branch/PR. After two unsuccessful repair cycles, preserve work and record Blocked for Steven. Steven alone merges. No public deployment or additional agent roles.
- Symphony-ready: Yes, after prerequisite merges and local Symphony readiness.

---

## 6. Manage provider relationships and plans from the client UI

**Blocked by:** #4: Sign in as seeded provider and client accounts.

**Symphony-ready:** Yes, after prerequisite merges and local Symphony readiness.

## Parent

PIC-273 — https://linear.app/pickerflicker/issue/PIC-273/spec-healthie-session-1-pre-work-and-local-developerqa-workflow

## What to build

Clients browse their providers/plans, add an available provider with Basic or Premium, and remove relationships; providers can browse their current clients and per-relationship plans.

## Acceptance criteria

- [ ] Enrollment references Provider and Client, with a required Basic/Premium plan, Basic default, valid foreign keys, unique provider/client pair and separate client-first index. Avoid redundant automatically generated indexes and reject duplicates even when validations race.
- [ ] Client-owned relationship list/add/remove screens work; the dropdown excludes current providers and the plan selector allows Premium. Explain that enrollment grants access to the client’s existing and future journal entries. Removal deletes the relationship without deleting the client or its journal data.
- [ ] Providers have read-only current-client/plan views; clients cannot manage another client’s relationships, and providers cannot create/remove enrollments through direct requests. Pundit scopes all lists and record actions.
- [ ] Seed shared clients with different plans across providers plus empty/unrelated examples. Direct ActiveRecord queries return all clients for a provider and all providers for a client. Headed QA demonstrates the complete relationship flow and role boundaries.

## Validation

- [ ] Run focused model/database and query checks for both relationship directions, plan checks, unique-pair protection and exact intended indexes.
- [ ] Use headed Chromium to add Basic/Premium relationships, verify dropdown changes and provider client-list changes, then remove a relationship. Test duplicate submissions and direct unauthorized create/delete requests.
- [ ] Verify repeatable seeds and handoff into the running development preview; retain real screenshots and commit-specific report evidence.

## Blocked by

#4: Sign in as seeded provider and client accounts

## Symphony handoff

- Parent PRD/spec: PIC-273 — https://linear.app/pickerflicker/issue/PIC-273/spec-healthie-session-1-pre-work-and-local-developerqa-workflow
- Suggested starting point: the merged deliverable of the blocking tickets and the relevant existing application/runtime behavior.
- Notes for the orchestrator: This slice does not require journal CRUD: deliver both relationship-query directions and user-visible plan management through add/remove. Preserve any journals that already exist when this ticket is scheduled after the journal slice. Providers cannot manage enrollments; no invitations, billing or separate plan-editing screen. Redis caching is deferred to its own behavior slice.
- Project contract: Parent spec: PIC-273. Team/project: Pickerflicker (PIC) / healthie-platform. Code/PR repository: https://github.com/pickerflicker/healthie-platform. Read the accepted spec, project instructions, glossary and ADRs before editing. Newly published implementation tickets stay in Backlog; Steven moving one to Todo authorizes work. All dependencies must be merged and Done. Maintain a separate ticket branch/workspace from current main, no stacked PRs, and one shared local stack. Exactly one ticket remains in flight through human review. Developer owns application edits and records notable assumptions; independent QA runs headed Chromium against isolated test data/cache. The PR holds the canonical QA report with actual screenshots/results/tested commit; Linear gets only an outcome/commit/link. Keep the seeded development preview running in In Review. Feedback in Todo resumes the same branch/PR. After two unsuccessful repair cycles, preserve work and record Blocked for Steven. Steven alone merges. No public deployment or additional agent roles.
- Symphony-ready: Yes, after prerequisite merges and local Symphony readiness.

---

## 7. Browse authorized provider journal views and all four queries

**Blocked by:** #5: Manage a client’s journal end to end, #6: Manage provider relationships and plans from the client UI.

**Symphony-ready:** Yes, after prerequisite merges and local Symphony readiness.

## Parent

PIC-273 — https://linear.app/pickerflicker/issue/PIC-273/spec-healthie-session-1-pre-work-and-local-developerqa-workflow

## What to build

A provider browses an associated client’s journal and a combined journal feed, with correct ordering and access that appears/disappears as the client adds/removes the provider.

## Acceptance criteria

- [ ] Provider navigation exposes current clients’ individual journals and a combined feed, ordered by creation time descending and ID descending. Read paths follow current enrollments and return no duplicate entries for the supported unique enrollment model.
- [ ] Pundit record checks and scopes permit the client owner and current provider reads while denying unrelated clients/providers, removed providers and all provider journal mutations. Adding an enrollment exposes existing entries; removing it revokes later direct and feed access without deleting entries.
- [ ] All four employer-required ActiveRecord queries are directly runnable and documented using the accepted glossary and explicit ordering. Keep both journal listing queries uncached. Explain the composite journal index’s client-local ordering benefit without claiming it guarantees global provider-feed ordering.
- [ ] Seeds and headed QA cover shared clients, different plans, older entries, tied timestamps and empty feeds; produce concise schema/query/index tradeoff notes suitable for the setup walkthrough without implementing the unknown interview extension.

## Validation

- [ ] Run focused association/query/policy/request tests for all four required queries, ordered feeds, tied timestamps and absence of unrelated records.
- [ ] In headed Chromium, sign in as a client to add/remove a provider, then sign in normally as that provider and verify journal access before and after each relationship change. Include read-only and direct URL/request denials.
- [ ] Check the four queries against the intentional seed dataset and inspect representative query plans without making performance guarantees from tiny data.

## Blocked by

#5: Manage a client’s journal end to end, #6: Manage provider relationships and plans from the client UI

## Symphony handoff

- Parent PRD/spec: PIC-273 — https://linear.app/pickerflicker/issue/PIC-273/spec-healthie-session-1-pre-work-and-local-developerqa-workflow
- Suggested starting point: the merged deliverable of the blocking tickets and the relevant existing application/runtime behavior.
- Notes for the orchestrator: This is the first slice requiring both client journals and enrollments, hence both blockers. Keep raw queries explainable; do not add cache, pagination infrastructure, backdating or provider-specific journal sharing. Preserve the tested review preview and refresh PR evidence on feedback.
- Project contract: Parent spec: PIC-273. Team/project: Pickerflicker (PIC) / healthie-platform. Code/PR repository: https://github.com/pickerflicker/healthie-platform. Read the accepted spec, project instructions, glossary and ADRs before editing. Newly published implementation tickets stay in Backlog; Steven moving one to Todo authorizes work. All dependencies must be merged and Done. Maintain a separate ticket branch/workspace from current main, no stacked PRs, and one shared local stack. Exactly one ticket remains in flight through human review. Developer owns application edits and records notable assumptions; independent QA runs headed Chromium against isolated test data/cache. The PR holds the canonical QA report with actual screenshots/results/tested commit; Linear gets only an outcome/commit/link. Keep the seeded development preview running in In Review. Feedback in Todo resumes the same branch/PR. After two unsuccessful repair cycles, preserve work and record Blocked for Steven. Steven alone merges. No public deployment or additional agent roles.
- Symphony-ready: Yes, after prerequisite merges and local Symphony readiness.

---

## 8. Cache the client provider list with correct invalidation

**Blocked by:** #7: Browse authorized provider journal views and all four queries.

**Symphony-ready:** Yes, after prerequisite merges and local Symphony readiness.

## Parent

PIC-273 — https://linear.app/pickerflicker/issue/PIC-273/spec-healthie-session-1-pre-work-and-local-developerqa-workflow

## What to build

Repeated client provider-list reads use Redis, while committed relationship changes refresh the list and provider journal access remains correct even with a previously warm cache.

## Acceptance criteria

- [ ] Only the client provider-list result is cached, with a per-client key and serializable values/IDs. Keep its raw ActiveRecord association query available; provider-client listings and both journal queries remain uncached.
- [ ] A first read populates Redis and repeated reads reuse it. Committed enrollment add/remove invalidates the affected list; rollback cannot publish changed membership. If cached fields include plans or provider display data, changes to those fields invalidate affected results. Seed reload clears project-scoped stale values.
- [ ] Pundit checks current authoritative relationships independently of cached data. Different clients do not share results, and a removed provider cannot access journals or feeds after the client’s provider-list cache was warmed.
- [ ] Focused Rails/Redis checks and headed browser QA demonstrate cache reuse, fresh add/remove results and privacy boundaries. Run one final targeted seeded product journey across both normal logins, relationship changes and journal behavior; update the canonical PR report and keep the development preview ready for Steven.

## Validation

- [ ] Use the real local Redis integration and observable fetch/query evidence to distinguish miss/hit/invalidation; test per-client isolation, commit/rollback behavior and any cached display-field update.
- [ ] Warm a client’s provider list, remove an enrollment, then verify both the refreshed list and provider journal denial through headed browser acceptance and direct requests.
- [ ] Verify test-cache clearing leaves development cache/data intact, repeated seeds are coherent, and a focused final journey exercises the accepted baseline without a broad browser or load matrix.

## Blocked by

#7: Browse authorized provider journal views and all four queries

## Symphony handoff

- Parent PRD/spec: PIC-273 — https://linear.app/pickerflicker/issue/PIC-273/spec-healthie-session-1-pre-work-and-local-developerqa-workflow
- Suggested starting point: the merged deliverable of the blocking tickets and the relevant existing application/runtime behavior.
- Notes for the orchestrator: The authorized provider views are a real blocker because this slice proves warm-cache removal does not retain journal access. Keep caching narrowly scoped; do not introduce journal caches, use cached membership for permissions, or serialize live ActiveRecord objects. Record remaining tradeoffs and evidence in the existing PR report; stop in In Review for Steven’s manual merge.
- Project contract: Parent spec: PIC-273. Team/project: Pickerflicker (PIC) / healthie-platform. Code/PR repository: https://github.com/pickerflicker/healthie-platform. Read the accepted spec, project instructions, glossary and ADRs before editing. Newly published implementation tickets stay in Backlog; Steven moving one to Todo authorizes work. All dependencies must be merged and Done. Maintain a separate ticket branch/workspace from current main, no stacked PRs, and one shared local stack. Exactly one ticket remains in flight through human review. Developer owns application edits and records notable assumptions; independent QA runs headed Chromium against isolated test data/cache. The PR holds the canonical QA report with actual screenshots/results/tested commit; Linear gets only an outcome/commit/link. Keep the seeded development preview running in In Review. Feedback in Todo resumes the same branch/PR. After two unsuccessful repair cycles, preserve work and record Blocked for Steven. Steven alone merges. No public deployment or additional agent roles.
- Symphony-ready: Yes, after prerequisite merges and local Symphony readiness.

---

## Review questions

- Is the granularity right, or should any tickets be merged or split?
- Are these blocking edges genuine prerequisites, without unnecessary sequencing?
- Is the operator-led bootstrap distinction clear before product work moves to Symphony?

Dependency-ready frontier before execution: ticket 1 only. After ticket 1 merges, tickets 2 and 3 are dependency-ready, but the agreed one-ticket review gate still requires serial execution. Ticket 4 follows ticket 2; tickets 5 and 6 both follow ticket 4; ticket 7 requires both; ticket 8 requires ticket 7. GitHub/Linear merge automation is not an artificial blocker for product development while accurately verified manual Done transitions remain available.
