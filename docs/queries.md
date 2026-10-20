# Session 1 queries and walkthrough

Seed the local development database using `mise exec -- bin/rails db:seed`.
Open `mise exec -- bin/rails console` and run all four employer-required queries:

```ruby
provider = User.find_by!(email: "provider@healthie.example").provider
client = User.find_by!(email: "client@healthie.example").client

provider.clients.order(:id)
client.providers.order(:id)
client.journal_entries.order(created_at: :desc, id: :desc)
provider.journal_entries.order(created_at: :desc, id: :desc)
```

Both journal listings use creation time descending, then ID descending. Editing
text leaves the creation time unchanged. Relationship lists use ID ascending for
repeatable browsing; their ordering is a project convention. These are ordinary
ActiveRecord relations, directly runnable without an HTTP session. They are not
authorization APIs: a console operator selects the profile explicitly. Web reads
start with Pundit scopes and independently authorize records. They consult current
enrollments, so adding a provider exposes historical entries and removing one
revokes subsequent direct/list reads without deleting journal entries. Plans do
not restrict journal visibility. Providers have read-only access.

For relationship plans, use the join records:

```ruby
client.enrollments.includes(provider: :user).order(:id).map { |e| [e.provider.name, e.plan] }
```

## Intentional dataset

All local fixture logins use `Healthie-demo-2026`; append `@healthie.example`
to the login below. Seeds add missing baseline records without removing other
browsing data. Counts below describe a clean seed baseline.

| Login | Profile and expected query results |
| --- | --- |
| provider | Morgan Patel: Alex Rivera (Basic), Sam Chen (Premium); four journal entries |
| second-provider | Taylor Reed: Alex (Premium); Alex's three entries, excluding Sam |
| empty-provider | Casey Park: no clients or feed entries |
| client | Alex Rivera: Morgan and Taylor; three entries, with two tied creation times |
| unrelated-client | Sam Chen: Morgan; one entry, inaccessible to Taylor |
| empty-client | Jamie Brooks: no providers or entries |

Morgan's combined feed is: “Tried a new breakfast recipe.” (Sam, October 20),
“An evening stretch helped me unwind.” (Alex, October 19, higher ID),
“Prepared lunch for tomorrow.” (Alex, same timestamp, lower ID), then
“Walked after breakfast and felt energized.” (Alex, October 17). Alex's journal
has the last three in that order. Shared Alex appears once per provider feed;
unique `(provider_id, client_id)` enrollments prevent duplicate join rows.
The tests also exercise tied timestamps across different clients.

## Schema and index tradeoffs

- User stores name/email and the Devise login with one role and matching
  Provider/Client profile. Ordinary foreign keys and unique profile indexes keep
  identity separate from relationships; account creation validates both profiles
  atomically. Bulk SQL bypasses that cross-table validation.
- Enrollment carries a relationship's Basic/Premium plan. Its unique
  `(provider_id, client_id)` index enforces one relationship per pair and supports
  provider-to-clients lookups; the separate `client_id` index supports the reverse
  lookup. A standalone `provider_id` index would duplicate the leading access path.
- JournalEntry belongs to Client, with required text and a foreign key. It has no
  provider/enrollment ownership: every current provider shares client-wide access
  under the accepted privacy assumption (ADR 0002).
- The journal B-tree `(client_id, created_at, id)` supports filtering by one client
  and a backward scan for that client's `created_at DESC, id DESC`. Across several
  clients, rows grouped by client do **not** guarantee the provider feed's global
  order; the explicit `ORDER BY` remains required and PostgreSQL may sort after
  joining. No additional index is justified by a tiny seed dataset alone.
- Both journal listing queries and provider-client lists remain uncached in Redis.
  ActiveRecord's ordinary request-local query cache is separate from persistent
  application caching. The only planned Redis feature is the per-client provider
  display list (PIC-281), never permission evidence.

## Inspect the actual queries

```sh
mise exec -- bin/rails runner script/interview_queries.rb
# Same read-only check on the intentionally seeded disposable QA database:
RAILS_ENV=test mise exec -- bin/rails runner script/interview_queries.rb
```

The script prints each relation's SQL, result IDs and PostgreSQL `EXPLAIN` plan.
Compare results with the baseline above and inspect join access paths and sort
nodes. A sequential scan or explicit sort can be reasonable for these few rows;
planner choices depend on data, statistics and PostgreSQL version. `EXPLAIN`
shows estimates, not measured latency or production throughput. Do not force
index scans or infer large-dataset performance from this demonstration. Pagination,
backdating, provider-specific sharing and the unknown live interview extension
remain outside this pre-work.
