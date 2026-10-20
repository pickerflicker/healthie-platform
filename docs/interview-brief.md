# Healthie pairing interview brief

Source: candidate setup guide pasted by Steven in this chat. Treat the guide as the interview requirements; recommendations are not additional company requirements.

## Session format

Two one-hour pairing sessions. Each has approximately 0–10 minutes for a screen-shared setup walkthrough, 10–45 minutes of collaborative feature work driven by the candidate, and 45–60 minutes discussing tradeoffs and production considerations. Screen sharing lasts the whole session.

AI tools are permitted and encouraged. Evaluation includes approaching the problem before using tools, understanding and defending generated code, troubleshooting unexpected behavior, and communicating thinking.

## Provided Session 1 pre-work

Set up a Rails application, or standalone migrations/models foundation, for providers, clients and health journal entries. A finished product is not required.

- Providers and clients each have a name and email address.
- Providers have many clients; a client may have multiple providers.
- Each provider–client relationship has one plan: basic or premium.
- Journal entries belong to clients and contain freeform text.
- Include working ActiveRecord queries for a provider's clients, a client's providers, a client's journal entries ordered by date, and journal entries across all clients of a provider ordered by date.

The live session will discuss schema design/tradeoffs and add an interviewer-selected query, validation, or small model extension. Large-dataset approaches may be discussed. Those are live topics, not instructions to anticipate and pre-implement a particular extension.

## Missing information and unresolved scope

Steven confirmed Session 2 is frontend-only and he will not interview for it. Scope this project to Session 1. The interview is not scheduled; Steven wants pre-work finished as soon as possible and will schedule afterward.

The required foundation is ActiveRecord models/migrations and the four queries. A CRUD browser UI, Redis caching, authentication, deployment, and scale infrastructure are not mandated by the provided Session 1 text. Steven independently requested local Compose infrastructure, Redis query caching and browser QA; keep these separate from employer requirements and choose scope deliberately.

Steven selected journal creation time with ID as the deterministic tie-breaker, retaining the proposed newest-first direction (created_at DESC, id DESC). This is a project decision rather than an ordering direction specified by Healthie. Other unspecified details, such as email uniqueness, should be recorded as assumptions rather than attributed to Healthie. Product modeling and pre-work scope remain under discussion.
