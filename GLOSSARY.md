# Healthie interview domain

Terms from the provided candidate setup guide. Additional product behavior remains subject to scoping.

## Language

**Provider**:
A practitioner, such as a dietitian, who works with clients.

**Client**:
A person who can be signed up with multiple providers and can post health journal entries.

**Provider credentials**:
Optional degrees, licenses/professional designations and certifications displayed after a provider's name, drawn from a curated 50-choice U.S.-focused catalog (see docs/spec.md). A provider can select several or none. RD and RDN are alternative designations of the same registration credential; selections are profile information, not verification or access rights. DO and OD are distinct, and degrees such as PhD, DNP and PharmD do not imply MD/DO qualifications.

**Plan**:
The basic or premium service level for a particular provider–client relationship. A client's plan can differ between providers.

**Journal entry**:
A client-authored health journal record containing freeform text. In the pre-work baseline it is client-wide and readable by the client’s associated providers.

**Login account**:
The identity used to sign in, holding the person’s name and email. In the pre-work baseline, each account has exactly one role—provider or client—and a matching provider or client profile.

**Provider relationship**:
A client's enrollment with a particular provider, carrying one Basic or Premium plan. Clients can add and remove these relationships; a current relationship grants the provider read access to that client's journal.
