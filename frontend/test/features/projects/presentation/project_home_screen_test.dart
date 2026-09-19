import 'dart:async';

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
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/projects/domain/project_repository.dart';
import 'package:tapture/features/projects/presentation/current_project.dart';
import 'package:tapture/features/projects/presentation/project_home_screen.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/factories.dart';
import '../fakes/fake_project_repository.dart';

void main() {
  testWidgets('loading renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    final StreamController<List<ProjectListRow>> pending =
        StreamController<List<ProjectListRow>>();
    addTearDown(pending.close);
    await _pump(
      tester,
      overrides: <Override>[
        projectListProvider.overrideWith((Ref _) => pending.stream),
      ],
    );
    await tester.pump();

    expect(find.byType(AppSkeleton), findsOneWidget);
    expect(find.byType(AppPrimaryAction), findsNothing);
  });

  testWidgets('an empty home renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    await _pump(tester, repo: repo);
    await tester.pump();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.homeEmptyHeadline), findsOneWidget);
    expect(find.byType(AppPrimaryAction), findsNothing);
  });

  testWidgets('a populated home shows context, counts and one primary action', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    repo.seedHomeCounts(
      'project-1',
      review: 2,
      process: 3,
      toExport: 1,
      toShare: 4,
    );
    await _pump(
      tester,
      repo: repo,
      openProjectId: 'project-1',
      contextLabel: 'Ward 1',
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Alpha'), findsWidgets);
    expect(find.text('Ward 1'), findsOneWidget);
    expect(find.text(Copy.homeReviewPending(2)), findsOneWidget);
    expect(find.text(Copy.homeProcessPending(3)), findsOneWidget);
    expect(find.text(Copy.homeExportPending(1)), findsOneWidget);
    expect(find.text(Copy.homeSharePending(4)), findsOneWidget);
    expect(find.byType(AppPrimaryAction), findsOneWidget);
    expect(find.text(Copy.continueCapturing), findsOneWidget);
    expect(find.text(Copy.unprocessedCount(0)), findsNothing);

    final Size screen = tester.getSize(find.byType(MaterialApp));
    final Offset action = tester.getCenter(find.byType(AppPrimaryAction));
    expect(action.dy, greaterThan(screen.height * 2 / 3));
  });

  testWidgets('a failed load renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      overrides: <Override>[
        projectListProvider.overrideWith(
          (Ref _) => Stream<List<ProjectListRow>>.error(
            const StorageFailure(
              message: 'The project home could not be read.',
              recoveryAction: 'Try again.',
            ),
          ),
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('The project home could not be read.'), findsOneWidget);
    expect(find.byType(AppPrimaryAction), findsNothing);
  });

  testWidgets('each count opens its filtered list', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    repo.seedHomeCounts(
      'project-1',
      review: 2,
      process: 3,
      toExport: 1,
      toShare: 4,
    );

    Future<void> expectOpens({
      required Finder tap,
      required String path,
      String? filter,
    }) async {
      final GoRouter router = await _pump(
        tester,
        repo: repo,
        openProjectId: 'project-1',
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(tap);
      await tester.pump();
      expect(router.state.uri.path, path);
      expect(router.state.uri.queryParameters[AppRoutes.filterQuery], filter);
    }

    await expectOpens(
      tap: find.byKey(const ValueKey<String>('home-review')),
      path: AppRoutes.records,
      filter: AppRoutes.reviewFilter,
    );
    await expectOpens(
      tap: find.byKey(const ValueKey<String>('home-process')),
      path: AppRoutes.queue,
      filter: AppRoutes.processFilter,
    );
    await expectOpens(
      tap: find.byKey(const ValueKey<String>('home-export')),
      path: AppRoutes.records,
      filter: AppRoutes.exportFilter,
    );
    await expectOpens(
      tap: find.byKey(const ValueKey<String>('home-share')),
      path: AppRoutes.exports,
      filter: AppRoutes.shareFilter,
    );
    await expectOpens(
      tap: find.text(Copy.continueCapturing),
      path: AppRoutes.capture('project-1'),
    );
  });

  testWidgets('each home menu item reaches its route', (
    WidgetTester tester,
  ) async {
    Future<void> expectOpens({
      required String label,
      required String path,
      Map<String, String> query = const <String, String>{},
    }) async {
      final GoRouter router = await _pumpPopulated(tester);
      await _chooseOverflow(tester, label);
      expect(router.state.uri.path, path);
      for (final MapEntry<String, String> entry in query.entries) {
        expect(router.state.uri.queryParameters[entry.key], entry.value);
      }
    }

    await expectOpens(label: Copy.projectAllProjects, path: AppRoutes.projects);
    await expectOpens(label: Copy.projectNew, path: AppRoutes.projectCreate);
    await expectOpens(
      label: Copy.projectsDuplicate,
      path: AppRoutes.projectCreate,
      query: <String, String>{
        AppRoutes.sourceQuery: 'project-1',
        AppRoutes.nameQuery: Copy.projectCopyName('Alpha'),
      },
    );
    await expectOpens(
      label: Copy.projectEditTitle,
      path: AppRoutes.projectEdit('project-1'),
    );
    await expectOpens(
      label: Copy.projectSettingsTitle,
      path: AppRoutes.projectSettings('project-1'),
    );
  });

  testWidgets('archive from the home menu lands on the list', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pumpPopulated(tester);
    await _chooseOverflow(tester, Copy.projectArchive);
    expect(router.state.uri.path, AppRoutes.projects);
  });

  testWidgets('delete from the home menu lands on the list', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pumpPopulated(tester);
    await tester.tap(find.byType(AppOverflowMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.projectDelete));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Alpha');
    await tester.pump();
    await tester.tap(find.text(Copy.projectDelete).last);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.projects);
  });

  testWidgets('the home menu is labelled and meets 48dp', (
    WidgetTester tester,
  ) async {
    await _pumpPopulated(tester);
    expect(find.byType(AppOverflowMenu), meetsTapTarget());
    expect(find.byType(AppOverflowMenu), hasSemanticLabel(Copy.overflowMenu));
  });
}

