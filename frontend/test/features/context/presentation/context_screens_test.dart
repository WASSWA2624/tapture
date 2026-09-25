import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/features/context/context.dart';
import 'package:tapture/features/context/presentation/context_bar.dart';
import 'package:tapture/features/context/presentation/context_hierarchy_screen.dart';
import 'package:tapture/features/context/presentation/context_picker_sheet.dart';
import 'package:tapture/features/context/presentation/context_preset_list.dart';
import 'package:tapture/features/context/presentation/context_preset_save.dart';
import 'package:tapture/features/context/presentation/pinned_fields_sheet.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/reference/domain/reference_row.dart';
import 'package:tapture/features/reference/reference.dart'
    show referenceRepositoryProvider;
import 'package:tapture/features/settings/domain/setting_keys.dart';
import 'package:tapture/features/settings/settings.dart' show SettingsStore;
import 'package:tapture/features/templates/domain/field_def.dart';
import 'package:tapture/features/templates/domain/template_def.dart';
import 'package:tapture/features/templates/domain/template_row.dart';
import 'package:tapture/features/templates/templates.dart'
    show templateRepositoryProvider;

import '../../../support/factories.dart';
import '../../../support/fakes/fake_context_repository.dart';
import '../../../support/fakes/fake_reference_repository.dart';
import '../../../support/fakes/fake_template_repository.dart';
import '../../projects/fakes/fake_project_repository.dart';

