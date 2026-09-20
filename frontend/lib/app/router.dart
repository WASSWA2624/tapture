import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/nav_shell.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_brand_lockup.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/gallery/widget_gallery_screen.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/projects/presentation/current_project.dart';
import 'package:tapture/features/projects/presentation/project_create_screen.dart';
import 'package:tapture/features/projects/presentation/project_edit_screen.dart';
import 'package:tapture/features/projects/presentation/project_home_screen.dart';
import 'package:tapture/features/projects/presentation/project_list_screen.dart';
import 'package:tapture/features/projects/presentation/project_settings_screen.dart';
import 'package:tapture/features/settings/presentation/app_lock_screen.dart';
import 'package:tapture/features/settings/presentation/appearance_settings_screen.dart';
import 'package:tapture/features/settings/presentation/capture_settings_screen.dart';
import 'package:tapture/features/settings/presentation/settings_screen.dart';
import 'package:tapture/features/settings/presentation/storage_settings_screen.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/presentation/template_create_screen.dart';
import 'package:tapture/features/templates/presentation/template_list_screen.dart';

export 'package:tapture/features/projects/presentation/current_project.dart'
    show CurrentProject, currentProjectProvider, openProjectIdProvider;

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

  /// App-lock unlock gate. Covers launch, resume and deep links.
  static const String lock = '/lock';

  /// One project's home.
  static String project(String id) => '$projects/${Uri.encodeComponent(id)}';

  /// Create or duplicate a project. Listed before [project] so `new` is
  /// not captured as an id.
  static const String projectCreate = '$projects/new';

  /// Query key for the project whose structure is being copied.
  static const String sourceQuery = 'source';

  /// Query key for the editable suggested name on the create form.
  static const String nameQuery = 'name';

  /// Create form, optionally prefilled from [sourceId] and [name].
  static String projectCreateFrom({String? sourceId, String? name}) {
    return Uri(
      path: projectCreate,
      queryParameters: <String, String>{
        if (sourceId != null && sourceId.isNotEmpty) sourceQuery: sourceId,
        if (name != null && name.isNotEmpty) nameQuery: name,
      },
    ).toString();
  }

  /// Capture for [projectId].
  static String capture(String projectId) => '${project(projectId)}/capture';

  /// Details form for [projectId].
  static String projectEdit(String projectId) => '${project(projectId)}/edit';

  /// Per-project settings for [projectId].
  static String projectSettings(String projectId) =>
      '${project(projectId)}/settings';

  /// One record, opened directly from a deep link.
  static String record(String id) => '/records/${Uri.encodeComponent(id)}';

  /// The records list.
  static const String records = '/records';

  /// Settings tab of the four-destination shell.
  static const String more = '/more';

  /// Pinned-template destination the status line opens. Task 092 owns the
  /// screen.
  static const String templates = '/templates';

  /// Blank-template form. Listed before [template] so `new` is not an id.
  static const String templateCreate = '$templates/new';

  /// Shipped-library picker. Task 093 owns the screen.
  static const String templateLibrary = '$templates/library';

  /// Field list for [id]. Task 094 owns the screen.
  static String template(String id) => '$templates/${Uri.encodeComponent(id)}';

  /// JSON export for [id]. Task 100 owns the screen.
  static String templateExport(String id) => '${template(id)}/export';

  /// Unprocessed-queue destination the status line opens. Task 159 owns the
  /// screen.
  static const String queue = '/queue';

  /// Export history. Task 207 owns the screen.
  static const String exports = '/exports';

  /// Query key for a filtered list opened from a home count.
  static const String filterQuery = 'filter';

  /// Review list filter: records that need a person.
  static const String reviewFilter = 'needsReview';

  /// Process list filter: records waiting to be processed.
  static const String processFilter = 'queued';

  /// Export list filter: approved records ready to write out.
  static const String exportFilter = 'approved';

  /// Share list filter: finished export files.
  static const String shareFilter = 'share';

  /// Records already filtered to [filter].
  static String recordsFiltered(String filter) {
    return Uri(
      path: records,
      queryParameters: <String, String>{filterQuery: filter},
    ).toString();
  }

  /// Queue already filtered to [filter].
  static String queueFiltered(String filter) {
    return Uri(
      path: queue,
      queryParameters: <String, String>{filterQuery: filter},
    ).toString();
  }

  /// Export history already filtered to [filter].
  static String exportsFiltered(String filter) {
    return Uri(
      path: exports,
      queryParameters: <String, String>{filterQuery: filter},
    ).toString();
  }

  /// Operator profile under Settings.
  static const String settingsOperator = '$more/operator';

  /// Capture defaults under Settings.
  static const String settingsCapture = '$more/capture';

  /// AI section. The screen arrives in a later phase.
  static const String settingsAi = '$more/ai';

  /// Language section. The screen arrives in a later phase.
  static const String settingsLanguage = '$more/language';

  /// Appearance under Settings: system, light, dark or outdoor.
  static const String settingsAppearance = '$more/appearance';

  /// Storage usage under Settings.
  static const String settingsStorage = '$more/storage';

  /// Files section (specification "Data"). The screen arrives later.
  static const String settingsFiles = '$more/files';

  /// App lock under Settings.
  static const String settingsSecurity = '$more/security';

  /// About under Settings.
  static const String settingsAbout = '$more/about';
}

