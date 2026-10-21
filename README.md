# healthie-platform

Rails 8.1 / Ruby 3.4 interview app. Local Docker Compose runs Rails, PostgreSQL and Redis; native mise tooling runs focused checks and Playwright.

## Four required interview queries — Session 1

These are the four ActiveRecord queries required by the interview spec. After the local setup below, **run all four in one read-only command**:

```sh
bin/queries
```

The [shortcut](bin/queries) runs the [query script](script/interview_queries.rb) inside the existing Rails container, using this checkout's Compose configuration. It works even when Docker is missing from your shell's PATH and requires no native Ruby gems. The web container must already be running. It prints each query's SQL, result IDs and PostgreSQL `EXPLAIN` plan against the current development database. Results reflect current data, including changes made in the UI; the [query walkthrough](docs/queries.md) documents the clean seed baseline and index tradeoffs.

From another directory, use the full path: `~/dev/healthie-platform/bin/queries`.

| Spec requirement | ActiveRecord query |
| --- | --- |
| All clients for a provider | `provider.clients.order("enrollments.created_at DESC", "enrollments.id DESC").preload(:user)` |
| All providers for a client | `client.providers.order("enrollments.created_at DESC", "enrollments.id DESC").preload(:user)` |
| A client's journal entries, newest first | `client.journal_entries.order(created_at: :desc, id: :desc)` |
| Journal entries across all clients of a provider, newest first | `provider.journal_entries.order(created_at: :desc, id: :desc)` |

To run them individually in a native Rails console, first run `source script/native_bundle_env`, then `mise exec -- bin/rails console` and select the seeded profiles:

```ruby
provider = User.find_by!(email: "provider@healthie.example").provider
client = User.find_by!(email: "client@healthie.example").client
```

## Run locally

```sh
mise trust
mise install
source script/native_bundle_env
mise exec -- bin/bootstrap
bin/stack up
mise exec -- bin/rails db:seed
mise exec -- bin/check
mise exec -- bin/acceptance
```

Review preview: http://127.0.0.1:3000. `bin/preview` binds the shared web service to this checkout. `bin/stack stop` preserves database storage. Tests use `healthie_test` and the `healthie:test` Redis namespace; development browsing data is retained. All automated tests create their own accounts and scenarios; none load or depend on `db/seeds.rb`. Browser fixtures reset only the disposable test database records/cache before and after each test, including retries and individual-file runs.

## Interface and CSS build

The approved Off-white calm interface uses compiled Tailwind CSS and daisyUI with ERB/Hotwire. `bin/bootstrap`, `bin/preview`, `bin/check` and `bin/acceptance` compile CSS automatically. Use `mise exec -- bin/dev` for native Rails plus CSS watching. [Frontend documentation](docs/frontend.md) records the design reference, bundled fonts, Docker/asset builds and dependency evidence.

## Fictional manual demo

**Provider: `provider@healthie.example` — Morgan Patel, RDN + LD.**
**Client: `client@healthie.example` — Alex Rivera.**
**Local-only fixture password: `Healthie-demo-2026`** for both and all newly seeded accounts.

All identities, credentials, relationships and journals are **fictional demo data**.
Character names are playful app fixtures, not claims about real people, canonical
qualifications or anyone's health. Emails use reserved example domains. There is
no signup or password recovery. Fictional doctors (House, Grey, Watson, Crusher)
join invented nutrition practitioners; all 30 providers have supported credentials.
The application still permits blank credentials outside this manual baseline.

Append `@healthie.example` to each login below. Counts describe a clean baseline;
manual changes can increase totals or change scenarios.

| Login | Fictional identity / credentials | What to try |
| --- | --- | --- |
| **provider** | **Morgan Patel · RDN + LD** | 38 clients, Basic and Premium, hundreds of combined entries. Open Sherlock, Frodo or Picard; open Quinn's empty journal. |
| **client** | **Alex Rivera** | Eight providers with credentials and mixed plans; 50 entries. Create/edit/delete a note, add an available provider (22 remain), then remove that relationship. Morgan stays Basic; Taylor stays Premium in the baseline. |
| second-provider | Taylor Reed · MD | Open shared Alex or Sherlock. Sam's journal URL is denied to Taylor because Sam is enrolled with Morgan only. |
| empty-provider | Casey Park · CNS | No clients or combined feed. |
| empty-client | Jamie Brooks | No providers or journals. |
| unrelated-client | Sam Chen | 12 entries; Premium with Morgan, **not enrolled with Taylor**. Copy a journal URL, sign in as Taylor and revisit it to see denial. |
| sherlock-holmes | Sherlock Holmes | Shared by Morgan, Taylor and Gregory House (MD). Copy a journal URL and confirm access as Morgan/Taylor. As Sherlock, remove Taylor in My providers; Taylor's next direct read is denied while Morgan retains access. |
| quinn-stillwater | Quinn Stillwater | Enrolled with Morgan but zero journals. |
| luna-lovegood | Luna Lovegood | 15 entries and no providers; a copied journal URL is denied to Morgan. |
| pip-willow | Pip Willow | Two entries; Cedar Bloom (RDN + LD) has just this client. |
| poppy-thyme / wren-maple | Poppy Thyme · CNS / Wren Maple · RDN + LD | Two additional empty providers. Pearl Ginger (CNS) has two clients. |

Morgan's feed includes Frodo packing a second apple for Mordor, Sherlock's
meal-prep mystery and Picard promoting water alongside tea. Alex mixes those
playful motifs with ordinary meal planning, walks, sleep and small follow-ups;
several entries have multiple paragraphs. All text is original.

