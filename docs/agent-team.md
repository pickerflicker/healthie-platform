# Two-role interview team

Developer is Symphony's parent session and sole application editor. It reads the issue, implements, self-reviews the complete diff, and runs bin/check. Then it spawns exactly one persistent independent QA agent in the same ticket workspace. QA validates acceptance and changed behavior, may write disposable test artifacts, and must not edit application source or spawn agents. Reuse the same QA session for repair cycles. Developer handles repairs. There is no additional planner, coordinator, builder, or reviewer agent.

Maintain Developer Workpad and QA Workpad Linear comments, updated in place. Record role/session identity, base commit, concise findings, commands, outcomes, and outstanding risks. Never record private reasoning or secrets. The issue description owns the only acceptance checklist; only Developer updates it after QA evidence.

Default checks: framework/eager-load check, style check, and relevant fast behavior tests. Setup/UI milestones also require one targeted browser or HTTP smoke. No broad test matrix or coverage quota. QA inspects the actual diff and aggregates findings. High-risk scope requires Steven's clarification before execution.

Start: move one dependency-ready issue to In Progress with ready-for-agent. Pause: move it to Backlog; preserve workspace and workpads. Todo, Backlog, Blocked, and In Review are inactive. Blocked requires a comment explaining evidence, owner, exact unblock condition and safe retry, plus Blocked label. Handoff to In Review; never commit/push/merge/deploy unless that specific issue explicitly authorizes it. Use linear_transition_issue for states, never raw GraphQL mutations. Do not move to Done with unchecked acceptance criteria.
