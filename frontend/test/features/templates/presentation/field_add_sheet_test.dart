import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';
import 'package:tapture/features/templates/presentation/field_add_sheet.dart';
import 'package:tapture/features/templates/presentation/field_advanced_section.dart';
import 'package:tapture/features/templates/presentation/template_list_screen.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../projects/fakes/fake_project_repository.dart';
import '../fakes/fake_template_repository.dart';

void main() {
  test('keyFrom writes snake_case and appends a unit', () {
    expect(FieldAddSheet.keyFrom('Serial number'), 'serial_number');
    expect(FieldAddSheet.keyFrom('Length', unit: 'mm'), 'length_mm');
    expect(FieldAddSheet.keyFrom('  '), 'field');
    expect(FieldAddSheet.keyFrom('2019'), 'field_2019');
  });

  test('uniqueKey handles a collision without renaming the kept key', () {
    expect(
      FieldAddSheet.uniqueKey('serial', const <String>['serial', 'name']),
      'serial_2',
    );
    expect(
      FieldAddSheet.uniqueKey('serial', const <String>[
        'serial',
        'serial_2',
      ], keep: 'serial'),
      'serial',
    );
  });

  test('packsTwoFacts matches the §13.1 checker', () {
    expect(FieldAddSheet.packsTwoFacts('Make / Model'), isTrue);
    expect(FieldAddSheet.packsTwoFacts('Address'), isTrue);
    expect(FieldAddSheet.packsTwoFacts('Serial number'), isFalse);
  });

  test('required_when naming an unknown field is refused', () {
    final Result<void> unknown = FieldAdvancedSection.validateRequiredWhen(
      'missing_flag == true',
      const <String>['fault_present'],
    );
    expect(unknown, isA<FailureResult<void>>());
    final Result<void> known = FieldAdvancedSection.validateRequiredWhen(
      'fault_present == true',
      const <String>['fault_present'],
    );
    expect(known, isA<Success<void>>());
    expect(
      FieldAdvancedSection.validateRequiredWhen('true', const <String>[]),
      isA<Success<void>>(),
    );
    expect(
      FieldAdvancedSection.previewRequiredWhen(
        'fault_present == true',
        const <String, String>{'fault_present': 'Fault present'},
      ),
      'Required when Fault present is yes',
    );
  });

  test(
    'hiding a field leaves captured values and unhide brings them back',
    () async {
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      final DateTime t0 = DateTime.utc(2026, 9, 20, 8);
      final FixedClock clock = FixedClock(t0);
      final TemplateRepositoryImpl templates = TemplateRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: 'device-test',
        ids: UuidV7Service.sequence(clock),
      );
      const FieldDef serial = FieldDef(
        fieldKey: 'serial',
        label: 'Serial',
        type: FieldType.text,
      );
      final TemplateDef stored = _ok(
        await templates.save(aTemplate(fields: const <FieldDef>[serial])),
      );
      final String recordId = _ok(
        await upsertRecord(
          db,
          row: RecordsCompanion(
            projectId: const Value<String>('project-1'),
            templateId: Value<String>(stored.id),
            status: const Value<String>('captured'),
            processingMode: const Value<String>('manual'),
            contextJson: const Value<String>('{}'),
            identityHash: const Value<String>('h1'),
            source: const Value<String>('capture'),
            capturedAt: Value<DateTime>(t0),
            capturedBy: const Value<String>('Ada'),
          ),
          clock: clock,
          deviceId: 'device-test',
          ids: UuidV7Service.sequence(clock),
        ),
      ).id;
      final RecordField value = _ok(
        await insertRecordField(
          db,
          row: RecordFieldsCompanion(
            recordId: Value<String>(recordId),
            fieldKey: const Value<String>('serial'),
            valueRaw: const Value<String>('A-1'),
            source: const Value<String>('typed'),
          ),
          clock: clock,
          deviceId: 'device-test',
          ids: UuidV7Service.sequence(clock),
        ),
      );

      final TemplateDef hidden = _ok(
        await templates.save(
          FieldAddSheet.setHidden(stored, fieldKey: 'serial', hidden: true),
        ),
      );
      expect(hidden.fields.single.hidden, isTrue);
      expect(FieldAddSheet.visibleKeys(hidden.fields), isEmpty);
      expect((await db.select(db.recordFields).get()).single.id, value.id);
      expect((await db.select(db.recordFields).get()).single.valueRaw, 'A-1');

      final TemplateDef shown = _ok(
        await templates.save(
          FieldAddSheet.setHidden(hidden, fieldKey: 'serial', hidden: false),
        ),
      );
      expect(shown.fields.single.hidden, isFalse);
      expect(FieldAddSheet.visibleKeys(shown.fields), <String>['serial']);
      expect((await db.select(db.recordFields).get()).single.valueRaw, 'A-1');
    },
  );

  testWidgets('a missing template renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      overrides: <Override>[
        templateListProvider.overrideWith(
          (Ref _) => Stream<List<TemplateDef>>.value(const <TemplateDef>[]),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.fieldAddEmptyHeadline), findsOneWidget);
    expect(find.text(Copy.fieldAddEmptyMessage), findsOneWidget);
  });

  testWidgets('a failed load renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      overrides: <Override>[
        templateListProvider.overrideWith(
          (Ref _) => Stream<List<TemplateDef>>.error(
            const StorageFailure(
              message: 'The field could not be read.',
              recoveryAction: 'Try again.',
            ),
          ),
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('The field could not be read.'), findsOneWidget);
  });

  testWidgets('a failed save renders on the form', (WidgetTester tester) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    final TemplateDef stored = _ok(
      await templates.save(aTemplate(name: 'Assets')),
    );
    templates.saveFailure = const StorageFailure(
      message: 'The field could not be saved on this device.',
      recoveryAction: 'Free space, then try again.',
    );
    await _pump(
      tester,
      templateId: stored.id,
      overrides: <Override>[
        templateRepositoryProvider.overrideWith((Ref _) => templates),
      ],
      openProject: true,
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Serial');
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump();

    expect(
      find.text('The field could not be saved on this device.'),
      findsOneWidget,
    );
    expect(_ok(await templates.byId(stored.id))!.fields, isEmpty);
  });

  testWidgets('a field lands optional unless the operator says otherwise', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    final TemplateDef stored = _ok(
      await templates.save(aTemplate(name: 'Assets')),
    );
    await _pump(
      tester,
      templateId: stored.id,
      overrides: <Override>[
        templateRepositoryProvider.overrideWith((Ref _) => templates),
      ],
      openProject: true,
    );
    await tester.pumpAndSettle();

    expect(find.text(Copy.fieldAdvanced), findsOneWidget);
    expect(find.text(Copy.fieldValidationTitle), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'Serial');
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pumpAndSettle();

    final List<FieldDef> fields = _ok(await templates.byId(stored.id))!.fields;
    expect(fields, hasLength(1));
    expect(fields.single.fieldKey, 'serial');
    expect(fields.single.label, 'Serial');
    expect(fields.single.requiredness, Requiredness.optional);
    expect(fields.single.type, FieldType.text);
  });

  testWidgets('a two-fact label is questioned once and can still be kept', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    final TemplateDef stored = _ok(
      await templates.save(aTemplate(name: 'Assets')),
    );
    await _pump(
      tester,
      templateId: stored.id,
      overrides: <Override>[
        templateRepositoryProvider.overrideWith((Ref _) => templates),
      ],
      openProject: true,
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Make / Model');
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump();

    expect(find.text(Copy.fieldTwoFactsWarning), findsWidgets);
    expect(find.text(Copy.fieldKeepAnyway), findsOneWidget);
    expect(_ok(await templates.byId(stored.id))!.fields, isEmpty);

    await tester.tap(find.text(Copy.fieldKeepAnyway));
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pumpAndSettle();

    final List<FieldDef> fields = _ok(await templates.byId(stored.id))!.fields;
    expect(fields, hasLength(1));
    expect(fields.single.label, 'Make / Model');
    expect(fields.single.requiredness, Requiredness.optional);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  List<Override> overrides = const <Override>[],
  String templateId = 'template-1',
  bool openProject = false,
}) async {
  final FakeProjectRepository projects = FakeProjectRepository();
  addTearDown(projects.dispose);
  if (openProject) {
    _ok(await projects.create(aProject()));
  }
  final SettingsStore store = SettingsStore.fake(
    stored: <String, Object?>{
      if (openProject) SettingKeys.openProjectId.name: 'project-1',
    },
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        projectRepositoryProvider.overrideWith((Ref _) => projects),
        projectSettingsStoreProvider.overrideWith((Ref _) => store),
        ...overrides,
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: FieldAddSheet(templateId: templateId),
      ),
    ),
  );
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
