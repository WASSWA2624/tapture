import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/nav_shell.dart';
import 'package:tapture/app/route_paths.dart';
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
import 'package:tapture/features/capture/capture.dart';
import 'package:tapture/features/context/presentation/context_hierarchy_screen.dart';
import 'package:tapture/features/context/presentation/context_preset_list.dart';
import 'package:tapture/features/processing/presentation/queue_screen.dart';
import 'package:tapture/features/projects/presentation/current_project.dart';
import 'package:tapture/features/projects/presentation/project_create_screen.dart';
import 'package:tapture/features/projects/presentation/project_edit_screen.dart';
import 'package:tapture/features/projects/presentation/project_home_screen.dart';
import 'package:tapture/features/projects/presentation/project_list_screen.dart';
import 'package:tapture/features/projects/presentation/project_settings_screen.dart';
import 'package:tapture/features/reference/data/dataset_csv_import.dart';
import 'package:tapture/features/reference/presentation/dataset_browser_screen.dart';
import 'package:tapture/features/reference/presentation/dataset_key_screen.dart';
import 'package:tapture/features/reference/presentation/dataset_list_screen.dart';
import 'package:tapture/features/reference/presentation/dataset_row_edit_screen.dart';
import 'package:tapture/features/settings/presentation/ai_provider_settings_screen.dart';
import 'package:tapture/features/settings/presentation/app_lock_screen.dart';
import 'package:tapture/features/settings/presentation/appearance_settings_screen.dart';
import 'package:tapture/features/settings/presentation/capture_settings_screen.dart';
import 'package:tapture/features/settings/presentation/settings_screen.dart';
import 'package:tapture/features/settings/presentation/storage_settings_screen.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/presentation/checklist_screen.dart';
import 'package:tapture/features/templates/presentation/detection_profile_screen.dart';
import 'package:tapture/features/templates/presentation/field_add_sheet.dart';
import 'package:tapture/features/templates/presentation/field_list_screen.dart';
import 'package:tapture/features/templates/presentation/identity_fields_screen.dart';
import 'package:tapture/features/templates/presentation/lookup_binding_screen.dart';
import 'package:tapture/features/templates/presentation/output_mapping_screen.dart';
import 'package:tapture/features/templates/presentation/required_columns_screen.dart';
import 'package:tapture/features/templates/presentation/row_aliases_screen.dart';
import 'package:tapture/features/templates/presentation/shipped_picker_screen.dart';
import 'package:tapture/features/templates/presentation/template_create_screen.dart';
import 'package:tapture/features/templates/presentation/template_import_action.dart';
import 'package:tapture/features/templates/presentation/template_list_screen.dart';
import 'package:tapture/features/templates/presentation/template_migration_screen.dart';
import 'package:tapture/features/templates/presentation/xlsx_mapping_screen.dart';

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
  static const String projects = RoutePaths.projects;

  /// Query key for the location a diverted deep link should resume at.
  static const String fromQuery = RoutePaths.fromQuery;

  /// App-lock unlock gate. Covers launch, resume and deep links.
  static const String lock = '/lock';

  /// One project's home.
  static String project(String id) => RoutePaths.project(id);

  /// Create or duplicate a project. Listed before [project] so `new` is
  /// not captured as an id.
  static const String projectCreate = RoutePaths.projectCreate;

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
  static String capture(String projectId) =>
      RoutePaths.projectCapture(projectId);

  /// Details form for [projectId].
  static String projectEdit(String projectId) =>
      RoutePaths.projectEdit(projectId);

  /// Per-project settings for [projectId].
  static String projectSettings(String projectId) =>
      RoutePaths.projectSettings(projectId);

  /// One record, opened directly from a deep link.
  static String record(String id) => RoutePaths.record(id);

  /// The records list.
  static const String records = RoutePaths.records;

  /// Settings tab of the four-destination shell.
  static const String more = RoutePaths.more;

  /// Pinned-template destination the status line opens. Nested under
  /// [more] so Settings stays in the branch stack.
  static const String templates = RoutePaths.templates;

  /// Blank-template form. Listed before [template] so `new` is not an id.
  static const String templateCreate = '$templates/new';

  /// Shipped-library picker. Task 093 owns the screen.
  static const String templateLibrary = '$templates/library';

  /// JSON import. Listed before [template] so `import` is not an id.
  static const String templateImport = '$templates/import';

  /// Spreadsheet mapping. Listed before [template] so `xlsx` is not an id.
  static const String templateXlsx = '$templates/xlsx';

  /// Field list for [id]. Task 094 owns the screen.
  static String template(String id) => '$templates/${Uri.encodeComponent(id)}';

  /// Lookup binding for [fieldKey] on [id].
  static String templateLookup(String id, String fieldKey) =>
      '${templateField(id, fieldKey)}/lookup';

  /// Datasets for [projectId].
  static String projectDatasets(String projectId) =>
      RoutePaths.projectDatasets(projectId);

  /// Context hierarchy editor for [projectId].
  static String projectContext(String projectId) =>
      RoutePaths.projectContext(projectId);

  /// Templates attached to [projectId], preserving the project branch stack.
  static String projectTemplates(String projectId) =>
      RoutePaths.projectTemplates(projectId);

  /// Context presets for [projectId].
  static String projectContextPresets(String projectId) =>
      '${projectContext(projectId)}/presets';

  /// Dataset import for [projectId].
  static String projectDatasetImport(String projectId) =>
      RoutePaths.projectDatasetImport(projectId);

  /// Dataset browser for [datasetId] in [projectId].
  static String projectDataset(String projectId, String datasetId) =>
      RoutePaths.projectDataset(projectId, datasetId);

  /// Row editor for [rowId] in [datasetId] / [projectId].
  static String projectDatasetRow(
    String projectId,
    String datasetId,
    String rowId,
  ) => RoutePaths.projectDatasetRow(projectId, datasetId, rowId);

  /// JSON export for [id]. Task 100 owns the screen.
  static String templateExport(String id) => '${template(id)}/export';

  /// Add-field destination. Task 095 owns the sheet.
  static String templateFieldCreate(String id) => '${template(id)}/fields/new';

  /// Edit-field destination for [fieldKey]. Task 095 owns the sheet.
  static String templateField(String id, String fieldKey) =>
      '${template(id)}/fields/${Uri.encodeComponent(fieldKey)}';

  /// Bulk requiredness for [id]. Task 096 owns the screen.
  static String templateRequired(String id) => '${template(id)}/required';

  /// Identity keys for [id]. Task 098 owns the screen.
  static String templateIdentity(String id) => '${template(id)}/identity';

  /// Output columns for [id]. Task 098 owns the screen.
  static String templateOutput(String id) => '${template(id)}/output';

  /// Record migration for [id]. Task 099 owns the screen.
  static String templateMigrate(String id) => '${template(id)}/migrate';

  /// Per-row aliases for [id]. Task 103 owns the screen.
  static String templateAliases(String id) => '${template(id)}/aliases';

  /// Capture checklist for [id]. Task 103 owns the screen.
  static String templateChecklist(String id) => '${template(id)}/checklist';

  /// Detection profile for [id]. Task 104 owns the screen.
  static String templateDetection(String id) => '${template(id)}/detection';

  /// Query key for the template a capture was opened from.
  static const String templateQuery = 'template';

  /// Query key for the checklist row a capture was opened from.
  static const String rowQuery = 'row';

  /// Capture for [projectId], already aimed at [templateId] and [rowId].
  static String captureRow({
    required String projectId,
    required String templateId,
    required String rowId,
  }) {
    return Uri(
      path: capture(projectId),
      queryParameters: <String, String>{
        templateQuery: templateId,
        rowQuery: rowId,
      },
    ).toString();
  }

  /// Unprocessed-queue destination the status line opens. Nested under
  /// [more] so Settings stays in the branch stack. Task 159 owns the screen.
  static const String queue = RoutePaths.queue;

  /// Export history. Nested under [more]. Task 207 owns the screen.
  static const String exports = RoutePaths.exports;

  /// Records list for [projectId].
  static String projectRecords(String projectId) =>
      RoutePaths.projectRecords(projectId);

  /// Unprocessed queue for [projectId].
  static String projectQueue(String projectId) =>
      RoutePaths.projectQueue(projectId);

  /// Export history for [projectId].
  static String projectExports(String projectId) =>
      RoutePaths.projectExports(projectId);

  /// Query key for a filtered list opened from a home count.
  static const String filterQuery = RoutePaths.filterQuery;

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

  /// Project records already filtered to [filter].
  static String projectRecordsFiltered(String projectId, String filter) {
    return Uri(
      path: projectRecords(projectId),
      queryParameters: <String, String>{filterQuery: filter},
    ).toString();
  }

  /// Project queue already filtered to [filter].
  static String projectQueueFiltered(String projectId, String filter) {
    return Uri(
      path: projectQueue(projectId),
      queryParameters: <String, String>{filterQuery: filter},
    ).toString();
  }

  /// Project export history already filtered to [filter].
  static String projectExportsFiltered(String projectId, String filter) {
    return Uri(
      path: projectExports(projectId),
      queryParameters: <String, String>{filterQuery: filter},
    ).toString();
  }

  /// Operator profile under Settings.
  static const String settingsOperator = RoutePaths.settingsOperator;

  /// Capture defaults under Settings.
  static const String settingsCapture = RoutePaths.settingsCapture;

  /// AI section. The screen arrives in a later phase.
  static const String settingsAi = RoutePaths.settingsAi;

  /// Language section. The screen arrives in a later phase.
  static const String settingsLanguage = RoutePaths.settingsLanguage;

  /// Appearance under Settings: system, light, dark or outdoor.
  static const String settingsAppearance = RoutePaths.settingsAppearance;

  /// Storage usage under Settings.
  static const String settingsStorage = RoutePaths.settingsStorage;

  /// Files section (specification "Data"). The screen arrives later.
  static const String settingsFiles = RoutePaths.settingsFiles;

  /// App lock under Settings.
  static const String settingsSecurity = RoutePaths.settingsSecurity;

  /// About under Settings.
  static const String settingsAbout = RoutePaths.settingsAbout;

  /// Open-source licences under About.
  static const String settingsLicences = RoutePaths.settingsLicences;
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
  final SettingsStore store = ref.read(projectSettingsStoreProvider);
  final GoRouter router = GoRouter(
    initialLocation: _initialLocation(store),
    refreshListenable: refresh,
    redirect: (BuildContext _, GoRouterState state) {
      final String? legacy = _legacyLocation(state);
      if (legacy != null) {
        return legacy;
      }
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
  void persist() => _persistLastLocation(store, router);
  router.routerDelegate.addListener(persist);
  ref.onDispose(() {
    router.routerDelegate.removeListener(persist);
    router.dispose();
  });
  return router;
});

