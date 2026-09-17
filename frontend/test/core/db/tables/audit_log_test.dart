import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  late AppDatabase db;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  test('an update writes one audit row with previous and new values', () async {
    await db.transaction(() async {
      await appendAudit(
        db,
        entityType: 'records',
        entityId: 'r1',
        action: AuditAction.updated,
        fieldKey: 'name',
        previousValue: 'old',
        newValue: 'new',
        clock: FixedClock(t0),
        device: 'device-a',
        operator: 'Ada',
      );
    });

    final List<AuditLogData> rows = await db.select(db.auditLog).get();
    expect(rows, hasLength(1));
    expect(rows.single.previousValue, 'old');
    expect(rows.single.newValue, 'new');
    expect(rows.single.fieldKey, 'name');
    expect(rows.single.action, AuditAction.updated);
    expect(rows.single.device, 'device-a');
    expect(rows.single.operator, 'Ada');
  });

  test('version 2 creates the audit_log table with merge columns', () async {
    await db.close();
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture_audit_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    final File seed = File('${directory.path}/tapture.sqlite');
    _seedVersion1(seed);

    final AppDatabase upgraded = AppDatabase.open(
      directoryPath: directory.path,
    );
    addTearDown(upgraded.close);
    await upgraded.customSelect('SELECT 1').get();

    final Set<String> columns = await _columns(upgraded, 'audit_log');
    expect(
      columns,
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'entity_type',
        'entity_id',
        'action',
        'field_key',
        'previous_value',
        'new_value',
        'reason',
        'operator',
        'device',
        'at',
      ]),
    );
  });
}

void _seedVersion1(File file) {
  file.parent.createSync(recursive: true);
  final Database database = sqlite3.open(file.path);
  database.execute('PRAGMA user_version = 1');
  database.dispose();
}

Future<Set<String>> _columns(AppDatabase db, String table) async {
  final List<QueryRow> info = await db
      .customSelect('PRAGMA table_info("$table")')
      .get();
  return <String>{for (final QueryRow row in info) row.read<String>('name')};
}
