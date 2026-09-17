# 049 — Drift database bootstrap and migration strategy

**Phase** 04 · Local database  |  **Depends on** [004](../01-orchestration/004-folder-scaffold.md), [005](../01-orchestration/005-dependency-allowlist.md), [018](../01-orchestration/018-network-test.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

`AppDatabase` opens on a write-ahead-logging connection in the application support directory, closes cleanly, survives
hot restart, and carries a `schemaVersion` constant with a per-version `MigrationStrategy` that every later table task
extends instead of inventing.

## Files

- `frontend/lib/core/db/app_database.dart` (new)
- `frontend/lib/core/db/migrations.dart` (new)
- `frontend/README.md` (edit)

## Contract

```dart
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  factory AppDatabase.memory();
  @override
  int get schemaVersion => kSchemaVersion;
  @override
  MigrationStrategy get migration => appMigration(this);
}

const int kSchemaVersion = 1;
MigrationStrategy appMigration(AppDatabase db);
```

## Steps

1. Open the file in the application support directory, WAL enabled, foreign keys on, in a lazy connection.
2. Expose `AppDatabase.memory()` for tests so no suite touches the real file.
3. Write `appMigration` as an ordered list of numbered upgrade steps keyed off `from`/`to`, each step a named function.
4. Gate any step that drops or rewrites a column behind an export prompt raised to the caller, never applied silently.
5. Wire `build_runner`, commit the generated output, and record the generation command in `frontend/README.md`.

## Constraints

- A migration step never back-fills `id`, `createdAt`, `updatedAt`, `updatedByDevice` or `rev`: every table ships those
  columns in the step that creates it, so merge identity exists from the first migration (FE-SEC-08, FE-SEC-09).
- Drift output is committed, regenerated in the same commit as the schema change (FE-CODE-13).

## Definition of done

- [ ] The database opens, closes and reopens across a hot restart with no lock left behind.
- [ ] Upgrading from any released version to head preserves every row; a destructive step refuses to run without the
      export acknowledgement.
- [ ] Adding a schema change without adding a migration step and its test fails the suite.
- [ ] Tests: `frontend/test/core/db/app_database_test.dart` opens an in-memory database and asserts a clean close;
      `migrations_test.dart` walks a seeded version 1 file to head and compares row counts and column sets.

## Out of scope

- Encrypted connections; that is task 064.
