# Client journal query

Journal entries belong to the client independently of provider relationships. In a Rails console, the required client query is:

```ruby
client = User.find_by!(email: "client@healthie.example").client
client.journal_entries.order(created_at: :desc, id: :desc)
```

The controller starts with `policy_scope(JournalEntry)` and applies the same explicit ordering. Editing text leaves `created_at` unchanged. The composite `(client_id, created_at, id)` index supports this per-client filter/order; it replaces a standalone client index. Journals are queried directly, without Redis caching.

The [fictional manual demo](../README.md#fictional-manual-demo) now includes 50
Alex entries over a fixed 90-day baseline, preserving the three original notes
and their timestamp tie. Morgan's feed includes several fictional clients; Sam's
journal is denied to Taylor, while Luna's unassigned history is denied to Morgan.
Jamie remains empty. These manual seeds are independent of automated test data.
