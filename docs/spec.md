# Healthie Session 1 pre-work: local Rails application and interview agent workflow

## Problem Statement

Steven needs an understandable, runnable foundation for Healthie's Session 1 pairing interview. He must explain his setup and data-model choices in roughly ten minutes, then collaboratively implement an interviewer-selected query, validation or small model extension during roughly thirty-five minutes of pairing. He wants to finish the pre-work promptly and schedule the session afterward.

The employer requires provider/client data, many-to-many provider relationships with a per-relationship Basic or Premium plan, client-authored freeform journal entries, and four working ActiveRecord queries. Steven additionally wants a small role-specific browser experience and a visible AI-assisted development workflow that he can operate and explain. The setup must run on his laptop and remain small enough to understand and extend during the interview.

## Solution

Provide a local Rails application with seeded provider and client accounts, a straightforward server-rendered interface, explicit domain relationships, and directly runnable examples of the four required queries. Clients manage their journals and provider relationships. Providers inspect their associated clients, plans and journal feeds. Enforce access through Devise authentication and Pundit authorization, and demonstrate a narrowly scoped Redis cache for a client's provider list.

Use Docker Desktop and one shared Compose stack for Rails, PostgreSQL and Redis. Run Symphony natively on macOS, polling the existing Linear project every ten seconds. Exactly one Developer and one independent QA agent handle one ticket through implementation, headless Chromium acceptance and Steven's human review. Preserve the preview during review, publish the canonical QA report on the PR, and wait for Steven's manual merge before proceeding to another ticket.

## User Stories

