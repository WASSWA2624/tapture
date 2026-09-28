# 09 — Testing

## BE-TEST-01 — Tests ship with the change

No task closes without them. The gate runs them all.

## BE-TEST-02 — What each layer owes

Domain: unit tests, no database. Services: unit tests against repository fakes. Repositories: integration tests
against a real Postgres. Routes: contract tests against the OpenAPI document.

## BE-TEST-03 — A real database for integration tests

Ephemeral, migrated from scratch, seeded by factories. No shared development database, no test that depends on
leftover rows.

## BE-TEST-04 — The permission matrix is a test

Every role against every capability, asserted in a table. A new role or capability extends the table.

## BE-TEST-05 — Retention is tested with a controlled clock

Time is injected. Tests advance it and assert that packages purge on acknowledgement and on expiry.

## BE-TEST-06 — No test reaches a real provider

The AI proxy is tested against a fake provider that can succeed, fail, time out and return malformed output.

## BE-TEST-07 — Idempotency is tested

Replaying a relay push and an acknowledgement changes nothing the second time.

## BE-TEST-08 — Security paths are tested as first-class behaviour

Expired token, reused refresh token, wrong project, non-member device, oversized upload, malformed input. Each has a
test asserting the exact status and error code.

## BE-TEST-09 — Migrations are tested from the last release

Not only from empty. The upgrade path is the one that breaks.

## BE-TEST-10 — Logs are tested for leaks

A test drives representative requests and asserts no forbidden pattern appears in the output.
