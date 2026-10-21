# Session 1 queries and walkthrough

Seed the local development database using `mise exec -- bin/rails db:seed`.
Open `mise exec -- bin/rails console` and run all four employer-required queries:

```ruby
provider = User.find_by!(email: "provider@healthie.example").provider
client = User.find_by!(email: "client@healthie.example").client

provider.clients.order("enrollments.created_at DESC", "enrollments.id DESC").preload(:user)
client.providers.order("enrollments.created_at DESC", "enrollments.id DESC").preload(:user)
client.journal_entries.order(created_at: :desc, id: :desc)
provider.journal_entries.order(created_at: :desc, id: :desc)
```

Both journal listings use creation time descending, then ID descending. Editing
text leaves the creation time unchanged. Relationship lists use `enrollments.created_at DESC, enrollments.id DESC`,
independent of profile age or edits. Removing and re-adding moves the relationship
to its new enrollment position. These explicit list queries preload User identities;
the associations themselves remain unscoped. These are ordinary ActiveRecord
relations, directly runnable without an HTTP session. They are not
authorization APIs: a console operator selects the profile explicitly. Web reads
start with Pundit scopes and independently authorize records. They consult current
enrollments, so adding a provider exposes historical entries and removing one
revokes subsequent direct/list reads without deleting journal entries. Plans do
not restrict journal visibility. Providers have read-only access.

For relationship plans, use the join records:

```ruby
client.enrollments.preload(provider: :user).order(created_at: :desc, id: :desc).map { |e| [e.provider.name, e.plan] }
```

## Intentional dataset

See the [README login/scenario table](../README.md#fictional-manual-demo) for
accounts, credentials, memorable stories, precise rerun restoration rules and the
Docker seed command. These are fictional manual demo fixtures, independent of
regular model/request/browser test scenarios.

A clean baseline implements exactly **30 providers, 100 clients, 200 enrollments
and 1,000 journals**. The fixed inclusive 90-day window is **July 23–October 20,
2026 UTC**, with endpoints `2026-07-23T08:00:00Z` and `2026-10-20T08:00:00Z`.
Existing development data and edits can change these totals/distributions.

| Distribution | Clean baseline |
| --- | --- |
| Enrollment plans | 103 Basic / 97 Premium |
| Provider credentials | 9 RDN+LD / 4 RDN+LD+CDCES / 7 CNS / 10 MD; no blanks |
| Provider client counts | Morgan 38; Taylor 9; Casey, Poppy and Wren 0; Cedar 1; Pearl 2; remaining 23 providers 4–10 each |
| Client provider counts | 7 unassigned / 10 with one / 70 with two / 6 with three / 6 with four / Alex with eight |
| Primary provider | Morgan: 38 clients, 503 combined entries, both plans, Quinn with no entries |
| Primary client | Alex: 8 providers, 50 entries, 22 available providers; Basic Morgan / Premium Taylor |
| Journal volumes | Alex 50, Sam 12, Jamie 0, Sherlock 45, Frodo 40, Bilbo 35, Arthur 30, Dorothy 25, Picard 40, Quinn 0, Luna 15, Pip 2; 87 others with 8, Marlow Kingsley with 10 |

Morgan and Taylor share Alex and Sherlock. Taylor cannot access Sam; Morgan
cannot access Luna's unassigned history. Credentials belong to providers, while
plans belong to each enrollment. Shared clients can have different plans with
different providers. Casey/Jamie remain deliberate empty accounts, and the last
five invented clients plus Luna and Jamie have no providers.

Ordering is explicit and does not follow account age. On a clean load Morgan's
newest two enrollments are Frodo then Sherlock, tied at October 20 10:00 UTC.
Alex's newest two are Meredith Grey then Gregory House, tied at 11:00 UTC.
The larger enrollment ID wins each tie; new account/profile dates precede the
relationships by months. Existing legacy record timestamps are preserved.
Alex retains the original October 19 18:00 notes (stretch, then lunch by ID),
plus newer October 20 08:00 ties. Morgan's feed has exact ties across clients
as well. Read actual IDs from `bin/queries`, since existing/manual records mean
there are no portable hard-coded IDs. Unchanged reseeding preserves these IDs,
timestamps and query orders.

The opt-in `script/demo_seed_smoke.rb` validates the seed feature only, refuses
nonlocal/non-test/nonempty targets, and compares every database attribute plus
the four ordered ID lists across reruns. It additionally checks manual sentinel
records/edits, missing-state restoration and real Redis namespace isolation.
It is intentionally absent from regular application/CI test fixtures and checks.
Observed local native run: 2.30 seconds clean, 0.68 seconds unchanged rerun
(illustrative observations, not a benchmark gate).

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
  joining. No additional index is justified by a seed-scale dataset alone.
- Both journal listing queries and provider-client lists remain uncached in Redis.
  ActiveRecord's ordinary request-local query cache is separate from persistent
  application caching. The only Redis result cache is the per-client provider
  display list, never permission evidence.

## Provider-list cache

`Client::ProviderList` owns the cache key, one-minute TTL, scalar query and
after-commit invalidation. Enrollment and User callbacks identify affected
clients; `client.provider_list` remains the display read entry point.

`client.provider_list` returns serializable hashes with enrollment/provider IDs,
provider name, credentials and plan, ordered by enrollment creation time then ID, both descending. The client **My providers** page
uses it after Pundit scopes the client; `client.providers` remains a raw
ActiveRecord association. The provider directory dropdown is also queried live.

Redis keys are `healthie:<environment>:clients/<client ID>/provider-list/v2`, with
an explicit one-minute expiry on each provider-list write. The first read fetches
the enrollment result with a joined scalar projection; subsequent reads reuse it. Enrollment commits (including plan updates) delete
affected client keys. Provider name and credential commits delete keys for all enrolled clients.
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
```

The script prints each relation's SQL, result IDs and PostgreSQL `EXPLAIN` plan.
Compare results with the baseline above and inspect join access paths and sort
nodes. A sequential scan or explicit sort can be reasonable at this seed scale;
planner choices depend on data, statistics and PostgreSQL version. `EXPLAIN`
shows estimates, not measured latency or production throughput. Do not force
index scans or infer large-dataset performance from this demonstration. Pagination,
backdating, provider-specific sharing and the unknown live interview extension
remain outside this pre-work.
