# 004 — Local database: every table, with merge columns from the first migration

**Phase** 04 · Local database  |  **Depends on** [001](../01-orchestration/001-project-setup.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

`AppDatabase` opens a lazy write-ahead-logging connection in the application support directory with foreign keys on,
closes cleanly, survives a hot restart, and carries `kSchemaVersion` with a numbered `MigrationStrategy` that reaches
head 12 through twelve named upgrade steps. `MergeColumns` gives every table its id, timestamps, device and revision
in the migration that creates it; `BaseDao` supplies watched lists, typed reads, paging, `Result` returns and a soft
delete that always writes a tombstone; `runInTransaction` joins an open write instead of nesting one. On that sit the
bookkeeping tables no feature owns — tombstones, the append-only audit log and the single device-profile row — then
projects with their context definitions, state and presets; templates with their fields and predefined rows; records
with the one-row-per-field table carrying raw, refined and final values; photos, attachments and captions keyed by
content hash; reference datasets and their normalised rows; processing jobs, provider results and field evidence;
duplicates and variances; meetings with attendees and actions; export history; and the merge sessions, conflicts and
version vectors. Eight hand-written domain repository interfaces keep Drift out of the features, each with a fake and
a factory behind it; `runIntegrityCheck` reports broken references without repairing anything; and
`DatabaseEncryption` swaps the file for an encrypted one with the key held only in secure storage, without a single
query or DAO changing.

## Files

Database core:

- `frontend/lib/core/db/app_database.dart` (new)
- `frontend/lib/core/db/app_database_io.dart` (new)
- `frontend/lib/core/db/app_database_stub.dart` (new)
- `frontend/lib/core/db/migrations.dart` (new)
- `frontend/README.md` (changed)

Shared columns and write plumbing:

- `frontend/lib/core/db/columns.dart` (new)
- `frontend/lib/core/db/base_dao.dart` (new)
- `frontend/lib/core/db/transactions.dart` (new)

Tables:

- `frontend/lib/core/db/tables/tombstones.dart` (new)
- `frontend/lib/core/db/tables/audit_log.dart` (new)
- `frontend/lib/core/db/tables/device_profile.dart` (new)
- `frontend/lib/core/db/tables/projects.dart` (new)
- `frontend/lib/core/db/tables/context.dart` (new)
- `frontend/lib/core/db/tables/templates.dart` (new)
- `frontend/lib/core/db/tables/template_fields.dart` (new)
- `frontend/lib/core/db/tables/template_rows.dart` (new)
- `frontend/lib/core/db/tables/records.dart` (new)
- `frontend/lib/core/db/tables/record_fields.dart` (new)
- `frontend/lib/core/db/tables/photos.dart` (new)
- `frontend/lib/core/db/tables/attachments.dart` (new)
- `frontend/lib/core/db/tables/captions.dart` (new)
- `frontend/lib/core/db/tables/reference.dart` (new)
- `frontend/lib/core/db/tables/processing.dart` (new)
- `frontend/lib/core/db/tables/field_evidence.dart` (new)
- `frontend/lib/core/db/tables/duplicates.dart` (new)
- `frontend/lib/core/db/tables/variances.dart` (new)
- `frontend/lib/core/db/tables/meetings.dart` (new)
- `frontend/lib/core/db/tables/exports.dart` (new)
- `frontend/lib/core/db/tables/merge.dart` (new)
- `frontend/lib/core/db/tables/sync_state.dart` (new)

Repository interfaces, pure Dart:

- `frontend/lib/features/projects/domain/project_repository.dart` (new)
- `frontend/lib/features/templates/domain/template_repository.dart` (new)
- `frontend/lib/features/records/domain/record_repository.dart` (new)
- `frontend/lib/features/capture/domain/photo_repository.dart` (new)
- `frontend/lib/features/reference/domain/reference_repository.dart` (new)
- `frontend/lib/features/processing/domain/processing_repository.dart` (new)
- `frontend/lib/features/exports/domain/export_repository.dart` (new)
- `frontend/lib/features/merge/domain/merge_repository.dart` (new)

Test support:

- `frontend/test/support/factories.dart` (new)
- `frontend/test/support/fakes/` (new, one fake per interface)

Integrity and encryption:

- `frontend/lib/core/db/integrity_check.dart` (new)
- `frontend/lib/core/db/encryption.dart` (new)

## Contract

The database, its schema version and the plumbing every table reuses:

```dart
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  factory AppDatabase.memory();
  @override
  int get schemaVersion => kSchemaVersion;
  @override
  MigrationStrategy get migration => appMigration(this);
}

const int kSchemaVersion = 1; // each table step bumps this; head is 12 once the merge tables of step 13 land
MigrationStrategy appMigration(AppDatabase db);

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

Open through `app_database_io.dart` / `app_database_stub.dart` (`dart.library.io` conditional import) so web tests do
not load `dart:ffi`.

Bookkeeping writes, and the version-vector comparison merge classifies against:

```dart
Future<void> writeTombstone(
  Transaction tx, {
  required String entityType,
  required String entityId,
  required String reason,
});

Future<void> appendAudit(
  Transaction tx, {
  required String entityType,
  required String entityId,
  required AuditAction action,
  String? fieldKey,
  String? previousValue,
  String? newValue,
  String? reason,
});

enum VectorRelation { dominates, dominated, concurrent, equal }

VectorRelation compareVectors(Map<String, int> mine, Map<String, int> theirs);
```

The domain ports and the factories later suites arrange with:

```dart
abstract interface class RecordRepository {
  Stream<List<RecordSummary>> watchByProject(String projectId, RecordFilter filter);
  Future<Result<RecordDetail?>> byId(String id);
  Future<Result<RecordDetail>> save(RecordDraft draft);
  Future<Result<void>> delete(String id, {required String reason});
}

// The same shape, one per feature: ProjectRepository, TemplateRepository, PhotoRepository,
// ReferenceRepository, ProcessingRepository, ExportRepository and MergeRepository.

// frontend/test/support/factories.dart
ProjectFactory aProject({String? name});
RecordFactory aRecord({String? projectId, Map<String, String>? fields});
Future<AppDatabase> seededDatabase({int records = 0});
```

Integrity and encryption:

```dart
sealed class IntegrityFinding {
  String get entityType;
  String get entityId;
  String get detail;
}

Future<Result<List<IntegrityFinding>>> runIntegrityCheck(AppDatabase db);

abstract interface class DatabaseEncryption {
  Future<Result<bool>> isEnabled();
  Future<Result<void>> enable({required void Function(double) onProgress});
  Future<Result<void>> disable({required String confirmation});
}
```

## Steps

### The database and its shared columns

1. Open `AppDatabase` on a lazy connection in the application support directory, write-ahead logging on, foreign keys
   on, and expose `AppDatabase.memory()` so no suite touches the real file. Reach the native opener through
   `app_database_io.dart` / `app_database_stub.dart` behind a `dart.library.io` conditional import so a web test never
   loads `dart:ffi`. Write `appMigration` as an ordered list of numbered upgrade steps keyed off `from`/`to`, each step
   a named function, and gate any step that drops or rewrites a column behind an export acknowledgement raised to the
   caller as a `StorageFailure` rather than applied silently. Wire `build_runner`, commit the generated output, and
   record the generation command in `frontend/README.md`. Drift is held at 2.31 with sqlite3 2.9.4 so the native-asset
   build hooks do not prefix every `dart run`.
2. Land the plumbing every table below reuses. `MergeColumns` supplies `id` as UUIDv7 text through the uuid service —
   never an autoincrement integer — plus `createdAt`, `updatedAt`, `updatedByDevice` and `rev`. `BaseDao` watches,
   reads, pages and upserts through a write helper that stamps `updatedAt` from the clock service, `updatedByDevice`
   from device identity and `rev = rev + 1` on every update, so no DAO does it by hand. `SqliteException`, uniqueness
   violations and busy timeouts map to sealed `StorageFailure` variants with a recovery action; no Drift exception
   escapes a DAO. `softDelete` leaves the tombstone hook step 3 fills, and the base never hard-deletes a row.
   `runInTransaction` joins an open write instead of opening a second.

### The tables, in build order

3. Schema v2 adds the three device-local bookkeeping tables. `tombstones` carries `entityType`, `entityId`,
   `deletedAt`, `deletedByDevice` and `reason`, unique on entity type plus entity id, and `writeTombstone` becomes the
   `softDelete` hook so the row and its tombstone share one transaction. `audit_log` carries `entityType`, `entityId`,
   `action`, `fieldKey`, `previousValue`, `newValue`, `reason`, `operator`, `device` and `at`, indexed on entity type
   plus entity id plus `at` for the record history view. `device_profile` holds `deviceId`, `operatorName` and
   preferences JSON as a single row keyed `local`, created on first launch behind `ensureDeviceProfile` and never
   inserted twice. `appendAudit` and `ensureDeviceProfile` both run inside the caller's transaction.
4. Schema v3 adds `projects` — `name`, `client`, `status`, `startedAt`, `completedAt`, `folderName` and `settings` as
   JSON validated on write and refused as a `StorageFailure` when malformed — indexed on `status` plus `updatedAt`,
   which is the order the project list reads. Beside it come the context tables: definitions (`projectId`, `level`,
   `fieldKey`, `label`, unique on `projectId` plus `level`), state (`projectId`, `level`, `value`, `setAt`, where
   setting a level deletes every level below it in the same transaction) and presets (`name`, `projectId`, `values`
   JSON).
5. Schema v4 adds the whole template definition. `templates` carries `projectId` nullable so shipped entries are
   project-free, `name`, `kind`, `source`, `sourceFilePath`, `sheetName`, `headerRow`, `identityFields`, `detection`
   and `version`, bumped on a header edit rather than rewriting history. `template_fields` carries `templateId`,
   `fieldKey`, `label`, `type`, `outputColumn`, `required`, `inputMode`, `stickable`, `contextLevel`, `autoFill`,
   `defaultValue`, `options`, `unit`, `validation`, `lookup`, `refine` and `sortOrder`, unique on `templateId` plus
   `fieldKey`, read in `sortOrder` then `label` order. `template_rows` carries `templateId`, `outputRowNumber`,
   `identifier`, `label`, `aliases`, `metadata` and `foundStatus`, indexed on `templateId` plus `identifier` with
   alias lookup done in Dart. `options`, `validation`, `lookup`, `aliases` and `metadata` are JSON validated on write.
6. Schema v5 adds `records` — `RecordRow` with `projectId`, `templateId`, `templateRowId` nullable, `status`,
   `processingMode`, `contextJson`, `identityHash`, `source`, `capturedAt`, `capturedBy`, `gpsLat`, `gpsLon`,
   `approvedAt` and `approvedBy` — indexed on `projectId` plus `status`, on `identityHash`, on `capturedAt` and on
   `templateId`. `record_fields` carries `recordId`, `fieldKey`, `valueRaw`, `valueRefined`, `valueFinal`,
   `confidence`, `source`, `verified`, `verifiedBy` and `verifiedAt`, unique on `recordId` plus `fieldKey` and indexed
   on `fieldKey` plus `valueFinal` for search. `contextJson` stores the values in force at capture, never a live join,
   so a later context correction cannot rewrite what was captured; refinement and approval write beside `valueRaw` and
   append an audit row in the same transaction.
7. Schema v6 adds the media metadata. `photos` carries `projectId`, `recordId` nullable for unfiled captures,
   `captureSessionId`, `originalFilename`, `storedFilename`, `relativePath`, `photoType`, `sortOrder`, `width`,
   `height`, `fileSize`, `mimeType`, `sha256`, `capturedAt`, `gpsLat` and `gpsLon`, unique on `projectId` plus
   `sha256` so re-importing the same image cannot create a second row. `attachments` repeats the identity columns —
   `relativePath`, `mimeType`, `fileSize`, `sha256` — and adds `kind` for document or audio, `durationMs` for audio
   and `pageCount` for documents, unique on `projectId` plus `sha256`. `captions` carries `ownerType` as record or
   photo, `ownerId`, `textRaw`, `textRefined`, `inputMode` as typed or spoken and `refinedAt`, indexed on `ownerType`
   plus `ownerId`; applying one caption to several photos writes one row per photo in one transaction, never a shared
   row.
8. Schema v7 adds the imported lookup tables. `reference_datasets` carries `name`, `scope` as global or project,
   `projectId` nullable, `keyColumn`, `columns` JSON, `sourceFile`, `importedAt` and `rowCount`. `reference_rows`
   carries `datasetId`, `keyValue`, `keyNormalised` and `values` JSON, unique on `datasetId` plus `keyValue` and
   indexed on `datasetId` plus `keyNormalised` for fuzzy matching. `keyNormalised` is folded on write — case-folded,
   accent-stripped, whitespace-collapsed — never at query time, and re-importing the same source file updates the
   dataset and its matching rows in place.
9. Schema v8 adds the provenance side of processing. `processing_jobs` carries `recordId`, `stage`, `status`,
   `attempts`, `lastError`, `queuedAt`, `startedAt`, `finishedAt`, `provider` and `model`, indexed on `status` plus
   `queuedAt`, and a claim is a compare-and-swap on the queued state so two workers cannot take the same job.
   `processing_results` carries `jobId`, `requestSummary`, `rawResponse`, `parsedOk` and `tokensOrCost`, written once
   when the job finishes. `field_evidence` carries `recordFieldId`, `sourceType` as photo, document or transcript,
   `photoId`, `documentId`, `page`, `region` as a JSON bounding box, `snippet` and `confidence`, indexed on
   `recordFieldId`; deleting a record field writes a tombstone so evidence is never orphaned.
10. Schema v9 adds the two review queues. `duplicates` carries `projectId`, `leftRecordId`, `rightRecordId`, `signal`,
    `score`, `status`, `resolution`, `resolvedBy` and `resolvedAt`, unique on the ordered record pair so one pair is
    never queued twice and detection upserts the existing row. `variances` carries `recordId`, `fieldKey`,
    `registerValue`, `foundValue`, `status`, `resolvedBy` and `resolvedAt`, unique on `recordId` plus `fieldKey`, and
    carries `projectId` too so the same `projectId` plus `status` index shape serves both review lists.
11. Schema v10 adds the meeting tables. `meetings` carries `recordId`, `title`, `startAt`, `endAt`, `chair`,
    `secretary`, `agenda` JSON, `transcriptRaw` and `minutesRefined`. `attendees` carries `meetingId`, `name`,
    `title`, `organisation`, `contact`, `signaturePresent` and `matchedStaffId` nullable, keeping the captured
    free-text name when a staff match is accepted. `meeting_actions` carries `meetingId`, `action`, `ownerName`,
    `dueDate` and `status`, indexed on `meetingId` plus `status`. Deleting a meeting is one transaction that
    tombstones the header and every child row without a hard delete.
12. Schema v11 adds `exports` — `projectId`, `version`, `formats`, `filters` JSON, `recordCount`, `filePath`,
    `fileHash` and `createdBy` — indexed on `projectId` plus `createdAt` for the history list. `version` increments
    per project so successive exports are distinguishable without reading the filesystem, a re-export is a new row,
    and an abandoned or incomplete run writes none.
13. Schema v12 adds everything merge persists. `merge_sessions` carries `bundleName`, `sourceDevice`, `importedAt`,
    `counts` JSON, `status` and `undoSnapshotPath`. `merge_conflicts` carries `sessionId`, `entityType`, `entityId`,
    `fieldKey`, `mineValue`, `theirsValue`, `mineMeta`, `theirsMeta`, `resolution`, `resolvedAt` and `resolvedBy`,
    indexed on `sessionId` plus `resolution` for the unresolved queue. `version_vectors` carries `entityType`,
    `entityId`, `deviceId` and `rev`, unique on the triple, with a query returning the whole vector for one entity in
    one read. `compareVectors` covers all four relations, reporting concurrency rather than resolving it, and
    resolving a conflict bumps the local vector entry.

### The repository layer

14. Declare eight domain ports — project, template, record, photo, reference, processing, export and merge — each
    returning domain models and `Result`, watched lists staying `Stream`, and taking domain filters rather than a
    Drift row, companion or `Value`. Give every interface a hand-written fake in `frontend/test/support/fakes/` that
    honours the same failure contract as the real one, so feature tests never open a database. Give the factories
    sensible defaults with named overrides, and `seededDatabase` that populates a coherent
    project–template–record–photo graph in one call.

### Integrity and encryption

15. Build the startup check. `runIntegrityCheck` detects record fields whose record is gone, photos and attachments
    whose file is missing, jobs and evidence rows pointing at deleted records, and rows deleted without a tombstone,
    then folds `PRAGMA foreign_key_check` output into the same findings list. It pages at the shared list size with a
    cap on rows examined per pass, runs its file stats off the UI thread, and returns findings for the maintenance
    screen to render.
16. Add the optional encrypted connection. Generate the key on enable, store it only through the secure storage
    service, and open the encrypted connection through the same `AppDatabase` factory path — `AppDatabase.open` takes
    a directory path and an encryption key, so tests can hot-restart a temporary file and encryption can swap the
    executor without a query or DAO changing. Copy `tapture.sqlite` into HMAC-SHA-256-CTR ciphertext, verify row
    counts per table, then delete the plain file, keeping a safety copy until verification passes. Report progress so
    a large database never looks frozen, make the whole operation resumable after a kill, require typed confirmation
    to disable, and treat a missing or unreadable key as a recoverable `StorageFailure` with a clear recovery action,
    never a wipe.

## Constraints

- Every table declares `id`, `createdAt`, `updatedAt`, `updatedByDevice` and `rev` through `MergeColumns` in the
  migration step that creates it, and no migration step ever back-fills them: merge identity exists from the first
  migration, so an entity imported from another device merges on `rev` rather than on a name (FE-SEC-08, FE-SEC-09).
- Nothing hard-deletes a row. `softDelete` writes exactly one tombstone inside the caller's transaction, which is what
  the data-safety suite of 001 asserts (FE-SEC-08, FE-SEC-09).
- Drift output is committed, regenerated in the same commit as the schema change (FE-CODE-13).
- Public DAO and helper methods return `Result<T>`; a raw exception never crosses out of `core/db/` (FE-CODE-06).
- Collections are exposed as watched streams, single rows as futures (FE-STATE-08).
- Audit rows are append-only: no update, no delete path, and they travel in bundles like any other data (FE-SEC-08,
  FE-SEC-09). Every value change goes through the audit append helper of step 3 in the same transaction.
- Never write a field value, caption or transcript to a log sink while writing it to the audit table (FE-CODE-08).
- Write-once columns stay write-once (FE-SEC-08, enforced by the data-safety suite of 001): `valueRaw` is written at
  creation and refinement writes `valueRefined` and approval `valueFinal`; `textRaw`, `capturedAt` and `sha256` are
  set at creation; `transcriptRaw` is never edited and refinement writes `minutesRefined` beside it; `rawResponse` and
  `requestSummary` are written when the job finishes and never rewritten, being the audit of what the provider said;
  `filePath` and `fileHash` are written when an export completes, and a re-export creates a new row.
- `folderName` is stored, never recomputed at read time: renaming a project must not move files on disk.
- Editing a template bumps `version` on the header rather than rewriting history: records keep the version they were
  captured against.
- Imported sheet names, headers and cell text are stored as data, never interpolated into a query or a provider
  instruction (FE-SEC-05).
- `relativePath` stays relative to the project folder so the tree survives a move of the storage root.
- GPS columns are nullable and stay null unless the project has location recording enabled (FE-SEC-07).
- Attendee names and contacts are personal data: no default GPS, no export beyond what the project consent flag
  allows (FE-SEC-07).
- `requestSummary` records shape and size, never a provider key or a bearer token (FE-SEC-01).
- `filters` records the query, never the exported values.
- A resolution records who and when. Nothing is auto-resolved, no detection writes a `resolution`, `mineValue` and
  `theirsValue` are recorded verbatim and never normalised so the undo path can replay them, and merge never picks a
  winner for a concurrent pair (FE-SEC-09, and rule 5 of the standard: AI proposes, a person approves).
- Domain stays pure Dart: no Drift, Flutter or HTTP import under any `domain/` folder, which is what the layering
  suite of 001 asserts (FE-STR-05, FE-STATE-05).
- Fakes are written by hand, not generated by a mocking framework (FE-TEST-03).
- Integrity findings are reported, never acted on: no delete, no rewrite, no silent repair (rule 1 of the standard).
- The integrity pass streams rows in batches so a 10,000-record project does not load into memory, and the encryption
  copy runs off the UI thread in chunks (FE-PERF-02, FE-PERF-07).
- The encryption key exists only in platform secure storage: never in the database, preferences, logs, exports or
  bundles (FE-SEC-01, FE-SEC-02).
- Encryption must be demonstrable, not claimed: a test proves the file cannot be read without the key (FE-SEC-11).

## Definition of done

### The database and its shared columns

- [x] The database opens, closes and reopens across a hot restart with no lock left behind.
- [x] Upgrading from any released version to head preserves every row; a destructive step refuses to run without the
      export acknowledgement.
- [x] Adding a schema change without adding a migration step and its test fails the suite.
- [x] No table declares `id`, `createdAt`, `updatedAt`, `updatedByDevice` or `rev` by hand.
- [x] Every update through the base DAO increments `rev` and advances `updatedAt`; a write that skips the helper is
      visible as an unchanged `rev`.
- [x] A failure part-way through a multi-table write leaves no partial rows, whether the call opened the transaction
      or joined one.
- [x] Tests: `frontend/test/core/db/app_database_test.dart` opens an in-memory database and asserts a clean close;
      `migrations_test.dart` walks a seeded version 1 file to head and compares row counts and column sets.
- [x] Tests: `frontend/test/core/db/columns_test.dart` asserts the rev-and-timestamp bump on repeated writes;
      `base_dao_test.dart` covers watch, get, upsert, paging and failure mapping against an in-memory database;
      `transactions_test.dart` asserts full rollback on a mid-transaction throw and on a nested call.

### The tables, in build order

- [x] Deleting any entity produces exactly one tombstone, in the same transaction, and no hard delete anywhere.
- [x] Every value change writes exactly one audit row carrying both previous and new value.
- [x] The device profile row exists after first launch and a second launch does not duplicate it.
- [x] Tests: `frontend/test/core/db/tables/tombstones_test.dart` asserts delete-plus-tombstone atomicity and that a
      failed delete writes neither; `audit_log_test.dart` asserts an update records previous and new values;
      `device_profile_test.dart` asserts idempotent first-launch creation. All against an in-memory database, each
      covering its table's migration step.
- [x] A project can be created, listed by status and updated, with the list query served by the index.
- [x] Setting a higher context level clears every lower level, and no orphan state row survives.
- [x] Malformed settings JSON is refused on write with a recoverable failure, never stored.
- [x] Tests: `frontend/test/core/db/tables/projects_test.dart` covers create, paged list by status and update;
      `context_test.dart` asserts the clear-lower-levels rule and preset round-trip. Both against an in-memory
      database, covering their migration steps.
- [x] A template with fields and rows round-trips, and a duplicate `fieldKey` within one template is refused by the
      unique index rather than by application code.
- [x] A shipped template with no `projectId` coexists with project-scoped templates.
- [x] Tests: `frontend/test/core/db/tables/templates_test.dart` covers header insert, version bump and the shipped
      case; `template_fields_test.dart` asserts the unique constraint and sort order; `template_rows_test.dart`
      covers alias lookup. All against an in-memory database, covering their migration steps.
- [x] Listing a project's records by status is paged and served by the index, never by a full scan.
- [x] Writing a refined or final value leaves `valueRaw` byte-identical; a second write to `valueRaw` is refused.
- [x] A duplicate `fieldKey` for one record is refused by the unique index.
- [x] Tests: `frontend/test/core/db/tables/records_test.dart` covers paged listing by project and status and lookup by
      `identityHash`; `record_fields_test.dart` asserts raw is untouched by refinement and that the unique index
      holds. Both against an in-memory database, covering their migration steps.
- [x] Importing the same file twice into one project is refused by the unique hash index, not by application code.
- [x] Applying one caption to thirty photos writes thirty rows and leaves each independently editable.
- [x] Refining a caption leaves `textRaw` unchanged.
- [x] Tests: `frontend/test/core/db/tables/photos_test.dart` asserts hash uniqueness per project and unfiled capture
      with a null `recordId`; `attachments_test.dart` covers the document and audio variants; `captions_test.dart`
      asserts the many-photo write and raw immutability. All against an in-memory database, covering their migration
      steps.
- [x] A dataset of 10,000 rows imports and a key lookup stays within the search budget of FE-PERF-01, measured under
      300ms.
- [x] Re-importing the same source file updates rows in place instead of creating a second dataset.
- [x] Tests: `frontend/test/core/db/tables/reference_test.dart` covers dataset insert, keyed lookup, normalised lookup
      and re-import, against an in-memory database, covering the migration step.
- [x] Claiming the next queued job is served by the status index and cannot hand the same job to two workers.
- [x] A retried job increments `attempts` and keeps every earlier result row.
- [x] Any final value can be traced to its evidence row and from there to a photo region, document page or transcript
      segment.
- [x] Tests: `frontend/test/core/db/tables/processing_test.dart` covers queue ordering, retry accounting and result
      immutability; `field_evidence_test.dart` asserts the three source types resolve and that deleting a record field
      leaves a tombstone rather than an orphan. Both against an in-memory database, covering their migration steps.
- [x] Detecting the same pair twice updates the existing row rather than inserting a second.
- [x] An unresolved queue of either kind can be listed by project and status through the index.
- [x] Resolving either kind stores the operator and timestamp and leaves both source records intact.
- [x] Tests: `frontend/test/core/db/tables/duplicates_test.dart` asserts pair uniqueness regardless of argument order
      and resolution recording; `variances_test.dart` covers the register-versus-found round-trip and its unique
      index. Both against an in-memory database, covering their migration steps.
- [x] A meeting with attendees and actions round-trips and deletes as one transaction with tombstones for each row.
- [x] Refining minutes leaves `transcriptRaw` byte-identical.
- [x] An attendee matched to a staff record keeps the free-text name that was captured.
- [x] Tests: `frontend/test/core/db/tables/meetings_test.dart` covers header, attendee and action inserts, transcript
      immutability under refinement, and cascade-with-tombstones on delete, against an in-memory database, covering
      the migration step.
- [x] Completing an export writes exactly one row, and an abandoned export writes none.
- [x] The history for a project lists newest first through the index.
- [x] Tests: `frontend/test/core/db/tables/exports_test.dart` covers per-project version increment, history ordering
      and the absence of a row after a failed export, against an in-memory database, covering the migration step.
- [x] Any incoming entity is classified as dominating, dominated, concurrent or equal from one vector read.
- [x] A session retains its undo snapshot path and its unresolved conflicts survive an app restart.
- [x] Resolving a conflict records the operator and timestamp and bumps the entity's vector entry.
- [x] Tests: `frontend/test/core/db/tables/merge_test.dart` covers session insert, the unresolved-conflict query and
      resolution recording; `sync_state_test.dart` asserts the unique triple and all four `compareVectors` outcomes.
      Both against an in-memory database, covering their migration steps.

### The repository layer

- [x] Presentation and domain code compiles with the database package absent from their imports.
- [x] A valid project, template, record or photo is one line of test setup (FE-TEST-04).
- [x] Every declared interface has a fake, and each fake honours the same failure contract as the real one.
- [x] Tests: unit tests per `*_repository.dart` exercising each fake with no Flutter binding.
- [x] Tests: `frontend/test/support/factories_test.dart` proves `seededDatabase` yields a graph the record DAO can
      read.

### Integrity and encryption

- [x] A database with deliberately orphaned rows produces one finding per problem, each naming entity type and id.
- [x] A clean database produces an empty list and adds no measurable delay to cold start (FE-PERF-01).
- [x] Running the check twice changes nothing on disk.
- [x] Tests: `frontend/test/core/db/integrity_check_test.dart` seeds orphaned fields, a missing photo file, a job on a
      deleted record and a tombstone-less delete, and asserts one finding each plus an unchanged row count
      afterwards.
- [x] Enabling encryption preserves every row and every table's row count matches before the plain file is removed.
- [x] A kill part-way through leaves either the plain database or the verified encrypted one, never a half-copied
      file.
- [x] Disabling requires explicit typed confirmation; a lost key produces a stated failure rather than data loss.
- [x] Tests: `frontend/test/core/db/encryption_test.dart` asserts the encrypted file fails to open without the key,
      opens with it, that row counts survive enable and disable, and that an interrupted enable is resumable.

## Out of scope

- The Drift-backed repository implementations under each feature's `data/` folder; those belong to the feature phases
  that own them.
- The maintenance screen that renders integrity findings, and file-side orphan detection; both belong to
  005 · File storage.