void main() {
  late FakeContextRepository repo;

  setUp(() {
    repo = FakeContextRepository();
    final TestFlutterView view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!;
    view.physicalSize = const Size(800, 1400);
    view.devicePixelRatio = 1;
  });

  tearDown(() {
    repo.dispose();
    final TestFlutterView view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  Widget wrap(Widget child, {List<Override> extra = const <Override>[]}) {
    return ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        contextRepositoryProvider.overrideWith((Ref _) => repo),
        ...extra,
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: child,
      ),
    );
  }

  testWidgets('hierarchy shows zero levels and a repository write failure', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    await tester.pumpWidget(
      wrap(
        const ContextHierarchyScreen(projectId: 'p1'),
        extra: <Override>[
          templateRepositoryProvider.overrideWith((Ref _) => templates),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(Copy.contextNoTemplatesHeadline), findsOneWidget);

    await repo.saveHierarchy('p1', const <ContextLevel>[
      ContextLevel(fieldKey: 'a', order: 0, label: 'A'),
    ]);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      wrap(
        const ContextHierarchyScreen(projectId: 'p1'),
        extra: <Override>[
          templateRepositoryProvider.overrideWith((Ref _) => templates),
        ],
      ),
    );
    await tester.pumpAndSettle();
    repo.hierarchyFailure = const StorageFailure(
      message: 'hier-write',
      recoveryAction: 'retry',
    );
    await tester.tap(find.byTooltip(Copy.contextRemoveLevel));
    await tester.pumpAndSettle();
    expect(find.textContaining('hier-write'), findsWidgets);
    expect((await repo.load('p1')).valueOrNull?.levels, hasLength(1));
  });

  testWidgets('a three-level hierarchy reorder persists', (
    WidgetTester tester,
  ) async {
    await repo.saveHierarchy('p1', const <ContextLevel>[
      ContextLevel(fieldKey: 'a', order: 0, label: 'A'),
      ContextLevel(fieldKey: 'b', order: 1, label: 'B'),
      ContextLevel(fieldKey: 'c', order: 2, label: 'C'),
    ]);
    await tester.pumpWidget(
      wrap(const ContextHierarchyScreen(projectId: 'p1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('A'), findsWidgets);
    expect(find.text('B'), findsWidgets);
    expect(find.text('C'), findsWidgets);

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('C').last),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.moveBy(const Offset(0, -120));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final ContextState state = (await repo.load('p1')).valueOrNull!;
    expect(state.levels.map((ContextLevel level) => level.fieldKey), <String>[
      'c',
      'a',
      'b',
    ]);
  });

  testWidgets('the bar is hidden when the context is empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(const Scaffold(body: ContextBar())));
    await tester.pumpAndSettle();
    expect(find.byType(AppChip), findsNothing);
  });

  testWidgets('a narrow bar stays within two lines and shortens the middle', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository projects = FakeProjectRepository();
    addTearDown(projects.dispose);
    _ok(await projects.create(aProject(id: 'p1', name: 'Inventory')));
    await repo.saveHierarchy('p1', const <ContextLevel>[
      ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
      ContextLevel(fieldKey: 'facility', order: 1, label: 'Facility'),
      ContextLevel(fieldKey: 'dept', order: 2, label: 'Department'),
    ]);
    await repo.setLevelValue(
      projectId: 'p1',
      fieldKey: 'district',
      value: 'Kampala',
    );
    await repo.setLevelValue(
      projectId: 'p1',
      fieldKey: 'facility',
      value: 'Kasubi Health Centre IV Outpatient Wing',
    );
    await repo.setLevelValue(
      projectId: 'p1',
      fieldKey: 'dept',
      value: 'Theatre',
    );
    await repo.savePinned('p1', const <String, String>{'surveyor': 'Sam'});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_barApp(repo, projects));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Kasubi Health Centre IV Outpatient'),
      findsNothing,
    );
    expect(find.textContaining('Pinned'), findsOneWidget);
    final Size size = tester.getSize(find.byType(ContextBar));
    expect(size.height, lessThanOrEqualTo(Sizes.minTapTarget * 2 + Space.x4));
  });

  testWidgets(
    'picker covers no recents, dataset search, free text and failure',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () {
                  showContextPickerSheet(
                    context: context,
                    projectId: 'p1',
                    level: const ContextLevel(
                      fieldKey: 'site',
                      order: 0,
                      label: 'Site',
                    ),
                    currentValue: '',
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(Copy.contextRecents), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      final FakeReferenceRepository references = FakeReferenceRepository();
      addTearDown(references.dispose);
      await references.saveRow(
        const ReferenceRow(
          id: 'row-1',
          datasetId: 'ds-1',
          key: 'Kasubi HC IV',
          values: <String, String>{'name': 'Kasubi HC IV'},
        ),
      );
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () {
                  showContextPickerSheet(
                    context: context,
                    projectId: 'p1',
                    level: const ContextLevel(
                      fieldKey: 'facility',
                      order: 0,
                      label: 'Facility',
                      datasetId: 'ds-1',
                    ),
                    currentValue: '',
                  );
                },
                child: const Text('open-data'),
              );
            },
          ),
          extra: <Override>[
            referenceRepositoryProvider.overrideWith((Ref _) => references),
          ],
        ),
      );
      await tester.tap(find.text('open-data'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(AppSearchField), 'Kasubi');
      await tester.pump(AppConstants.interaction.debounce);
      await tester.pumpAndSettle();
      expect(find.text('Kasubi HC IV'), findsWidgets);

      await repo.saveHierarchy('p1', const <ContextLevel>[
        ContextLevel(fieldKey: 'district', order: 0, label: 'district'),
        ContextLevel(fieldKey: 'facility', order: 1, label: 'Facility'),
        ContextLevel(fieldKey: 'dept', order: 2, label: 'Department'),
      ]);
      await repo.setLevelValue(
        projectId: 'p1',
        fieldKey: 'district',
        value: 'Kampala',
      );
      await repo.setLevelValue(
        projectId: 'p1',
        fieldKey: 'facility',
        value: 'Clinic',
      );
      await repo.setLevelValue(
        projectId: 'p1',
        fieldKey: 'dept',
        value: 'Theatre',
      );
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () {
                  showContextPickerSheet(
                    context: context,
                    projectId: 'p1',
                    level: const ContextLevel(
                      fieldKey: 'district',
                      order: 0,
                      label: 'district',
                    ),
                    currentValue: 'Kampala',
                  );
                },
                child: const Text('open-cascade'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('open-cascade'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Wakiso');
      await tester.tap(find.widgetWithText(AppButton, Copy.contextUseValue));
      await tester.pumpAndSettle();
      expect(find.textContaining('Change district to Wakiso?'), findsOneWidget);
      expect(find.textContaining('Facility (Clinic)'), findsOneWidget);
      expect(find.textContaining('Department (Theatre)'), findsOneWidget);
      await tester.tap(find.text(Copy.cancel));
      await tester.pumpAndSettle();
      ContextState state = (await repo.load('p1')).valueOrNull!;
      expect(state.values['district'], 'Kampala');
      expect(state.values['facility'], 'Clinic');

      await tester.tap(find.widgetWithText(AppButton, Copy.contextUseValue));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Copy.contextCascadeConfirm));
      await tester.pumpAndSettle();
      state = (await repo.load('p1')).valueOrNull!;
      expect(state.values['district'], 'Wakiso');
      expect(state.values.containsKey('facility'), isFalse);
      expect(state.values.containsKey('dept'), isFalse);

      repo.valueFailure = const StorageFailure(
        message: 'pick-fail',
        recoveryAction: 'retry',
      );
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () {
                  showContextPickerSheet(
                    context: context,
                    projectId: 'p1',
                    level: const ContextLevel(
                      fieldKey: 'district',
                      order: 0,
                      label: 'district',
                    ),
                    currentValue: '',
                  );
                },
                child: const Text('open-fail'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('open-fail'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Jinja');
      await tester.tap(find.widgetWithText(AppButton, Copy.contextUseValue));
      await tester.pumpAndSettle();
      expect(find.textContaining('pick-fail'), findsWidgets);
    },
  );

  testWidgets('pinned fields save a stickable value and show a failure', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    await templates.save(
      const TemplateDef(
        id: 't1',
        templateKey: 'equipment',
        name: 'Equipment',
        version: 1,
        projectId: 'p1',
        fields: <FieldDef>[
          FieldDef(
            fieldKey: 'surveyor',
            label: 'Surveyor',
            type: FieldType.text,
            stickable: true,
          ),
        ],
        identityFieldKeys: <String>[],
        rows: <TemplateRow>[],
      ),
    );
    await tester.pumpWidget(
      wrap(
        const Scaffold(body: PinnedFieldsSheet(projectId: 'p1')),
        extra: <Override>[
          templateRepositoryProvider.overrideWith((Ref _) => templates),
        ],
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pumpAndSettle();
    expect(find.text('Surveyor'), findsWidgets);
    await tester.enterText(find.byType(EditableText), 'Sam');
    repo.pinnedFailure = const StorageFailure(
      message: 'pin-fail',
      recoveryAction: 'retry',
    );
    await tester.tap(find.text(Copy.ok));
    await tester.pump();
    expect(find.textContaining('pin-fail'), findsWidgets);
    repo.pinnedFailure = null;
    await tester.tap(find.text(Copy.tryAgain));
    await tester.pump();
    await tester.tap(find.text(Copy.ok));
    await tester.pump();
    final ContextState state = (await repo.load('p1')).valueOrNull!;
    expect(state.pinned['surveyor'], 'Sam');
  });

  testWidgets(
    'presets cover an empty list, a duplicate name, an omitted level and a failure',
    (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const ContextPresetList(projectId: 'p1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(Copy.contextPresetsEmptyHeadline), findsOneWidget);
      expect(find.text(Copy.contextPresetsEmptyMessage), findsOneWidget);

      await repo.saveHierarchy('p1', const <ContextLevel>[
        ContextLevel(fieldKey: 'a', order: 0, label: 'A'),
        ContextLevel(fieldKey: 'b', order: 1, label: 'B'),
      ]);
      await repo.setLevelValue(projectId: 'p1', fieldKey: 'a', value: '1');
      await repo.setLevelValue(projectId: 'p1', fieldKey: 'b', value: '2');
      await repo.savePreset(
        projectId: 'p1',
        name: 'Room',
        values: const <String, String>{'a': '1'},
        pinned: const <String, String>{},
      );
      await tester.pumpWidget(wrap(const ContextPresetList(projectId: 'p1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Room'));
      await tester.pump();
      final ContextState applied = (await repo.load('p1')).valueOrNull!;
      expect(applied.values['a'], '1');
      expect(applied.values.containsKey('b'), isFalse);
      expect(find.text(Copy.contextCascadeTitle), findsNothing);

      await repo.setLevelValue(projectId: 'p1', fieldKey: 'a', value: '9');
      await tester.pumpWidget(
        wrap(const Scaffold(body: ContextPresetSave(projectId: 'p1'))),
      );
      await tester.pump();
      await tester.enterText(find.byType(EditableText), 'Room');
      await tester.tap(find.widgetWithText(AppButton, Copy.contextPresetSave));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(Copy.contextPresetOverwriteTitle), findsWidgets);
      await tester.tap(find.text(Copy.cancel));
      await tester.pump();
      expect((await repo.watchPresets('p1').first).single.values['a'], '1');

      await tester.tap(find.widgetWithText(AppButton, Copy.contextPresetSave));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text(Copy.contextPresetOverwriteTitle).last);
      await tester.pump();
      expect((await repo.watchPresets('p1').first).single.values['a'], '9');

      repo.presetFailure = const StorageFailure(
        message: 'preset-fail',
        recoveryAction: 'retry',
      );
      await tester.enterText(find.byType(EditableText), 'Other');
      await tester.tap(find.widgetWithText(AppButton, Copy.contextPresetSave));
      await tester.pump();
      expect(find.textContaining('preset-fail'), findsWidgets);
    },
  );
}

Widget _barApp(FakeContextRepository repo, FakeProjectRepository projects) {
  return ProviderScope(
    overrides: <Override>[
      contextRepositoryProvider.overrideWith((Ref _) => repo),
      projectRepositoryProvider.overrideWith((Ref _) => projects),
      projectSettingsStoreProvider.overrideWith(
        (Ref _) => SettingsStore.fake(
          stored: <String, Object?>{SettingKeys.openProjectId.name: 'p1'},
        ),
      ),
    ],
    child: MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: const Scaffold(body: ContextBar()),
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

extension on Result<ContextState> {
  ContextState? get valueOrNull {
    return switch (this) {
      Success<ContextState>(:final ContextState value) => value,
      FailureResult<ContextState>() => null,
    };
  }
}
