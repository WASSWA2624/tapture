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