1. As an interview candidate, I want a working Rails foundation matching the Session 1 brief, so that pairing can focus on the interviewer's extension.
2. As an interview candidate, I want the required queries available directly through ActiveRecord, so that I can explain their relationships and SQL without relying on a browser screen or cache wrapper.
3. As an interview candidate, I want clear documentation of employer requirements versus my additional choices, so that I can defend the scope accurately.
4. As a developer, I want a reproducible local startup process for Rails, PostgreSQL and Redis, so that I can begin work without depending on another application host.
5. As a developer, I want persistent database data across ordinary restarts, so that the app remains useful for browsing.
6. As a developer, I want intentional seeds covering every entity, so that the application is populated immediately.
7. As a developer, I want seed loading to be repeatable without duplicating baseline records, so that the same starting relationships remain predictable.
8. As a developer, I want new entities and important feature states added to the seed set, so that future features remain easy to browse and test.
9. As a developer, I want automated checks isolated from browsing data and cache, so that QA does not erase or contaminate my review preview.
10. As a seeded user, I want to sign in with email and password, so that the app knows my identity.
11. As a seeded user, I want to sign out and sign in as another seeded account, so that I can demonstrate both role experiences through the actual login flow.
12. As a client, I want client-specific navigation, so that my journal and provider actions are easy to find.
13. As a provider, I want provider-specific navigation, so that I can inspect my clients and their journals.
14. As a user, I want my name and email to have one authoritative stored value, so that login and domain screens stay consistent.
15. As a client, I want to see all my current providers and each relationship's plan, so that I understand my enrollments.
16. As a client, I want to choose an available provider from a dropdown, so that I can establish a relationship.
17. As a client, I want to select Basic or Premium when adding a provider, with Basic preselected, so that the plan applies to that particular relationship.
18. As a client, I want already-associated providers excluded from the dropdown and duplicate additions rejected, so that I cannot accidentally create duplicate relationships.
19. As a client, I want provider selection to explain its journal-sharing effect, so that I understand that the selected provider gains access to my existing and future entries.
20. As a client, I want to remove a provider relationship, so that the provider loses future access to my journal while my entries remain intact.
21. As a provider, I want all clients currently associated with me, so that I can browse my client list.
22. As a provider, I want to see the plan for each of my client relationships, so that Basic and Premium are represented per relationship.
23. As a client, I want to create a freeform text journal entry, so that I can record a health journal update.
24. As a client, I want to browse my journal newest first, so that recent entries are easy to find.
25. As a client, I want to edit my own entry, so that I can correct its text.
26. As a client, I want to delete my own entry, so that I can remove a record I authored.
27. As a provider, I want a client's entries ordered by creation time, so that I can inspect that client's journal.
28. As a provider, I want a combined ordered journal feed across my associated clients, so that I can inspect their latest updates together.
29. As a user, I want entries with identical creation timestamps to have deterministic ordering, so that listings remain stable.
30. As a client, I want other clients denied access to my journal and relationship actions, so that changing a URL or submitting a request cannot bypass ownership.
31. As a client, I want unrelated providers denied access to my journal, so that a provider role alone is not sufficient for access.
32. As a client, I want a removed provider denied access even after earlier authorized requests and cache warming, so that removal takes effect for subsequent requests.
33. As a provider, I want read-only journal access, so that viewing a client's record does not grant authority to alter it.
34. As a client, I want repeated provider-list reads served from Redis, so that the app demonstrates a clear query-result cache.
35. As a client, I want provider-list results refreshed after committed relationship changes, so that cached data does not hide an addition or retain a removal.
36. As a user, I want cached results scoped to the correct client, so that accounts cannot receive one another's provider lists.
37. As an interview candidate, I want journal queries left uncached, so that their ordering and relationships remain directly explainable.
38. As a project owner, I want newly published tickets in Backlog, so that creating a plan does not silently authorize implementation.
39. As a project owner, I want moving a ticket to Todo to authorize the agents, so that Linear is the execution control plane without an extra readiness label.
40. As a project owner, I want exactly one ticket in flight through human review, so that work stays understandable and the shared preview is stable.
41. As a project owner, I want dependent tickets to wait for prerequisites to be manually merged and marked Done, so that there are no stacked PRs to manage.
42. As a developer, I want the Developer agent to record notable assumptions in the ticket, so that decisions are visible rather than silently invented.
43. As a project owner, I want independent QA to run headless Playwright Chromium, so that acceptance runs unattended while retaining screenshots; visible runs are available on demand.
44. As a reviewer, I want a canonical PR QA report containing real screenshots, acceptance results and the tested commit, so that I can evaluate the behavior and code together.
45. As a project owner, I want only a concise QA outcome, tested commit and report link in Linear, so that there are not two competing full reports.
46. As a reviewer, I want the tested app left running while the ticket is In Review, so that I can browse it before merging.
47. As a reviewer, I want feedback returned to Todo to resume the same ticket, branch and PR, so that the Developer repairs the issue and QA refreshes the existing report.
48. As a project owner, I want two unsuccessful repair cycles to produce Blocked with reproduction evidence, so that I can reproduce the problem, add feedback and return the ticket to Todo.
49. As a project owner, I want pause, Blocked and In Review to preserve ownership across scheduler restarts, so that restarting execution cannot accidentally begin a different ticket.
50. As a project owner, I want to connect the repository to Linear after the initial base setup and verify merge-to-Done automation, so that a manual PR merge can release the next eligible ticket without another routine status update.
51. As an interview candidate, I want concise schema, index and cache tradeoff notes, so that I can discuss larger datasets without building speculative scale infrastructure.

## Implementation Decisions

### Application boundary and identity

- Retain the existing Rails 8.1.4 / Ruby 3.4.11 baseline and lock dependencies. Use a minimal server-rendered Rails interface with the existing Hotwire/import-map foundation rather than adding a separate frontend application.
- Enable ActiveRecord and use PostgreSQL. Domain records are User, Provider, Client, Enrollment and JournalEntry. Enrollment is the implementation name for the glossary's provider relationship.
- User owns canonical name, email and Devise login data. Store a required string-backed provider/client role, exposing boolean role predicates independently of profile accessors. Validate required identity fields and valid roles; treat login-email uniqueness as an application login requirement rather than a condition specified by the employer brief.
- Provider and Client are separate profiles referencing User through required unique foreign keys. Delegate shared identity fields to User. Create a user and its matching profile atomically and enforce role/profile consistency through the application. Unique profile foreign keys alone do not prohibit one account from having both types of profile.
- Use composition, not STI or a polymorphic profile reference. Domain references target the actual provider and client tables. Ordinary forms cannot change the account's role.
- Use minimal Devise email/password authentication with seeded accounts. Use Pundit policies for record actions and policy scopes for authorized listings. Handle authentication and authorization failures centrally; view controls complement, rather than replace, server enforcement.

### Provider relationships and journals

