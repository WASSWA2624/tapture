import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/features/projects/presentation/project_duplicate_action.dart';

void main() {
  testWidgets('duplicate opens create with a suggested name', (
    WidgetTester tester,
  ) async {
    late String opened;
    final GoRouter router = GoRouter(
      initialLocation: '/projects/source-1',
      routes: <RouteBase>[
        GoRoute(
          path: '/projects',
          builder: (BuildContext _, GoRouterState _) {
            return const SizedBox.shrink();
          },
          routes: <RouteBase>[
            GoRoute(
              path: 'new',
              builder: (BuildContext _, GoRouterState state) {
                opened = state.uri.toString();
                return const Text('create');
              },
            ),
            GoRoute(
              path: ':projectId',
              builder: (BuildContext _, GoRouterState _) {
                return const ProjectDuplicateAction(
                  sourceId: 'source-1',
                  sourceName: 'Alpha',
                );
              },
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: buildTheme(brightness: Brightness.light),
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, Copy.projectsDuplicate));
    await tester.pumpAndSettle();

    expect(find.text('create'), findsOneWidget);
    expect(opened, contains('source=source-1'));
    expect(opened, contains('copy'));
  });
}
