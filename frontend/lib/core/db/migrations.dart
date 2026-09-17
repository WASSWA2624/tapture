import 'package:drift/drift.dart';
import 'package:tapture/core/errors/failure.dart';

import 'app_database.dart';

/// One upgrade from `version - 1` to [version].
typedef _UpgradeStep = Future<void> Function(Migrator migrator, AppDatabase db);

/// The migration strategy later table tasks extend rather than inventing.
typedef Migrations = MigrationStrategy;

/// Ordered upgrade steps keyed by the schema version they produce.
///
/// Version 1 creates the empty schema. Later table tasks append a named
/// function and bump [kSchemaVersion]; they never edit earlier steps, and they
/// never back-fill `id`, `createdAt`, `updatedAt`, `updatedByDevice` or `rev`.
final Map<int, Future<void> Function(Migrator migrator, AppDatabase db)>
kUpgradeSteps = <int, _UpgradeStep>{
  1: migrateToV1,
  2: migrateToV2,
  3: migrateToV3,
  4: migrateToV4,
  5: migrateToV5,
  6: migrateToV6,
  7: migrateToV7,
  8: migrateToV8,
  9: migrateToV9,
  10: migrateToV10,
  11: migrateToV11,
};

/// Versions that drop or rewrite a column and must not run without an export.
const Set<int> kDestructiveSteps = <int>{};

bool _exportAcknowledged = false;

/// Records that the operator has exported before a destructive migration.
void acknowledgeExport() {
  _exportAcknowledged = true;
}

/// Clears the export acknowledgement, so a later migration must prompt again.
void clearExportAcknowledgement() {
  _exportAcknowledged = false;
}

/// Throws if a destructive step would run without [acknowledgeExport].
void ensureExportAcknowledged({required bool isDestructive}) {
  if (!isDestructive) {
    return;
  }
  if (_exportAcknowledged) {
    return;
  }
  throw const StorageFailure(
    message: 'This update would drop or rewrite a column.',
    recoveryAction: 'Export your projects, then confirm the update.',
  );
}

/// Schema version 1: the empty database every later table task extends.
Future<void> migrateToV1(Migrator migrator, AppDatabase db) async {
  if (db.schemaVersion < 1) {
    throw StateError('schema version is unusable');
  }
  await migrator.createAll();
}

/// Schema version 2: tombstones, audit log and the single device profile.
Future<void> migrateToV2(Migrator migrator, AppDatabase db) async {
  await migrator.createTable(db.tombstones);
  await migrator.createTable(db.auditLog);
  await migrator.createTable(db.deviceProfile);
  await migrator.createIndex(db.auditLogHistory);
}

/// Schema version 3: projects and the context hierarchy that hangs off them.
Future<void> migrateToV3(Migrator migrator, AppDatabase db) async {
  await migrator.createTable(db.projects);
  await migrator.createTable(db.context);
  await migrator.createTable(db.contextState);
  await migrator.createTable(db.contextPresets);
  await migrator.createIndex(db.projectsByStatus);
}

/// Schema version 4: templates, template fields and predefined rows.
Future<void> migrateToV4(Migrator migrator, AppDatabase db) async {
  await migrator.createTable(db.templates);
  await migrator.createTable(db.templateFields);
  await migrator.createTable(db.templateRows);
  await migrator.createIndex(db.templateRowsByIdentifier);
}

/// Schema version 5: records and one-row-per-field values.
Future<void> migrateToV5(Migrator migrator, AppDatabase db) async {
  await migrator.createTable(db.records);
  await migrator.createTable(db.recordFields);
  await migrator.createIndex(db.recordsByProjectStatus);
  await migrator.createIndex(db.recordsByIdentityHash);
  await migrator.createIndex(db.recordsByCapturedAt);
  await migrator.createIndex(db.recordsByTemplate);
  await migrator.createIndex(db.recordFieldsByFinal);
}

/// Schema version 6: photos, attachments and captions.
Future<void> migrateToV6(Migrator migrator, AppDatabase db) async {
  await migrator.createTable(db.photos);
  await migrator.createTable(db.attachments);
  await migrator.createTable(db.captions);
  await migrator.createIndex(db.captionsByOwner);
}

/// Schema version 7: reference datasets and their rows.
Future<void> migrateToV7(Migrator migrator, AppDatabase db) async {
  await migrator.createTable(db.reference);
  await migrator.createTable(db.referenceRows);
  await migrator.createIndex(db.referenceRowsByKey);
  await migrator.createIndex(db.referenceRowsByNormalised);
}

/// Schema version 8: processing jobs, results and field evidence.
Future<void> migrateToV8(Migrator migrator, AppDatabase db) async {
  await migrator.createTable(db.processing);
  await migrator.createTable(db.processingResults);
  await migrator.createTable(db.fieldEvidence);
  await migrator.createIndex(db.processingJobsByStatus);
  await migrator.createIndex(db.fieldEvidenceByField);
}

/// Schema version 9: duplicate pairs and as-recorded versus as-found variances.
Future<void> migrateToV9(Migrator migrator, AppDatabase db) async {
  await migrator.createTable(db.duplicates);
  await migrator.createTable(db.variances);
  await migrator.createIndex(db.duplicatesByPair);
  await migrator.createIndex(db.duplicatesByProjectStatus);
  await migrator.createIndex(db.variancesByField);
  await migrator.createIndex(db.variancesByProjectStatus);
}

/// Schema version 10: meetings, attendees and action items.
Future<void> migrateToV10(Migrator migrator, AppDatabase db) async {
  await migrator.createTable(db.meetings);
  await migrator.createTable(db.attendees);
  await migrator.createTable(db.meetingActions);
  await migrator.createIndex(db.meetingActionsByMeetingStatus);
}

/// Schema version 11: export history.
Future<void> migrateToV11(Migrator migrator, AppDatabase db) async {
  await migrator.createTable(db.exports);
  await migrator.createIndex(db.exportsByProjectCreated);
}

/// Runs the named step for [version], after the destructive-migration gate.
Future<void> runUpgradeStep({
  required int version,
  required Migrator migrator,
  required AppDatabase db,
}) async {
  ensureExportAcknowledged(isDestructive: kDestructiveSteps.contains(version));
  final _UpgradeStep? step = kUpgradeSteps[version];
  if (step == null) {
    throw StateError('Missing migration step for schema version $version');
  }
  await step(migrator, db);
}

/// Per-version upgrade path from any released schema to [kSchemaVersion].
MigrationStrategy appMigration(AppDatabase db) {
  return MigrationStrategy(
    onCreate: (Migrator migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (Migrator migrator, int from, int to) async {
      for (int version = from + 1; version <= to; version++) {
        await runUpgradeStep(version: version, migrator: migrator, db: db);
      }
    },
    beforeOpen: (OpeningDetails details) async {
      await db.customStatement('PRAGMA foreign_keys = ON');
      if (details.versionNow < 1) {
        throw StateError('schema version is unusable');
      }
    },
  );
}
