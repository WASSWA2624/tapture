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
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/features/context/context.dart';
import 'package:tapture/features/context/presentation/context_bar.dart';
import 'package:tapture/features/context/presentation/context_hierarchy_screen.dart';
import 'package:tapture/features/context/presentation/context_picker_sheet.dart';
import 'package:tapture/features/context/presentation/context_preset_list.dart';
import 'package:tapture/features/context/presentation/context_preset_save.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/reference/domain/reference_row.dart';
import 'package:tapture/features/reference/reference.dart'
    show referenceRepositoryProvider;
import 'package:tapture/features/settings/domain/setting_keys.dart';
import 'package:tapture/features/settings/settings.dart' show SettingsStore;
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
    // Remove sits in the level's one overflow menu (task 076, W3).
    await tester.tap(
      find.byKey(const ValueKey<String>('context-level-menu-a')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.contextRemoveLevel));
    await tester.pumpAndSettle();
    expect(find.textContaining('hier-write'), findsWidgets);
    expect((await repo.load('p1')).valueOrNull?.levels, hasLength(1));
  });

  testWidgets(
    'context overview opens the prefilled editor and retains failed input',
    (tester) async {
      final FakeTemplateRepository templates = FakeTemplateRepository();
      addTearDown(templates.dispose);
      await repo.saveHierarchy('p1', const <ContextLevel>[
        ContextLevel(fieldKey: 'site', order: 0, label: 'Site'),
      ]);
      await repo.setLevelValue(
        projectId: 'p1',
        fieldKey: 'site',
        value: 'North',
      );
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showContextValuesSheet(context: context, projectId: 'p1'),
                child: const Text('Open values'),
              ),
            ),
          ),
          extra: <Override>[
            templateRepositoryProvider.overrideWithValue(templates),
            projectSettingsStoreProvider.overrideWithValue(
              SettingsStore.fake(),
            ),
          ],
        ),
      );
      await tester.tap(find.text('Open values'));
      await tester.pumpAndSettle();
      expect(find.text('North'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('context-values-level-site')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomSheet), findsOneWidget);
      expect(
        tester
            .widget<ContextPickerSheet>(find.byType(ContextPickerSheet))
            .currentValue,
        'North',
      );
      repo.valueFailure = const StorageFailure(
        message: 'Context write refused',
        recoveryAction: 'retry',
      );
      await tester.enterText(find.byType(TextField), 'South');
      await tester.tap(
        find.widgetWithText(AppPrimaryAction, Copy.contextUseValue),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Context write refused'), findsWidgets);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'South',
      );
      expect((await repo.load('p1')).valueOrNull!.values['site'], 'North');
      repo.valueFailure = null;
      await tester.tap(
        find.widgetWithText(AppPrimaryAction, Copy.contextUseValue),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ContextPickerSheet), findsNothing);
      expect((await repo.load('p1')).valueOrNull!.values['site'], 'South');
    },
  );

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

    // A level moves by its drag handle, not a long press on the row (task
    // 076, W3).
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(AppIcons.reorder).last),
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

  testWidgets(
    'at 320dp full hierarchy and pins have reachable natural bodies',
    (WidgetTester tester) async {
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
        findsOneWidget,
      );
      final Rect bar = tester.getRect(find.byType(ContextBar));
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey<String>('context-bar-pins')))
            .dy,
        greaterThan(
          tester
              .getTopLeft(
                find.byKey(const ValueKey<String>('context-bar-hierarchy')),
              )
              .dy,
        ),
      );
      for (final String key in <String>[
        'context-bar-level-dept',
        'context-bar-pin-surveyor',
      ]) {
        final Finder chip = find.byKey(ValueKey<String>(key));
        await tester.dragUntilVisible(
          chip,
          find
              .ancestor(of: chip, matching: find.byType(SingleChildScrollView))
              .first,
          const Offset(-80, 0),
        );
        await tester.pumpAndSettle();
        final Rect rect = tester.getRect(chip);
        expect(rect.height, greaterThanOrEqualTo(Sizes.minTapTarget));
        expect(rect.top, greaterThanOrEqualTo(bar.top));
        expect(rect.bottom, lessThanOrEqualTo(bar.bottom));
        expect(rect.left, greaterThanOrEqualTo(bar.left));
        expect(rect.right, lessThanOrEqualTo(bar.right));
      }
      expect(
        find.text(Copy.contextLevelValue('Department', 'Theatre')),
        findsOneWidget,
      );
      expect(
        find.text(Copy.contextPinnedValue('surveyor', 'Sam')),
        findsOneWidget,
      );
    },
  );

  testWidgets('second visit sets facility in two taps', (
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
      value: 'Kasubi HC IV',
    );
    await repo.setLevelValue(
      projectId: 'p1',
      fieldKey: 'facility',
      value: 'Mulago',
    );
    await tester.pumpWidget(_barApp(repo, projects));
    await tester.pumpAndSettle();

    // Tap one: the facility chip.
    await tester.tap(
      find.byKey(const ValueKey<String>('context-bar-level-facility')),
    );
    await tester.pumpAndSettle();
    // Tap two: the recent value. No confirmation follows.
    await tester.tap(find.widgetWithText(AppListTile, 'Kasubi HC IV'));
    await tester.pumpAndSettle();

    expect(find.text(Copy.contextCascadeTitle), findsNothing);
    expect(find.byType(ContextPickerSheet), findsNothing);
    final ContextState state = (await repo.load('p1')).valueOrNull!;
    expect(state.values['facility'], 'Kasubi HC IV');
    expect(state.values['district'], 'Kampala');
  });

  testWidgets('choosing the current value again changes nothing', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository projects = FakeProjectRepository();
    addTearDown(projects.dispose);
    _ok(await projects.create(aProject(id: 'p1', name: 'Inventory')));
    await repo.saveHierarchy('p1', const <ContextLevel>[
      ContextLevel(fieldKey: 'facility', order: 0, label: 'Facility'),
      ContextLevel(fieldKey: 'dept', order: 1, label: 'Department'),
    ]);
    await repo.setLevelValue(
      projectId: 'p1',
      fieldKey: 'facility',
      value: 'Mulago',
    );
    await repo.setLevelValue(
      projectId: 'p1',
      fieldKey: 'dept',
      value: 'Theatre',
    );
    await tester.pumpWidget(_barApp(repo, projects));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('context-bar-level-facility')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppListTile, 'Mulago'));
    await tester.pumpAndSettle();

    expect(find.text(Copy.contextCascadeTitle), findsNothing);
    expect(find.byType(ContextPickerSheet), findsNothing);
    expect((await repo.load('p1')).valueOrNull!.values, <String, String>{
      'facility': 'Mulago',
      'dept': 'Theatre',
    });
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
      // No recents: no Recent section, straight to free text.
      expect(find.text(Copy.contextRecents), findsNothing);
      expect(find.byType(AppTextField), findsOneWidget);
      await tester.tap(
        find.widgetWithText(AppPrimaryAction, Copy.contextUseValue),
      );
      await tester.pumpAndSettle();
      // An empty value writes nothing and keeps the sheet open.
      expect(find.byType(ContextPickerSheet), findsOneWidget);

      final FakeReferenceRepository references = FakeReferenceRepository();
      addTearDown(references.dispose);
      await references.saveRow(
        ReferenceRow(
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
      await tester.tap(
        find.widgetWithText(AppPrimaryAction, Copy.contextUseValue),
      );
      // The confirmation opens while the submit bar is busy.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('Change district to Wakiso?'), findsOneWidget);
      expect(find.textContaining('Facility (Clinic)'), findsOneWidget);
      expect(find.textContaining('Department (Theatre)'), findsOneWidget);
      await tester.tap(find.text(Copy.cancel));
      await tester.pumpAndSettle();
      ContextState state = (await repo.load('p1')).valueOrNull!;
      expect(state.values['district'], 'Kampala');
      expect(state.values['facility'], 'Clinic');
      expect(state.values['dept'], 'Theatre');

      await tester.tap(
        find.widgetWithText(AppPrimaryAction, Copy.contextUseValue),
      );
      // The confirmation opens while the submit bar is busy.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
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
      await tester.tap(
        find.widgetWithText(AppPrimaryAction, Copy.contextUseValue),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('pick-fail'), findsWidgets);
    },
  );

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
      expect(find.text(Copy.contextPresetApplied('Room')), findsOneWidget);

      await repo.setLevelValue(projectId: 'p1', fieldKey: 'a', value: '9');
      await tester.pumpWidget(
        wrap(const Scaffold(body: ContextPresetSave(projectId: 'p1'))),
      );
      await tester.pump();
      await tester.enterText(find.byType(EditableText), 'Room');
      await tester.tap(
        find.widgetWithText(AppPrimaryAction, Copy.contextPresetSave),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(Copy.contextPresetOverwriteTitle), findsWidgets);
      await tester.tap(find.text(Copy.cancel));
      await tester.pump();
      expect((await repo.watchPresets('p1').first).single.values['a'], '1');

      await tester.tap(
        find.widgetWithText(AppPrimaryAction, Copy.contextPresetSave),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text(Copy.contextPresetReplace));
      await tester.pump();
      expect((await repo.watchPresets('p1').first).single.values['a'], '9');

      repo.presetFailure = const StorageFailure(
        message: 'preset-fail',
        recoveryAction: 'retry',
      );
      await tester.enterText(find.byType(EditableText), 'Other');
      await tester.tap(
        find.widgetWithText(AppPrimaryAction, Copy.contextPresetSave),
      );
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
