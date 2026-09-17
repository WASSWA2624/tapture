import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/columns.dart';
import 'package:tapture/core/time/clock.dart';

/// Well-known merge id so this table holds exactly one row.
const String _rowId = 'local';

/// The one device-local profile: identity, operator name and preferences.
@DataClassName('DeviceProfileRow')
class DeviceProfile extends Table with MergeColumns {
  /// Stable device identifier minted by [deviceId].
  TextColumn get deviceId => text()();

  /// Display name of the operator on this device.
  TextColumn get operatorName => text().withDefault(const Constant(''))();

  /// Preferences JSON. An object, stored as text.
  TextColumn get preferences => text().withDefault(const Constant('{}'))();
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
