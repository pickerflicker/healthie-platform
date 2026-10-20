# Home-Lab Deployment

Status: planned, not deployed. Product scope and production acceptance are pending brainstorming. This document adapts /Users/smh/second_brain/03_resources/templates/web_app_deployment.md; follow the shared personal_app_development_flow.md for promotion.

## Project workflow map

Bootstrap: bin/bootstrap. Preview: bin/preview at http://127.0.0.1:3000. Validation: bin/check. Acceptance: bin/acceptance. Teardown: Ctrl-C in the preview terminal. Persistence/reset/seed/migration commands: deferred because the skeleton has no database. Production deploy: not implemented; do not deploy using ad hoc commands.

## Planned production handles

App/slug: healthie-platform. Intended URL: https://healthie-platform.derpylabs.dev. Host: Webapp VM 10.0.0.127. Checkout: /opt/healthie-platform/app. Host-managed secrets: /opt/healthie-platform/env. Intended Compose file: infra/compose.home-lab.yml (not created yet). Container port: 3000. Use Docker network proxy and Traefik labels with exact Host(`healthie-platform.derpylabs.dev`) routing.

## Privacy boundary

Default public route requires host-level authentication on every path including /up until Steven chooses a public-access model. No production secrets belong in implementation workspaces, Git, Linear or logs.

## Persistence and migration contract

None in the skeleton. If introduced, use shared PostgreSQL 10.0.0.168:5432; production database/role healthie_platform_production; development database/role healthie_platform_development; disposable validation names healthie_platform_validation_{workspace_id}. Separate credentials with no development privileges on production. Deterministic synthetic seeds only. No project Postgres container. Add guarded reset/migration validation before persistence is accepted. Production migrations must run once with framework/advisory locking in an explicit deployment step; abort promotion on failure. Never migrate on push or ordinary startup.

## Route setup and initial deploy

After approved local acceptance and production plan, configure the route with /Users/smh/.codex/scripts/configure-derpylabs-subdomain.sh healthie-platform. It reads Keychain credentials without printing them. Use explicit proxied nab9-tunnel DNS and ingress through Traefik. Provision the host-auth policy, repo-scoped read-only deploy key, immutable image, guarded deploy command and rollback before promotion. Deploy only the approved clean default-branch commit from the canonical checkout.

## Verification and evidence

Record container state, commit, host-auth denial, authenticated /up response at the VM, Traefik origin SNI and public Cloudflare URL. Add exact commands once Compose and authentication exist. Local /up success is not production evidence. Infra Watch lifecycle stays Planned until production is verified; no live monitoring activation during skeleton work.
