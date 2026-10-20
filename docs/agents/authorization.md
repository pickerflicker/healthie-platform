# Pundit conventions

Read before changing or reviewing controllers, policies/scopes, record lookups, ownership parameters or authorization-sensitive queries/caches. These are project coding and review rules; apply them within the active ticket's scope. They do not establish that a feature or verification hook is already implemented. Product permissions remain defined by [the spec](../spec.md) and [the domain ADRs](../adr/).

## Choose the lookup and check deliberately

| Operation | Project convention |
| --- | --- |
| Collection | Start with `policy_scope(Model)`, then apply search, ordering and pagination to that relation. Add `authorize Model, :index?` when entering the collection itself requires an action permission. |
| Individual record | Load the record, then `authorize record` for the actual action before rendering sensitive data or performing a mutation. |
| Individual record whose existence should be concealed | Use `policy_scope(Model).find(id)`, then `authorize record`. A missing/out-of-scope ID returns 404; a visible record can still fail the action check with 403. |
| New record | Build through a trusted owner/authorized parent, assign only permitted input, then authorize the unsaved record before saving. |
| Class/headless action | Class or symbol authorization is appropriate only when there is genuinely no individual record to check. |

For example, a journal endpoint using the concealment convention would do:

```ruby
@journal_entry = policy_scope(JournalEntry).find(params[:id])
authorize @journal_entry # show?, update? or destroy? follows the controller action
```

Choose and test 403 versus 404 per endpoint; retain established role-boundary responses unless the ticket changes that contract. Do not blanket-convert authorization errors into 404s. Authentication failures continue through Devise. Handle denial centrally without exposing another account's data in messages.

## Policy and controller rules

1. **Deny by default.** Explicitly grant supported actions; unsupported actions stay denied. Authenticate protected requests before authorization. Account role alone does not establish access to a particular record.
2. **Check the record independently.** An instance predicate checks the role and applicable ownership/current relationship even when the caller used a scoped lookup. Scope membership does not grant every action: a provider may read a currently associated client's journal but cannot edit it. Avoid duplicating the full permission rule in controllers or views.
3. **Authorize before side effects.** Writes, deletes and other protected effects follow authorization. Checking a parent does not automatically authorize its child or a newly selected association; validate both the nested relationship and the relevant action. Use the same policy predicates to show controls in views, while enforcing them on direct requests too.
4. **Trust server-derived ownership.** Take the acting identity from `current_user` and derive journal/client ownership through trusted associations. Permit only intended editable fields. Request-supplied role, `user_id`, `client_id` or nested IDs must not silently transfer ownership or bypass policy checks. A user-selected provider ID still needs its own eligibility/relationship validation.
5. **Keep scopes and policies small.** Return an ActiveRecord relation from scopes; constrain rows in SQL rather than loading everything and filtering Ruby arrays. Predicates return booleans and may query needed relationships, but do not mutate records, send responses or produce other side effects. Use ordinary Ruby helpers for shared rules; avoid a custom permission framework. A provider-selection directory and a provider's private profile are different authorization contexts: use an explicit context-specific policy/scope when their visibility differs.
6. **Use current relationships.** For journal reads, use current database enrollment membership as specified in the ADR. Redis provider-list data is display data, not permission evidence. Removal must deny subsequent direct reads and feeds even after cache warming. Preserve the client's entries; providers remain read-only.
7. **Detect forgotten calls.** Use `verify_policy_scoped` for collection actions and `verify_authorized` for record actions. If an action requires both calls, verify both. Keep exceptions explicit and narrow for genuinely public/authentication endpoints; document why. These hooks detect missing calls, not whether the right record or rule was checked.

## Developer review and QA

For changed authorization behavior, verify the smallest meaningful set of cases:

- Policy/scope checks distinguish the owner, a different account of the same role, the opposite role and unauthenticated access where applicable. Test record predicates directly so a restrictive controller scope cannot hide a permissive predicate.
- Direct HTTP requests cover allowed actions and relevant denied reads/writes, guessed IDs, forged ownership fields and mismatched nested IDs. Assert the chosen 403/404 behavior, no sensitive data disclosure and no database changes on denied mutations.
- Relationship-sensitive changes cover associated versus unrelated providers, provider write denial, and access revoked on the next request after removal with previously warmed display caches. Verify the scoped collection contains exactly the expected accessible records.
- Check authorization happens before effects and that applicable verification hooks/exemptions are correct. Passing `verify_authorized` alone is insufficient evidence of access control. Record backend inputs, expected/actual results and the reason for the check under [the QA evidence policy](qa-evidence.md).

Use existing Minitest/request tests and targeted policy checks; no extra testing library, blanket coverage target or mandatory browser run for a backend-only policy change. A document review is not a claim that these application checks have passed.

## Sources

Reviewed 2026-10-20: [Pundit policies/scopes](https://github.com/varvet/pundit#policies), [verification hooks](https://github.com/varvet/pundit#ensuring-policies-and-scopes-are-used), [OWASP authorization guidance](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html). The lookup/error-response conventions and Healthie-specific permissions above are this project's choices.