/// The process-wide router. Kept alive: the shell watches it on every frame
/// (FE-STATE-09).
final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  final ValueNotifier<int> refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen<String?>(openProjectIdProvider, (String? previous, String? next) {
    refresh.value++;
  });
  ref.listen<AppLockSession>(appLockSessionProvider, (
    AppLockSession? previous,
    AppLockSession next,
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
      path: AppRoutes.lock,
      builder: (BuildContext _, GoRouterState _) {
        return const AppLockScreen();
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
                return const ProjectListScreen();
              },
              routes: <RouteBase>[
                GoRoute(
                  path: 'new',
                  builder: (BuildContext _, GoRouterState state) {
                    return ProjectCreateScreen(
                      sourceId:
                          state.uri.queryParameters[AppRoutes.sourceQuery],
                      initialName:
                          state.uri.queryParameters[AppRoutes.nameQuery],
                    );
                  },
                ),
                GoRoute(
                  path: ':projectId',
                  metadata: _projectScoped,
                  builder: (BuildContext _, GoRouterState _) {
                    return const ProjectHomeScreen();
                  },
                  routes: <RouteBase>[
                    GoRoute(
                      path: 'edit',
                      metadata: _projectScoped,
                      builder: (BuildContext _, GoRouterState _) {
                        return const ProjectEditScreen();
                      },
                    ),
                    GoRoute(
                      path: 'settings',
                      metadata: _projectScoped,
                      builder: (BuildContext _, GoRouterState _) {
                        return const ProjectSettingsScreen();
                      },
                    ),
                  ],
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
                return const SettingsScreen(showAppBar: false);
              },
              routes: <RouteBase>[
                GoRoute(
                  path: 'operator',
                  builder: (BuildContext _, GoRouterState _) {
                    return const OperatorProfileScreen();
                  },
                ),
                GoRoute(
                  path: 'capture',
                  builder: (BuildContext _, GoRouterState _) {
                    return const CaptureSettingsScreen();
                  },
                ),
                GoRoute(
                  path: 'appearance',
                  builder: (BuildContext _, GoRouterState _) {
                    return const AppearanceSettingsScreen();
                  },
                ),
                GoRoute(
                  path: 'storage',
                  builder: (BuildContext _, GoRouterState _) {
                    return const StorageSettingsScreen();
                  },
                ),
                GoRoute(
                  path: 'security',
                  builder: (BuildContext _, GoRouterState _) {
                    return const AppLockScreen.manage();
                  },
                ),
                GoRoute(
                  path: 'about',
                  builder: (BuildContext _, GoRouterState _) {
                    return const AboutScreen();
                  },
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.templates,
              builder: (BuildContext _, GoRouterState _) {
                return const TemplateListScreen();
              },
              routes: <RouteBase>[
                GoRoute(
                  path: 'new',
                  builder: (BuildContext _, GoRouterState _) {
                    return const TemplateCreateScreen();
                  },
                ),
                GoRoute(
                  path: 'library',
                  builder: (BuildContext _, GoRouterState _) {
                    return const _RoutePage(name: 'template-library');
                  },
                ),
                GoRoute(
                  path: ':templateId',
                  builder: (BuildContext _, GoRouterState _) {
                    return const _RoutePage(name: 'template-fields');
                  },
                  routes: <RouteBase>[
                    GoRoute(
                      path: 'export',
                      builder: (BuildContext _, GoRouterState _) {
                        return const _RoutePage(name: 'template-export');
                      },
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.queue,
              builder: (BuildContext _, GoRouterState _) {
                return const _RoutePage(name: 'queue');
              },
            ),
            GoRoute(
              path: AppRoutes.exports,
              builder: (BuildContext _, GoRouterState _) {
                return const _RoutePage(name: 'exports');
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
    final bool settings = name == 'more';
    final bool listLike = _isListRoute(name);
    final bool showSearch = listLike && context.sizeClass != SizeClass.expanded;
    return AppPage(
      key: ValueKey<String>('route-$name'),
      title: title,
      showAppBar: false,
      inset: !listLike && !settings,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (settings) ...<Widget>[
            const AppListTile(
              title: Copy.appName,
              subtitle: Copy.operatorNameUse,
              leading: AppBrandLockup(showName: false),
            ),
            const AppSectionHeader(title: Copy.navMore),
            AppListTile(
              title: Copy.navTemplates,
              leading: const Icon(Icons.article_outlined),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AppRoutes.templates),
            ),
            AppListTile(
              title: Copy.navQueue,
              leading: const Icon(Icons.pending_outlined),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AppRoutes.queue),
            ),
          ],
          if (showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.x3,
                Space.x1,
                Space.x3,
                Space.x2,
              ),
              child: AppSearchField(hint: Copy.search, onChanged: (_) {}),
            ),
          if (!settings)
            AppEmptyState(
              icon: _iconFor(name),
              headline: Copy.emptyHeadline,
              message: Copy.emptyMessage,
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
    'template-library' => Copy.templatesPickLibrary,
    'template-fields' => Copy.templateFieldsTitle,
    'template-export' => Copy.templatesExport,
    'queue' => Copy.navQueue,
    'exports' => Copy.navExports,
    _ => Copy.emptyHeadline,
  };
}

IconData _iconFor(String name) {
  return switch (name) {
    'projects' || 'project' => Icons.folder_outlined,
    'capture' => Icons.photo_camera_outlined,
    'records' || 'record' => Icons.list_alt_outlined,
    'more' => Icons.settings_outlined,
    'templates' => Icons.article_outlined,
    'template-library' => Icons.article_outlined,
    'template-fields' => Icons.view_list_outlined,
    'template-export' => Icons.ios_share_outlined,
    'queue' => Icons.pending_outlined,
    'exports' => Icons.ios_share_outlined,
    _ => Icons.inbox_outlined,
  };
}

bool _isListRoute(String name) {
  return name == 'projects' ||
      name == 'project' ||
      name == 'records' ||
      name == 'record' ||
      name == 'templates' ||
      name == 'queue' ||
      name == 'exports';
}

const String _projectScopedKey = 'projectScoped';

const String _captureTab = '/capture';

const Map<String, dynamic> _projectScoped = <String, dynamic>{
  _projectScopedKey: true,
};
