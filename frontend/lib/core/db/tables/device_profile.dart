import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/columns.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/device/device_identity.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

/// Well-known merge id so this table holds exactly one row.
const String deviceProfileRowId = 'local';

const String _rowId = deviceProfileRowId;

/// The audit field the one-time device id check is recorded under.
const String _deviceIdField = 'deviceId';

/// Why the device id check wrote its audit row.
const String _deviceIdReason = 'The device id is kept in the device profile.';

/// The one device-local profile: identity, operator name and preferences.
@DataClassName('DeviceProfileRow')
class DeviceProfile extends Table with MergeColumns {
  /// Stable device identifier minted by [deviceId].
  TextColumn get deviceId => text()();

  /// Display name of the operator on this device.
  TextColumn get operatorName => text().withDefault(const Constant(''))();

  /// Preferences JSON. An object, stored as text.
  TextColumn get preferences => text().withDefault(const Constant('{}'))();

  /// Backend account id, filled by enrolment. Null on every pre-backend install.
  TextColumn get accountId => text().nullable()();
}

/// The device id (specification §10.2): read from the one profile row, which
/// is the only place it is kept, and minted there on first launch.
///
/// The first launch after task 078 also reads the id a pre-078 build left in
/// the OS temp folder ([legacyId], [legacyDeviceId] by default). When that
/// file holds an id, it is the id this install has been stamping rows with,
/// so it wins over the profile's; an audit row records the check, and from
/// then on only the profile is read. Every caller — the bootstrap, the
/// settings store and the operator profile — resolves through here, so one
/// install has one id.
Future<String> resolveDeviceId(
  AppDatabase db, {
  required Clock clock,
  required IdService ids,
  String? Function()? legacyId,
}) async {
  final DeviceProfileRow? row = await _profileRow(db);
  if (row != null && await _deviceIdChecked(db)) {
    return row.deviceId;
  }
  final String? legacy = (legacyId ?? () => legacyDeviceId())();
  final String id = legacy != null && legacy.isNotEmpty
      ? legacy
      : row?.deviceId ?? ids.newId();
  await db.transaction(() async {
    final DeviceProfileRow current = await ensureDeviceProfile(
      db,
      deviceId: id,
      clock: clock,
    );
    if (current.deviceId != id) {
      await (db.update(
        db.deviceProfile,
      )..where(($DeviceProfileTable tbl) => tbl.id.equals(_rowId))).write(
        DeviceProfileCompanion(
          deviceId: Value<String>(id),
          updatedAt: Value<DateTime>(clock.nowUtc()),
          updatedByDevice: Value<String>(id),
          rev: Value<int>(current.rev + 1),
        ),
      );
    }
    await appendAudit(
      db,
      entityType: db.deviceProfile.actualTableName,
      entityId: _rowId,
      action: row == null ? AuditAction.created : AuditAction.updated,
      fieldKey: _deviceIdField,
      previousValue: row?.deviceId,
      newValue: id,
      reason: _deviceIdReason,
      clock: clock,
      device: id,
    );
  });
  return id;
}

Future<DeviceProfileRow?> _profileRow(AppDatabase db) {
  return (db.select(db.deviceProfile)
        ..where(($DeviceProfileTable tbl) => tbl.id.equals(_rowId)))
      .getSingleOrNull();
}

/// Whether [resolveDeviceId] has already recorded its one-time check.
Future<bool> _deviceIdChecked(AppDatabase db) async {
  final AuditLogData? marker =
      await (db.select(db.auditLog)
            ..where(
              ($AuditLogTable tbl) =>
                  tbl.entityType.equals(db.deviceProfile.actualTableName) &
                  tbl.entityId.equals(_rowId) &
                  tbl.fieldKey.equals(_deviceIdField),
            )
            ..limit(1))
          .getSingleOrNull();
  return marker != null;
}

/// Inserts the single profile row on first launch. A second call is a no-op.
Future<DeviceProfileRow> ensureDeviceProfile(
  GeneratedDatabase tx, {
  required String deviceId,
  Clock? clock,
  String operatorName = '',
  String preferences = '{}',
}) async {
  final AppDatabase db = tx as AppDatabase;
  final DateTime now = (clock ?? const SystemClock()).nowUtc();
  await tx
      .into(db.deviceProfile)
      .insert(
        DeviceProfileCompanion.insert(
          id: const Value<String>(_rowId),
          deviceId: deviceId,
          operatorName: Value<String>(operatorName),
          preferences: Value<String>(preferences),
          createdAt: now,
          updatedAt: now,
          updatedByDevice: deviceId,
        ),
        mode: InsertMode.insertOrIgnore,
      );
  return (tx.select(
    db.deviceProfile,
  )..where(($DeviceProfileTable tbl) => tbl.id.equals(_rowId))).getSingle();
}