Fixed **90-day inclusive UTC baseline: July 23–October 20, 2026** (reference
`2026-10-20T08:00:00Z`). Older stories, quiet periods, busy days and exact ties
make ordering visible. On a clean load Morgan's newest enrollments are Frodo and Sherlock tied
at October 20 10:00 UTC; the later enrollment ID sorts first. Alex's newest
providers are Meredith Grey and Gregory House tied at 11:00 UTC, also ID descending.
Account/profile timestamps are older and deliberately disagree with enrollments.
Alex retains the two original October 19 18:00 journal ties; October 20 08:00
contains further ties within Alex and across clients in Morgan's feed. Run
`bin/queries` for all four queries and actual IDs; see [query details](docs/queries.md).

### Load and rerun safely

`bin/preview` only rebuilds/restarts Rails; it does **not** load the richer seeds.
After binding this checkout with `bin/preview`, seed the Docker development app:

```sh
/Applications/Docker.app/Contents/Resources/bin/docker compose exec -T web bin/rails db:seed
```

Native alternative after `source script/native_bundle_env`:
`mise exec -- bin/rails db:seed`. Never seed production. Seeds reject environments
other than development/test, add records through validated Rails APIs and clear
only `healthie:<current environment>` cache **after successful completion**.
They never truncate or delete data. The seed output reports actual runtime and
totals; the [seed summary](docs/queries.md#intentional-dataset) gives exact clean counts.

Unchanged reruns preserve IDs, all record timestamps, ordering, plans, journal text
and password digests. Existing names, passwords, nonempty provider credentials,
relationship plans and journal text edits survive. New accounts receive the
fixture password; rerunning does not reset an edited password.

Reruns **restore missing accounts at their stable email**, blank credentials on
seeded providers, missing baseline relationships (original plan/time), and missing
journal timestamp slots. They do not restore empty states after manual additions
or remove extra relationships/journals. An email edit makes that account a separate
manual identity, so the baseline email is recreated. Journal identity is client +
exact timestamp + ordinal among that timestamp's rows, not mutable text: existing
rows at a baseline timestamp satisfy slots, including manual rows. Moving/deleting
a baseline timestamp can cause a missing slot to be recreated; edited/moved records
are retained. Deleting one of tied rows recreates the missing slot with a new ID.
This additive repair is intentional, so rerunning is **not a harmless refresh** of
a manually altered access/revocation scenario. Never reset development data to
rehearse; use the disposable test database for seed validation.

The opt-in smoke is separate from regular tests and refuses any target except
empty local `healthie_test`:

```sh
source script/native_bundle_env
mise exec -- bin/reset-test-data healthie_test
RAILS_ENV=test mise exec -- bin/rails runner script/demo_seed_smoke.rb
```

It checks exact counts/scenarios, all-attribute rerun stability, manual sentinels,
edits, missing-state repair and environment-scoped Redis invalidation. It leaves
test validation data behind; normal tests still own their setup and never load seeds.

Clients use **My providers** to add Basic (default) or Premium relationships and remove providers; providers use **My clients** to open current clients' individual journals, or **Combined journal feed** to browse all current clients' entries. Journals are read-only for providers and ordered by creation time descending, then ID descending. Enrollment grants access to existing and future client-wide journals; removing it revokes subsequent direct and feed access while preserving journals and accounts. Only the client's provider display list uses Redis; see the [cache walkthrough](docs/queries.md#provider-list-cache).

`User.create_account!(name:, email:, password:, role:)` creates an account and matching profile atomically. User owns identity and a required string role; Provider/Client delegate identity. Model validation enforces the matching profile, immutable role/account association and retained required profile. Database constraints enforce required/unique profile foreign keys and valid roles. Direct SQL/bulk writes bypass cross-table model validation and are outside the normal account creation path.

## Check commands

| Command | Coverage | GitHub CI |
| --- | --- | --- |
| `bin/check` | Rails tests, Ruby style and code loading | Yes |
| `bin/acceptance` | Headless browser scenarios | Yes |
| `bin/check-delivery --base origin/main` | Delivery regression tests and QA artifact guard | Yes, with the PR/push base |
| `bin/check-agents` | 38 local agent-infrastructure tests plus nested toolchain validation | Local only |
| `bin/check-all --base origin/main` | All four suites above, sequentially | Local only |

For a complete local run, source `script/native_bundle_env`, then run `mise exec -- bin/check-all --base origin/main`. PostgreSQL/Redis and browser dependencies must be ready; agent checks also require the prepared Symphony runtime documented in [operations](docs/operations.md#validation-coverage). Missing prerequisites fail the command rather than skip a suite. Without `--base`, the delivery guard checks staged files instead of the committed branch diff.

Application-only PRs require the ordinary GitHub CI suites. Changes to agent launch, permissions, dispatch, retry handling or their test/check tooling additionally require a passing local `bin/check-agents` result recorded in the PR. Report suites by name; use “all checks passed” only for a successful `bin/check-all` run. Live Codex probes and optional security audits are separate, explicitly requested checks. The generated `bin/ci` audit runner is neither the GitHub workflow nor the full local command.

Browser tests share only small `signIn`/`signOut` helpers in `test/support/browser.js`. Each case declares its own records and expectations; authentication failure/tampering steps remain inline in the authentication test.

[Linear project](https://linear.app/pickerflicker/project/healthie-platform-c6cbdb1032a3). See [operations](docs/operations.md) and [Developer/QA workflow](docs/agent-team.md).
