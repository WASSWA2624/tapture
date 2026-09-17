import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/columns.dart';
import 'package:tapture/core/time/clock.dart';

/// A deleted entity that must not come back on merge.
class Tombstones extends Table with MergeColumns {
  /// The table the deleted row belonged to.
  TextColumn get entityType => text()();

  /// Merge id of the deleted row.
  TextColumn get entityId => text()();

  /// When the delete was written.
  DateTimeColumn get deletedAt => dateTime()();

  /// Device that wrote the delete.
  TextColumn get deletedByDevice => text()();

  /// Why the row was removed.
  TextColumn get reason => text()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{entityType, entityId},
  ];
}

/// Writes one tombstone for [entityId] inside the caller's transaction.
///
/// A second delete of the same entity is ignored so merge sees exactly one
/// tombstone. Drift's `transaction` callback does not receive a `Transaction`
/// object (`@internal`); callers pass the database whose zone is the open write.
Future<void> writeTombstone(
  GeneratedDatabase tx, {
  required String entityType,
  required String entityId,
  required String reason,
  Clock? clock,
  String? deviceId,
}) async {
  final AppDatabase db = tx as AppDatabase;
  final DateTime now = (clock ?? const SystemClock()).nowUtc();
  final String device = deviceId ?? '';
  await tx
      .into(db.tombstones)
      .insert(
        TombstonesCompanion.insert(
          entityType: entityType,
          entityId: entityId,
          deletedAt: now,
          deletedByDevice: device,
          reason: reason,
          createdAt: now,
          updatedAt: now,
          updatedByDevice: device,
        ),
        mode: InsertMode.insertOrIgnore,
      );
}
