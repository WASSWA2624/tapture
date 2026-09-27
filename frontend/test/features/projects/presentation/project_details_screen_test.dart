import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/router.dart' show AppRoutes;
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/projects/presentation/project_details_screen.dart';
import 'package:tapture/features/projects/projects.dart';

import '../../../support/factories.dart';
import '../fakes/fake_project_repository.dart';

void main() {
  testWidgets('every detail shows, and an empty one reads Not set', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(
      await repo.create(
        aProject(name: 'Alpha').copyWith(organisation: 'City works'),
      ),
    );
    await _pump(tester, repo);

    expect(find.text(Copy.projectEditTitle), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('City works'), findsOneWidget);
    expect(find.text(Copy.projectDescription), findsOneWidget);
    expect(find.text(Copy.projectValueNotSet), findsWidgets);
    expect(find.text(Copy.projectStatusActive), findsOneWidget);
    expect(find.text(Copy.projectCreatedAt), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('Edit details opens the edit form', (WidgetTester tester) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    final GoRouter router = await _pump(tester, repo);

    await tester.tap(
      find.byKey(const ValueKey<String>('project-details-edit')),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.projectEdit('project-1'));
    expect(find.text('edit form'), findsOneWidget);
  });

  testWidgets('an archived project still shows its details', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    _ok(await repo.setStatus('project-1', ProjectStatus.archived));
    await _pump(tester, repo);

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text(Copy.projectStatusArchived), findsOneWidget);
  });

  for (final Size size in const <Size>[
    Size(360, 780),
    Size(780, 360),
    Size(800, 1000),
    Size(1280, 800),
  ]) {
    testWidgets(
      'at ${size.width.toInt()}x${size.height.toInt()} and 200 percent text '
      'nothing overflows',
      (WidgetTester tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final FakeProjectRepository repo = FakeProjectRepository();
        addTearDown(repo.dispose);
        _ok(
          await repo.create(
            aProject(name: 'A project with a long name that has to wrap'),
          ),
        );
        await _pump(tester, repo);

        expect(tester.takeException(), isNull);
        expect(find.text(Copy.projectEditDetails), findsOneWidget);
      },
    );
  }
}

Future<GoRouter> _pump(WidgetTester tester, FakeProjectRepository repo) async {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.projectDetails('project-1'),
    routes: <RouteBase>[
      GoRoute(
        path: '/projects/:projectId/details',
        builder: (BuildContext _, GoRouterState state) {
          return ProjectDetailsScreen(
            projectId: state.pathParameters['projectId']!,
          );
        },
      ),
      GoRoute(
        path: '/projects/:projectId/edit',
        builder: (BuildContext _, GoRouterState _) {
          return const Scaffold(body: Text('edit form'));
        },
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        projectRepositoryProvider.overrideWith((Ref _) => repo),
      ],
      child: MaterialApp.router(
        theme: buildTheme(brightness: Brightness.light),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
