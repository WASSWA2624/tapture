import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/template_assets.dart';
import 'package:tapture/core/db/app_database.dart' hide TemplateRow;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/templates/data/shipped_template_loader.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';
import 'package:tapture/features/templates/domain/template_repository.dart';

void main() {
  late AppDatabase db;
  late TemplateRepositoryImpl repo;
  late ShippedTemplateLoader loader;

  final DateTime t0 = DateTime.utc(2026, 9, 20, 8);
  final FixedClock clock = FixedClock(t0);

  setUp(() {
    db = AppDatabase.memory();
    repo = TemplateRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'device-test',
      ids: UuidV7Service.sequence(clock),
    );
    loader = ShippedTemplateLoader(
      templates: repo,
      readAsset: (String path) => File(path).readAsString(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'library resolves inherited groups before a template is shown',
    () async {
      final List<TemplateDef> rows = _ok(await loader.library());
      expect(rows, hasLength(TemplateAssets.library.length));

      final TemplateDef generic = _named(rows, 'generic_item');
      expect(generic.projectId, isNull);
      expect(generic.source, 'shipped');
      expect(generic.version, 1);
      expect(generic.fields.length, greaterThan(10));
      expect(
        generic.fields
            .where(
              (FieldDef field) => const <String>{
                'item_identifier',
                'item_name',
                'description_raw',
                'description_refined',
                'quantity_counted',
                'unit_of_measure',
                'condition_grade',
                'status',
                'notes_raw',
                'notes_refined',
              }.contains(field.fieldKey),
            )
            .length,
        10,
      );
      expect(
        generic.fields.map((FieldDef field) => field.fieldKey),
        containsAll(<String>[
          'record_uid',
          'site_code',
          'caption_raw',
          'reviewed_date',
          'item_name',
        ]),
      );
      expect(generic.identityFieldKeys, <String>[
        'item_identifier',
        'item_name',
        'site_code',
      ]);
      expect(
        generic.fields.where((FieldDef field) => field.identity),
        hasLength(3),
      );
    },
  );

  test('a derived template keeps parent fields and its own extras', () async {
    final TemplateDef medical = _named(
      _ok(await loader.library()),
      'medical_equipment',
    );
    expect(
      medical.fields.map((FieldDef field) => field.fieldKey),
      containsAll(<String>['asset_tag', 'serial_number', 'device_type_name']),
    );
    expect(medical.kind, 'medical');
  });

  test(
    'copying writes a project-owned version 1 and leaves the asset',
    () async {
      final TemplateDef first = _ok(
        await loader.copyToProject(
          templateKey: 'generic_item',
          projectId: 'project-1',
          name: 'Site register',
        ),
      );
      expect(first.id, isNotEmpty);
      expect(first.projectId, 'project-1');
      expect(first.version, 1);
      expect(first.source, 'shipped');
      expect(first.name, 'Site register');
      expect(first.templateKey, 'generic_item');
      expect(
        first.fields.map((FieldDef field) => field.label),
        isNot(contains(startsWith('templates.'))),
      );
      expect(
        first.fields.map((FieldDef field) => field.fieldKey),
        contains('item_name'),
      );

      final TemplateDef library = _named(
        _ok(await loader.library()),
        'generic_item',
      );
      expect(library.projectId, isNull);
      expect(library.name, startsWith('templates.'));
      expect(library.fields.first.label, startsWith('templates.'));
      expect(
        await File(TemplateAssets.genericItem).readAsString(),
        contains('"generic_item"'),
      );
    },
  );

  test('editing one copy leaves the library and a second copy alone', () async {
    final TemplateDef first = _ok(
      await loader.copyToProject(
        templateKey: 'generic_item',
        projectId: 'project-1',
        name: 'First',
      ),
    );
    final TemplateDef second = _ok(
      await loader.copyToProject(
        templateKey: 'generic_item',
        projectId: 'project-1',
        name: 'Second',
      ),
    );
    expect(first.id, isNot(second.id));

    final TemplateDef edited = _ok(
      await repo.save(
        first.copyWith(
          fields: <FieldDef>[
            ...first.fields,
            const FieldDef(
              fieldKey: 'extra_note',
              label: 'Extra note',
              type: FieldType.text,
            ),
          ],
        ),
      ),
    );
    expect(
      edited.fields.map((FieldDef field) => field.fieldKey),
      contains('extra_note'),
    );

    final TemplateDef reloaded = _ok(await repo.byId(second.id))!;
    expect(reloaded.name, 'Second');
    expect(
      reloaded.fields.map((FieldDef field) => field.fieldKey),
      isNot(contains('extra_note')),
    );
    expect(reloaded.fields.length, first.fields.length);

    final TemplateDef library = _named(
      _ok(await loader.library()),
      'generic_item',
    );
    expect(
      library.fields.map((FieldDef field) => field.fieldKey),
      isNot(contains('extra_note')),
    );
  });

  test('a broken asset fails validation and writes nothing', () async {
    final ShippedTemplateLoader broken = ShippedTemplateLoader(
      templates: repo,
      readAsset: (String path) async {
        if (path == TemplateAssets.schema) {
          return File(path).readAsString();
        }
        if (path == TemplateAssets.groups) {
          return File(path).readAsString();
        }
        return '{"schema_version":2}';
      },
    );
    final Result<List<TemplateDef>> result = await broken.library();
    expect(result, isA<FailureResult<List<TemplateDef>>>());
    expect(await repo.watchByProject('project-1').first, isEmpty);
  });

  test('copying without a name fails and writes nothing', () async {
    final Result<TemplateDef> result = await loader.copyToProject(
      templateKey: 'generic_item',
      projectId: 'project-1',
      name: '   ',
    );
    expect(result, isA<FailureResult<TemplateDef>>());
    expect(await repo.watchByProject('project-1').first, isEmpty);
  });
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

TemplateDef _named(List<TemplateDef> rows, String key) {
  return rows.firstWhere((TemplateDef row) => row.templateKey == key);
}
