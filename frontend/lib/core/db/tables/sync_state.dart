import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/columns.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

export '../vector_relation.dart';

/// Highest revision seen for one entity on one device.
///
/// Unique on [entityType], [entityId] and [deviceId]. The whole vector for
/// one entity is one equality read. [seenRev] is the vector clock;
/// [MergeColumns.rev] is this row's own write counter.
@DataClassName('VersionVectorRow')
class SyncState extends Table with MergeColumns {
  @override
  String get tableName => 'version_vectors';

  /// Table the entity belongs to.
  TextColumn get entityType => text()();

  /// Merge id of the entity.
  TextColumn get entityId => text()();

  /// Replica that produced [seenRev].
  TextColumn get deviceId => text()();

  /// Highest entity revision seen from [deviceId].
  IntColumn get seenRev => integer()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{entityType, entityId, deviceId},
  ];
}

/// The whole vector for one entity in one read: device id to revision.
Future<Result<Map<String, int>>> loadVersionVector(
  GeneratedDatabase db, {
  required String entityType,
  required String entityId,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final List<VersionVectorRow> rows =
        await (database.select(database.syncState)..where(
              ($SyncStateTable tbl) =>
                  tbl.entityType.equals(entityType) &
                  tbl.entityId.equals(entityId),
            ))
            .get();
    return Success<Map<String, int>>(<String, int>{
      for (final VersionVectorRow row in rows) row.deviceId: row.seenRev,
    });
  } on Failure catch (failure) {
    return FailureResult<Map<String, int>>(failure);
  } on Object catch (error) {
    return FailureResult<Map<String, int>>(storageFailureFrom(error));
  }
}

/// Inserts or updates the row for this device on [entityType]/[entityId].
Future<Result<VersionVectorRow>> upsertVersionVector(
  GeneratedDatabase db, {
  required String entityType,
  required String entityId,
  required int rev,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    return Success<VersionVectorRow>(
      await _writeVector(
        database,
        entityType: entityType,
        entityId: entityId,
        revision: rev,
        clock: clock,
        deviceId: deviceId,
        ids: ids,
      ),
    );
  } on Failure catch (failure) {
    return FailureResult<VersionVectorRow>(failure);
  } on Object catch (error) {
    return FailureResult<VersionVectorRow>(storageFailureFrom(error));
  }
}

/// Adds one to this device's counter for the entity, inserting when absent.
Future<Result<VersionVectorRow>> bumpVersionVector(
  GeneratedDatabase db, {
  required String entityType,
  required String entityId,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    return Success<VersionVectorRow>(
      await _writeVector(
        database,
        entityType: entityType,
        entityId: entityId,
        revision: 1,
        increment: true,
        clock: clock,
        deviceId: deviceId,
        ids: ids,
      ),
    );
  } on Failure catch (failure) {
    return FailureResult<VersionVectorRow>(failure);
  } on Object catch (error) {
    return FailureResult<VersionVectorRow>(storageFailureFrom(error));
  }
}

Future<VersionVectorRow?> _vectorRow(
  AppDatabase db, {
  required String entityType,
  required String entityId,
  required String deviceId,
}) {
  return (db.select(db.syncState)..where(
        ($SyncStateTable tbl) =>
            tbl.entityType.equals(entityType) &
            tbl.entityId.equals(entityId) &
            tbl.deviceId.equals(deviceId),
      ))
      .getSingleOrNull();
}

Future<VersionVectorRow> _writeVector(
  AppDatabase db, {
  required String entityType,
  required String entityId,
  required int revision,
  required Clock clock,
  required String deviceId,
  required IdService ids,
  bool increment = false,
}) => db.transaction(() async {
  final DateTime at = clock.nowUtc();
  await db.customInsert(
    'INSERT INTO version_vectors '
    '(id, created_at, updated_at, updated_by_device, rev, '
    'entity_type, entity_id, device_id, seen_rev) VALUES (?, ?, ?, ?, 1, ?, ?, ?, ?) '
    'ON CONFLICT(entity_type, entity_id, device_id) DO UPDATE SET '
    'seen_rev = ${increment ? 'version_vectors.seen_rev + 1' : 'excluded.seen_rev'}, '
    'updated_at = excluded.updated_at, updated_by_device = excluded.updated_by_device, '
    'rev = version_vectors.rev + 1 '
    '${increment ? '' : 'WHERE excluded.seen_rev > version_vectors.seen_rev'}',
    variables: <Variable<Object>>[
      Variable<String>(ids.newId()),
      Variable<DateTime>(at),
      Variable<DateTime>(at),
      Variable<String>(deviceId),
      Variable<String>(entityType),
      Variable<String>(entityId),
      Variable<String>(deviceId),
      Variable<int>(revision),
    ],
    updates: <TableInfo<dynamic, dynamic>>{db.syncState},
  );
  return (await _vectorRow(
    db,
    entityType: entityType,
    entityId: entityId,
    deviceId: deviceId,
  ))!;
});
