import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/nav_shell.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_page.dart';
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

  /// The records list.
  static const String records = '/records';

  /// Settings and the rest of the four-destination shell.
  static const String more = '/more';

  /// Pinned-template destination the status line opens. Task 092 owns the
  /// screen.
  static const String templates = '/templates';

  /// Unprocessed-queue destination the status line opens. Task 159 owns the
  /// screen.
  static const String queue = '/queue';
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
              path: AppRoutes.records,
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
              path: AppRoutes.more,
              builder: (BuildContext _, GoRouterState _) {
                return const _RoutePage(name: 'more');
              },
            ),
            GoRoute(
              path: AppRoutes.templates,
              builder: (BuildContext _, GoRouterState _) {
                return const _RoutePage(name: 'templates');
              },
            ),
            GoRoute(
              path: AppRoutes.queue,
              builder: (BuildContext _, GoRouterState _) {
                return const _RoutePage(name: 'queue');
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
    final String title = _titleFor(name);
    return AppPage(
      key: ValueKey<String>('route-$name'),
      title: title,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            Copy.emptyHeadline,
            style: AppText.bodyStrong.copyWith(color: context.colors.onSurface),
          ),
          const SizedBox(height: Space.x2),
          Text(
            Copy.emptyMessage,
            style: AppText.body.copyWith(color: context.colors.onSurface),
          ),
          SizedBox(
            width: 0,
            height: 0,
            child: TextField(key: ValueKey<String>('field-$name')),
          ),
        ],
      ),
    );
  }
}

String _titleFor(String name) {
  return switch (name) {
    'projects' || 'project' => Copy.navProjects,
    'capture' => Copy.navCapture,
    'records' || 'record' => Copy.navRecords,
    'more' => Copy.navMore,
    'templates' => Copy.navTemplates,
    'queue' => Copy.navQueue,
    _ => Copy.emptyHeadline,
  };
}

const String _projectScopedKey = 'projectScoped';

const String _captureTab = '/capture';

const Map<String, dynamic> _projectScoped = <String, dynamic>{
  _projectScopedKey: true,
};
