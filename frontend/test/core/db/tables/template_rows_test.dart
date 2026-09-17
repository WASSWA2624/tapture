import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/template_rows.dart';
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
          name: Value<String>('Rows'),
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

  test('alias lookup finds a row by a local name', () async {
    final TemplateRow written = _ok(
      await upsertTemplateRow(
        db,
        row: TemplateRowsCompanion(
          templateId: Value<String>(templateId),
          outputRowNumber: const Value<int>(12),
          identifier: const Value<String>('bp-1'),
          label: const Value<String>('Blood Pressure Machine'),
          aliases: Value<String>(jsonEncode(<String>['BP machine'])),
        ),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );

    final TemplateRow? byAlias = _ok(
      await lookupTemplateRow(db, templateId: templateId, query: 'BP machine'),
    );
    expect(byAlias?.id, written.id);

    final TemplateRow? byLabel = _ok(
      await lookupTemplateRow(
        db,
        templateId: templateId,
        query: 'Blood Pressure Machine',
      ),
    );
    expect(byLabel?.id, written.id);

    expect(
      _ok(
        await lookupTemplateRow(db, templateId: templateId, query: 'unknown'),
      ),
      isNull,
    );
  });

  test(
    'version 4 creates the template_rows table with merge columns',
    () async {
      await db.close();
      final Directory directory = Directory.systemTemp.createTempSync(
        'tapture_template_rows_',
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
        await _columns(upgraded, 'template_rows'),
        containsAll(<String>[
          'id',
          'created_at',
          'updated_at',
          'updated_by_device',
          'rev',
          'template_id',
          'output_row_number',
          'identifier',
          'label',
          'aliases',
          'metadata',
          'found_status',
        ]),
      );
    },
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
