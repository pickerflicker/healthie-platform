# Client journal query

Journal entries belong to the client independently of provider relationships. In a Rails console, the required client query is:

```ruby
client = User.find_by!(email: "client@healthie.example").client
client.journal_entries.order(created_at: :desc, id: :desc)
```

The controller starts with `policy_scope(JournalEntry)` and applies the same explicit ordering. Editing text leaves `created_at` unchanged. The composite `(client_id, created_at, id)` index supports this per-client filter/order; it replaces a standalone client index. Journals are queried directly, without Redis caching.

Seeds include three entries for Alex across two dates, two sharing a creation timestamp, one unrelated client's entry and Jamie's empty journal. All demo accounts use the documented local demo password. Additional client logins are `unrelated-client@healthie.example` and `empty-client@healthie.example`. Provider journal access is deferred until the enrollment/read feature.
