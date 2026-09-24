import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/context/context.dart'
    show contextRepositoryProvider;
import 'package:tapture/features/context/presentation/pinned_fields_sheet.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/fakes/fake_context_repository.dart';
import '../../templates/fakes/fake_template_repository.dart';

void main() {
  testWidgets('templates with no stickable fields offer mark pinnable', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    _ok(
      await templates.save(
        const TemplateDef(
          id: 't1',
          templateKey: 'generic_item',
          name: 'Generic',
          version: 1,
          projectId: 'project-1',
          fields: <FieldDef>[
            FieldDef(fieldKey: 'name', label: 'Name', type: FieldType.text),
          ],
          identityFieldKeys: <String>[],
          rows: <TemplateRow>[],
        ),
      ),
    );
    final GoRouter router = await _pump(tester, templates);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.contextOpenTemplates), findsNothing);
    await tester.tap(find.text(Copy.contextMarkPinnable));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, RoutePaths.projectTemplates('project-1'));
  });

  testWidgets('a project with no templates offers add templates', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    final GoRouter router = await _pump(tester, templates);
    expect(find.text(Copy.contextMarkPinnable), findsNothing);
    await tester.tap(find.text(Copy.contextOpenTemplates));
    await tester.pumpAndSettle();
    expect(
      router.state.uri.path,
      RoutePaths.templateLibrary(projectId: 'project-1'),
    );
  });
}

Future<GoRouter> _pump(
  WidgetTester tester,
  FakeTemplateRepository templates,
) async {
  final FakeContextRepository contexts = FakeContextRepository();
  addTearDown(contexts.dispose);
  final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext _, GoRouterState _) {
          return const Scaffold(
            body: PinnedFieldsSheet(projectId: 'project-1'),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.projectTemplates('project-1'),
        builder: (BuildContext _, GoRouterState _) => const Text('templates'),
      ),
      GoRoute(
        path: RoutePaths.templateLibrary(projectId: 'project-1'),
        builder: (BuildContext _, GoRouterState _) => const Text('library'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        templateRepositoryProvider.overrideWith((Ref _) => templates),
        contextRepositoryProvider.overrideWith((Ref _) => contexts),
      ],
      child: MaterialApp.router(
        theme: buildTheme(brightness: Brightness.light),
        routerConfig: router,
      ),
    ),
  );
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });
  await tester.pump();
  return router;
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>() => throw TestFailure('expected a template'),
  };
}