- Enrollments join a Provider and Client, with exactly one Basic or Premium plan per pair. Basic is the initial selection when the client adds a provider; allow Premium selection without any billing behavior.
- Only clients manage their own relationships. Exclude existing providers from the selection list and reject duplicate submissions. Provider/client account management and a separate plan-editing workflow are outside this baseline.
- Adding an enrollment grants the provider read access to that client's existing and future journal entries. Removing an enrollment revokes access on subsequent requests and preserves the client's journal entries. Clearly describe the sharing effect in the client UI. This is an accepted pre-work privacy assumption, not a permission explicitly specified in the employer brief.
- JournalEntry belongs to Client and stores freeform text, creation time and ordinary modification metadata. It has no provider or enrollment ownership reference. Clients alone create, edit and delete their own entries; current providers have read-only access. Journal creation derives ownership from the signed-in client's profile rather than trusting submitted ownership identifiers.
- Display both client journals and provider combined feeds by creation time descending, then ID descending. Express ordering explicitly in the queries rather than adding a named recent-first scope. Editing entry text does not change its position based on creation time.
- Provide directly runnable ActiveRecord queries for all clients of a provider, all providers of a client, all entries of a client in the agreed order, and all entries across a provider's associated clients in that order. Keep the underlying provider-list association query available even when the UI uses its cached representation.

### Constraints, indexes and cache

- Require valid references and plan values. Use a unique composite provider/client enrollment index, plus a separate client-first index. Avoid a redundant standalone provider index and account for reference declarations that automatically generate indexes.
- Index journal entries by client, creation time and ID. This supports client-specific access and ordering, but does not promise a sort-free globally ordered provider feed. Inspect query plans before adding speculative indexes for larger datasets.
- Cache only a client's provider-list query result in Redis using a client-specific key and a serializable payload, rather than cached ActiveRecord instances. Provider-client listings and both journal listings remain directly queried from PostgreSQL.
- Invalidate the affected client's provider-list cache after successfully committed relationship changes. If the payload contains plan or provider display fields, updates to those fields must also refresh affected results. Failed or rolled-back changes must not publish a changed membership view. Cache lifetime and payload details are implementation choices; expiry alone cannot stand in for the agreed relationship-change invalidation.
- Authorization always consults the signed-in identity and current authoritative relationships independently of cached display results. Removing an enrollment must revoke access even when Redis has an earlier cached provider list.

### Local development and intentional seeds

- All application services and data run on Steven's laptop. Docker Desktop supplies one shared Compose stack for Rails, PostgreSQL and Redis. Use persistent local database storage and loopback browser access. Keep PostgreSQL and Redis running between ticket workspaces; restart Rails for the selected workspace as needed.
- Use separate development and test databases in the same PostgreSQL service and isolated development/test cache namespaces. Browser acceptance uses the test environment just as other destructive automated checks do; leave the human preview on its intentional development dataset. No per-ticket database server or per-role service stack.
- Provide repeatable setup, schema/migration, seed/reload, check, preview and cleanup capabilities. Destructive test or reset operations must verify their intended local target. Ordinary stop/restart preserves database data; explicit cleanup is scoped to this project.
- Seeds are a durable manual browsing/demo baseline, not automated test fixtures. All automated tests own their setup and must not load or depend on demo seeds. Populate all entities with realistic synthetic records, including multiple providers and clients, a client with different plans across providers, shared clients, journal dates and tied timestamps, and useful empty/unrelated cases. Seed loading is deterministic and repeatable. Extend it as features add entities or important states.
- On ticket/workspace handoff, prepare the selected branch's schema and intentional seed baseline and clear the project's relevant cache. Preserve data during review and repair of the current ticket; do not reset the reviewer preview merely because a worker session resumes.

### Linear and Symphony execution

