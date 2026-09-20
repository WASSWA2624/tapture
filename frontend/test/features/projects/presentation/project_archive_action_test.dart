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
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/features/projects/presentation/project_archive_action.dart';
import 'package:tapture/features/projects/presentation/project_list_screen.dart';
import 'package:tapture/features/projects/projects.dart';

import '../../../support/factories.dart';
import '../fakes/fake_project_repository.dart';

void main() {
  testWidgets('archive hides the project from the active list', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pumpAction(tester, repo: repo);
    await tester.pump();

    await tester.tap(find.text(Copy.projectArchive));
    await tester.pump();

    expect(repo.stored.single.status, ProjectStatus.archived);
    expect(repo.stored.single.name, 'Alpha');
    expect(repo.stored.single.folderName, 'test-project');
  });

  testWidgets('unarchive restores the project to the active list', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    _ok(await repo.setStatus('project-1', ProjectStatus.archived));
    await _pumpAction(tester, repo: repo, archived: true);
    await tester.pump();

    await tester.tap(find.text(Copy.projectUnarchive));
    await tester.pump();

    expect(repo.stored.single.status, ProjectStatus.active);
  });

  testWidgets('the archived filter reveals hidden projects', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    _ok(await repo.setStatus('project-1', ProjectStatus.archived));
    await _pumpList(tester, repo: repo);
    await tester.pump();

    expect(find.byType(AppListTile), findsNothing);
    expect(find.text('Alpha'), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('app-page-overflow')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.projectShowArchived));
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
  });
}

Future<void> _pumpAction(
  WidgetTester tester, {
  required FakeProjectRepository repo,
  bool archived = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        projectRepositoryProvider.overrideWith((Ref _) => repo),
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Scaffold(
          body: ProjectArchiveAction(
            project: aProject(
              name: 'Alpha',
            ).copyWith(status: archived ? ProjectStatus.archived : null),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpList(
  WidgetTester tester, {
  required FakeProjectRepository repo,
}) async {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.projects,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.projects,
        builder: (BuildContext _, GoRouterState _) {
          return const ProjectListScreen();
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
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
