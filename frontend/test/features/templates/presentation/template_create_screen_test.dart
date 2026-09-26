import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/presentation/template_create_screen.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../projects/fakes/fake_project_repository.dart';
import '../fakes/fake_template_repository.dart';

void main() {
  testWidgets('an empty name fails validation and writes nothing', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    await _pump(tester, templates: templates);

    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump();

    expect(find.text(Copy.nameRequired), findsWidgets);
    expect(templates.count, 0);
  });

  testWidgets('a failed create shows the failure on the form', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository()
      ..saveFailure = const StorageFailure(
        message: 'The template could not be saved on this device.',
        recoveryAction: 'Free space, then try again.',
      );
    addTearDown(templates.dispose);
    await _pump(tester, templates: templates, openProject: true);

    await tester.enterText(find.byType(TextField).first, 'Assets');
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump();

    expect(
      find.text('The template could not be saved on this device.'),
      findsOneWidget,
    );
    expect(templates.count, 0);
  });

  testWidgets('a blank template opens the field list with no fields', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    await _pump(
      tester,
      templates: templates,
      openProject: true,
      withRouter: true,
    );

    await tester.enterText(find.byType(TextField).first, 'Assets');
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump();
    await tester.pump();

    expect(templates.count, 1);
    final TemplateDef stored = _present(await templates.byId('template-0'));
    expect(stored.name, 'Assets');
    expect(stored.fields, isEmpty);
    expect(find.text('fields'), findsOneWidget);

    _ok(
      await templates.save(
        stored.copyWith(
          fields: const <FieldDef>[
            FieldDef(
              fieldKey: 'asset_tag',
              label: 'Asset tag',
              type: FieldType.text,
            ),
          ],
        ),
      ),
    );
    expect(_present(await templates.byId(stored.id)).fields, hasLength(1));
  });

  testWidgets('several rows save as fields in order with unique keys', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    await _pump(tester, templates: templates, openProject: true);

    await tester.enterText(find.byType(TextField).first, 'Assets');
    await tester.enterText(_labelField(0), 'Asset tag');
    await _addRow(tester);
    await tester.enterText(_labelField(1), 'Asset tag');
    await _addRow(tester);
    await tester.enterText(_labelField(2), 'Room');
    await _addRow(tester);
    final Finder required = find.text(Copy.fieldRequired).at(2);
    await tester.ensureVisible(required);
    await tester.tap(required);
    await tester.pump();
    await _create(tester);

    final TemplateDef stored = _present(await templates.byId('template-0'));
    expect(
      stored.fields.map((FieldDef field) => field.fieldKey).toList(),
      <String>['asset_tag', 'asset_tag_2', 'room'],
    );
    expect(
      stored.fields.map((FieldDef field) => field.sortOrder).toList(),
      <int>[0, 1, 2],
    );
    expect(stored.fields[2].requiredness, Requiredness.required);
    expect(stored.fields[0].requiredness, Requiredness.optional);
  });

  testWidgets('a removed row is not saved', (WidgetTester tester) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    await _pump(tester, templates: templates, openProject: true);

    await tester.enterText(find.byType(TextField).first, 'Assets');
    await tester.enterText(_labelField(0), 'Serial');
    await _addRow(tester);
    await tester.enterText(_labelField(1), 'Colour');
    final Finder remove = find.byTooltip(Copy.templateFieldRowRemove).first;
    await tester.ensureVisible(remove);
    await tester.pumpAndSettle();
    await tester.tap(remove);
    await tester.pump();
    await _create(tester);

    final TemplateDef stored = _present(await templates.byId('template-0'));
    expect(stored.fields.single.label, 'Colour');
  });

  testWidgets('a label with two facts warns once, then saves on keep anyway', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    await _pump(tester, templates: templates, openProject: true);

    await tester.enterText(find.byType(TextField).first, 'Assets');
    await tester.enterText(_labelField(0), 'Make and model');
    await _create(tester);
    expect(templates.count, 0);
    expect(find.text(Copy.fieldTwoFactsWarning), findsWidgets);

    final Finder keep = find.text(Copy.fieldKeepAnyway);
    await tester.ensureVisible(keep);
    await tester.pumpAndSettle();
    await tester.tap(keep);
    await tester.pump();
    await _create(tester);
    expect(templates.count, 1);
  });

  testWidgets('a failed create keeps every row', (WidgetTester tester) async {
    final FakeTemplateRepository templates = FakeTemplateRepository()
      ..saveFailure = const StorageFailure(
        message: 'The template could not be saved on this device.',
        recoveryAction: 'Free space, then try again.',
      );
    addTearDown(templates.dispose);
    await _pump(tester, templates: templates, openProject: true);

    await tester.enterText(find.byType(TextField).first, 'Assets');
    await tester.enterText(_labelField(0), 'Serial');
    await _addRow(tester);
    await tester.enterText(_labelField(1), 'Colour');
    await _create(tester);

    expect(templates.count, 0);
    expect(find.text('Serial'), findsOneWidget);
    expect(find.text('Colour'), findsOneWidget);
  });

  for (final ({String name, Size size, double scale}) layout
      in <({String name, Size size, double scale})>[
        (name: '200 percent text', size: const Size(393, 886), scale: 2),
        (name: 'landscape', size: const Size(886, 393), scale: 1),
      ]) {
    testWidgets('in ${layout.name} the rows and Create stay reachable', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = layout.size;
      tester.platformDispatcher.textScaleFactorTestValue = layout.scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final FakeTemplateRepository templates = FakeTemplateRepository();
      addTearDown(templates.dispose);
      await _pump(tester, templates: templates, openProject: true);
      await _addRow(tester);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text(Copy.templatesAddField));
      expect(find.text(Copy.templateFieldRowTitle(2)), findsOneWidget);
      final Rect create = tester.getRect(find.byType(AppPrimaryAction));
      expect(create.bottom, lessThanOrEqualTo(layout.size.height));
    });
  }
}

