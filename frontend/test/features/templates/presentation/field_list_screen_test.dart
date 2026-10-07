import 'package:tapture/features/templates/presentation/template_editor_source.dart';
import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/database_provider.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/db/tables/template_fields.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/presentation/field_list_filter.dart';
import 'package:tapture/features/templates/presentation/field_list_screen.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../../support/pump_external_work.dart';
import '../../projects/fakes/fake_project_repository.dart';
import '../fakes/fake_template_repository.dart';

void main() {
  testWidgets('loading renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    final StreamController<List<TemplateDef>> pending =
        StreamController<List<TemplateDef>>();
    addTearDown(pending.close);
    await _pump(
      tester,
      overrides: <Override>[
        templateEditorSourceProvider.overrideWith(
          (Ref _, String _) => pending.stream,
        ),
      ],
    );
    await tester.pump();

    expect(find.byType(AppSkeleton), findsOneWidget);
  });

  testWidgets('an empty field list renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      overrides: <Override>[
        templateEditorSourceProvider.overrideWith(
          (Ref _, String _) => Stream<List<TemplateDef>>.value(<TemplateDef>[
            aTemplate(name: 'Assets'),
          ]),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.templatesFieldsEmptyHeadline), findsOneWidget);
    expect(find.text(Copy.templatesFieldsEmptyMessage), findsOneWidget);
    expect(find.text(Copy.templatesAddField), findsNWidgets(2));
    expect(find.byType(AppPrimaryAction), findsOneWidget);

    await tester.tap(find.text(Copy.templatesAddField).first);
    await tester.pumpAndSettle();
    expect(find.text('add'), findsOneWidget);
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
              message: 'The field list could not be read.',
              recoveryAction: 'Try again.',
            ),
          ),
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('The field list could not be read.'), findsOneWidget);
  });

  testWidgets('offline renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      overrides: <Override>[
        templateEditorSourceProvider.overrideWith(
          (Ref _, String _) =>
              Stream<List<TemplateDef>>.error(const NetworkFailure()),
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(const NetworkFailure().message), findsOneWidget);
  });

  testWidgets(
    'deletion recounts live stored values after a cancelled warning',
    (WidgetTester tester) async {
      final _StoredField fixture = await _seedStoredField(tester);
      await _pumpStoredField(tester, fixture);

      await _openFieldDelete(tester);
      await pumpExternalWork(
        tester,
        () => find.byType(AppDialog).evaluate().isNotEmpty,
      );
      expect(
        find.text(Copy.templatesDeleteFieldMessage(values: 2)),
        findsOneWidget,
      );
      await tester.tap(find.text(Copy.cancel));
      await tester.pumpAndSettle();
      expect(
        _ok(await fixture.templates.byId(fixture.template.id)),
        fixture.template,
      );

      await tester.runAsync(() async {
        final sqlite.RecordRow record =
            (await fixture.database.select(fixture.database.records).get())
                .last;
        await (fixture.database.update(
          fixture.database.records,
        )..where((sqlite.$RecordsTable row) => row.id.equals(record.id))).write(
          const sqlite.RecordsCompanion(status: Value<String>('deleted')),
        );
      });
      await _openFieldDelete(tester);
      await pumpExternalWork(
        tester,
        () => find.byType(AppDialog).evaluate().isNotEmpty,
      );
      expect(
        find.text(Copy.templatesDeleteFieldMessage(values: 1)),
        findsOneWidget,
      );
      expect(
        find.text(Copy.templatesDeleteFieldMessage(values: 2)),
        findsNothing,
      );
      await tester.tap(find.text(Copy.cancel));
      await tester.pumpAndSettle();
      await _expectStoredFieldUnchanged(tester, fixture);
    },
  );

  testWidgets('a failed value read prevents confirmation and permits retry', (
    WidgetTester tester,
  ) async {
    final _StoredField fixture = await _seedStoredField(tester);
    await _pumpStoredField(tester, fixture);
    // Keep evidence physically present while making the real SQL read fail.
    await tester.runAsync(() {
      return fixture.database.customStatement(
        'ALTER TABLE record_fields RENAME TO unreadable_record_fields',
      );
    });
    try {
      await _openFieldDelete(tester);
      await pumpExternalWork(
        tester,
        () => find.byType(AppSnackbar).evaluate().isNotEmpty,
      );
      expect(find.byType(AppDialog), findsNothing);
      final AppSnackbar snack = tester.widget<AppSnackbar>(
        find.byType(AppSnackbar),
      );
      expect(snack.tone, SnackTone.error);
      expect(
        snack.localizedMessage,
        Copy.messages.failureTheDatabaseCouldNotCompleteThatWrite,
      );
      expect(
        _ok(await fixture.templates.byId(fixture.template.id)),
        fixture.template,
      );
    } finally {
      await tester.runAsync(() {
        return fixture.database.customStatement(
          'ALTER TABLE unreadable_record_fields RENAME TO record_fields',
        );
      });
    }
    await _expectStoredFieldUnchanged(tester, fixture);

    await _openFieldDelete(tester);
    await pumpExternalWork(
      tester,
      () => find.byType(AppDialog).evaluate().isNotEmpty,
    );
    expect(
      find.text(Copy.templatesDeleteFieldMessage(values: 2)),
      findsOneWidget,
    );
    await tester.tap(find.text(Copy.cancel));
    await tester.pumpAndSettle();
    await _expectStoredFieldUnchanged(tester, fixture);
  });

  testWidgets('move down swaps two fields of a section and leaves output '
      'columns', (WidgetTester tester) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    final TemplateDef stored = _ok(
      await templates.save(
        aTemplate(
          fields: const <FieldDef>[
            FieldDef(
              fieldKey: 'serial',
              label: 'Serial',
              type: FieldType.text,
              requiredness: Requiredness.required,
              outputColumn: 'B',
              sortOrder: 0,
            ),
            FieldDef(
              fieldKey: 'note',
              label: 'Note',
              type: FieldType.text,
              outputColumn: 'D',
              sortOrder: 1,
            ),
            FieldDef(
              fieldKey: 'asset_name',
              label: 'Name',
              type: FieldType.text,
              requiredness: Requiredness.required,
              outputColumn: 'C',
              sortOrder: 2,
            ),
          ],
        ),
      ),
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

    expect(_titles(tester), <String>['Serial', 'Name', 'Note']);
    expect(find.textContaining(Copy.fieldTypeLabel('text')), findsNWidgets(3));

    await tester.tap(find.byTooltip(Copy.fieldMoveDown('Serial')));
    await tester.pumpAndSettle();

    expect(_titles(tester), <String>['Name', 'Serial', 'Note']);
    final TemplateDef reordered = _ok(await templates.byId(stored.id))!;
    // Only the two required fields trade places; Note keeps its slot.
    expect(reordered.fields.map((FieldDef field) => field.fieldKey), <String>[
      'asset_name',
      'note',
      'serial',
    ]);
    expect(
      reordered.fields.map((FieldDef field) => field.outputColumn),
      <String?>['C', 'D', 'B'],
    );
    expect(reordered.fields.map((FieldDef field) => field.sortOrder), <int>[
      0,
      1,
      2,
    ]);
    expect(reordered.fields[1], stored.fields[1]);
  });

  testWidgets('fields list Required, then Recommended, then Optional, each '
      'in stored order', (WidgetTester tester) async {
    await _pumpMixed(tester);

    expect(_titles(tester), <String>[
      'Serial',
      'Rating',
      'Maker',
      'Note',
      'Installed',
    ]);
    final double required = _top(tester, Requiredness.required);
    final double recommended = _top(tester, Requiredness.recommended);
    final double optional = _top(tester, Requiredness.optional);
    expect(required, lessThan(recommended));
    expect(recommended, lessThan(optional));
    expect(tester.getTopLeft(find.text('Rating')).dy, lessThan(recommended));
    expect(tester.getTopLeft(find.text('Maker')).dy, greaterThan(recommended));
    expect(tester.getTopLeft(find.text('Note')).dy, greaterThan(optional));
  });

  testWidgets('an empty section is left out', (WidgetTester tester) async {
    await _pumpMixed(
      tester,
      fields: const <FieldDef>[
        FieldDef(
          fieldKey: 'serial',
          label: 'Serial',
          type: FieldType.text,
          requiredness: Requiredness.required,
        ),
        FieldDef(fieldKey: 'note', label: 'Note', type: FieldType.text),
      ],
    );

    expect(_section(Requiredness.required), findsOneWidget);
    expect(_section(Requiredness.recommended), findsNothing);
    expect(_section(Requiredness.optional), findsOneWidget);
  });

  testWidgets("a section's edge arrows are off, even beside another section", (
    WidgetTester tester,
  ) async {
    await _pumpMixed(tester);

    expect(_arrow(tester, Copy.fieldMoveUp('Serial')), isNull);
    expect(_arrow(tester, Copy.fieldMoveDown('Serial')), isNotNull);
    expect(_arrow(tester, Copy.fieldMoveUp('Rating')), isNotNull);
    expect(_arrow(tester, Copy.fieldMoveDown('Rating')), isNull);
    expect(_arrow(tester, Copy.fieldMoveUp('Maker')), isNull);
    expect(_arrow(tester, Copy.fieldMoveDown('Maker')), isNull);
    expect(_arrow(tester, Copy.fieldMoveUp('Note')), isNull);
    expect(_arrow(tester, Copy.fieldMoveDown('Installed')), isNull);
  });

  testWidgets('moving up an optional field swaps only it and the one before '
      'it in its section', (WidgetTester tester) async {
    final FakeTemplateRepository templates = await _pumpMixed(tester);
    final List<FieldDef> before = _ok(
      await templates.byId('template-1'),
    )!.fields;

    await tester.tap(find.byTooltip(Copy.fieldMoveUp('Installed')));
    await tester.pumpAndSettle();

    final List<FieldDef> after = _ok(
      await templates.byId('template-1'),
    )!.fields;
    expect(after.map((FieldDef field) => field.fieldKey), <String>[
      'installed',
      'serial',
      'maker',
      'rating',
      'note',
    ]);
    final List<int> changed = <int>[
      for (int index = 0; index < after.length; index++)
        if (after[index].fieldKey != before[index].fieldKey) index,
    ];
    expect(changed, <int>[0, 4]);
    expect(_titles(tester), <String>[
      'Serial',
      'Rating',
      'Maker',
      'Installed',
      'Note',
    ]);
  });

  testWidgets('a drag moves a field inside its section only', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = await _pumpMixed(tester);

    // Drag Rating far above the top of the Required section.
    final TestGesture drag = await tester.startGesture(
      tester.getCenter(find.byTooltip(Copy.fieldReorder('Rating'))),
    );
    await tester.pump(const Duration(milliseconds: 20));
    await drag.moveBy(const Offset(0, -400));
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();

    final List<FieldDef> after = _ok(
      await templates.byId('template-1'),
    )!.fields;
    expect(after.map((FieldDef field) => field.fieldKey), <String>[
      'note',
      'rating',
      'maker',
      'serial',
      'installed',
    ]);
    expect(_titles(tester), <String>[
      'Rating',
      'Serial',
      'Maker',
      'Note',
      'Installed',
    ]);
  });

  testWidgets('the filter narrows by requiredness and by type and counts', (
    WidgetTester tester,
  ) async {
    await _pumpMixed(tester);
    expect(find.byTooltip(Copy.searchFilters(0)), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('search-filter')));
    await tester.pumpAndSettle();
    expect(find.text(Copy.fieldFiltersTitle), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('field-requiredness-filter')),
    );
    await tester.pumpAndSettle();
    await tester.tap(_inTopSheet(Copy.fieldOptional));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(_titles(tester), <String>['Note', 'Installed']);
    expect(find.byTooltip(Copy.searchFilters(1)), findsOneWidget);
    // A filtered list is flat, without drag.
    expect(_section(Requiredness.optional), findsNothing);
    expect(find.byTooltip(Copy.fieldReorder('Note')), findsNothing);

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(FieldListScreen)),
    );
    container.read(fieldListFilterProvider.notifier)
      ..setRequiredness(const <Requiredness>{})
      ..setTypes(const <FieldType>{FieldType.number, FieldType.date});
    await tester.pumpAndSettle();
    expect(_titles(tester), <String>['Rating', 'Installed']);
    expect(find.byTooltip(Copy.searchFilters(2)), findsOneWidget);

    container.read(fieldListFilterProvider.notifier).setRequiredness(
      const <Requiredness>{Requiredness.required},
    );
    await tester.pumpAndSettle();
    expect(_titles(tester), <String>['Rating']);
    expect(find.byTooltip(Copy.searchFilters(3)), findsOneWidget);

    // Search and filter combine.
    container.read(fieldListQueryProvider.notifier).set('serial');
    await tester.pumpAndSettle();
    expect(find.text(Copy.fieldsNoMatch), findsOneWidget);
    expect(find.text(Copy.searchFilterNoMatchMessage), findsOneWidget);

    container.read(fieldListFilterProvider.notifier).clear();
    await tester.pumpAndSettle();
    expect(_titles(tester), <String>['Serial']);
  });

  testWidgets('the type filter offers only the types the template uses', (
    WidgetTester tester,
  ) async {
    await _pumpMixed(tester);
    await tester.tap(find.byKey(const ValueKey<String>('search-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('field-type-filter')));
    await tester.pumpAndSettle();

    expect(_inTopSheet(Copy.fieldTypeLabel('number')), findsOneWidget);
    expect(_inTopSheet(Copy.fieldTypeLabel('date')), findsOneWidget);
    expect(_inTopSheet(Copy.fieldTypeLabel('barcode')), findsNothing);
  });

  testWidgets('a field row names its default value', (
    WidgetTester tester,
  ) async {
    await _pumpMixed(
      tester,
      fields: const <FieldDef>[
        FieldDef(
          fieldKey: 'status',
          label: 'Status',
          type: FieldType.text,
          defaultValue: 'In use',
        ),
        FieldDef(fieldKey: 'note', label: 'Note', type: FieldType.text),
      ],
    );

    expect(
      find.text(
        Copy.fieldRowSubtitle(
          typeLabel: Copy.fieldTypeLabel('text'),
          requiredField: false,
          calculated: false,
          fromPhotos: false,
          defaultValue: 'In use',
        ),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Default: In use'), findsOneWidget);
    expect(find.textContaining('Default:'), findsOneWidget);
  });
}

typedef _StoredField = ({
  sqlite.AppDatabase database,
  TemplateDef template,
  FakeTemplateRepository templates,
  sqlite.TemplateField definition,
  List<sqlite.RecordField> values,
});

Future<_StoredField> _seedStoredField(WidgetTester tester) async {
  final _StoredField fixture = (await tester.runAsync(() async {
    final sqlite.AppDatabase database = await seededDatabase(records: 2);
    try {
      final sqlite.Template header = await database
          .select(database.templates)
          .getSingle();
      final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 1));
      final IdService ids = UuidV7Service.sequence(clock);
      final sqlite.TemplateField definition = _ok(
        await upsertTemplateField(
          database,
          row: sqlite.TemplateFieldsCompanion(
            templateId: Value<String>(header.id),
            fieldKey: const Value<String>('serial'),
            label: const Value<String>('Serial'),
            type: const Value<String>('text'),
            sortOrder: const Value<int>(0),
          ),
          clock: clock,
          deviceId: 'field-delete-test',
          ids: ids,
        ),
      );
      final List<sqlite.RecordField> values = <sqlite.RecordField>[];
      for (final sqlite.RecordRow record
          in await database.select(database.records).get()) {
        values.add(
          _ok(
            await insertRecordField(
              database,
              row: sqlite.RecordFieldsCompanion(
                recordId: Value<String>(record.id),
                fieldKey: const Value<String>('serial'),
                valueRaw: Value<String>('captured-${record.id}'),
                valueRefined: Value<String>('proposed-${record.id}'),
                valueFinal: Value<String>('approved-${record.id}'),
                source: const Value<String>('typed'),
              ),
              clock: clock,
              deviceId: 'field-delete-test',
              ids: ids,
            ),
          ),
        );
      }
      final FakeTemplateRepository templates = FakeTemplateRepository();
      final TemplateDef template = _ok(
        await templates.save(
          aTemplate(
            id: header.id,
            fields: const <FieldDef>[
              FieldDef(
                fieldKey: 'serial',
                label: 'Serial',
                type: FieldType.text,
              ),
            ],
          ),
        ),
      );
      return (
        database: database,
        template: template,
        templates: templates,
        definition: definition,
        values: values,
      );
    } on Object {
      await database.close();
      rethrow;
    }
  }))!;
  addTearDown(fixture.database.close);
  addTearDown(fixture.templates.dispose);
  return fixture;
}

Future<void> _pumpStoredField(WidgetTester tester, _StoredField fixture) async {
  await _pump(
    tester,
    templateId: fixture.template.id,
    openProject: true,
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(fixture.database),
      templateRepositoryProvider.overrideWithValue(fixture.templates),
    ],
  );
  await tester.pumpAndSettle();
}

Future<void> _openFieldDelete(WidgetTester tester) async {
  final Finder field = find.byWidgetPredicate(
    (Widget widget) => widget is AppListTile && widget.title == 'Serial',
  );
  await tester.tap(
    find.descendant(of: field, matching: find.byType(AppOverflowMenu)),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(Copy.templatesDeleteField));
}

Future<void> _expectStoredFieldUnchanged(
  WidgetTester tester,
  _StoredField fixture,
) async {
  expect(
    _ok(await fixture.templates.byId(fixture.template.id)),
    fixture.template,
  );
  await tester.runAsync(() async {
    expect(
      await fixture.database
          .select(fixture.database.templateFields)
          .getSingle(),
      fixture.definition,
    );
    expect(
      await fixture.database.select(fixture.database.recordFields).get(),
      fixture.values,
    );
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
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.template(templateId),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.templates,
        builder: (BuildContext _, GoRouterState _) {
          return const SizedBox.shrink();
        },
        routes: <RouteBase>[
          GoRoute(
            path: ':templateId',
            builder: (BuildContext _, GoRouterState state) {
              return FieldListScreen(
                templateId: state.pathParameters['templateId']!,
              );
            },
            routes: <RouteBase>[
              GoRoute(
                path: 'fields/new',
                builder: (BuildContext _, GoRouterState _) {
                  return const Text('add');
                },
              ),
              GoRoute(
                path: 'fields/:fieldKey',
                builder: (BuildContext _, GoRouterState _) {
                  return const Text('edit');
                },
              ),
            ],
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
        projectSettingsStoreProvider.overrideWith((Ref _) => store),
        ...overrides,
      ],
      child: MaterialApp.router(
        theme: buildTheme(brightness: Brightness.light),
        routerConfig: router,
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

/// Stored order: Note (optional), Serial (required), Maker (recommended),
/// Rating (required), Installed (optional).
const List<FieldDef> _mixed = <FieldDef>[
  FieldDef(fieldKey: 'note', label: 'Note', type: FieldType.text, sortOrder: 0),
  FieldDef(
    fieldKey: 'serial',
    label: 'Serial',
    type: FieldType.text,
    requiredness: Requiredness.required,
    sortOrder: 1,
  ),
  FieldDef(
    fieldKey: 'maker',
    label: 'Maker',
    type: FieldType.text,
    requiredness: Requiredness.recommended,
    sortOrder: 2,
  ),
  FieldDef(
    fieldKey: 'rating',
    label: 'Rating',
    type: FieldType.number,
    requiredness: Requiredness.required,
    sortOrder: 3,
  ),
  FieldDef(
    fieldKey: 'installed',
    label: 'Installed',
    type: FieldType.date,
    sortOrder: 4,
  ),
];

Future<FakeTemplateRepository> _pumpMixed(
  WidgetTester tester, {
  List<FieldDef> fields = _mixed,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(900, 1400);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final FakeTemplateRepository templates = FakeTemplateRepository();
  addTearDown(templates.dispose);
  _ok(await templates.save(aTemplate(fields: fields)));
  await _pump(
    tester,
    overrides: <Override>[
      templateRepositoryProvider.overrideWith((Ref _) => templates),
    ],
    openProject: true,
  );
  await tester.pumpAndSettle();
  return templates;
}

List<String> _titles(WidgetTester tester) {
  final List<AppListTile> tiles = tester
      .widgetList<AppListTile>(find.byType(AppListTile))
      .toList();
  tiles.sort(
    (AppListTile a, AppListTile b) => tester
        .getTopLeft(find.byWidget(a))
        .dy
        .compareTo(tester.getTopLeft(find.byWidget(b)).dy),
  );
  return <String>[for (final AppListTile tile in tiles) tile.title];
}

Finder _section(Requiredness requiredness) {
  return find.byKey(ValueKey<String>('field-section-${requiredness.name}'));
}

double _top(WidgetTester tester, Requiredness requiredness) {
  return tester.getTopLeft(_section(requiredness)).dy;
}

VoidCallback? _arrow(WidgetTester tester, String tooltip) {
  return tester
      .widget<AppIconButton>(
        find.ancestor(
          of: find.byTooltip(tooltip),
          matching: find.byType(AppIconButton),
        ),
      )
      .onPressed;
}

/// [text] inside the sheet opened last.
Finder _inTopSheet(String text) {
  return find.descendant(
    of: find.byType(AppBottomSheet).last,
    matching: find.text(text),
  );
}
