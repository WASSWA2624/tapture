import 'package:drift/drift.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import 'app_database.dart';
import 'tables/audit_log.dart';
import 'tables/tombstones.dart';

/// Lifts one tombstone in the caller's transaction, stamping revision metadata
/// and append-only audit. No content column is changed.
Future<void> restoreDeletedRow<T extends Table, R>(
  AppDatabase db, {
  required TableInfo<T, R> table,
  required String id,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  final Tombstone? tombstone =
      await (db.select(db.tombstones)..where(
            ($TombstonesTable row) =>
                row.entityType.equals(table.actualTableName) &
                row.entityId.equals(id),
          ))
          .getSingleOrNull();
  if (tombstone == null) return;
  // A project traverses allTables, whose row types are erased. A typed Drift
  // update would reject its RawValuesInsertable even though these metadata
  // columns are shared by every restorable entity.
  await db.customUpdate(
    'UPDATE "${table.actualTableName}" '
    'SET updated_at = ?, updated_by_device = ?, rev = rev + 1 WHERE id = ?',
    variables: <Variable<Object>>[
      Variable<DateTime>(clock.nowUtc()),
      Variable<String>(deviceId),
      Variable<String>(id),
    ],
    updates: <TableInfo<T, R>>{table},
  );
  await removeTombstone(db, entityType: table.actualTableName, entityId: id);
  await appendAudit(
    db,
    entityType: table.actualTableName,
    entityId: id,
    action: AuditAction.updated,
    fieldKey: 'restored',
    previousValue: tombstone.reason,
    newValue: 'live',
    clock: clock,
    device: deviceId,
  );
}