/// Label text fields in page order: the name first, then one per row.
Finder _labelField(int row) => find.byType(TextField).at(row + 1);

Future<void> _addRow(WidgetTester tester) async {
  final Finder add = find.text(Copy.templatesAddField);
  await tester.ensureVisible(add);
  await tester.pumpAndSettle();
  await tester.tap(add);
  await tester.pump();
}

Future<void> _create(WidgetTester tester) async {
  await tester.tap(find.byType(AppPrimaryAction));
  await tester.pump();
  await tester.pump();
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeTemplateRepository templates,
  bool openProject = false,
  bool withRouter = false,
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
  final List<Override> overrides = <Override>[
    templateRepositoryProvider.overrideWith((Ref _) => templates),
    projectRepositoryProvider.overrideWith((Ref _) => projects),
    projectSettingsStoreProvider.overrideWith((Ref _) => store),
  ];
  if (withRouter) {
    final GoRouter router = GoRouter(
      initialLocation: AppRoutes.templateCreate,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.templates,
          builder: (BuildContext _, GoRouterState _) {
            return const SizedBox.shrink();
          },
          routes: <RouteBase>[
            GoRoute(
              path: 'new',
              builder: (BuildContext _, GoRouterState _) {
                return const TemplateCreateScreen();
              },
            ),
            GoRoute(
              path: ':templateId',
              builder: (BuildContext _, GoRouterState _) {
                return const Text('fields');
              },
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        retry: (int _, Object _) => null,
        overrides: overrides,
        child: MaterialApp.router(
          theme: buildTheme(brightness: Brightness.light),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    return;
  }
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: overrides,
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const TemplateCreateScreen(),
      ),
    ),
  );
  await tester.pump();
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

TemplateDef _present(Result<TemplateDef?> result) {
  final TemplateDef? value = _ok(result);
  if (value == null) {
    throw TestFailure('Expected a stored template.');
  }
  return value;
}
