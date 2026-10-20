# Infrastructure plan

1. Generate Rails 8.1.4 on Ruby 3.4.11 in the canonical checkout /Users/smh/dev/healthie-platform. Keep default Hotwire/import maps. Defer persistence and all product features to brainstorming.
2. Add reproducible bootstrap, checks, preview and health smoke; verify locally.
3. Publish the bootstrap to private pickerflicker/healthie-platform so the runner can clone it.
4. Register WORKFLOW.md in the existing canonical Symphony container, normal profile with the explicit two-role override, one issue concurrency, exact Linear project slug, and In Progress + ready-for-agent eligibility.
5. Run PIC-272 to prove clone/bootstrap, independent QA and safe handoff/pause. Leave no product ticket active.
6. Brainstorm the product, then record the accepted scope and create dependency-aware tickets before feature work.

Linear board: https://linear.app/pickerflicker/project/healthie-platform-c6cbdb1032a3
Setup: PIC-271. Infrastructure smoke: PIC-272.

No database server, product schema, authentication, background processing infrastructure, or deployment is required to boot this stateless skeleton. Persistence will use the shared Postgres server and isolated roles/databases. Production promotion follows local acceptance and Steven's approval.
