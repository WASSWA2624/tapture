# 04 — Data and migrations

## BE-DATA-01 — Postgres, and nothing exotic

Standard SQL, no vendor features the deployment cannot rely on. Extensions require a task and a documented reason.

## BE-DATA-02 — Client identifiers are authoritative

Records, projects and templates carry the UUIDv7 the device generated. The server never reassigns an identifier and
never invents one for a client-owned entity.

## BE-DATA-03 — The server stores metadata, not content

Accounts, devices, memberships, roles, version vectors, package metadata and audit rows. Project content exists only
as an encrypted package blob, and only until it is purged.

## BE-DATA-04 — Every schema change is a numbered migration

Forward-only, reviewed, and applied in order. No manual change to a deployed database, ever.

## BE-DATA-05 — Destructive migrations need a documented step

Dropping or rewriting a column requires an export step in the runbook and an explicit approval in the pull request.

## BE-DATA-06 — Every transient table carries its retention columns

`created_at`, `expires_at` and acknowledgement state, so the purge job can act without special cases.

## BE-DATA-07 — Constraints in the database, not only in code

Foreign keys, uniqueness and not-null are declared. Application checks are a convenience; the database is the
guarantee.

## BE-DATA-08 — Indexes are justified

Every index names the query it serves in a comment. Unused indexes are removed.

## BE-DATA-09 — Transactions wrap multi-table writes

Relay acknowledgement, membership changes and purge batches are atomic or they do not happen.

## BE-DATA-10 — Timestamps are UTC

`timestamptz` everywhere. Local time exists only at the edge of a rendered report.

## BE-DATA-11 — Migrations are tested

A migration test runs from the previously released schema to head against seeded data, in continuous integration.
