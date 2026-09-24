import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/dictation_scope.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/projects/domain/project_repository.dart';
import 'package:tapture/features/projects/presentation/project_export_screen.dart';
import 'package:tapture/features/projects/presentation/project_filters_screen.dart';
import 'package:tapture/features/projects/presentation/project_list_screen.dart';
import 'package:tapture/features/projects/projects.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/factories.dart';
import '../../../support/fakes/fake_stt_service.dart';
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
  });

  testWidgets('an empty list renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.projectsEmptyHeadline), findsOneWidget);
    expect(find.text(Copy.projectsEmptyMessage), findsOneWidget);
    expect(find.text(Copy.projectsCreate), findsOneWidget);
    expect(find.byType(AppPrimaryAction), findsOneWidget);
    expect(find.text(Copy.projectsImport), findsNothing);

    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pumpAndSettle();
    expect(find.text('create'), findsOneWidget);
  });

  testWidgets('a populated list renders counts and last-worked time', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    repo.seedCounts(
      'project-1',
      recordCount: 2,
      unprocessedCount: 1,
      lastWorkedAt: DateTime.utc(2026, 9, 17, 8),
    );
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    expect(find.byType(AppListTile), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(
      find.text(Copy.projectListSubtitle(records: 2, unprocessed: 1)),
      findsOneWidget,
    );
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
              message: 'The project list could not be read.',
              recoveryAction: 'Try again.',
            ),
          ),
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('The project list could not be read.'), findsOneWidget);
  });

  testWidgets('the landing list paints inside the two-second budget', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    for (int index = 0; index < AppConstants.lists.pageSize; index++) {
      _ok(
        await repo.create(
          aProject(id: 'project-$index', name: 'Project $index'),
        ),
      );
      repo.seedCounts(
        'project-$index',
        recordCount: index,
        unprocessedCount: index ~/ 2,
      );
    }
    final Stopwatch watch = Stopwatch()..start();
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();
    watch.stop();

    expect(
      find.byType(AppListTile),
      findsNWidgets(AppConstants.lists.pageSize),
    );
    expect(watch.elapsedMilliseconds, lessThan(2000));
  });

  testWidgets('Create a project shows with zero, one and many projects', (
    WidgetTester tester,
  ) async {
    for (final int count in <int>[0, 1, 3]) {
      final FakeProjectRepository repo = FakeProjectRepository();
      addTearDown(repo.dispose);
      for (int index = 0; index < count; index++) {
        _ok(
          await repo.create(
            aProject(id: 'project-$index', name: 'Project $index'),
          ),
        );
      }
      await _pump(tester, repo: repo);
      await tester.pumpAndSettle();

      expect(find.byType(AppPrimaryAction), findsOneWidget);
      expect(find.text(Copy.projectsCreate), findsOneWidget);

      await tester.tap(find.byType(AppPrimaryAction));
      await tester.pumpAndSettle();
      expect(find.text('create'), findsOneWidget);
    }
  });

  testWidgets('the title bar offers Show archived at 400 and 800 dp', (
    WidgetTester tester,
  ) async {
    for (final double width in <double>[400, 800]) {
      final FakeProjectRepository repo = FakeProjectRepository();
      addTearDown(repo.dispose);
      _ok(await repo.create(aProject(name: 'Alpha')));
      _ok(await repo.setStatus('project-1', ProjectStatus.archived));
      _bindSize(tester, width);
      await _pump(tester, repo: repo);
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(AppSwitchTile), findsNothing);
      expect(find.text('Alpha'), findsNothing);
      expect(find.byKey(ProjectListActions.createKey), findsNothing);
      expect(find.byType(AppPrimaryAction), findsOneWidget);
      expect(find.text(Copy.projectsCreate), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('app-page-overflow')),
        meetsTapTarget(),
      );
      expect(
        find.byKey(const ValueKey<String>('app-page-overflow')),
        hasSemanticLabel(Copy.overflowMenu),
      );

      await tester.tap(find.byType(AppPrimaryAction));
      await tester.pumpAndSettle();
      expect(find.text('create'), findsOneWidget);
    }
  });

  testWidgets('Show archived lives in the more menu and filters the list', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    _ok(await repo.setStatus('project-1', ProjectStatus.archived));
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('Alpha'), findsNothing);

    await _openPageOverflow(tester);
    expect(find.text(Copy.projectShowArchived), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_outlined), findsWidgets);
    await tester.tap(find.text(Copy.projectShowArchived));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(_rowNumber('project-1', '1'), findsOneWidget);

    await _openPageOverflow(tester);
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.tap(find.text(Copy.projectShowArchived));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsNothing);
  });

  testWidgets('Create a project shows with zero projects at every width', (
    WidgetTester tester,
  ) async {
    for (final double width in <double>[400, 800, 1200]) {
      final FakeProjectRepository repo = FakeProjectRepository();
      addTearDown(repo.dispose);
      _bindSize(tester, width);
      await _pump(tester, repo: repo);
      await tester.pumpAndSettle();

      if (width < 1024) {
        expect(find.byType(AppPrimaryAction), findsOneWidget);
        expect(find.text(Copy.projectsCreate), findsOneWidget);
        expect(find.text(Copy.projectsEmptyHeadline), findsOneWidget);
      } else {
        expect(find.byType(AppPrimaryAction), findsNothing);
        expect(find.text(Copy.projectsCreate), findsNothing);
      }
    }
  });

  testWidgets(
    'Create a project stays in the body at 400 and 800 dp with projects',
    (WidgetTester tester) async {
      for (final double width in <double>[400, 800]) {
        final FakeProjectRepository repo = FakeProjectRepository();
        addTearDown(repo.dispose);
        _ok(await repo.create(aProject(name: 'Alpha')));
        _bindSize(tester, width);
        await _pump(tester, repo: repo);
        await tester.pumpAndSettle();

        expect(find.byType(AppListTile), findsOneWidget);
        expect(find.text('Alpha'), findsOneWidget);
        expect(find.byType(AppPrimaryAction), findsOneWidget);
        expect(find.text(Copy.projectsCreate), findsOneWidget);
      }
    },
  );

  testWidgets('Create a project hides at 1200 dp when projects exist', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    _bindSize(tester, 1200);
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    expect(find.byType(AppListTile), findsNothing);
    expect(find.byType(AppPrimaryAction), findsNothing);
    expect(find.text(Copy.projectsCreate), findsNothing);
  });

  testWidgets('Show archived fits at 360 dp and 200 percent text', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(Checkbox), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('app-page-overflow')),
      findsOneWidget,
    );
    await _openPageOverflow(tester);
    expect(find.text(Copy.projectShowArchived), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rows are numbered in display order and renumber on pin', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(id: 'project-1', name: 'Alpha')));
    _ok(await repo.create(aProject(id: 'project-2', name: 'Beta')));
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();

    expect(_rowNumber('project-1', '1'), findsOneWidget);
    expect(_rowNumber('project-2', '2'), findsOneWidget);

    await tester.tap(_rowMenu('project-2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.projectPin));
    await tester.pumpAndSettle();

    expect(_rowNumber('project-2', '1'), findsOneWidget);
    expect(_rowNumber('project-1', '2'), findsOneWidget);
    expect(
      repo.stored.where((Project p) => p.id == 'project-2').single.pinnedAt,
      isNotNull,
    );
  });

  testWidgets('the row number leads at the start edge in RTL', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(name: 'Alpha')));
    await _pump(tester, repo: repo, rtl: true);
    await tester.pumpAndSettle();

    final double numberX = tester.getCenter(_rowNumber('project-1', '1')).dx;
    final double titleX = tester.getCenter(find.text('Alpha')).dx;
    final double menuX = tester.getCenter(_rowMenu('project-1')).dx;
    expect(numberX, greaterThan(titleX));
    expect(titleX, greaterThan(menuX));
  });

  testWidgets('export from the row menu opens that project', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    _ok(await repo.create(aProject(id: 'project-1', name: 'Alpha')));
    await _pump(tester, repo: repo);
    await tester.pumpAndSettle();
    await tester.tap(_rowMenu('project-1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.projectExport));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ProjectExportScreen>(find.byType(ProjectExportScreen))
          .projectId,
      'project-1',
    );
  });

  testWidgets('the filter sits after the microphone and opens filters', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    await _pump(tester, repo: repo, speech: true);
    await tester.pumpAndSettle();
    final Finder mic = find.byKey(
      const ValueKey<String>('app-text-field-dictate'),
    );
    final Finder filter = find.byTooltip(Copy.projectFilters(0));
    expect(mic, findsOneWidget);
    expect(filter, findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(tester.getCenter(filter).dx, greaterThan(tester.getCenter(mic).dx));
    await tester.tap(filter);
    await tester.pumpAndSettle();
    expect(find.byType(ProjectFiltersScreen), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  FakeProjectRepository? repo,
  List<Override> overrides = const <Override>[],
  bool rtl = false,
  bool speech = false,
}) async {
  final FakeSttService? stt = speech ? FakeSttService() : null;
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.projects,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.projects,
        builder: (BuildContext _, GoRouterState _) {
          return const ProjectListScreen();
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'new',
            builder: (BuildContext _, GoRouterState _) {
              return const Text('create');
            },
          ),
          GoRoute(
            path: 'filters',
            builder: (BuildContext _, GoRouterState _) {
              return const ProjectFiltersScreen();
            },
          ),
          GoRoute(
            path: ':projectId',
            builder: (BuildContext _, GoRouterState _) {
              return const SizedBox.shrink();
            },
            routes: <RouteBase>[
              GoRoute(
                path: 'exports',
                builder: (BuildContext _, GoRouterState state) {
                  return ProjectExportScreen(
                    projectId: state.pathParameters['projectId']!,
                  );
                },
              ),
              GoRoute(
                path: 'edit',
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
        if (repo != null)
          projectRepositoryProvider.overrideWith((Ref _) => repo),
        ...overrides,
      ],
      child: MaterialApp.router(
        theme: buildTheme(brightness: Brightness.light),
        routerConfig: router,
        builder: (BuildContext _, Widget? child) {
          Widget wrapped = child ?? const SizedBox.shrink();
          if (rtl) {
            wrapped = Directionality(
              textDirection: TextDirection.rtl,
              child: wrapped,
            );
          }
          final FakeSttService? speechService = stt;
          if (speechService != null) {
            wrapped = DictationScope(
              service: speechService,
              languageTag: 'en',
              child: wrapped,
            );
          }
          return wrapped;
        },
      ),
    ),
  );
}

Future<void> _openPageOverflow(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('app-page-overflow')));
  await tester.pumpAndSettle();
}

Finder _rowMenu(String id) {
  return find.descendant(
    of: find.byKey(ValueKey<String>('project-row-$id')),
    matching: find.byType(AppOverflowMenu),
  );
}

Finder _rowNumber(String id, String n) {
  return find.descendant(
    of: find.byKey(ValueKey<String>('project-row-$id')),
    matching: find.text(n),
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

void _bindSize(WidgetTester tester, double width) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
