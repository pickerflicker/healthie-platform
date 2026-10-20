# healthie-platform

Rails 8.1 / Ruby 3.4 interview app. Local Docker Compose runs Rails, PostgreSQL and Redis; native mise tooling runs focused checks and Playwright.

```sh
mise trust
mise install
mise exec -- bin/bootstrap
bin/stack up
mise exec -- bin/rails db:seed
mise exec -- bin/check
RAILS_ENV=test mise exec -- bin/rails db:seed
mise exec -- bin/acceptance
```

Review preview: http://127.0.0.1:3000. `bin/preview` binds the shared web service to this checkout. `bin/stack stop` preserves database storage. Tests use `healthie_test` and the `healthie:test` Redis namespace; development browsing data is retained.

Sign in with `provider@healthie.example` (Morgan Patel) or `client@healthie.example` (Alex Rivera). All seeded accounts use the local fixture password `Healthie-demo-2026`. Additional accounts are `second-provider@healthie.example` (Taylor Reed), `empty-provider@healthie.example` (Casey Park), `unrelated-client@healthie.example` (Sam Chen) and `empty-client@healthie.example` (Jamie Brooks). Alex has Basic with Morgan and Premium with Taylor; Sam has Premium with Morgan. Jamie and Casey start without relationships. Seeds restore intentional identities/passwords and add missing baseline relationships without duplicating records or removing unrelated data. No signup or password recovery is exposed.

Clients use **My providers** to add Basic (default) or Premium relationships and remove providers; providers use **My clients** to open current clients' individual journals, or **Combined journal feed** to browse all current clients' entries. Journals are read-only for providers and ordered by creation time descending, then ID descending. Enrollment grants access to existing and future client-wide journals; removing it revokes subsequent direct and feed access while preserving journals and accounts. Redis provider-list caching is deferred to PIC-281.

Run the four required ActiveRecord queries in `mise exec -- bin/rails console`:

```ruby
provider = User.find_by!(email: "provider@healthie.example").provider
client = User.find_by!(email: "client@healthie.example").client
provider.clients.order(:id)
client.providers.order(:id)
client.journal_entries.order(created_at: :desc, id: :desc)
provider.journal_entries.order(created_at: :desc, id: :desc)
```

See [queries and walkthrough tradeoffs](docs/queries.md) for expected seed results, plans, index limits and a read-only runner that prints all four SQL queries and `EXPLAIN` plans.

`User.create_account!(name:, email:, password:, role:)` creates an account and matching profile atomically. User owns identity and a required string role; Provider/Client delegate identity. Model validation enforces the matching profile, immutable role/account association and retained required profile. Database constraints enforce required/unique profile foreign keys and valid roles. Direct SQL/bulk writes bypass cross-table model validation and are outside the normal account creation path.

[Linear project](https://linear.app/pickerflicker/project/healthie-platform-c6cbdb1032a3). See [operations](docs/operations.md) and [Developer/QA workflow](docs/agent-team.md).