/// The identity fields of the single profile row.
typedef DeviceProfileIdentity = ({
  String operatorName,
  String preferences,
  String? accountId,
});

/// Reads the single profile row, inserting it when first launch has not.
Future<DeviceProfileIdentity> readDeviceProfile(
  GeneratedDatabase tx, {
  required String deviceId,
  Clock? clock,
}) async {
  final DeviceProfileRow row = await ensureDeviceProfile(
    tx,
    deviceId: deviceId,
    clock: clock,
  );
  return (
    operatorName: row.operatorName,
    preferences: row.preferences,
    accountId: row.accountId,
  );
}

/// Updates the single profile row. Never inserts a second row.
Future<DeviceProfileIdentity> writeDeviceProfile(
  GeneratedDatabase tx, {
  required String deviceId,
  required String operatorName,
  required String preferences,
  Clock? clock,
}) async {
  final AppDatabase db = tx as AppDatabase;
  final DeviceProfileRow existing = await ensureDeviceProfile(
    tx,
    deviceId: deviceId,
    clock: clock,
  );
  final DateTime now = (clock ?? const SystemClock()).nowUtc();
  await (tx.update(
    db.deviceProfile,
  )..where(($DeviceProfileTable tbl) => tbl.id.equals(_rowId))).write(
    DeviceProfileCompanion(
      operatorName: Value<String>(operatorName),
      preferences: Value<String>(preferences),
      updatedAt: Value<DateTime>(now),
      updatedByDevice: Value<String>(deviceId),
      rev: Value<int>(existing.rev + 1),
    ),
  );
  return readDeviceProfile(tx, deviceId: deviceId, clock: clock);
}

/// The account this device's profile is enrolled as, or null before
/// enrolment. Records written here are attributed to it (§71.2).
Future<String?> enrolledAccountId(GeneratedDatabase tx) async {
  final AppDatabase db = tx as AppDatabase;
  final DeviceProfileRow? row = await _profileRow(db);
  return row?.accountId;
}

/// Attaches enrolment identity without rewriting the original operator or
/// records (§71.2): the profile gains [accountId], and this device's records
/// captured or approved before enrolment are annotated with it. Their
/// `capturedBy` and `approvedBy` stay exactly as they were.
Future<void> linkDeviceAccount(
  AppDatabase db, {
  required String deviceId,
  required String accountId,
  Clock? clock,
}) async {
  final Clock source = clock ?? const SystemClock();
  await db.transaction(() async {
    final DeviceProfileRow existing = await ensureDeviceProfile(
      db,
      deviceId: deviceId,
      clock: source,
    );
    if (existing.accountId != accountId) {
      await (db.update(
        db.deviceProfile,
      )..where(($DeviceProfileTable row) => row.id.equals(_rowId))).write(
        DeviceProfileCompanion(
          accountId: Value<String?>(accountId),
          updatedAt: Value<DateTime>(source.nowUtc()),
          updatedByDevice: Value<String>(deviceId),
          rev: Value<int>(existing.rev + 1),
        ),
      );
    }
    // A record captured here is stamped with the device id or the operator
    // name; a record merged in from another device carries neither.
    final List<String> operator = <String>[
      deviceId,
      if (existing.operatorName.trim().isNotEmpty) existing.operatorName,
    ];
    await (db.update(db.records)..where(
          ($RecordsTable row) =>
              row.capturedByAccount.isNull() & row.capturedBy.isIn(operator),
        ))
        .write(RecordsCompanion(capturedByAccount: Value<String?>(accountId)));
    await (db.update(db.records)..where(
          ($RecordsTable row) =>
              row.approvedByAccount.isNull() &
              row.approvedBy.isNotNull() &
              row.approvedBy.isIn(operator),
        ))
        .write(RecordsCompanion(approvedByAccount: Value<String?>(accountId)));
  });
}
