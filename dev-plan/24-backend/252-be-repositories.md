# 252 — Repository base and transactions

**Phase** 24 · The minimal backend  |  **Depends on** [251](251-be-schema-relay.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The repository conventions every table access follows and the transaction helper every multi-table write uses, so a
failure part-way through leaves no partial rows.

## Files

- `backend/src/repositories/base.ts` (new)
- `backend/test/repositories/transaction.test.ts` (new)

## Contract

```ts
withTransaction<T>(fn: (tx: Tx) => Promise<T>): Promise<T>
```

## Steps

1. Parameterised statements only, taking the connection or the ambient transaction, never opening a second one.
2. Map database errors — unique violation, foreign key violation, serialisation failure — to the typed errors of 459 so
   no driver message can reach a client.

## Constraints

- SQL exists nowhere outside `repositories/`, and services depend on repository interfaces so they can be tested
  without a database (BE-STR-04, BE-TEST-02).
- Relay acknowledgement, membership change and purge batches are atomic or they do not happen (BE-DATA-09).

## Definition of done

- [ ] A failure mid-transaction leaves no partial rows and surfaces a typed error, not a driver message.
- [ ] Tests: an integration test with a deliberate mid-transaction failure across two tables, and a test asserting a
      unique violation maps to the expected error code.