Future<GoRouter> _pump(
  WidgetTester tester, {
  FakeProjectRepository? repo,
  String? openProjectId,
  String? contextLabel,
  List<Override> overrides = const <Override>[],
}) async {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.project(openProjectId ?? 'project-1'),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.projects,
        builder: (BuildContext _, GoRouterState _) {
          return const SizedBox.shrink();
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'new',
            builder: (BuildContext _, GoRouterState _) {
              return const Text('create');
            },
          ),
          GoRoute(
            path: ':projectId',
            builder: (BuildContext _, GoRouterState _) {
              return const ProjectHomeScreen();
            },
            routes: <RouteBase>[
              GoRoute(
                path: 'capture',
                builder: (BuildContext _, GoRouterState _) {
                  return const Text('capture');
                },
              ),
              GoRoute(
                path: 'edit',
                builder: (BuildContext _, GoRouterState _) {
                  return const Text('edit');
                },
              ),
              GoRoute(
                path: 'settings',
                builder: (BuildContext _, GoRouterState _) {
                  return const Text('settings');
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.records,
        builder: (BuildContext _, GoRouterState _) {
          return const Text('records');
        },
      ),
      GoRoute(
        path: AppRoutes.queue,
        builder: (BuildContext _, GoRouterState _) {
          return const Text('queue');
        },
      ),
      GoRoute(
        path: AppRoutes.exports,
        builder: (BuildContext _, GoRouterState _) {
          return const Text('exports');
        },
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        if (repo != null)
          projectRepositoryProvider.overrideWith((Ref _) => repo),
        if (openProjectId != null)
          projectSettingsStoreProvider.overrideWith(
            (Ref _) => SettingsStore.fake(
              stored: <String, Object?>{
                SettingKeys.openProjectId.name: openProjectId,
              },
            ),
          ),
        if (contextLabel != null)
          projectHomeContextProvider.overrideWith((Ref _) => contextLabel),
        ...overrides,
      ],
      child: MaterialApp.router(
        theme: buildTheme(brightness: Brightness.light),
        routerConfig: router,
      ),
    ),
  );
  return router;
}

Future<GoRouter> _pumpPopulated(WidgetTester tester) async {
  final FakeProjectRepository repo = FakeProjectRepository();
  addTearDown(repo.dispose);
  _ok(await repo.create(aProject(name: 'Alpha')));
  repo.seedHomeCounts(
    'project-1',
    review: 2,
    process: 3,
    toExport: 1,
    toShare: 4,
  );
  final GoRouter router = await _pump(
    tester,
    repo: repo,
    openProjectId: 'project-1',
    contextLabel: 'Ward 1',
  );
  await tester.pump();
  await tester.pump();
  return router;
}

Future<void> _chooseOverflow(WidgetTester tester, String label) async {
  await tester.tap(find.byType(AppOverflowMenu));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
