# Optional provider credentials as a constrained array

Accepted 2026-10-20 for PIC-285. Store the small fixed set of professional abbreviations on Provider as a non-null PostgreSQL string array with an empty default. Validate and normalize at the profile boundary and enforce supported values with a database CHECK. Use the supported-list order for storage/display and treat the checkbox empty sentinel as clearing, with duplicate selections removed. Reject malformed or unsupported input rather than silently storing it.

This keeps an optional display field small and explainable, without a join table or generic credentialing subsystem. The tradeoff is PostgreSQL-specific array/constraint behavior and a migration plus code change when the supported set changes. A separate model would become appropriate if credentials later need jurisdiction, expiry, license numbers or verification; none is currently authorized.

The provider edits its own credentials through Devise/Pundit and a server-derived profile. Names remain User identity data. Credentials never grant permissions or affect enrollment plans. Scalar client-list rows include the array through joins/pluck; a new cache-key version bypasses legacy payloads, and committed changes invalidate every enrolled client's list.
