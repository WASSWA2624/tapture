import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;

/// Who produces an export: the operator named in this device's profile, as
/// the project package's manifest names them, or [fallback] (the device id)
/// before a name is set. Every export row records it, so a file can be
/// traced to a person months later (task 018 step 15).
Future<String> exportOperator(
  sqlite.AppDatabase db, {
  required String fallback,
}) async {
  final List<QueryRow> rows = await db
      .customSelect('SELECT operator_name FROM device_profile LIMIT 1')
      .get();
  final String name = rows.isEmpty
      ? ''
      : (rows.single.data['operator_name'] as String? ?? '').trim();
  return name.isEmpty ? fallback : name;
}
