# Client-wide journals shared with current providers

**Superseded by [ADR 0005](0005-provider-specific-journal-limits.md), PIC-290 (2026-10-22).** The following records the original pre-work decision.

Journal entries belong to Client and are readable by that client and its currently associated providers. Removing an enrollment revokes provider access while preserving entries; entries do not belong to a provider or enrollment. Steven selected this interpretation to match the client-owned journal and provider-wide queries in the interview brief, which does not itself specify privacy semantics. Provider-specific sharing is deferred. Enforce access through Pundit and current database relationships, independently of the cached client provider list.
