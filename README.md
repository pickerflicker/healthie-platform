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

Sign in with `provider@healthie.example` (Morgan Patel) or `client@healthie.example` (Alex Rivera). Both use the local fixture password `Healthie-demo-2026`. Seeds restore those intentional identities/passwords without duplicating accounts; they do not remove unrelated records. No signup or password recovery is exposed. Role homes are intentionally minimal for this slice.

`User.create_account!(name:, email:, password:, role:)` creates an account and matching profile atomically. User owns identity and a required string role; Provider/Client delegate identity. Model validation enforces the matching profile, immutable role/account association and retained required profile. Database constraints enforce required/unique profile foreign keys and valid roles. Direct SQL/bulk writes bypass cross-table model validation and are outside the normal account creation path.

[Linear project](https://linear.app/pickerflicker/project/healthie-platform-c6cbdb1032a3). See [operations](docs/operations.md) and [Developer/QA workflow](docs/agent-team.md).
