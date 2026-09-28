# 05 — Security

## BE-SEC-01 — HTTPS only

No plaintext listener, in any environment that holds real data. HSTS on. Certificates are the deployment's
responsibility and are documented in the runbook.

## BE-SEC-02 — Passwords are hashed with a memory-hard function

Argon2id with documented parameters. Never a fast hash, never a home-made scheme, never reversible storage.

## BE-SEC-03 — Tokens are short-lived and bound to a device

A short access token plus a rotating refresh token tied to an enrolled device identifier. Refresh reuse invalidates
the family and is logged as a security event.

## BE-SEC-04 — Secrets come from the environment or a secret store

Never from source, never from the database, never returned by any endpoint, never written to a log. A secret in a
diff fails the build.

## BE-SEC-05 — Validate before you trust

Every input is schema-validated. Every SQL statement is parameterised. No string concatenation into a query, a
command or a file path, ever.

## BE-SEC-06 — Authorisation is checked in the service, not the route

One permission function per capability, unit-tested against a role matrix, so a new route cannot forget the check.

## BE-SEC-07 — Rate limit and lock out

Authentication endpoints are rate limited per address and per account, with lockout and a logged security event.

## BE-SEC-08 — Uploads are opaque and bounded

Relay packages are size-limited, stored as blobs and never unpacked, parsed or inspected server-side.

## BE-SEC-09 — Least privilege everywhere

The database user cannot create schemas. The container runs as a non-root user. The AI key has only the scope it
needs.

## BE-SEC-10 — Dependencies are audited

An advisory check runs in the gate. A new dependency needs a task, a pinned version and a licence note.

## BE-SEC-11 — Security-relevant changes get a second reader

Anything touching authentication, authorisation, relay access or key custody requires an explicit review from someone
other than the author.
