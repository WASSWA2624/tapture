import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/template_fields.dart';
import 'package:tapture/core/db/tables/template_rows.dart';
import 'package:tapture/core/db/tables/templates.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  late AppDatabase db;
  late UuidV7Service ids;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);
  final DateTime t1 = t0.add(const Duration(seconds: 2));

  setUp(() {
    db = AppDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
  });

  tearDown(() async {
    await db.close();
  });

  test('header insert, version bump and a shipped template coexist', () async {
    final Template shipped = _ok(
      await upsertTemplate(
        db,
        row: _header(name: 'Equipment', kind: 'equipment'),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    expect(shipped.projectId, isNull);
    expect(shipped.version, 1);

    final Template scoped = _ok(
      await upsertTemplate(
        db,
        row: _header(name: 'Clinic kit', kind: 'equipment', projectId: 'p1'),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    expect(scoped.projectId, 'p1');

    final Template bumped = _ok(
      await upsertTemplate(
        db,
        row: TemplatesCompanion(
          id: Value<String>(shipped.id),
          name: const Value<String>('Equipment v2'),
        ),
        clock: FixedClock(t1),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    expect(bumped.version, 2);
    expect(bumped.name, 'Equipment v2');

    final List<Template> rows = await db.select(db.templates).get();
    expect(rows, hasLength(2));
    expect(rows.where((Template row) => row.projectId == null), hasLength(1));
    expect(rows.where((Template row) => row.projectId == 'p1'), hasLength(1));
  });

  test('a template with fields and rows round-trips', () async {
    final Template header = _ok(
      await upsertTemplate(
        db,
        row: _header(name: 'Meters', kind: 'meter'),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    final TemplateField field = _ok(
      await upsertTemplateField(
        db,
        row: TemplateFieldsCompanion(
          templateId: Value<String>(header.id),
          fieldKey: const Value<String>('serial'),
          label: const Value<String>('Serial'),
          type: const Value<String>('text'),
          sortOrder: const Value<int>(1),
        ),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    final TemplateRow row = _ok(
      await upsertTemplateRow(
        db,
        row: TemplateRowsCompanion(
          templateId: Value<String>(header.id),
          outputRowNumber: const Value<int>(4),
          identifier: const Value<String>('m-1'),
          label: const Value<String>('Meter 1'),
          aliases: Value<String>(jsonEncode(<String>['M1'])),
        ),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );

    final List<TemplateField> fields = _ok(
      await listTemplateFields(db, templateId: header.id),
    );
    expect(fields.single.id, field.id);
    expect(fields.single.fieldKey, 'serial');

    final TemplateRow? found = _ok(
      await lookupTemplateRow(db, templateId: header.id, query: 'M1'),
    );
    expect(found?.id, row.id);
    expect(found?.outputRowNumber, 4);
  });

  test('version 4 creates the templates table with merge columns', () async {
    await db.close();
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture_templates_',
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

    expect(
      await _columns(upgraded, 'templates'),
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'project_id',
        'name',
        'kind',
        'source',
        'source_file_path',
        'sheet_name',
        'header_row',
        'identity_fields',
        'detection',
        'version',
      ]),
    );
  });
}

TemplatesCompanion _header({
  required String name,
  required String kind,
  String? projectId,
}) {
  return TemplatesCompanion(
    projectId: Value<String?>(projectId),
    name: Value<String>(name),
    kind: Value<String>(kind),
    source: const Value<String>('shipped'),
  );
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

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
