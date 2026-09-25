import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/projects/domain/project_repository.dart';
import 'package:tapture/features/projects/presentation/project_records_screen.dart';
import 'package:tapture/features/projects/projects.dart';

import '../fakes/fake_project_repository.dart';

void main() {
  testWidgets('the process list shows a captured record', (
    WidgetTester tester,
  ) async {
    final FakeProjectRepository repo = FakeProjectRepository();
    addTearDown(repo.dispose);
    repo.seedRecords('project-1', const <ProjectRecordRow>[
      (
        id: 'r1',
        status: 'captured',
        photoCount: 2,
        thumbPath: null,
        fields: <ProjectRecordFieldValue>[],
      ),
      (
        id: 'r2',
        status: 'approved',
        photoCount: 1,
        thumbPath: null,
        fields: <ProjectRecordFieldValue>[],
      ),
    ]);
    final GoRouter router = GoRouter(
      initialLocation:
          '${RoutePaths.projectRecords('project-1')}?filter=queued',
      routes: <RouteBase>[
        GoRoute(
          path: '${RoutePaths.projects}/:projectId/records',
          builder: (BuildContext _, GoRouterState state) {
            return ProjectRecordsScreen(
              projectId: state.pathParameters['projectId']!,
            );
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

    expect(find.text(Copy.projectRecordPosition(1)), findsOneWidget);
    expect(find.byTooltip(Copy.recordEdit), findsOneWidget);
    expect(find.text(Copy.projectRecordPosition(2)), findsNothing);
  });
}
