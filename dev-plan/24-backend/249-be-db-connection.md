# 249 — Database connection, pooling and migrations

**Phase** 24 · The minimal backend  |  **Depends on** [246](246-be-config.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The Postgres pool with timeouts, health reporting and a graceful drain, plus the numbered forward-only migration runner
and the upgrade test that runs from the previously released schema.

## Files

- `backend/src/db/pool.ts` (new)
- `backend/src/db/migrate.ts` (new)
- `backend/migrations/` (new)
- `backend/test/db/pool.test.ts` (new)
- `backend/test/db/migrate.test.ts` (new)

## Steps

1. Size the pool and its connection and statement timeouts from configuration; expose a status the readiness route can
   read.
2. Drain on shutdown: stop handing out connections, let in-flight transactions finish, close the pool, exit.
3. Apply migrations in filename order, each inside a transaction, recording every applied file in a schema history
   table; refuse to run out of order or to re-run a changed file.
4. Expose migration as an explicit command or job behind a flag, never as an implicit step of every boot.

## Constraints

- Migrations are forward-only and never edited after release; a destructive one needs the runbook export step and an
  explicit approval (BE-DATA-04, BE-DATA-05).
- The database user cannot create schemas (BE-SEC-09).

## Definition of done

- [ ] Shutdown drains the pool without dropping an in-flight transaction.
- [ ] Migrations apply in order, record themselves, and never run implicitly at boot.
- [ ] Upgrading from the last released schema preserves every row.
- [ ] Tests: integration tests against an ephemeral database migrated from scratch for pool behaviour and drain
      (BE-TEST-03); a migration test from the previous release schema with seeded data (BE-TEST-09).
