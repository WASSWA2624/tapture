import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/columns.dart';
import 'package:tapture/core/time/clock.dart';

/// Append-only history of a value change. Never updated or deleted.
@TableIndex(name: 'audit_log_history', columns: {#entityType, #entityId, #at})
class AuditLog extends Table with MergeColumns {
  /// The table the changed row belongs to.
  TextColumn get entityType => text()();

  /// Merge id of the changed row.
  TextColumn get entityId => text()();

  /// What happened to the row or field.
  TextColumn get action => textEnum<AuditAction>()();

  /// Field that changed, when this row is a field-level change.
  TextColumn get fieldKey => text().nullable()();

  /// Value before the change. Written only here, never to a log sink.
  TextColumn get previousValue => text().nullable()();

  /// Value after the change. Written only here, never to a log sink.
  TextColumn get newValue => text().nullable()();

  /// Why the change was made, when known.
  TextColumn get reason => text().nullable()();

  /// Operator name copied from the device profile at write time.
  TextColumn get operator => text()();

  /// Device that wrote the change.
  TextColumn get device => text()();

  /// When the change was written.
  DateTimeColumn get at => dateTime()();
}

/// The kinds of change the audit log records.
enum AuditAction {
  /// A row was inserted.
  created,

  /// A field or row was changed.
  updated,

  /// A row was marked deleted.
  deleted,
}

/// Appends one audit row inside the caller's transaction.
///
/// Callers pass the database whose zone is the open write; see [writeTombstone].
Future<void> appendAudit(
  GeneratedDatabase tx, {
  required String entityType,
  required String entityId,
  required AuditAction action,
  String? fieldKey,
  String? previousValue,
  String? newValue,
  String? reason,
  Clock? clock,
  String? device,
  String? operator,
}) async {
  final AppDatabase db = tx as AppDatabase;
  final DateTime now = (clock ?? const SystemClock()).nowUtc();
  await tx
      .into(db.auditLog)
      .insert(
        AuditLogCompanion.insert(
          entityType: entityType,
          entityId: entityId,
          action: action,
          fieldKey: Value<String?>(fieldKey),
          previousValue: Value<String?>(previousValue),
          newValue: Value<String?>(newValue),
          reason: Value<String?>(reason),
          operator: operator ?? '',
          device: device ?? '',
          at: now,
          createdAt: now,
          updatedAt: now,
          updatedByDevice: device ?? '',
        ),
      );
}
