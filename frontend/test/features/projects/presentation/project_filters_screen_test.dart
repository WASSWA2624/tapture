import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/projects/presentation/project_filters_screen.dart';
import 'package:tapture/features/projects/projects.dart';

import '../fakes/fake_project_repository.dart';

void main() {
  testWidgets('filters apply together and the checkbox leads its label', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    final GoRouter router = GoRouter(
      initialLocation: RoutePaths.projectFilters,
      routes: <RouteBase>[
        GoRoute(
          path: RoutePaths.projects,
          builder: (BuildContext _, GoRouterState _) => const Text('list'),
          routes: <RouteBase>[
            GoRoute(
              path: 'filters',
              builder: (BuildContext _, GoRouterState _) {
                return const ProjectFiltersScreen();
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

    expect(find.text(Copy.projectStatusActive), findsOneWidget);
    expect(find.text(Copy.projectStatusArchived), findsOneWidget);
    expect(find.text(Copy.projectPinFilter), findsOneWidget);
    final Row row = tester.widget<Row>(
      find
          .ancestor(
            of: find.text(Copy.projectStatusActive),
            matching: find.byType(Row),
          )
          .first,
    );
    expect(row.children.first, isA<IgnorePointer>());

    await tester.tap(find.text(Copy.projectStatusArchived));
    await tester.pump();
    await tester.tap(find.text(Copy.projectApplyFilters));
    await tester.pumpAndSettle();

    final ProjectListCriteria criteria = ProviderScope.containerOf(
      tester.element(find.text('list')),
    ).read(projectListCriteriaProvider);
    expect(criteria.statuses, contains(ProjectStatus.archived));
    expect(find.text('list'), findsOneWidget);
  });
}
