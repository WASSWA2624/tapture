import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/template_fields.dart';
import 'package:tapture/core/db/tables/templates.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  late AppDatabase db;
  late UuidV7Service ids;
  late String templateId;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);

  setUp(() async {
    db = AppDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
    templateId = _ok(
      await upsertTemplate(
        db,
        row: const TemplatesCompanion(
          name: Value<String>('Fields'),
          kind: Value<String>('item'),
          source: Value<String>('shipped'),
        ),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    ).id;
  });

  tearDown(() async {
    await db.close();
  });

  test('a duplicate fieldKey is refused by the unique index', () async {
    _ok(
      await upsertTemplateField(
        db,
        row: _field(
          templateId: templateId,
          fieldKey: 'serial',
          label: 'Serial',
          sortOrder: 1,
        ),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );

    final Result<TemplateField> duplicate = await upsertTemplateField(
      db,
      row: _field(
        templateId: templateId,
        fieldKey: 'serial',
        label: 'Serial copy',
        sortOrder: 2,
      ),
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: ids,
    );
    late StorageFailure failure;
    duplicate.fold((Failure value) {
      failure = value as StorageFailure;
    }, (_) => fail('expected a uniqueness failure'));
    expect(failure.message, contains('already exists'));
    expect(failure.recoveryAction, isNotEmpty);

    final List<TemplateField> rows = _ok(
      await listTemplateFields(db, templateId: templateId),
    );
    expect(rows, hasLength(1));
  });

  test('fields read in sortOrder then label', () async {
    _ok(
      await upsertTemplateField(
        db,
        row: _field(
          templateId: templateId,
          fieldKey: 'z',
          label: 'Zed',
          sortOrder: 2,
        ),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    _ok(
      await upsertTemplateField(
        db,
        row: _field(
          templateId: templateId,
          fieldKey: 'b',
          label: 'Beta',
          sortOrder: 1,
        ),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    _ok(
      await upsertTemplateField(
        db,
        row: _field(
          templateId: templateId,
          fieldKey: 'a',
          label: 'Alpha',
          sortOrder: 1,
        ),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );

    final List<String> keys = _ok(
      await listTemplateFields(db, templateId: templateId),
    ).map((TemplateField row) => row.fieldKey).toList();
    expect(keys, <String>['a', 'b', 'z']);
  });

  test(
    'version 4 creates the template_fields table with merge columns',
    () async {
      await db.close();
      final Directory directory = Directory.systemTemp.createTempSync(
        'tapture_template_fields_',
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
        await _columns(upgraded, 'template_fields'),
        containsAll(<String>[
          'id',
          'created_at',
          'updated_at',
          'updated_by_device',
          'rev',
          'template_id',
          'field_key',
          'label',
          'type',
          'output_column',
          'required',
          'input_mode',
          'stickable',
          'context_level',
          'auto_fill',
          'default_value',
          'options',
          'unit',
          'validation',
          'lookup',
          'refine',
          'sort_order',
        ]),
      );
    },
  );
}

TemplateFieldsCompanion _field({
  required String templateId,
  required String fieldKey,
  required String label,
  required int sortOrder,
}) {
  return TemplateFieldsCompanion(
    templateId: Value<String>(templateId),
    fieldKey: Value<String>(fieldKey),
    label: Value<String>(label),
    type: const Value<String>('text'),
    sortOrder: Value<int>(sortOrder),
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
