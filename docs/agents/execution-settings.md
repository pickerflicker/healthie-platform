# Ticket execution settings

This document owns the ticket format and model/effort/Fast selection policy. The ticket-authoring chat recommends effort while creating an implementation issue; no coordinating agent or classifier runs during dispatch.

## Ticket format

Include this plain-text section in every new implementation ticket:

```text
## Agent execution

Model: gpt-6.1-sol
Reasoning effort: medium
Fast mode: disabled
Reason: Small feature with clear requirements and limited scope.
```

Use exactly one `Agent execution` level-two heading. Field names are case-insensitive; plain `-` or `*` bullets are also accepted. Keep each field on its own line. `Reason` is a human explanation, not launch configuration. Settings elsewhere in the ticket or in comments do not configure the launcher.

- Model is fixed to `gpt-6.1-sol` for Developer and QA. Other model values are rejected.
- Reasoning effort is `low`, `medium` or `high`. Recommend low for mechanical well-specified work, medium for ordinary queries/validations/small features, and high for ambiguous behavior or consequential authorization/data changes. Complexity is a judgment made during ticket authoring, not inferred from ticket length or priority.
- Fast mode is `enabled` or `disabled`. When Steven says "use fast mode" while creating a ticket or batch, record enabled on those tickets. Otherwise record disabled. There is no global interview-mode switch.
- Older tickets with no section, or absent fields, default to medium effort and Fast disabled. Duplicate sections/fields, unsupported values and a conflicting model stop launch with a clear error rather than becoming shell arguments.

## Applying the selection

[bin/codex-for-ticket](../../bin/codex-for-ticket) is the configured Symphony launch command. It verifies the canonical gate owner, workspace, project and active state, makes one bounded read-only Linear lookup, and selects Codex startup options from the section above. It uses inherited `LINEAR_API_KEY` authentication without storing or printing it. Ticket text is data, never shell code. A lookup failure prevents launch; it does not guess ticket-specific settings.

The adapter pins Developer's model and the default QA model/effort, permits one direct QA subagent and prevents recursive delegation. QA inherits the parent service tier and must not override model or effort. Fast disabled explicitly selects Codex's default service tier, overriding a saved global Fast preference. Tracker and retry policies remain in the workflow/runtime. The local permission bridge applies the narrowly scoped Git grant documented in [operations.md](../operations.md#ticket-git-permissions).

Selections are fixed for a worker session and its continuation turns. Edit the ticket before its next worker launch to change them; an existing session is not hot-reconfigured. A new launch re-reads the ticket. This feature does not change ticket readiness or authorize starting another ticket.

The adapter writes a private, non-secret selection receipt to canonical `tmp/symphony/launch-settings/PIC-<number>.json` before replacing itself with the permission bridge and Codex. This records selected settings, not proof of a completed model call or QA result. Developer records the selection and actual role/session identity in its Workpad. See [../agent-team.md](../agent-team.md) for responsibilities and [../operations.md](../operations.md) for validation and rollout commands.
