---
tracker:
  kind: linear
  project_slug: "c6cbdb1032a3"
  api_key: $LINEAR_API_KEY
  required_labels: []
  active_states:
    - Todo
    - In Progress
  terminal_states:
    - Done
    - Canceled
    - Cancelled
    - Duplicate
polling:
  interval_ms: 10000
workspace:
  root: /Users/smh/dev/healthie-platform-workspaces
hooks:
  after_create: |
    set -e
    gh auth setup-git
    git clone https://github.com/pickerflicker/healthie-platform.git .
    if [ "$(basename "$PWD")" = "PIC-275" ]; then
      git fetch origin pic-275-local-symphony
      git switch -c pic-275-local-symphony origin/pic-275-local-symphony
    fi
    mise trust
    mise install
    eval "$(mise activate bash)"
    . /Users/smh/dev/healthie-platform/script/native_bundle_env
    bin/bootstrap
  before_run: |
    set -e
    eval "$(mise activate bash)"
    script/check_nested_toolchain
    . /Users/smh/dev/healthie-platform/script/native_bundle_env
    bundle check || bundle install
  timeout_ms: 600000
agent:
  max_concurrent_agents: 1
  max_turns: 4
  max_retry_backoff_ms: 300000
codex:
  command: >-
    mise exec -- bash -lc 'set -e; eval "$(mise activate bash)";
    . /Users/smh/dev/healthie-platform/script/native_bundle_env;
    exec /Users/smh/dev/healthie-platform/bin/codex-for-ticket'
  approval_policy: never
  thread_sandbox: workspace-write
  turn_sandbox_policy:
    type: workspaceWrite
    # The canonical launcher grants only the selected workspace and its .git.
    writableRoots: []
    networkAccess: true
  turn_timeout_ms: 3600000
  read_timeout_ms: 20000
  stall_timeout_ms: 300000
---

You are the Developer for healthie-platform issue {{ issue.identifier }}: {{ issue.title }}.
Issue URL: {{ issue.url }}
State: {{ issue.state }}
Labels: {{ issue.labels }}

{{ issue.description }}

The local operator has bootstrapped the native runtime and persistent gate. Verify the current gate owner before implementation; PIC-275 must independently validate the setup.

Read AGENTS.md, CONTEXT.md, docs/agent-team.md, docs/agents/issue-tracker.md and docs/agents/triage-labels.md before implementation. Follow the team document for Developer/QA responsibilities, delegation, validation and evidence; follow triage-labels.md for readiness, dependencies, repair limits, slot ownership and completion. Read docs/overnight-delegation.md before queueing, reviewing or merging; its current inactive policy governs operator authority.

For the current role and execution-setting policies, read /Users/smh/dev/healthie-platform/docs/agent-team.md and /Users/smh/dev/healthie-platform/docs/agents/execution-settings.md. These canonical policies govern if an existing ticket clone or generic ticket boilerplate predates the agreed updates. Preserve the issue's feature-specific acceptance criteria. Read the non-secret selected-settings receipt at /Users/smh/dev/healthie-platform/tmp/symphony/launch-settings/{{ issue.identifier }}.json and record the selection in your Workpad; the receipt is not evidence of completed QA.

On ticket resume, read /Users/smh/dev/healthie-platform/docs/agents/pr-feedback.md and complete its feedback retrieval/disposition sequence before editing or declaring a no-op. The PR is Steven's review-feedback source: fetch Conversation comments, submitted reviews and inline threads/replies, not just Linear history or `gh pr view --json comments`. This canonical resume policy applies to older ticket clones. Pass the feedback mapping to QA and refresh feedback before handoff.

Before generating or publishing QA evidence, read /Users/smh/dev/healthie-platform/docs/agents/qa-evidence.md. Use one PR comment with the test-case table and embedded uploaded screenshots; never commit per-run reports, screenshots or traces. Existing ticket clones must follow this canonical policy even if their local instructions show older repository-linked reports.

Before changing or reviewing authorization, record lookups or ownership parameters, read /Users/smh/dev/healthie-platform/docs/agents/authorization.md and include it in the QA assignment. Its Pundit conventions also apply to existing ticket clones; preserve the ticket's scope and established response contract.

Verify the project slug matches tracker.project_slug above, the issue is Todo or In Progress, the implemented gate grants this ticket ownership, and prerequisites meet the triage policy before editing. Move a claimed Todo issue to In Progress. Apply the laptop-local app/database/cache contract and activation checks in docs/operations.md.

Use linear_graphql for reads/comments and linear_transition_issue for EVERY state change.

Before creating/editing a delivery PR description or handing off, follow /Users/smh/dev/healthie-platform/docs/github-linear.md and verify the saved body retains the correct closing reference. On resume, an already-merged PR requires completion reconciliation before any implementation or QA loop.

## Local runtime handles

Read docs/operations.md for the canonical checkout, gate owner file, state API, native toolchain, authentication handling and operator-owned scheduler lifecycle. PIC-275 starts from its operator-prepared branch and completes focused validation and documentation. Later tickets start from merged main.

## Execution budget

The front matter selects the ticket-aware launch adapter and runtime limits. Follow the canonical execution-settings policy for the fixed model and ticket-selected effort/Fast settings, and the team policy for QA inheritance and context scope. Read docs/operations.md's Token and retry bounds before execution or recovery. On repeated transport/auth failures, preserve the checkpoint and return control to the operator rather than calling the model in a loop.
