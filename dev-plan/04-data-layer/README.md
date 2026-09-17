# 04 — Local database

Every table, one task each, with the merge columns present from the first migration.

Tasks 049–064 (16). Each file is a standalone implementation prompt.

- [x] [049 — Drift database bootstrap and migration strategy](049-drift-setup.md)
- [x] [050 — Shared columns, DAO base and transaction helper](050-column-mixins.md)
- [x] [051 — Tombstones, audit log and device profile tables](051-tombstones-table.md)
- [x] [052 — Projects and context tables](052-projects-table.md)
- [x] [053 — Templates, template fields and template rows tables](053-templates-table.md)
- [x] [054 — Records and record fields tables](054-records-table.md)
- [x] [055 — Photos, attachments and captions tables](055-photos-table.md)
- [x] [056 — Reference dataset tables](056-reference-tables.md)
- [x] [057 — Processing jobs, results and field evidence tables](057-jobs-table.md)
- [x] [058 — Duplicates and variances tables](058-duplicates-table.md)
- [x] [059 — Meeting tables](059-meetings-tables.md)
- [x] [060 — Exports table](060-exports-table.md)
- [x] [061 — Merge session, conflict and version vector tables](061-merge-tables.md)
- [x] [062 — Repository interfaces and test factories](062-repository-interfaces.md)
- [x] [063 — Database integrity check](063-db-integrity-check.md)
- [x] [064 — Optional database encryption](064-db-encryption.md)

## As built

Reproduce by implementing 049–064 in order. Each table task **bumps** `kSchemaVersion` and **appends** a named upgrade step. Never edit an earlier step. The tree that must exist at the end:

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
