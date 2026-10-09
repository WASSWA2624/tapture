import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';
import 'package:tapture/features/templates/presentation/field_add_sheet.dart';
import 'package:tapture/features/templates/presentation/field_advanced_section.dart';
import 'package:tapture/features/templates/presentation/template_editor_source.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../../support/pump_external_work.dart';
import '../../projects/fakes/fake_project_repository.dart';
import '../fakes/fake_template_repository.dart';

void main() {
  testWidgets(
    'an unrelated validation edit retains an unavailable source through save and reopen',
    (WidgetTester tester) async {
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 9));
      final TemplateRepositoryImpl repository = TemplateRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: 'app-id',
        ids: UuidV7Service.sequence(clock),
      );
      final TemplateDef initial = _ok(
        await repository.save(
          aTemplate(
            fields: const <FieldDef>[
              FieldDef(
                fieldKey: 'address',
                label: 'Address',
                type: FieldType.text,
              ),
            ],
          ),
        ),
      );
      final Map<String, Object?> declaration = <String, Object?>{
        'provider': 'future',
        'raw': <Object?>[false, 42, null],
      };
      await db
          .update(db.templateFields)
          .write(
            TemplateFieldsCompanion(
              autoFill: const Value<bool>(true),
              validation: Value<String>(
                jsonEncode(<String, Object?>{
                  'minLength': 2,
                  '_tapture': <String, Object?>{
                    'autoFill': declaration,
                    'autoFillTop': null,
                  },
                }),
              ),
            ),
          );
      Future<void> open() async {
        await _pump(
          tester,
          templateId: initial.id,
          fieldKey: 'address',
          overrides: <Override>[
            templateRepositoryProvider.overrideWithValue(repository),
          ],
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(Copy.fieldAdvanced));
        await tester.tap(find.text(Copy.fieldAdvanced));
        await tester.pumpAndSettle();
      }

      await open();
      final Finder minimum = find.byWidgetPredicate(
        (Widget widget) =>
            widget is AppTextField && widget.label == Copy.fieldMinLength,
      );
      await tester.ensureVisible(minimum);
      await tester.enterText(
        find.descendant(of: minimum, matching: find.byType(TextField)),
        '3',
      );
      await tester.pump();
      await _saveCompoundField(
        tester,
        repository: repository,
        initial: initial,
      );
      final TemplateDef loaded = await _reload(
        tester,
        repository,
        initial.id,
        db,
      );
      expect(loaded.fields.single.autoFill, isNull);
      expect(loaded.fields.single.validation, <String, Object?>{
        'minLength': 3,
        '_tapture': <String, Object?>{
          'autoFill': declaration,
          'autoFillTop': null,
        },
      });
      expect(
        TemplateVersioning.shapeFor(
          loaded,
          initial.version,
        )!.fields.single.validation['_tapture'],
        <String, Object?>{'autoFill': declaration, 'autoFillTop': null},
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await open();
      final Finder source = find.byWidgetPredicate(
        (Widget widget) =>
            widget is AppChoiceField<String> &&
            widget.label == Copy.fieldAutoFill,
      );
      expect(
        tester.widget<AppChoiceField<String>>(source).value,
        'unavailable',
      );
      expect(tester.widget<AppTextField>(minimum).controller.text, '3');
      await pumpExternalFutures(tester, <Future<Object?>>[db.close()]);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  for (final AutoFill? selected in <AutoFill?>[null, AutoFill.localAddress]) {
    testWidgets(
      'an explicit ${selected?.name ?? 'None'} replaces opaque source metadata durably',
      (WidgetTester tester) async {
        final AppDatabase db = AppDatabase.memory();
        addTearDown(db.close);
        final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 9));
        final TemplateRepositoryImpl repository = TemplateRepositoryImpl(
          db: db,
          clock: clock,
          deviceId: 'app-id',
          ids: UuidV7Service.sequence(clock),
        );
        final TemplateDef initial = _ok(
          await repository.save(
            aTemplate(
              fields: const <FieldDef>[
                FieldDef(
                  fieldKey: 'address',
                  label: 'Address',
                  type: FieldType.text,
                ),
              ],
            ),
          ),
        );
        await db
            .update(db.templateFields)
            .write(
              const TemplateFieldsCompanion(
                autoFill: Value<bool>(true),
                validation: Value<String>(
                  '{"_tapture":{"autoFill":"FUTURE_SOURCE","autoFillTop":"FUTURE_TOP"}}',
                ),
              ),
            );
        await _pump(
          tester,
          templateId: initial.id,
          fieldKey: 'address',
          overrides: <Override>[
            templateRepositoryProvider.overrideWithValue(repository),
          ],
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(Copy.fieldAdvanced));
        await tester.tap(find.text(Copy.fieldAdvanced));
        await tester.pumpAndSettle();
        final Finder source = find.byWidgetPredicate(
          (Widget widget) =>
              widget is AppChoiceField<String> &&
              widget.label == Copy.fieldAutoFill,
        );
        expect(
          tester.widget<AppChoiceField<String>>(source).value,
          'unavailable',
        );
        await tester.ensureVisible(source);
        await tester.tap(source);
        await tester.pumpAndSettle();
        if (selected != null) {
          await tester.enterText(
            find.descendant(
              of: find.byType(AppSearchField),
              matching: find.byType(TextField),
            ),
            Copy.fieldAutoFillLocalAddress,
          );
          await tester.pumpAndSettle();
        }
        await tester.tap(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is AppListTile &&
                widget.title ==
                    (selected == null
                        ? Copy.fieldAutoFillNone
                        : Copy.fieldAutoFillLocalAddress),
          ),
        );
        await tester.pumpAndSettle();
        await _saveCompoundField(
          tester,
          repository: repository,
          initial: initial,
        );
        final TemplateDef loaded = await _reload(
          tester,
          repository,
          initial.id,
          db,
        );
        expect(loaded.fields.single.autoFill, selected);
        expect(
          loaded.fields.single.validation.containsKey('_tapture'),
          isFalse,
        );
        final Future<TemplateField> readRow = db
            .select(db.templateFields)
            .getSingle();
        await pumpExternalFutures(tester, <Future<Object?>>[readRow]);
        final TemplateField row = await readRow;
        expect(row.autoFill, selected != null);
        expect(
          jsonDecode(row.validation),
          selected == null
              ? <String, Object?>{}
              : <String, Object?>{
                  '_tapture': <String, Object?>{'autoFill': 'LOCAL_ADDRESS'},
                },
        );
        expect(
          TemplateVersioning.shapeFor(
            loaded,
            initial.version,
          )!.fields.single.validation['_tapture'],
          <String, Object?>{
            'autoFill': 'FUTURE_SOURCE',
            'autoFillTop': 'FUTURE_TOP',
          },
        );
        await pumpExternalFutures(tester, <Future<Object?>>[db.close()]);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
  testWidgets(
    'Advanced explains source choices and clearing a configured source persists None in a new version',
    (WidgetTester tester) async {
      final AppDatabase db = AppDatabase.memory();
      addTearDown(db.close);
      final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 9));
      final TemplateRepositoryImpl repository = TemplateRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: 'app-id',
        ids: UuidV7Service.sequence(clock),
      );
      final TemplateDef initial = _ok(
        await repository.save(
          aTemplate(
            fields: const <FieldDef>[
              FieldDef(
                fieldKey: 'service_date',
                label: 'Service date',
                type: FieldType.date,
                autoFill: AutoFill.today,
              ),
            ],
          ),
        ),
      );
      await _pump(
        tester,
        templateId: initial.id,
        fieldKey: 'service_date',
        overrides: <Override>[
          templateRepositoryProvider.overrideWithValue(repository),
        ],
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(Copy.fieldAdvanced));
      await tester.tap(find.text(Copy.fieldAdvanced));
      await tester.pumpAndSettle();
      expect(find.text(Copy.fieldSourceHelp), findsOneWidget);
      expect(find.text(Copy.captureTemperatureUnavailable), findsOneWidget);
      final Finder source = find.byWidgetPredicate(
        (Widget widget) =>
            widget is AppChoiceField<String> &&
            widget.label == Copy.fieldAutoFill,
      );
      await tester.ensureVisible(source);
      await tester.tap(source);
      await tester.pumpAndSettle();
      await tester.tap(find.text(Copy.fieldAutoFillNone));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(AppPrimaryAction));
      await tester.tap(find.byType(AppPrimaryAction));
      await tester.pumpAndSettle();
      final TemplateDef reloaded = _ok(await repository.byId(initial.id))!;
      expect(reloaded.fields.single.autoFill, isNull);
      expect(reloaded.version, initial.version + 1);
      expect(
        TemplateVersioning.shapeFor(
          reloaded,
          initial.version,
        )?.fields.single.autoFill,
        AutoFill.today,
      );
      expect(
        (await db.select(db.templateFields).get()).single.autoFill,
        isFalse,
      );
      final Future<void> closed = db.close();
      await tester.pumpAndSettle();
      await closed;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
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
        templateEditorSourceProvider.overrideWith(
          (Ref _, String _) =>
              Stream<List<TemplateDef>>.value(const <TemplateDef>[]),
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
        templateEditorSourceProvider.overrideWith(
          (Ref _, String _) => Stream<List<TemplateDef>>.error(
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

  testWidgets('editing a lookup field offers Bind to dataset, which opens the '
      'binding', (WidgetTester tester) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    final TemplateDef stored = _ok(
      await templates.save(
        aTemplate(
          name: 'Equipment',
          fields: const <FieldDef>[
            FieldDef(
              fieldKey: 'supplier',
              label: 'Supplier',
              type: FieldType.lookup,
            ),
          ],
        ),
      ),
    );
    final FakeProjectRepository projects = FakeProjectRepository();
    addTearDown(projects.dispose);
    _ok(await projects.create(aProject()));
    final GoRouter router = GoRouter(
      initialLocation: RoutePaths.templateField(stored.id, 'supplier'),
      routes: <RouteBase>[
        GoRoute(
          path: '${RoutePaths.templates}/:templateId/fields/:fieldKey',
          builder: (BuildContext _, GoRouterState state) => FieldAddSheet(
            templateId: state.pathParameters['templateId']!,
            fieldKey: state.pathParameters['fieldKey'],
          ),
          routes: <RouteBase>[
            GoRoute(
              path: 'lookup',
              builder: (BuildContext _, GoRouterState _) =>
                  const Text('lookup-route'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        retry: (int _, Object _) => null,
        overrides: <Override>[
          projectRepositoryProvider.overrideWith((Ref _) => projects),
          projectSettingsStoreProvider.overrideWith(
            (Ref _) => SettingsStore.fake(
              stored: <String, Object?>{
                SettingKeys.openProjectId.name: 'project-1',
              },
            ),
          ),
          templateRepositoryProvider.overrideWith((Ref _) => templates),
        ],
        child: MaterialApp.router(
          theme: buildTheme(brightness: Brightness.light),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(Copy.templatesBindDataset));
    await tester.pumpAndSettle();

    expect(find.text('lookup-route'), findsOneWidget);
  });
}

Future<void> _saveCompoundField(
  WidgetTester tester, {
  required TemplateRepository repository,
  required TemplateDef initial,
}) async {
  final Future<TemplateDef> saved =
      (initial.projectId == null
              ? repository.watchLibrary()
              : repository.watchByProject(initial.projectId!))
          .map(
            (List<TemplateDef> templates) => templates.singleWhere(
              (TemplateDef value) => value.id == initial.id,
            ),
          )
          .firstWhere((TemplateDef value) => value.version > initial.version);
  await tester.ensureVisible(find.byType(AppPrimaryAction));
  await tester.tap(find.byType(AppPrimaryAction));
  await tester.pumpAndSettle();
  expect(find.text(Copy.fieldKeepAnyway), findsOneWidget);
  await tester.ensureVisible(find.text(Copy.fieldKeepAnyway));
  await tester.tap(find.text(Copy.fieldKeepAnyway));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byType(AppPrimaryAction));
  await tester.tap(find.byType(AppPrimaryAction));
  await pumpExternalFutures(tester, <Future<Object?>>[saved]);
  expect((await saved).version, initial.version + 1);
}

Future<TemplateDef> _reload(
  WidgetTester tester,
  TemplateRepository repository,
  String id,
  AppDatabase db,
) async {
  final Future<List<Template>> headers = db.select(db.templates).get();
  final Future<List<Tombstone>> tombstones = db.select(db.tombstones).get();
  await pumpExternalFutures(tester, <Future<Object?>>[headers, tombstones]);
  expect((await headers).map((Template row) => row.id), contains(id));
  expect(
    (await tombstones).where(
      (Tombstone row) => row.entityType == 'templates' && row.entityId == id,
    ),
    isEmpty,
  );
  final Future<Result<TemplateDef?>> read = repository.byId(id);
  await pumpExternalFutures(tester, <Future<Object?>>[read]);
  final TemplateDef? value = _ok(await read);
  expect(
    value,
    isNotNull,
    reason: 'Existing SQL header $id must resolve through its real repository.',
  );
  return value!;
}

Future<void> _pump(
  WidgetTester tester, {
  List<Override> overrides = const <Override>[],
  String templateId = 'template-1',
  String? fieldKey,
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
        home: FieldAddSheet(templateId: templateId, fieldKey: fieldKey),
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
