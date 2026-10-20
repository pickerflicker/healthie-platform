# healthie-platform

Clean Rails 8.1.4 / Ruby 3.4.11 interview app. Product brainstorming is next.

```sh
mise trust
mise install
mise exec -- bin/bootstrap
mise exec -- bin/check
mise exec -- bin/preview
# In another terminal:
bin/acceptance
```

Preview: http://127.0.0.1:3000. Stop with Ctrl-C. Set PORT to avoid conflicts.
No database is needed yet. Active Record and persistence are deferred until the product is defined; use shared Postgres when added.

[Linear control plane](https://linear.app/pickerflicker/project/healthie-platform-c6cbdb1032a3). See docs/agent-team.md for the Developer + QA pair and docs/operations.md for Symphony controls.
