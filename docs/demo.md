# Fictional manual demo


**Provider: `provider@healthie.example` — Morgan Patel, RDN + LD.**
**Client: `client@healthie.example` — Alex Rivera.**
**Local-only fixture password: `Healthie-demo-2026`** for both and all newly seeded accounts.

All identities, credentials, relationships and journals are **fictional demo data**.
Character names are playful app fixtures, not claims about real people, canonical
qualifications or anyone's health. Emails use reserved example domains. There is
no signup or password recovery. Fictional doctors (House, Grey, Watson, Crusher)
join invented nutrition practitioners; all 30 providers have supported credentials.
The application still permits blank credentials outside this manual baseline.

Append `@healthie.example` to each login below. Counts describe a clean baseline;
manual changes can increase totals or change scenarios.

| Login | Fictional identity / credentials | What to try |
| --- | --- | --- |
| **provider** | **Morgan Patel · RDN + LD** | 38 clients, Basic and Premium, 476 attributed combined entries. Open Sherlock, Frodo or Picard; open Quinn's empty journal. |
| **client** | **Alex Rivera** | Eight providers with credentials and mixed plans; 50 entries. Edit/delete a note (creation needs explicit backend provider_id with eight enrollments), add an available provider (22 remain), then remove that relationship. Morgan stays Basic; Taylor stays Premium in the baseline. |
| second-provider | Taylor Reed · MD | Open shared Alex or Sherlock. Sam's journal URL is denied to Taylor because Sam is enrolled with Morgan only. |
| empty-provider | Casey Park · CNS | No clients or combined feed. |
| empty-client | Jamie Brooks | No providers or journals. |
| unrelated-client | Sam Chen | 12 entries; Premium with Morgan, **not enrolled with Taylor**. Copy a journal URL, sign in as Taylor and revisit it to see denial. |
| sherlock-holmes | Sherlock Holmes | Shared by Morgan, Taylor and Gregory House (MD). Copy each provider's own attributed journal URL and confirm the other provider is denied. As Sherlock, remove Taylor in My providers; Taylor's next direct read is denied while Morgan retains access only to Morgan-attributed entries. |
| quinn-stillwater | Quinn Stillwater | Enrolled with Morgan but zero journals. |
| luna-lovegood | Luna Lovegood | 15 entries attributed to Gregory House on Basic; a copied journal URL is denied to Morgan. |
| pip-willow | Pip Willow | Two entries; Cedar Bloom (RDN + LD) has just this client. |
| poppy-thyme / wren-maple | Poppy Thyme · CNS / Wren Maple · RDN + LD | Two additional empty providers. Pearl Ginger (CNS) has two clients. |

Morgan's feed includes Frodo packing a second apple for Mordor, Sherlock's
meal-prep mystery and Picard promoting water alongside tea. Alex mixes those
playful motifs with ordinary meal planning, walks, sleep and small follow-ups;
several entries have multiple paragraphs. All text is original.

Fixed **90-day inclusive UTC baseline: July 23–October 20, 2026** (reference
`2026-10-20T08:00:00Z`). Older stories, quiet periods, busy days and exact ties
make ordering visible. On a clean load Morgan's newest enrollments are Frodo and Sherlock tied
at October 20 10:00 UTC; the later enrollment ID sorts first. Alex's newest
providers are Meredith Grey and Gregory House tied at 11:00 UTC, also ID descending.
Account/profile timestamps are older and deliberately disagree with enrollments.
Alex retains the two original October 19 18:00 journal ties; October 20 08:00
contains further ties within Alex and across clients in Morgan's feed. Run
`bin/queries` for all four queries and actual IDs; see [query details](queries.md).

### Load and rerun safely

`bin/preview` only rebuilds/restarts Rails; it does **not** load the richer seeds.
After binding this checkout with `bin/preview`, seed the Docker development app:

```sh
/Applications/Docker.app/Contents/Resources/bin/docker compose exec -T web bin/rails db:seed
```