- Keep the existing Linear project as the issue tracker and GitHub as the code/PR repository. Publish one spec parent with implementation children and native dependency links. The spec parent and newly published tickets remain in Backlog; Steven's move to Todo authorizes an implementation ticket. No readiness label is required.
- Run Symphony natively on macOS and poll Linear every ten seconds. Verify exclusive ownership of this Linear project before activation. Local scheduler setup is infrastructure work, not evidence that the product is implemented.
- Use exactly two execution roles: Developer as parent and sole application editor, plus one persistent independent QA subagent in the same ticket workspace. QA may add tests and evidence; Developer handles application fixes. No extra reviewer, coordinator session or recursive team.
- A claimed ticket moves from Todo to In Progress. One ticket owns the project's slot through implementation, QA and human review; simple executing-agent concurrency limits are insufficient. Implement durable ownership so In Review, Blocked and explicit pause prevent any other ticket, even independent work, from dispatching. Preserve or reconstruct that ownership after restart.
- After QA passes, publish the PR/report and move to In Review, stop coding, and leave the development preview running on the tested branch. Steven alone merges. Only merged and Done work releases the slot to a dependency-ready Todo ticket. Canceled prerequisites do not count as delivered without explicit resolution of dependent scope.
- Feedback in Linear and a move back to Todo resume the same branch and PR before any new ticket. Developer repairs, QA rechecks the updated commit, and the same report is refreshed before returning to In Review.
- After two unsuccessful Developer/QA repair cycles, preserve work and record Blocked with reproduction steps, failure evidence and the exact unblock condition. Steven reproduces, adds feedback and returns it to Todo. Pausing likewise preserves the slot until resumed or explicitly released.
- After the initial local base setup, connect the repository to Linear and verify that a linked, manually merged PR moves its ticket to Done. Until verified, do not assume that merging changes Linear status; a prerequisite remains gated by its actual completion status. Symphony polls Linear rather than GitHub for scheduling state.
- Keep the canonical QA report, screenshots, tested commit and acceptance results on the PR. Linear holds a concise outcome, commit and link. Use real browser captures and a supported durable artifact publication route; a laptop filesystem path is not usable PR evidence. Retain diagnostic artifacts when useful for reproducing a failure.

## Testing Decisions

- The primary acceptance boundary is a real browser driving the local Rails app and its database-backed behavior. Use Playwright Chromium in headless mode by default; use HEADED=true for an explicitly requested visible demonstration. Validate observable outcomes, persistence and denied access; screenshots accompany assertions rather than substitute for them.
- This boundary follows the testing approach already agreed during the design session. Supplement it only where the browser cannot directly prove an invariant: focused Rails model/database checks, request/policy checks, cache integration checks and scheduler lifecycle checks. Avoid introducing a new abstraction merely to make a test possible.
- Test login/logout and distinct role navigation with normal sign-in with test-owned credentials. Cover journal creation, reading, editing and deletion; own and unrelated records; provider read-only access; and direct unauthorized HTTP requests rather than only hidden links.
- Test the four required queries against a fixture dataset that includes shared clients, different plans, empty results, multiple entry dates and tied timestamps. Verify membership, no unintended duplication, and creation-time/ID ordering. Verify an edited entry retains creation-based position.
- Test enrollment creation and removal through browser acceptance. Check Basic default and Premium selection, duplicates, invalid plans, ownership tampering, visibility of existing entries after enrollment, denial after removal, and preservation of the client's entries. Focused model/database tests cover constraints and role/profile consistency, including unique-pair protection under competing writes where appropriate.
- Test Redis through its real local integration: a first provider-list read populates the cache, repeated reads reuse the cached result, and committed add/remove operations refresh results. Cover independent clients, any cached display-field changes, cache clearing and cache warming before access revocation. Verify authorization does not depend on cached membership.
- Test schema/migration setup and project-scoped cache isolation on the disposable test database without loading seeds. Demo seed repeatability is a manual environment check, not a dependency of any automated test. Unit, request and browser QA must not mutate the development preview's records.
- Test scheduler behavior at its tracker/process boundary with controlled issue states and dispatch evidence: ready Todo versus Backlog, unfinished dependencies, In Review/Blocked/pause gates, feedback returning the owned ticket, restart recovery, manual release and Done. Keep these tests deterministic; then perform one intentionally selected local end-to-end Linear smoke after setup. Publishing this spec does not authorize that smoke.
- Verify browser screenshots and the PR report identify the tested code revision and remain accessible from the PR after local test processes stop. Confirm that In Review leaves the human preview running without an active coding session.
- Existing prior art consists of Rails' generated test harness, the current framework/style/check entry point and health endpoint. The repository currently has no behavioral tests, domain models or Playwright configuration. Extend those foundations; do not describe missing suites as existing coverage.
- Keep checks proportional to this interview app: focused framework/style validation and behavior tests, with independent QA for each delivered slice. No coverage quota, broad browser matrix, performance benchmark program or speculative load infrastructure. Discuss scale using query plans and index tradeoffs without requiring a production-scale dataset.

