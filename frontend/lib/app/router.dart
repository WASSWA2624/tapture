import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/nav_shell.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/gallery/widget_gallery_screen.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/onboarding/onboarding.dart';

part 'route_guards.dart';

/// The type `router.dart` is named for (FE-STR-06). The contract publishes
/// [AppRoutes] and [routerProvider].
typedef Router = GoRouter;

/// Every path, declared once. Screens navigate through these helpers and
/// never concatenate a path string (FE-CODE-09).
abstract final class AppRoutes {
  /// The project picker. A project-scoped deep link with no project open
  /// lands here, carrying the intended location as [fromQuery].
  static const String projects = '/projects';

  /// Query key for the location a diverted deep link should resume at.
  static const String fromQuery = 'from';

  /// The first-run gate. Task 267 can insert sign-in in front of this path.
  static const String firstRun = '/first-run';

  /// One project's home.
  static String project(String id) => '$projects/${Uri.encodeComponent(id)}';

  /// Capture for [projectId].
  static String capture(String projectId) => '${project(projectId)}/capture';

  /// One record, opened directly from a deep link.
  static String record(String id) => '/records/${Uri.encodeComponent(id)}';
}

/// The process-wide router. Kept alive: the shell watches it on every frame
/// (FE-STATE-09).
final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  final ValueNotifier<int> refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen<String?>(openProjectIdProvider, (String? previous, String? next) {
    refresh.value++;
  });
  ref.listen<FirstRunSnapshot>(firstRunProvider, (
    FirstRunSnapshot? previous,
    FirstRunSnapshot next,
  ) {
    refresh.value++;
  });
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.projects,
    refreshListenable: refresh,
    redirect: (BuildContext _, GoRouterState state) {
      for (final RouteGuard guard in appGuards()) {
        final String? to = guard(state, ref);
        if (to != null) {
          return to;
        }
      }
      return null;
    },
    routes: _routes,
    errorBuilder: _notFound,
  );
  ref.onDispose(router.dispose);
  return router;
});

List<RouteBase> get _routes {
  final List<RouteBase> routes = <RouteBase>[
    GoRoute(
      path: '/',
      redirect: (BuildContext _, GoRouterState _) => AppRoutes.projects,
    ),
    GoRoute(
      path: AppRoutes.firstRun,
      builder: (BuildContext _, GoRouterState _) {
        return const FirstRunScreen();
      },
    ),
    StatefulShellRoute.indexedStack(
      builder:
          (BuildContext _, GoRouterState _, StatefulNavigationShell shell) {
            return NavShell(shell: shell);
          },
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.projects,
              builder: (BuildContext _, GoRouterState _) {
                return const _RoutePage(name: 'projects');
              },
              routes: <RouteBase>[
                GoRoute(
                  path: ':projectId',
                  metadata: _projectScoped,
                  builder: (BuildContext _, GoRouterState _) {
                    return const _RoutePage(name: 'project');
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: _captureTab,
              builder: (BuildContext _, GoRouterState _) {
                return const _RoutePage(name: 'capture');
              },
            ),
            GoRoute(
              path: '${AppRoutes.projects}/:projectId/capture',
              metadata: _projectScoped,
              builder: (BuildContext _, GoRouterState _) {
                return const _RoutePage(name: 'capture');
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/records',
              builder: (BuildContext _, GoRouterState _) {
                return const _RoutePage(name: 'records');
              },
              routes: <RouteBase>[
                GoRoute(
                  path: ':recordId',
                  builder: (BuildContext _, GoRouterState _) {
                    return const _RoutePage(name: 'record');
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/more',
              builder: (BuildContext _, GoRouterState _) {
                return const _RoutePage(name: 'more');
              },
            ),
          ],
        ),
      ],
    ),
  ];
  if (kDebugMode) {
    routes.add(
      GoRoute(
        path: WidgetGalleryScreen.route,
        builder: (BuildContext _, GoRouterState _) {
          return const WidgetGalleryScreen();
        },
      ),
    );
  }
  return routes;
}

Widget _notFound(BuildContext context, GoRouterState state) {
  final String path = state.uri.path.replaceAll('"', "'");
  return Scaffold(
    body: SafeArea(
      child: Center(
        child: AppErrorState(
          failure: ValidationFailure(
            message: 'The page "$path" is not in Tapture.',
            recoveryAction: 'Go back to projects and try again.',
          ),
          onRetry: () => context.go(AppRoutes.projects),
        ),
      ),
    ),
  );
}

class _RoutePage extends StatelessWidget {
  const _RoutePage({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(name, key: ValueKey<String>('route-$name')),
          TextField(key: ValueKey<String>('field-$name')),
        ],
      ),
    );
  }
}

const String _projectScopedKey = 'projectScoped';

const String _captureTab = '/capture';

const Map<String, dynamic> _projectScoped = <String, dynamic>{
  _projectScopedKey: true,
};
