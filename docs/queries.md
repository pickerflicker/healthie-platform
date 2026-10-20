# Session 1 queries and walkthrough

Seed the local development database using `mise exec -- bin/rails db:seed`.
Open `mise exec -- bin/rails console` and run all four employer-required queries:

```ruby
provider = User.find_by!(email: "provider@healthie.example").provider
client = User.find_by!(email: "client@healthie.example").client

provider.clients
client.providers
client.journal_entries.order(created_at: :desc, id: :desc)
provider.journal_entries.order(created_at: :desc, id: :desc)
```

Both journal listings use creation time descending, then ID descending. Editing
text leaves the creation time unchanged. Relationship lists use `enrollments.created_at DESC, enrollments.id DESC`,
independent of profile age or edits. Removing and re-adding moves the relationship
to its new enrollment position. Both association queries preload User identities. These are ordinary
ActiveRecord relations, directly runnable without an HTTP session. They are not
authorization APIs: a console operator selects the profile explicitly. Web reads
start with Pundit scopes and independently authorize records. They consult current
enrollments, so adding a provider exposes historical entries and removing one
revokes subsequent direct/list reads without deleting journal entries. Plans do
not restrict journal visibility. Providers have read-only access.

For relationship plans, use the join records:

```ruby
client.enrollments.preload(provider: :user).newest_first.map { |e| [e.provider.name, e.plan] }
```

## Intentional dataset

All local fixture logins use `Healthie-demo-2026`; append `@healthie.example`
to the login below. Seeds add missing baseline records without removing other
browsing data. Counts below describe a clean seed baseline.

| Login | Profile and expected query results |
| --- | --- |
| provider | Morgan Patel: Sam Chen (Premium), Alex Rivera (Basic); four journal entries |
| second-provider | Taylor Reed: Alex (Premium); Alex's three entries, excluding Sam |
| empty-provider | Casey Park: no clients or feed entries |
| client | Alex Rivera: Taylor then Morgan; three entries, with two tied creation times |
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
  application caching. The only Redis result cache is the per-client provider
  display list, never permission evidence.

## Provider-list cache

`client.provider_list` returns serializable hashes with enrollment/provider IDs,
provider name and plan, ordered by enrollment creation time then ID, both descending. The client **My providers** page
uses it after Pundit scopes the client; `client.providers` remains a raw
ActiveRecord association. The provider directory dropdown is also queried live.

Redis keys are `healthie:<environment>:clients/<client ID>/provider-list/v2`, with
an explicit one-minute expiry on each provider-list write. The first read fetches
the enrollment result with provider/user preloads; subsequent reads reuse it. Enrollment commits (including plan updates) delete
affected client keys. Provider name commits delete keys for all enrolled clients.
Email is not cached. The list uses ordinary `Rails.cache.fetch`; the application
reads it outside write transactions. Rolled-back relationship/name writes do not
invalidate or publish changed membership. Calling this display query inside a
write transaction is outside the supported flow: a cold fetch could cache
uncommitted data, and a warm fetch could return the pre-transaction list.
Seeds clear only this project's current-environment cache namespace after loading.

This small local app uses synchronous after-commit invalidation and Redis's Rails
store fallback to database queries on cache read failure. If a crash or Redis
failure prevents invalidation, a written entry expires within one minute of its
write; expiry is not the normal refresh mechanism. Entries written before the
one-minute TTL change retain their old expiry unless invalidated or cleared.
Bulk SQL skips model callbacks, so maintenance scripts must clear the relevant
project cache as seeds do. This is ordinary cache-aside behavior: it does not
serialize concurrent cache fills against commits across processes. Distributed
cache-coherence machinery is outside the accepted pre-work. Journal authorization
always queries current enrollments, regardless of stale or unavailable display
cache data.

To observe miss/hit/invalidation on the real local Redis integration:

```sh
source script/native_bundle_env
mise exec -- bin/rails test test/integration/provider_list_cache_test.rb
```

The focused checks observe Rails cache notifications, count the actual enrollment SQL,
verify Redis key presence, and exercise committed changes and rollbacks. They also
deliberately restore stale display data after removal and verify policy, direct
journal and feed denial. Test cache clearing leaves development keys intact.

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
