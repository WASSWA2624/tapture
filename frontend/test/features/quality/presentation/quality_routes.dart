import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/features/quality/quality.dart';

import '../../../support/fakes/fake_quality_repository.dart';
import '../../../support/screen_matrix.dart';

/// Where a stub destination says the router landed.
String landedOn(String location) => 'landed:$location';

/// Pumps the quality screens under a router at [initial], over [quality].
///
/// The project's quality routes are the real screens; every other project
/// destination is a stub that prints [landedOn] its location, so a test can
/// read where a tap went.
Future<GoRouter> pumpQualityRoutes(
  WidgetTester tester, {
  required FakeQualityRepository quality,
  required String initial,
  List<Override> overrides = const <Override>[],
  ScreenMatrix? cell,
}) async {
  if (cell != null) {
    tester.view.physicalSize = cell.size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  final GoRouter router = GoRouter(
    initialLocation: initial,
    routes: <RouteBase>[
      GoRoute(
        path: '/projects/:projectId',
        builder: (BuildContext _, GoRouterState state) =>
            _Stub(location: state.uri.toString()),
        routes: <RouteBase>[
          GoRoute(
            path: 'duplicates',
            builder: (BuildContext _, GoRouterState state) =>
                DuplicatesScreen(projectId: state.pathParameters['projectId']!),
            routes: <RouteBase>[
              GoRoute(
                path: ':pairId',
                builder: (BuildContext _, GoRouterState state) =>
                    DuplicateCompareScreen(
                      projectId: state.pathParameters['projectId']!,
                      pairId: state.pathParameters['pairId']!,
                    ),
              ),
            ],
          ),
          GoRoute(
            path: 'variance',
            builder: (BuildContext _, GoRouterState state) => VarianceScreen(
              projectId: state.pathParameters['projectId']!,
              recordId: state.uri.queryParameters['record'],
            ),
          ),
          GoRoute(
            path: 'quality',
            builder: (BuildContext _, GoRouterState state) =>
                QualitySummaryScreen(
                  projectId: state.pathParameters['projectId']!,
                ),
          ),
          for (final String stub in <String>['review', 'exports', 'records'])
            GoRoute(
              path: stub,
              builder: (BuildContext _, GoRouterState state) =>
                  _Stub(location: state.uri.toString()),
              routes: <RouteBase>[
                GoRoute(
                  path: ':recordId',
                  builder: (BuildContext _, GoRouterState state) =>
                      _Stub(location: state.uri.toString()),
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
        qualityRepositoryProvider.overrideWithValue(quality),
        ...overrides,
      ],
      child: MaterialApp.router(
        theme: buildTheme(
          brightness: cell?.brightness ?? Brightness.light,
          outdoor: cell?.outdoor ?? false,
        ),
        builder: (BuildContext context, Widget? child) => cell == null
            ? child!
            : MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(cell.textScale)),
                child: child!,
              ),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

class _Stub extends StatelessWidget {
  const _Stub({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Material(child: Center(child: Text(landedOn(location))));
  }
}
