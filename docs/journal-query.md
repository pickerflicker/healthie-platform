# Client journal query

Journal entries belong to the client independently of provider relationships. In a Rails console, the required client query is:

```ruby
client = User.find_by!(email: "client@healthie.example").client
client.journal_entries.order(created_at: :desc, id: :desc)
```

The controller starts with `policy_scope(JournalEntry)` and applies the same explicit ordering. Editing text leaves `created_at` unchanged. The composite `(client_id, created_at, id)` index supports this per-client filter/order; it replaces a standalone client index. Journals are queried directly, without Redis caching.

The [fictional manual demo](demo.md) now includes 50
Alex entries over a fixed 90-day baseline, preserving the three original notes
and their timestamp tie. Morgan's feed includes several fictional clients; Sam's
journal is denied to Taylor, while Luna's history attributed to Gregory House is denied to Morgan.
Jamie remains empty. These manual seeds are independent of automated test data.


Each new entry requires an enrolled provider. Basic counts existing entries for that pair in the current UTC calendar month (10 allowed); Premium is unlimited. Client ownership and creation time are server-derived in HTTP requests and immutable on updates. Text edits remain possible at the cap. The backend accepts provider_id; the unchanged text-only form works only for exactly one enrollment. Zero/multiple enrollments without a provider ID produce validation errors until the selector is implemented.
