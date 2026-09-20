import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart' hide TemplateRow;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';
import 'package:tapture/features/templates/domain/template_repository.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../fakes/fake_template_repository.dart';

void main() {
  group('in-memory database', () {
    late AppDatabase db;
    late TemplateRepositoryImpl repo;

    setUp(() {
      final DateTime t0 = DateTime.utc(2026, 9, 20, 8);
      final FixedClock clock = FixedClock(t0);
      db = AppDatabase.memory();
      repo = TemplateRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: 'device-test',
        ids: UuidV7Service.sequence(clock),
      );
    });

    tearDown(() async {
      await db.close();
    });

    _runImportSuite(() => repo);
  });

  group('fake', () {
    late FakeTemplateRepository repo;

    setUp(() {
      repo = FakeTemplateRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    _runImportSuite(() => repo);
  });
}

void _runImportSuite(TemplateRepository Function() create) {
  test('imported rows keep spreadsheet lines and match BP machine', () async {
    final TemplateRepository templates = create();
    final TemplateDef template = _ok(await templates.save(aTemplate()));
    final List<TemplateRow> drafted = PredefinedRowsImport.draft(
      rows: _sheet(),
      headerRow: 1,
      identifierColumn: 'A',
      labelColumn: 'B',
      aliasColumn: 'C',
      contextColumn: 'D',
    );

    expect(drafted, hasLength(1));
    expect(drafted.single.identifier, 'm-1');
    expect(drafted.single.label, 'Blood Pressure Machine');
    expect(drafted.single.outputRowNumber, 12);
    expect(drafted.single.aliases, <String>['BP machine']);
    expect(drafted.single.metadata['context'], 'Ward 2');

    final TemplateDef saved = _ok(
      await PredefinedRowsImport(
        templates,
      ).apply(template: template, rows: drafted),
    );
    expect(saved.rows.single.outputRowNumber, 12);
    expect(
      PredefinedRowsImport.match(saved.rows, 'BP machine')?.label,
      'Blood Pressure Machine',
    );

    final TemplateDef? loaded = _ok(await templates.byId(saved.id));
    expect(loaded, isNotNull);
    expect(loaded!.rows.single.outputRowNumber, 12);
    expect(
      PredefinedRowsImport.match(loaded.rows, 'bp machine')?.identifier,
      'm-1',
    );
  });

  test('aliases from a column land on the same spreadsheet line', () async {
    final TemplateRepository templates = create();
    final List<TemplateRow> drafted = PredefinedRowsImport.draft(
      rows: _sheet(alias: ''),
      headerRow: 1,
      identifierColumn: 'A',
      labelColumn: 'B',
    );
    final TemplateDef template = _ok(
      await templates.save(aTemplate(rows: drafted)),
    );
    final List<TemplateRow> merged = PredefinedRowsImport.mergeAliases(
      rows: template.rows,
      sheet: _sheet(),
      aliasColumn: 'C',
    );
    final TemplateDef saved = _ok(
      await PredefinedRowsImport(
        templates,
      ).apply(template: template, rows: merged),
    );

    expect(saved.rows.single.outputRowNumber, 12);
    expect(saved.rows.single.aliases, <String>['BP machine']);
    expect(
      PredefinedRowsImport.match(saved.rows, 'BP machine')?.label,
      'Blood Pressure Machine',
    );
  });
}

List<List<String>> _sheet({String alias = 'BP machine'}) {
  return <List<String>>[
    <String>['ID', 'Name', 'Also called', 'Room'],
    for (int i = 0; i < 10; i++) <String>['', '', '', ''],
    <String>['m-1', 'Blood Pressure Machine', alias, 'Ward 2'],
  ];
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
