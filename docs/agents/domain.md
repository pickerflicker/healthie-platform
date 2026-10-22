# Domain documentation

This is a single-context Rails project.

Before modeling, writing a spec, creating tickets, implementing or reviewing changes:

1. Read root `GLOSSARY.md` and use its domain vocabulary.
2. Read the relevant decisions under `docs/adr/`, especially the explicit User role/profile model and provider-specific journal visibility and limits (ADR 0005, superseding ADR 0002).
3. Read `CONTEXT.md` for the accepted interview-specific product and operating rules. Read `docs/interview-brief.md` when distinguishing employer requirements from Steven's additional scope.

Record new settled terms in the glossary and consequential architectural tradeoffs as concise ADRs. Keep implementation details out of the glossary. If a proposal conflicts with an accepted ADR, surface the conflict rather than silently replacing the decision.

Keep the context, glossary, ADRs and ensuing specs in this repository under version control. Runtime or deployment claims require current evidence; design notes do not prove implementation.