## Out of Scope

- The frontend-only Session 2 interview and any separate frontend preparation.
- Pre-implementing the unknown feature, validation or query that the interviewer will introduce during pairing.
- Public deployment, additional hosting infrastructure or production operations for this pre-work.
- An admin role, admin impersonation, multi-role accounts, self-registration, password-recovery/confirmation email flows, social login or a general permission-management UI.
- Provider-driven client enrollment, general provider/client account CRUD (except the PIC-285 own-credentials editor below), invitations, separate plan editing, billing, payments or subscription history.
- Provider-owned journal entries, provider-specific journal sharing, rich text, attachments, backdating or an independently editable journal date.
- Journal-feed caching, caching every required query, distributed cache-coherence infrastructure or using cache contents to grant access.
- Parallel ticket implementation, stacked PRs, automatic merges, extra agent roles or per-ticket application infrastructure stacks.
- Broad architectural refactors, speculative optimizations and exhaustive test matrices that are unnecessary to the accepted behavior.

## Further Notes

- Healthie's required Session 1 foundation is the provider/client model, relationship plans, client journals and four ActiveRecord queries. Authentication, role UI, caching and local agent infrastructure are Steven's selected additions, not employer mandates. The employer permits a partial foundation; finish the agreed scope promptly while retaining an explainable codebase.
- The interview is not yet scheduled. Steven will schedule after pre-work is ready. The live session includes a setup walkthrough, collaborative extension and tradeoff discussion, with AI allowed and the candidate expected to explain generated code.
- Preserve the accepted architecture decisions: explicit User role plus separate profiles, and client-wide journals shared with current providers. Read the repository glossary and ADRs before implementation; surface any conflict rather than quietly replacing them.
- Current state: a stateless Rails skeleton and planning/configuration documents. ActiveRecord is disabled; PostgreSQL integration, Devise, Pundit, domain migrations, seeds, local Compose services, Playwright acceptance and the durable review gate remain implementation work. Polling and status filters alone do not mean the local scheduler is ready.
- PIC-271 and PIC-272 retain earlier skeleton setup/smoke evidence and are currently In Review. Reconcile their review status before local dispatch so historical setup issues do not create ambiguous slot ownership. Do not treat them as validation of the new local runtime or silently mark them merged/completed.
- Publish this spec as a planning parent in Backlog, not as claimable implementation work. Create the approved implementation breakdown separately; retain native dependencies and enough acceptance/validation context for fresh agent sessions. No implementation ticket is activated by spec publication.
- Keep the repository copy and the published Linear spec synchronized, and include the planning documents, glossary and ADRs in version control through the normal review path. The PR remains the canonical location for per-ticket QA evidence; do not duplicate full QA reports in Linear.

## Enrollment list ordering

Both enrolled lists use `enrollments.created_at DESC, enrollments.id DESC`.
Relationship age, rather than User or profile creation/update time, determines
position. A removed and re-added enrollment gets a new position. Provider-facing
lists preload `client: :user`; the client provider-list query uses joins and
pluck to project serializable display rows into Redis. Cache
hits preserve that array order; committed membership changes invalidate it.
Authorization continues to query current enrollments independently of display data.
PIC-285 uses the v2 cache key with credential arrays and the same one-minute expiry. Old v1 payloads are not read and expire naturally.

## Optional provider credentials (PIC-285)

Providers may edit only their own optional professional credentials from their workspace using labeled checkboxes grouped under Credentials. The supported set is the curated 50-choice U.S.-focused catalog below, in group/choice order. Preserve exact stored/display codes, including mixed case and hyphens. Multiple selections and clearing all are supported; RD/RDN are alternatives with no mutual-exclusion or verification rule.

Store credentials on Provider as a non-null PostgreSQL string array defaulting to empty, with application-level supported-value validation. Assume well-formed credential arrays; normalize the empty checkbox sentinel, duplicates and supported-list order, and reject unsupported codes with feedback. Steven’s 2026-10-21 PR feedback supersedes the earlier credential CHECK and separate expansion migration: keep one add-column migration; the database retains the empty default and non-null requirement. Devise and action-specific Pundit enforce own-profile editing, with ownership derived server-side and only credentials writable. This narrowly extends the account CRUD exclusion; identity, roles, enrollment plans and journal access are unchanged.

