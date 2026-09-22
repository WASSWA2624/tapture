# 04 — Local database

Every table the app will ever need, with merge columns from the first migration.

Task 004 (1). One prompt for the completed phase; the atomics it absorbed are listed in [RETIRED.md](../RETIRED.md).

- [x] [004 — Local database: every table, with merge columns from the first migration](004-local-database.md)

## As built

The numbers below are the original atomics; they now live in task 004. Reproduce by implementing 049–064 in order. Each table task **bumps** `kSchemaVersion` and **appends** a named upgrade step. Never edit an earlier step. The tree that must exist at the end:

- `frontend/lib/core/db/app_database.dart` — `@DriftDatabase`, `kSchemaVersion = 12`, `AppDatabase.memory()`, lazy WAL open via `app_database_io.dart` / `app_database_stub.dart`
- `frontend/lib/core/db/migrations.dart` — numbered named steps v1→v12
- `frontend/lib/core/db/columns.dart` — `MergeColumns` (id UUIDv7 text, timestamps, device, rev)
- `frontend/lib/core/db/dao/base_dao.dart` — watch / page / upsert (rev + `updatedAt`) / soft-delete + tombstone hook; `runInTransaction` joins an open write
- Tables under `frontend/lib/core/db/tables/` (several use `part` files so FE-STR-06 holds): `tombstones`, `audit_log`, `device_profile`, `projects`, `context` (+ `context_state`, `context_presets`), `templates`, `template_fields`, `template_rows`, `records`, `record_fields`, `photos`, `attachments`, `captions`, `reference` (+ `reference_rows`), `processing` (+ `processing_results`), `field_evidence`, `duplicates`, `variances`, `meetings` (+ `attendees`, `meeting_actions`), `exports`, `merge` (+ `merge_conflicts`), `sync_state` / version vectors
- Domain ports + fakes: `frontend/lib/core/db/` repositories / `frontend/lib/core/testing/` factories (`aProject`, `aRecord`, `seededDatabase`)
- `runIntegrityCheck` — orphaned fields, missing files, jobs/evidence on gone records, deletes without tombstones, `PRAGMA foreign_key_check`
- `DatabaseEncryption` — HMAC-SHA-256-CTR copy; key only in secure storage (`SecretKey.databaseEncryption`); `AppDatabase.open(encryptionKey:)`

Generation: `dart run build_runner build --delete-conflicting-outputs` from `frontend/`; commit `app_database.g.dart`. Drift 2.31 / sqlite3 2.9.4 so native-asset hooks do not prefix `dart run`.

`valueRaw` / `textRaw` / `transcriptRaw` stay append-only. Soft-delete writes a tombstone; hard row delete and `File.delete` outside the purge job fail the 018 data-safety suite.

Shell and chrome (075 overflow, 073 nav) do not open DAOs from widgets — counts on the status line stay stub providers until later feature tasks replace them.
