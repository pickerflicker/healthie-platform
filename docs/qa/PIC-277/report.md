# PIC-277 independent QA

**Result: PASS — no blocking findings.** Tested application commit `e92ae3c4ab801a866cf979377a4bdd8928566480`, based on `28dc8a1ae7dccffecdf21d6622eea538df93794c`, on 2026-10-20. QA thread: `01a15a29-5299-7d63-9dd1-6e336fa1f406` (independent GPT-6.1 Sol / low). QA added browser regression coverage and this evidence only; no application-source edits.

## Acceptance evidence

| Criterion | Evidence | Result |
| --- | --- | --- |
| Explicit required role, canonical identity, unique matching profiles, atomic creation | Reviewed schema/models; focused Rails tests cover missing/mismatched/both profiles, duplicate email and profiles, FK/not-null/unique constraints, save rollback, delegated identity, immutable role/profile ownership | Pass |
| Both seeded sign-ins, role navigation and logout | Headless Chromium signs in as Morgan Patel/provider and Alex Rivera/client, checks landing URL/name/email, follows own-role navigation, signs out and confirms protected pages redirect | Pass |
| Repeatable seeds | Focused Rails tests repeat seeds, preserve IDs/counts and restore intended names/passwords | Pass |
| Server-side role boundaries and scoped access | Request/policy tests cover own-profile-only scopes and opposite-role denial. Browser verifies 403 for each opposite role even with forged role query parameter; login hidden `user[role]` cannot alter role | Pass |
| Meaningful invalid/unauthenticated handling | Browser verifies three protected URLs redirect when anonymous, incorrect password displays meaningful alert, and forbidden pages explain denial | Pass |
| Minimal auth scope | Routes inspection and browser HTTP checks confirm signup, recovery, account edit and admin return 404; Devise exposes sessions only | Pass |
| Isolated testing and preserved review preview | Test Rails server uses `RAILS_ENV=test` on 3100. Development IDs remain client=2/provider=1, one profile per type before/after. Development Redis sentinel survived all tests; QA removed its sentinel afterward. Preview 3000 `/up` returns 200 | Pass |

Headless Chromium follows Steven's 2026-10-20 policy, which supersedes the ticket's older headed wording.

## Commands and results

Using native tooling with `BUNDLE_PATH="$PWD/tmp/bundle"`:

- `RAILS_ENV=test mise exec -- bin/rails db:prepare db:seed` — success.
- `RAILS_ENV=test mise exec -- bin/rails test test/models/account_test.rb test/integration/authentication_test.rb` — **11 tests, 99 assertions, zero failures/errors/skips**.
- `env -u CI HEALTHIE_QA_BROWSER_WS_FILE=/Users/smh/dev/healthie-platform/tmp/symphony/browser-ws mise exec -- bin/acceptance` — **2 tests passed**, Chromium headless against isolated test app 3100, via operator's local browser host. Endpoint contents were not exposed.
- Development Rails runner before/after: same seeded account IDs/roles and profile counts; cache sentinel `preserved` survived test suite. `curl` review-preview health — HTTP 200.

Nonblocking tooling output: Bundler falls back to a temporary writable home; Devise/Rack emits a deprecated status-name warning for invalid login. Invalid-login behavior remains correct.

## Actual browser screenshots

All screenshots below were captured by Playwright during this run. QA visually inspected both role homes, login, invalid login and denied states; layout is readable and both account identities are correct.

- [Anonymous sign-in](sign-in.png)
- [Invalid credentials](invalid-login.png)
- [Provider home](provider-home.png)
- [Client home](client-home.png)
- [Provider denied client access](provider-denied.png)
- [Client denied provider access](client-denied.png)

## Limits

This ticket intentionally has minimal role home pages. Journals, enrollments and provider membership access are later tickets and are not claimed here. Normal ActiveRecord application paths enforce cross-profile consistency; direct SQL bypassing model validation is outside that claim. Screenshots and this report must remain linked from the PR; browser reports under ignored runtime directories are not the canonical evidence.
