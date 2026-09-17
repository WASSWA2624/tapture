import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/columns.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

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

/// How [compareVectors] places two version vectors relative to each other.
enum VectorRelation {
  /// The local vector is ahead on every device, and strictly ahead on one.
  dominates,

  /// The incoming vector is ahead on every device, and strictly ahead on one.
  dominated,

  /// Each side has a device the other has not caught up with.
  concurrent,

  /// Both maps name the same revisions, treating a missing device as zero.
  equal,
}

/// Classifies [mine] against [theirs]. Concurrent is reported, never resolved.
///
/// A missing device is treated as revision 0. An empty vector is [dominated]
/// by any non-empty one.
VectorRelation compareVectors(Map<String, int> mine, Map<String, int> theirs) {
  final Set<String> devices = <String>{...mine.keys, ...theirs.keys};
  bool mineGreater = false;
  bool theirsGreater = false;
  for (final String device in devices) {
    final int local = mine[device] ?? 0;
    final int incoming = theirs[device] ?? 0;
    if (local > incoming) {
      mineGreater = true;
    }
    if (incoming > local) {
      theirsGreater = true;
    }
  }
  if (!mineGreater && !theirsGreater) {
    return VectorRelation.equal;
  }
  if (mineGreater && !theirsGreater) {
    return VectorRelation.dominates;
  }
  if (theirsGreater && !mineGreater) {
    return VectorRelation.dominated;
  }
  return VectorRelation.concurrent;
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
    final VersionVectorRow? existing = await _vectorRow(
      database,
      entityType: entityType,
      entityId: entityId,
      deviceId: deviceId,
    );
    return _SyncStateDao(
      database,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    ).upsert(
      SyncStateCompanion(
        id: existing == null
            ? const Value<String>.absent()
            : Value<String>(existing.id),
        entityType: Value<String>(entityType),
        entityId: Value<String>(entityId),
        deviceId: Value<String>(deviceId),
        seenRev: Value<int>(rev),
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
    final VersionVectorRow? existing = await _vectorRow(
      database,
      entityType: entityType,
      entityId: entityId,
      deviceId: deviceId,
    );
    return upsertVersionVector(
      database,
      entityType: entityType,
      entityId: entityId,
      rev: (existing?.seenRev ?? 0) + 1,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
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

final class _SyncStateDao extends BaseDao<SyncState, VersionVectorRow> {
  _SyncStateDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.syncState);
}
