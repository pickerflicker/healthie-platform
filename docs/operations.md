# Operations

Canonical checkout: /Users/smh/dev/healthie-platform.
Remote: https://github.com/pickerflicker/healthie-platform (private).
Linear project slug: c6cbdb1032a3.
Runner: SSH alias symphony-runner (10.0.0.180), existing canonical symphony container.
Registration: /opt/symphony-runtime/projects/active/healthie-platform.env.
Workflow: /opt/symphony-runtime/workflows/healthie-platform.md, byte-for-byte WORKFLOW.md.
State API on runner: http://127.0.0.1:4010/api/v1/state.
Workspace: /srv/symphony-workspaces/healthie-platform.
Logs: /srv/symphony-logs/healthie-platform.
Project toolchain: /opt/data/home/.local/healthie-toolchain/ruby-3.4.11 (persistent runner home).
Profile: MODE=normal, explicit Developer + QA policy override. The shared fast profile forbids subagents and is intentionally not selected.

Start one ready issue with ready-for-agent + In Progress. Move to Backlog to pause; preserve its workspace. Worker hands off to In Review. Product issues await brainstorming. Inspect state with:

```sh
ssh symphony-runner 'curl -fsS http://127.0.0.1:4010/api/v1/state'
```

Do not restart the shared container to change this project: the supervisor discovers registration/workflow changes. Do not alter unrelated registrations. App preview binds 127.0.0.1. No production deployment or public route is provisioned at the skeleton stage.