String _initialLocation(SettingsStore store) {
  final String stored = store.read(SettingKeys.lastLocation);
  if (stored.isEmpty || stored == AppRoutes.lock) {
    return AppRoutes.projects;
  }
  if (!_isInternalLocation(stored)) {
    return AppRoutes.projects;
  }
  return stored;
}

void _persistLastLocation(SettingsStore store, GoRouter router) {
  final Uri uri;
  try {
    uri = router.state.uri;
  } on StateError {
    return;
  }
  if (uri.path == AppRoutes.lock) {
    return;
  }
  final String location = uri.toString();
  if (!_isInternalLocation(location)) {
    return;
  }
  if (store.read(SettingKeys.lastLocation) == location) {
    return;
  }
  unawaited(store.write(SettingKeys.lastLocation, location));
}

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
                    GoRoute(
                      path: 'records',
                      metadata: _projectScoped,
                      builder: (BuildContext _, GoRouterState _) {
                        return const _RoutePage(name: 'records');
                      },
                    ),
                    GoRoute(
                      path: 'queue',
                      metadata: _projectScoped,
                      builder: (BuildContext _, GoRouterState state) {
                        return QueueScreen(
                          projectId: state.pathParameters['projectId'],
                        );
                      },
                    ),
                    GoRoute(
                      path: 'exports',
                      metadata: _projectScoped,
                      builder: (BuildContext _, GoRouterState _) {
                        return const _RoutePage(name: 'exports');
                      },
                    ),
                    GoRoute(
                      path: 'context',
                      metadata: _projectScoped,
                      builder: (BuildContext context, GoRouterState state) {
                        return ContextHierarchyScreen(
                          projectId: state.pathParameters['projectId'],
                        );
                      },
                      routes: <RouteBase>[
                        GoRoute(
                          path: 'presets',
                          metadata: _projectScoped,
                          builder: (BuildContext context, GoRouterState state) {
                            return ContextPresetList(
                              projectId: state.pathParameters['projectId'],
                            );
                          },
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'templates',
                      metadata: _projectScoped,
                      builder: (BuildContext _, GoRouterState state) {
                        return TemplateListScreen(
                          projectId: state.pathParameters['projectId'],
                        );
                      },
                      routes: _templateChildRoutes(),
                    ),
                    GoRoute(
                      path: 'datasets',
                      metadata: _projectScoped,
                      builder: (BuildContext context, GoRouterState state) {
                        return DatasetListScreen(
                          projectId: state.pathParameters['projectId'],
                        );
                      },
                      routes: <RouteBase>[
                        GoRoute(
                          path: 'import',
                          metadata: _projectScoped,
                          builder: (BuildContext context, GoRouterState state) {
                            final Object? extra = state.extra;
                            return DatasetKeyScreen(
                              draft: extra is DatasetImportDraft ? extra : null,
                            );
                          },
                        ),
                        GoRoute(
                          path: ':datasetId',
                          metadata: _projectScoped,
                          builder: (BuildContext context, GoRouterState state) {
                            return DatasetBrowserScreen(
                              datasetId: state.pathParameters['datasetId']!,
                              projectId: state.pathParameters['projectId'],
                            );
                          },
                          routes: <RouteBase>[
                            GoRoute(
                              path: 'rows/:rowId',
                              metadata: _projectScoped,
                              builder:
                                  (BuildContext context, GoRouterState state) {
                                    return DatasetRowEditScreen(
                                      rowId: state.pathParameters['rowId']!,
                                    );
                                  },
                            ),
                          ],
                        ),
                      ],
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
              builder: (BuildContext _, GoRouterState state) {
                final String? projectId = state.pathParameters['projectId'];
                return CaptureScreen(projectId: projectId ?? '');
              },
            ),
            GoRoute(
              path: '${AppRoutes.projects}/:projectId/capture',
              metadata: _projectScoped,
              builder: (BuildContext _, GoRouterState state) {
                return CaptureScreen(
                  projectId: state.pathParameters['projectId'] ?? '',
                );
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
                  path: 'ai',
                  builder: (BuildContext _, GoRouterState _) {
                    return const _AiProviderRoute();
                  },
                ),
                GoRoute(
                  path: 'provider-key',
                  redirect: (BuildContext _, GoRouterState _) =>
                      AppRoutes.settingsAi,
                ),
                GoRoute(
                  path: 'about',
                  builder: (BuildContext _, GoRouterState _) {
                    return const AboutScreen();
                  },
                  routes: <RouteBase>[
                    GoRoute(
                      path: 'licences',
                      builder: (BuildContext _, GoRouterState _) {
                        return const LicencesScreen();
                      },
                    ),
                  ],
                ),
                GoRoute(
                  path: 'templates',
                  builder: (BuildContext _, GoRouterState _) {
                    return const TemplateListScreen();
                  },
                  routes: _templateChildRoutes(),
                ),
                GoRoute(
                  path: 'queue',
                  builder: (BuildContext _, GoRouterState _) {
                    return const QueueScreen();
                  },
                ),
                GoRoute(
                  path: 'exports',
                  builder: (BuildContext _, GoRouterState _) {
                    return const _RoutePage(name: 'exports');
                  },
                ),
              ],
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

class _AiProviderRoute extends ConsumerWidget {
  const _AiProviderRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AiProviderSettingsScreen(
      settings: ref.watch(projectSettingsStoreProvider),
    );
  }
}

List<RouteBase> _templateChildRoutes() {
  return <RouteBase>[
                    GoRoute(
                      path: 'new',
                      builder: (BuildContext _, GoRouterState _) {
                        return const TemplateCreateScreen();
                      },
                    ),
                    GoRoute(
                      path: 'library',
                      builder: (BuildContext _, GoRouterState _) {
                        return const ShippedPickerScreen();
                      },
                    ),
                    GoRoute(
                      path: 'import',
                      builder: (BuildContext _, GoRouterState state) {
                        return TemplateImportAction(payload: state.extra);
                      },
                    ),
                    GoRoute(
                      path: 'xlsx',
                      builder: (BuildContext _, GoRouterState state) {
                        return XlsxMappingScreen(
                          path: state.extra is String
                              ? state.extra as String
                              : null,
                        );
                      },
                    ),
                    GoRoute(
                      path: ':templateId',
                      builder: (BuildContext _, GoRouterState state) {
                        return FieldListScreen(
                          templateId: state.pathParameters['templateId']!,
                        );
                      },
                      routes: <RouteBase>[
                        GoRoute(
                          path: 'export',
                          builder: (BuildContext _, GoRouterState _) {
                            return const _RoutePage(name: 'template-export');
                          },
                        ),
                        GoRoute(
                          path: 'required',
                          builder: (BuildContext _, GoRouterState state) {
                            return RequiredColumnsScreen(
                              templateId: state.pathParameters['templateId']!,
                            );
                          },
                        ),
                        GoRoute(
                          path: 'identity',
                          builder: (BuildContext _, GoRouterState state) {
                            return IdentityFieldsScreen(
                              templateId: state.pathParameters['templateId']!,
                            );
                          },
                        ),
                        GoRoute(
                          path: 'output',
                          builder: (BuildContext _, GoRouterState state) {
                            return OutputMappingScreen(
                              templateId: state.pathParameters['templateId']!,
                            );
                          },
                        ),
                        GoRoute(
                          path: 'migrate',
                          builder: (BuildContext _, GoRouterState state) {
                            return TemplateMigrationScreen(
                              templateId: state.pathParameters['templateId']!,
                            );
                          },
                        ),
                        GoRoute(
                          path: 'aliases',
                          builder: (BuildContext _, GoRouterState state) {
                            return RowAliasesScreen(
                              templateId: state.pathParameters['templateId']!,
                            );
                          },
                        ),
                        GoRoute(
                          path: 'checklist',
                          builder: (BuildContext _, GoRouterState state) {
                            return ChecklistScreen(
                              templateId: state.pathParameters['templateId']!,
                            );
                          },
                        ),
                        GoRoute(
                          path: 'detection',
                          builder: (BuildContext _, GoRouterState state) {
                            return DetectionProfileScreen(
                              templateId: state.pathParameters['templateId']!,
                            );
                          },
                        ),
                        GoRoute(
                          path: 'fields/new',
                          builder: (BuildContext _, GoRouterState state) {
                            return FieldAddSheet(
                              templateId: state.pathParameters['templateId']!,
                            );
                          },
                        ),
                        GoRoute(
                          path: 'fields/:fieldKey',
                          builder: (BuildContext _, GoRouterState state) {
                            return FieldAddSheet(
                              templateId: state.pathParameters['templateId']!,
                              fieldKey: state.pathParameters['fieldKey'],
                            );
                          },
                          routes: <RouteBase>[
                            GoRoute(
                              path: 'lookup',
                              builder: (BuildContext _, GoRouterState state) {
                                return LookupBindingScreen(
                                  templateId:
                                      state.pathParameters['templateId']!,
                                  fieldKey: state.pathParameters['fieldKey']!,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ];
}

String? _legacyLocation(GoRouterState state) {
  final String path = state.uri.path;
  for (final ({String from, String to}) prefix in _legacyPrefixes) {
    if (path == prefix.from || path.startsWith('${prefix.from}/')) {
      return Uri(
        path: '${prefix.to}${path.substring(prefix.from.length)}',
        queryParameters: state.uri.queryParameters.isEmpty
            ? null
            : state.uri.queryParameters,
      ).toString();
    }
  }
  return null;
}

const List<({String from, String to})> _legacyPrefixes =
    <({String from, String to})>[
      (from: '/queue', to: AppRoutes.queue),
      (from: '/exports', to: AppRoutes.exports),
      (from: '/templates', to: AppRoutes.templates),
    ];

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
    final bool canPop = Navigator.of(context).canPop();
    return AppPage(
      key: ValueKey<String>('route-$name'),
      title: title,
      showAppBar: canPop,
      compactBar: true,
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
    'datasets' => Copy.navDatasets,
    'template-library' => Copy.templatesPickLibrary,
    'template-fields' => Copy.templateFieldsTitle,
    'template-export' => Copy.templatesExport,
    'template-required' => Copy.requiredColumnsTitle,
    'template-identity' => Copy.identityFieldsTitle,
    'template-output' => Copy.outputMappingTitle,
    'template-migrate' => Copy.templateMigrationTitle,
    'field-add' => Copy.templatesAddField,
    'field-edit' => Copy.templatesEditField,
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
    'datasets' => Icons.table_chart_outlined,
    'template-library' => Icons.article_outlined,
    'template-fields' => Icons.view_list_outlined,
    'template-export' => Icons.ios_share_outlined,
    'template-required' => Icons.rule,
    'template-identity' => Icons.fingerprint,
    'template-output' => Icons.view_column_outlined,
    'template-migrate' => Icons.upgrade,
    'field-add' => Icons.add,
    'field-edit' => Icons.edit_outlined,
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
