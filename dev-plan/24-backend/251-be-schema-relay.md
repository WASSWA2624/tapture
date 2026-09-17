# 251 — Schema: relay packages, acknowledgements, version vectors and audit

**Phase** 24 · The minimal backend  |  **Depends on** [250](250-be-schema-identity.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The remaining two migrations: transient relay metadata with its retention columns present from the first day, and the
append-only audit tables that no code path may update or delete.

## Files

- `backend/migrations/003_relay.sql` (new)
- `backend/migrations/004_audit.sql` (new)
- `backend/test/repositories/relay_schema.test.ts` (new)
- `backend/test/repositories/audit_schema.test.ts` (new)

## Steps

1. `relay_packages` carries identifier, project, author device, byte size, created, expires and storage reference, and
   nothing else — no content column, no field drawn from a project.
2. `relay_acknowledgements` records device, package and time, unique per pair; `relay_vectors` records project, device
   and counter, one row per project and device rather than per package.
3. `audit_events` and `security_events` record actor, target, action, outcome and time, with update and delete
   forbidden by constraint or trigger.

## Constraints

- Relay is the backend's one **optional** capability (§72): a deployment that never enables it is complete.
- The package metadata list is closed by BE-RELAY-06; a further column needs its own task and a written justification.
  Version vectors carry counters and device identifiers only, never a record identifier or a field name.
- Every transient table carries `created_at`, `expires_at` and acknowledgement state so purge needs no special case
  (BE-DATA-06).

## Definition of done

- [ ] Every transient row carries created and expiry columns, and the purge query needs no exception for any of them.
- [ ] No column on a package, acknowledgement or vector row can hold project content.
- [ ] Tests: integration tests for package insert, acknowledgement and the expiry query; a test proving an audit row
      cannot be updated or deleted.
