# 050 — Shared columns, DAO base and transaction helper

**Phase** 04 · Local database  |  **Depends on** [021](../02-foundation/021-result-and-failures.md), [023](../02-foundation/023-clock-service.md), [049](049-drift-setup.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The identity, change-tracking and write plumbing every table task reuses: one mixin supplying the shared columns, one
base DAO supplying typed reads, watched lists and `Result` returns, and one transaction wrapper so multi-table writes
apply whole or not at all. After this, a table task is a schema plus a thin DAO.

## Files

- `frontend/lib/core/db/columns.dart` (new)
- `frontend/lib/core/db/base_dao.dart` (new)
- `frontend/lib/core/db/transactions.dart` (new)

## Contract

```dart
mixin MergeColumns on Table {
  TextColumn get id => text().clientDefault(uuidV7)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get updatedByDevice => text()();
  IntColumn get rev => integer().withDefault(const Constant(1))();
}

abstract class BaseDao<T extends Table, R> {
  Stream<List<R>> watchAll();
  Future<Result<R?>> getById(String id);
  Future<Result<R>> upsert(Insertable<R> row);      // bumps rev and updatedAt
  Future<Result<void>> softDelete(String id, {required String reason});
  Future<Result<List<R>>> page({required int offset, required int limit});
}

Future<Result<T>> runInTransaction<T>(AppDatabase db, Future<T> Function() body);
```

## Steps

1. Supply a write helper that stamps `updatedAt` from the clock service, `updatedByDevice` from device identity and
   `rev = rev + 1` on every update, so no DAO does it by hand.
2. Generate `id` as UUIDv7 text through the uuid service; never an autoincrement integer.
3. Map `SqliteException`, uniqueness violations and busy timeouts to sealed `StorageFailure` variants with a recovery
   action; no Drift exception escapes a DAO.
4. Give `softDelete` a tombstone hook that task 051 fills; the base never hard-deletes a row.
5. Make `runInTransaction` safe when already inside a transaction — join it, never open a second.

## Constraints

- Public DAO and helper methods return `Result<T>`; a raw exception never crosses out of `core/db/` (FE-CODE-06).
- Collections are exposed as watched streams, single rows as futures (FE-STATE-08).

## Definition of done

- [ ] No table declares `id`, `createdAt`, `updatedAt`, `updatedByDevice` or `rev` by hand.
- [ ] Every update through the base DAO increments `rev` and advances `updatedAt`; a write that skips the helper is
      visible as an unchanged `rev`.
- [ ] A failure part-way through a multi-table write leaves no partial rows, whether the call opened the transaction or
      joined one.
- [ ] Tests: `frontend/test/core/db/columns_test.dart` asserts the rev-and-timestamp bump on repeated writes;
      `base_dao_test.dart` covers watch, get, upsert, paging and failure mapping against an in-memory database;
      `transactions_test.dart` asserts full rollback on a mid-transaction throw and on a nested call.
