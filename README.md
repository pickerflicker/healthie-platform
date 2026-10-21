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
| All clients for a provider | `provider.clients.order(:id)` |
| All providers for a client | `client.providers.order(:id)` |
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

Sign in with `provider@healthie.example` (Morgan Patel) or `client@healthie.example` (Alex Rivera). All seeded accounts use the local fixture password `Healthie-demo-2026`. Additional accounts are `second-provider@healthie.example` (Taylor Reed), `empty-provider@healthie.example` (Casey Park), `unrelated-client@healthie.example` (Sam Chen) and `empty-client@healthie.example` (Jamie Brooks). Alex has Basic with Morgan and Premium with Taylor; Sam has Premium with Morgan. Jamie and Casey start without relationships. Seeds restore intentional identities/passwords and add missing baseline relationships without duplicating records or removing unrelated data. No signup or password recovery is exposed.

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
