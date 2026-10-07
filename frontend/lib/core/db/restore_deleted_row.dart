import 'package:drift/drift.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import 'app_database.dart';
import 'base_dao.dart';
import 'tables/audit_log.dart';
import 'tables/tombstones.dart';

/// Lifts one tombstone in the caller's transaction, using the ordinary revision
/// writer and append-only audit. No content column is changed.
Future<void> restoreDeletedRow<T extends Table, R>(
  AppDatabase db, {
  required TableInfo<T, R> table,
  required String id,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  final Tombstone? tombstone = await (db.select(db.tombstones)..where(
    ($TombstonesTable row) => row.entityType.equals(table.actualTableName) & row.entityId.equals(id),
  )).getSingleOrNull();
  if (tombstone == null) return;
  final _RestoreDao<T, R> dao = _RestoreDao<T, R>(db, table: table, clock: clock, deviceId: deviceId, ids: ids);
  (await dao.upsert(RawValuesInsertable<R>(<String, Expression<Object>>{'id': Variable<String>(id)}))).getOrThrow();
  await removeTombstone(db, entityType: table.actualTableName, entityId: id);
  await appendAudit(db, entityType: table.actualTableName, entityId: id,
    action: AuditAction.updated, fieldKey: 'restored', previousValue: tombstone.reason,
    newValue: 'live', clock: clock, device: deviceId);
}

final class _RestoreDao<T extends Table, R> extends BaseDao<T, R> {
  _RestoreDao(super.db, {required super.table, required super.clock, required super.deviceId, required super.ids});
}
