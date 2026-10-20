# Keep ordering explicit at query call sites

Accepted 2026-10-20. Associations describe record relationships; query builders choose ordering explicitly with `.order(...)` in controllers, model query methods and interview examples. Keep presentation ordering out of association declarations and `default_scope`, and show the actual sort columns at the call site rather than hiding them behind an ordering-only scope.

PR #14 exposed the tradeoff: ordering `Provider#clients` by enrollment age propagated into `Provider#journal_entries`, requiring `reorder(nil)` to undo it, while callers using `.order(:id)` would append to rather than replace the inherited order. We accept small repetitions of explicit ordering to keep query behavior visible and independently composable; select preloads at the query call site as well, preserving needed eager loading without adding it to the shared relationship definition.

For example, a newest-enrollment-first list can use:

```ruby
# Association
has_many :clients, through: :enrollments

# Query
provider.clients.preload(:user)
  .order("enrollments.created_at DESC", "enrollments.id DESC")
```

This decision changes where ordering is expressed, not which business order is required. Qualify sort columns when joins make their owner ambiguous, retain the required deterministic tie-breaker, and test the explicit query and displayed order. Use `reorder` only when deliberately replacing an existing query order, rather than adding compensating resets to downstream associations. Filtering scopes and relationship definitions remain ordinary Rails tools.

Rails reference: [ordering and replacing an existing order](https://guides.rubyonrails.org/active_record_querying.html#reorder).
