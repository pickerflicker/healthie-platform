# healthie-platform

Rails interview skeleton. Product scope awaits brainstorming. Read docs/agent-team.md and docs/implementation-plan.md.

Project overrides: exactly two roles, Developer (parent) and one independent QA subagent; no coordinator or reviewer agent. Normal Symphony registration carries this lean policy. One issue at a time, only In Progress + ready-for-agent. No coverage target; focused framework checks and relevant behavioral checks. QA never edits application source. No recursive delegation.

Commands: bin/bootstrap, bin/check, bin/preview, bin/acceptance. Persistence is deliberately deferred. When introduced, use shared Postgres 10.0.0.168:5432 with separate project/environment roles and databases; no local Postgres service. Production deploy/reset/migration commands are deferred until persistence and deployment are designed. Never improvise them.

Shared context on Steven's Mac: /Users/smh/second_brain/03_resources/personal_app_development_flow.md and home_lab_infrastructure.md. Workers must rely on this repository's explicit operating rules when those Mac paths are unavailable. No production access, database provisioning, merge, or deployment from implementation workers. Use guarded Linear state transitions. Preserve dirty work. Stop in In Review for Steven.
