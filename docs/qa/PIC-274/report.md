# PIC-274 independent QA evidence

Result: PASS after one Developer repair. QA run on 2026-10-20; exact tested commit is recorded in the canonical PR QA comment after final commit verification.

- Docker Desktop Compose runs Rails/Ruby, PostgreSQL 17 and Redis 7 locally. All three services report healthy; preview is http://127.0.0.1:3000/up and remains running.
- `mise exec -- bin/bootstrap` passed against the laptop services. `mise exec -- bin/check` passed: eager loading, style, and one focused integration test with five assertions.
- `env -u CI mise exec -- bin/acceptance` passed in headed Chromium against the isolated test Rails server on port 3100. The real [browser screenshot](health.png) shows Rails' green health response. The test asserts HTTP 200 and green body; the screenshot alone is not the assertion.
- Disposable SQL sentinel rows were separately written in `healthie_development` and `healthie_test`. Dropping the test sentinel left development data intact.
- Separate-process cache writes reached Redis in the development/test namespaces. Clearing the test cache preserved the development value. The integration regression test verifies the actual Redis key under `healthie:test` and absence under `healthie:development`.
- A project-scoped `docker compose stop` followed by `docker compose start --wait` preserved the development database sentinel and Redis value. All services returned healthy and the preview remained reachable. QA sentinel data was removed afterward.
- `bin/reset-test-data healthie_development` refused the target. `bin/reset-test-data healthie_test` rebuilt only the disposable local test database.

QA found the first cache configuration was applied after Rails had initialized MemoryStore/NullStore. Developer moved configuration into both environment files; QA then reran the real Redis isolation checks and headed browser smoke successfully.

This infrastructure ticket has no domain records or application CRUD screens yet. Canonical report and tested commit live in the PR; this directory preserves the actual headed capture and validation record.