Native alternative after `source script/native_bundle_env`:
`mise exec -- bin/rails db:seed`. Never seed production. Seeds reject environments
other than development/test, create new records through validated Rails APIs and clear
only `healthie:<current environment>` cache **after successful completion**.
They never truncate or delete data. The seed output reports actual runtime and
totals; the [seed summary](queries.md#intentional-dataset) gives exact clean counts.

Unchanged reruns preserve IDs, all record timestamps, ordering, plans, journal text
and password digests. Existing names, passwords, nonempty provider credentials,
relationship plans and journal text edits survive. New accounts receive the
fixture password; rerunning does not reset an edited password.

Reruns **restore missing accounts at their stable email**, blank credentials on
seeded providers, missing baseline relationships (original plan/time), and missing
journal timestamp slots. They do not restore empty states after manual additions
or remove extra relationships/journals. An email edit makes that account a separate
manual identity, so the baseline email is recreated. Journal identity is client +
exact timestamp + ordinal among that timestamp's rows, not mutable text: existing
rows at a baseline timestamp satisfy slots, including occupied slots with edited text. Rows outside those allocated slots remain untouched. Moving/deleting
a baseline timestamp can cause a missing slot to be recreated; edited/moved records
are retained. Deleting one of tied rows recreates the missing slot with a new ID.
This additive repair is intentional, so rerunning is **not a harmless refresh** of
a manually altered access/revocation scenario. Never reset development data to
rehearse; use the disposable test database for seed validation.

The opt-in smoke is separate from regular tests and refuses any target except
empty local `healthie_test`:

```sh
source script/native_bundle_env
mise exec -- bin/reset-test-data healthie_test
RAILS_ENV=test mise exec -- bin/rails runner script/demo_seed_smoke.rb
```

It checks exact counts/scenarios, all-attribute rerun stability, manual sentinels,
edits, missing-state repair and environment-scoped Redis invalidation. It leaves
test validation data behind; normal tests still own their setup and never load seeds.

Clients use **My providers** to add Basic (default) or Premium relationships and remove providers; providers use **My clients** to open current clients' individual journals, or **Combined journal feed** to browse their own attributed entries for current clients. Journals are read-only for providers and ordered by creation time descending, then ID descending. Enrollment grants access only to that provider's attributed journals; removing it revokes subsequent direct and feed access while preserving journals and accounts. Only the client's provider display list uses Redis; see the [cache walkthrough](queries.md#provider-list-cache).

`User.create_account!(name:, email:, password:, role:)` creates an account and matching profile atomically. User owns identity and a required string role; Provider/Client delegate identity. Model validation enforces the matching profile, immutable role/account association and retained required profile. Database constraints enforce required/unique profile foreign keys and valid roles. Direct SQL/bulk writes bypass cross-table model validation and are outside the normal account creation path.



### Provider attribution and historical quota construction (PIC-290)

All 1,000 seed-owned slots now have a provider from their client's baseline pairs. Assignment uses stable pair order and the first pair with capacity in the timestamp's own month; Basic stops at 10 and Premium is unlimited. Existing attributed slots are retained. Existing NULL-provider seed slots receive only provider_id, preserving IDs, edited text, created_at and updated_at. Extra/unrecognized rows outside the established timestamp/ordinal slots and non-seed accounts are never attributed. Slot identity retains its established collision caveat: a manual row occupying a baseline slot is indistinguishable from an edited seed row; reserve those synthetic timestamps for seeds.

New historical rows use Rails' bundled time helper at their intended timestamp and run all model validations; no validation-skipping creates or plan rewrites manufacture capacity. Existing nonempty/manual plans are retained; a missing slot with no eligible monthly capacity fails the transaction for explicit repair. Six Basic seed-only enrollments with Gregory House cover Luna and the final five journal-bearing clients. Totals are now 206 enrollments (109 Basic/97 Premium); providers/clients/journals remain 30/100/1,000. Jamie is the sole unassigned client; Casey/Poppy/Wren remain empty providers. Morgan's clean attributed feed is 476 entries. Unchanged reruns preserve every attribute.

The text-only journal form is deliberately unchanged. It creates with exactly one current enrollment; zero or multiple enrollments return validation errors unless provider_id is supplied through the backend. Alex and other multi-provider clients can still list/edit/delete their history; browser provider selection is deferred.
