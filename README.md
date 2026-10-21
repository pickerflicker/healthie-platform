# healthie-platform

Rails interview app for provider–client relationships, Basic/Premium plans, and
client journals. Rails, PostgreSQL, and Redis run locally in Docker Compose;
[mise](mise.toml) pins Ruby and Node for local tooling.

## Setup (macOS)

Install and open Docker Desktop, install mise, and get access to the private repo.
Then run:

```sh
mkdir -p ~/dev
git clone git@github.com:pickerflicker/healthie-platform.git ~/dev/healthie-platform
cd ~/dev/healthie-platform

mise trust
mise install
mise exec -- npm ci
mise exec -- npm run build:css
bin/stack up
docker compose exec -T web bin/rails db:seed
```

Open **http://127.0.0.1:3000**. Sign in as `provider@healthie.example` or
`client@healthie.example`, both with password `Healthie-demo-2026`. These are
fictional, local-only demo accounts. See [demo scenarios and reseeding](docs/demo.md).

CSS builds on the host because Compose mounts this checkout. Running the app
does not require native Ruby gems; [native development and tests](docs/operations.md#native-development-setup) are optional next steps.

## Everyday commands

```sh
bin/stack up                  # Start services and prepare databases
bin/stack status              # Check services
bin/stack logs                # View logs
bin/stack stop                # Stop; keep database data
mise exec -- bin/preview       # Rebuild CSS and the web container after changes
bin/queries                   # Show the four interview queries, SQL, and plans
```

See [queries and caching](docs/queries.md), [check commands](docs/operations.md#check-commands),
and [frontend development](docs/frontend.md) for details.

## How agents work here

[WORKFLOW.md](WORKFLOW.md) is Symphony's execution configuration and per-ticket
Developer prompt. It tells Symphony which Linear project to poll, where to create
ticket checkouts, how to prepare them, and how to launch Codex with runtime limits.
It is needed for automated ticket execution; Rails itself does not use it.

Symphony clones this repository into a separate checkout for each ticket. The
Developer agent edits code and tests on a feature branch, then one independent
QA agent validates the change in that checkout. QA may add tests and evidence;
the Developer owns application-source changes. Agents follow [AGENTS.md](AGENTS.md)
and the [Developer/QA policy](docs/agent-team.md), publish a PR with one QA report,
and stop at In Review for Steven's review and merge. One ticket holds the project
slot through human review; the local preview and development data are preserved.

Agent execution requires additional credentials and runtime setup, including
machine-specific paths in `WORKFLOW.md`; see [operations](docs/operations.md).
Product decisions live in [CONTEXT.md](CONTEXT.md), [the spec](docs/spec.md),
and [ADRs](docs/adr/). Work is tracked in the
[Linear project](https://linear.app/pickerflicker/project/healthie-platform-c6cbdb1032a3).