Append selected abbreviations to names on provider home, My providers and Add a provider; empty credentials display the name alone. Keep User.name unchanged. Extend the scalar joins/pluck Redis payload with credentials, preserve explicit enrollment ordering and invalidate all enrolled clients only after a committed change. Failed/rolled-back writes and unrelated clients retain their lists. Version the payload to avoid legacy labels. Add a few deterministic manual seed examples; automated tests own their scenarios. ADR 0004 records the array tradeoff; no credentialing subsystem, new infrastructure or larger demo dataset is included.

### Approved credential catalog (expanded 2026-10-20)

These are degrees, licenses/professional designations and certifications, not equivalent roles or proof of practice authority. DO differs from OD; PhD/DNP/PharmD do not imply MD/DO. CNS means Certified Nutrition Specialist. No automatic selections, exclusions or verification. Additional jurisdiction aliases and specialty credentials are deferred.

**Medicine, eye care, dental and chiropractic**

- MD — Doctor of Medicine
- DO — Doctor of Osteopathic Medicine
- OD — Doctor of Optometry
- DDS — Doctor of Dental Surgery
- DMD — Doctor of Dental Medicine
- DPM — Doctor of Podiatric Medicine
- DC — Doctor of Chiropractic

**Nursing and physician assistants**

- RN — Registered Nurse
- LPN — Licensed Practical Nurse
- LVN — Licensed Vocational Nurse
- APRN — Advanced Practice Registered Nurse
- NP — Nurse Practitioner
- DNP — Doctor of Nursing Practice
- BSN — Bachelor of Science in Nursing
- MSN — Master of Science in Nursing
- CNM — Certified Nurse-Midwife
- CRNA — Certified Registered Nurse Anesthetist
- PA-C — Physician Assistant-Certified

**Nutrition and diabetes care**

- RD — Registered Dietitian
- RDN — Registered Dietitian Nutritionist
- LD — Licensed Dietitian
- LDN — Licensed Dietitian/Nutritionist
- CNS — Certified Nutrition Specialist
- CDCES — Certified Diabetes Care and Education Specialist

**Mental health and academic degrees**

- PhD — Doctor of Philosophy
- PsyD — Doctor of Psychology
- LCSW — Licensed Clinical Social Worker
- LMFT — Licensed Marriage and Family Therapist
- LPC — Licensed Professional Counselor
- LMHC — Licensed Mental Health Counselor
- LPCC — Licensed Professional Clinical Counselor
- MSW — Master of Social Work
- LSW — Licensed Social Worker
- LICSW — Licensed Independent Clinical Social Worker
- NCC — National Certified Counselor
- BCBA — Board Certified Behavior Analyst

**Physical and occupational therapy**

- PT — Physical Therapist
- DPT — Doctor of Physical Therapy
- OTD — Doctor of Occupational Therapy
- OTR — Occupational Therapist Registered
- PTA — Physical Therapist Assistant
- COTA — Certified Occupational Therapy Assistant

**Pharmacy**

- PharmD — Doctor of Pharmacy
- RPh — Registered Pharmacist

**Audiology and speech-language pathology**

- AuD — Doctor of Audiology
- CCC-A — Certificate of Clinical Competence in Audiology
- CCC-SLP — Certificate of Clinical Competence in Speech-Language Pathology

**Naturopathic medicine and acupuncture**

- ND — Doctor of Naturopathic Medicine
- LAc — Licensed Acupuncturist

**Health and wellness coaching**

- NBC-HWC — National Board Certified Health & Wellness Coach

## Approved interface direction

PIC-287 applies the approved Off-white calm design across existing roles, journal/relationship flows, optional provider credentials and public errors. Keep Rails ERB, Propshaft, Devise, Pundit, importmap and Hotwire; compiled Tailwind CSS and daisyUI supply one light theme, with bundled Manrope/Lora fonts, responsive role navigation, accessible confirmations and server-backed feedback. Existing product, permission, query/cache and credential decisions remain authoritative. See [frontend build and design documentation](frontend.md) for the durable reference, build paths and dependency decisions.
