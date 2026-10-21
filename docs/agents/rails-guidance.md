# Rails skills for Healthie

Developer and QA use the project-local 37signals-inspired guidance below when building, repairing or reviewing Rails features. Read this policy before the imported skills. Healthie's accepted requirements, ADRs, authorization and team policies govern whenever upstream guidance differs. Apply guidance to the current change; importing a skill does not authorize unrelated refactoring or new infrastructure.

## What to read

| Work | Required guidance |
| --- | --- |
| Rails feature implementation, repair or review | [Core Rails](../../.agents/skills/rails-best-practices-core/SKILL.md) |
| Writing tests or reviewing test quality | [Testing](../../.agents/skills/rails-testing/SKILL.md) |
| Schema, index, constraint or backfill changes | [Migrations](../../.agents/skills/rails-migrations/SKILL.md) |
| Authentication, authorization, ownership boundaries or security-sensitive endpoints | [Security](../../.agents/skills/rails-security-multitenancy/SKILL.md) and [Healthie's Pundit conventions](authorization.md) |

The topic files are explicit reference reads for these branches; they need not be auto-invoked as skills. Load only relevant sections. Include the applicable guidance and these overrides in the existing QA assignment. Developer's existing self-review and the single independent QA review apply them; the skills add no reviewer or role.

## Healthie overrides

- **Research dependency versions before selecting them.** Follow the canonical [dependency-version policy](../../AGENTS.md#dependency-versions) when adding dependencies or choosing version constraints, including its release checks, compatibility evidence and explanation for older-major choices.
- **Pundit remains the authorization system.** Keep policies, `policy_scope`, action-specific `authorize` calls and verification hooks under [authorization.md](authorization.md). Scoped lookups and ownership checks support that system. The upstream model-predicate/controller-guard approach does not replace or duplicate Pundit.
- **Devise remains the authentication system.** Keep `current_user` and the accepted User role plus Client/Provider profiles. Retain the seeded email/password sign-in flow. Upstream magic-link authentication, Identity/Session/account models and `Current` conventions are references for other architectures, not a migration plan for this app.
- **Redis remains the cache system.** Preserve the accepted per-client provider-list cache, invalidation after committed changes and development/test isolation. Database-backed Solid Cache/Queue/Cable examples do not authorize replacing Redis or adding services.
- **PostgreSQL constraints remain required.** Preserve agreed foreign keys, null constraints, unique indexes and domain CHECK constraints alongside useful user-facing model validation. Upstream examples of removing foreign keys do not apply. Scale migration precautions to the actual local PostgreSQL data and change; avoid unnecessary adapters, sharding or deployment machinery.
- **Ordering belongs at query call sites.** Follow [ADR 0003](../adr/0003-explicit-query-ordering.md) when changing associations, list queries or query examples. Keep associations free of presentation ordering/preloads; use explicit `.order(...)` and the needed preloads in each query builder. Preserve business sort keys and tie-breakers, and review/test queries for inherited-order regressions.
- **Choose loading by the consumer.** For scalar read-only display/cache data, prefer a needed-column SQL projection (`joins` where needed, then `pluck` and tuple-to-hash mapping). For consumers needing model methods or association traversal, load model objects and explicitly preload accessed associations. `joins` alone does not populate associations, but `joins + pluck` needs none to return selected values. Preserve an adequate projection during ordering changes; generic eager-loading wording is not a reason to introduce full records and extra queries. Interpret N+1 requirements as bounded query behavior, verify with query caching bypassed when appropriate, and record a concrete reason for any departure from this preference.
- **The accepted domain and scope remain authoritative.** Keep explicit journal ordering and the existing role/profile model. State records, concerns, tenant numbering and other upstream patterns need an actual requirement; they are not a checklist of abstractions to add. Verify subtle Rails behavior against the installed version before declaring an option redundant or required.
- **The current team and testing contract remains authoritative.** Follow [agent-team.md](../agent-team.md): minimal useful behavioral tests, optional TDD, one self-review, one independent QA, and browser checks when browser behavior changes. Every automated test owns its data or explicitly selected test fixtures; demo seeds are for manual browsing only. Preserve Playwright database/cache isolation. Upstream preferences for fixtures, test ordering or output wording do not require wholesale test rewrites or replace the canonical workpads/report format. [QA evidence](qa-evidence.md) stays on the PR, with generated artifacts outside Git.

## Source and updates

These are **unofficial community skills**, not published or endorsed by 37signals. The four skill files are copied without modification from [marckohlbrugge/37signals-skills](https://github.com/marckohlbrugge/37signals-skills/tree/c58e7d51e322442cd33674e17d074d093ed24f83/skills), commit `c58e7d51e322442cd33674e17d074d093ed24f83`, installed 2026-10-20. They are scoped to this repository, not installed globally. The source describes much of its content as LLM-generated; verify framework claims against official Rails documentation, installed source or a focused executable check.

Review upstream changes and these overrides before updating the pinned copies. Preserve attribution: upstream analysis, commentary and skills are MIT-licensed; code examples extracted from Fizzy carry the upstream O'Saasy license notice. See the [upstream license statement](https://github.com/marckohlbrugge/37signals-skills/blob/c58e7d51e322442cd33674e17d074d093ed24f83/README.md#license) before copying application code examples.

The canonical policy is `/Users/smh/dev/healthie-platform/docs/agents/rails-guidance.md`. Older Symphony ticket checkouts read this policy and its linked canonical skill files before Rails feature work; they need not copy or install another version to follow it.
