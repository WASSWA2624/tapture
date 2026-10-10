import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/nav_shell.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/backend/backend_config.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/files/picked_document.dart';
import 'package:tapture/core/lifecycle/lifecycle_observer.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/gallery/widget_gallery_screen.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/account/presentation/account_session.dart';
import 'package:tapture/features/account/presentation/relay_route.dart';
import 'package:tapture/features/account/presentation/sign_in_route.dart';
import 'package:tapture/features/capture/capture.dart';
import 'package:tapture/features/cloud/presentation/destination_list_screen.dart';
import 'package:tapture/features/cloud/presentation/upload_history_screen.dart';
import 'package:tapture/features/context/presentation/context_hierarchy_screen.dart';
import 'package:tapture/features/context/presentation/context_preset_list.dart';
import 'package:tapture/features/exports/presentation/export_workflow_screen.dart';
import 'package:tapture/features/import/import.dart'
    show
        ImportPurposeStep,
        ImportScreen,
        ImportSummaryScreen,
        RecordMappingScreen;
import 'package:tapture/features/meetings/domain/meeting.dart';
import 'package:tapture/features/meetings/presentation/meeting_create_screen.dart';
import 'package:tapture/features/meetings/presentation/meeting_review_controller.dart';
import 'package:tapture/features/meetings/presentation/meeting_review_screen.dart';
import 'package:tapture/features/merge/merge.dart';
import 'package:tapture/features/processing/presentation/queue_screen.dart';
import 'package:tapture/features/projects/presentation/current_project.dart';
import 'package:tapture/features/projects/presentation/project_create_screen.dart';
import 'package:tapture/features/projects/presentation/project_details_screen.dart';
import 'package:tapture/features/projects/presentation/project_edit_screen.dart';
import 'package:tapture/features/projects/presentation/project_export_screen.dart';
import 'package:tapture/features/projects/presentation/project_home_screen.dart';
import 'package:tapture/features/projects/presentation/project_list_screen.dart';
import 'package:tapture/features/projects/presentation/project_settings_screen.dart';
import 'package:tapture/features/projects/projects.dart'
    show Project, projectByIdProvider;
import 'package:tapture/features/quality/presentation/duplicate_compare_screen.dart';
import 'package:tapture/features/quality/presentation/duplicates_screen.dart';
import 'package:tapture/features/quality/presentation/quality_summary_screen.dart';
import 'package:tapture/features/quality/presentation/variance_screen.dart';
import 'package:tapture/features/records/presentation/record_detail_screen.dart';
import 'package:tapture/features/records/presentation/record_edit_screen.dart';
import 'package:tapture/features/records/presentation/record_history_screen.dart';
import 'package:tapture/features/records/presentation/records_list_screen.dart';
import 'package:tapture/features/records/presentation/recycle_bin_screen.dart';
import 'package:tapture/features/records/records.dart'
    show RecordEntry, recordRepositoryProvider;
import 'package:tapture/features/reference/reference.dart'
    show
        DatasetBrowserScreen,
        DatasetImportDraft,
        DatasetKeyScreen,
        DatasetListScreen,
        DatasetRowEditScreen;
import 'package:tapture/features/review/review.dart'
    show BatchReviewScreen, ReviewScreen;
import 'package:tapture/features/settings/presentation/ai_provider_settings_screen.dart';
import 'package:tapture/features/settings/presentation/app_lock_screen.dart';
import 'package:tapture/features/settings/presentation/appearance_settings_screen.dart';
import 'package:tapture/features/settings/presentation/capture_settings_screen.dart';
import 'package:tapture/features/settings/presentation/files_settings_screen.dart';
import 'package:tapture/features/settings/presentation/language_settings_screen.dart';
import 'package:tapture/features/settings/presentation/privacy_settings_screen.dart';
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
import 'package:tapture/features/transcripts/presentation/transcribe_screen.dart';
import 'package:tapture/features/transcripts/presentation/transcript_detail_screen.dart';
import 'package:tapture/features/transcripts/presentation/transcripts_screen.dart';

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

  /// Project filters. Listed before [project] so `filters` is not an id.
  static const String projectFilters = RoutePaths.projectFilters;

  /// Query key for the project whose structure is being copied.
  static const String sourceQuery = RoutePaths.sourceQuery;

  /// Query key for the editable suggested name on the create form.
  static const String nameQuery = RoutePaths.nameQuery;

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

  /// Read-only details page for [projectId].
  static String projectDetails(String projectId) =>
      RoutePaths.projectDetails(projectId);

  /// Per-project settings for [projectId].
  static String projectSettings(String projectId) =>
      RoutePaths.projectSettings(projectId);

  /// One record, opened directly from a deep link.
  static String record(String id) => RoutePaths.record(id);

  /// The page that edits the values of record [id]. Task 014 owns the
  /// screen.
  static String recordValuesEdit(String id) => RoutePaths.recordValuesEdit(id);

  /// The history of record [id]. Task 014 owns the screen.
  static String recordHistory(String id) => RoutePaths.recordHistory(id);

  /// Deleted records across projects, restorable until the purge. Nested
  /// under [more] so Settings stays in the branch stack. Task 014 owns the
  /// screen.
  static const String recycleBin = RoutePaths.recycleBin;

  /// Legacy records address, redirected into the opened project.
  static const String records = RoutePaths.records;

  /// Settings destination of the project shell.
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
      RoutePaths.projectContextPresets(projectId);

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

  /// Legacy global processing address, redirected to Projects (task 144).
  static const String queue = RoutePaths.queue;

  /// Legacy global export-history path. Exports belong to a project, so
  /// it opens Projects; each project's exports live under
  /// [projectExports].
  static const String exports = RoutePaths.exports;

  /// Records list for [projectId].
  static String projectRecords(String projectId) =>
      RoutePaths.projectRecords(projectId);

  /// One record's page on [projectId].
  static String projectRecord(String projectId, String recordId) =>
      RoutePaths.projectRecord(projectId, recordId);

  /// The capture page that edits one saved record on [projectId].
  static String projectRecordEdit(String projectId, String recordId) =>
      RoutePaths.projectRecordEdit(projectId, recordId);

  /// The page that edits the values of record [recordId] on [projectId].
  /// Task 014 owns the screen.
  static String projectRecordValuesEdit(String projectId, String recordId) =>
      RoutePaths.projectRecordValuesEdit(projectId, recordId);

  /// The history of record [recordId] on [projectId]. Task 014 owns the
  /// screen.
  static String projectRecordHistory(String projectId, String recordId) =>
      RoutePaths.projectRecordHistory(projectId, recordId);

  /// Unprocessed queue for [projectId].
  static String projectQueue(String projectId) =>
      RoutePaths.projectQueue(projectId);

  /// Export history for [projectId].
  static String projectExports(String projectId) =>
      RoutePaths.projectExports(projectId);

  /// Query key for a filtered list opened from a home count.
  static const String filterQuery = RoutePaths.filterQuery;

  /// Operator profile under Settings.
  static const String settingsOperator = RoutePaths.settingsOperator;

  /// Capture defaults under Settings.
  static const String settingsCapture = RoutePaths.settingsCapture;

  /// AI providers and keys under Settings.
  static const String settingsAi = RoutePaths.settingsAi;

  /// App and voice language under Settings.
  static const String settingsLanguage = RoutePaths.settingsLanguage;

  /// Appearance under Settings: system, light, dark or outdoor.
  static const String settingsAppearance = RoutePaths.settingsAppearance;

  /// Storage usage under Settings.
  static const String settingsStorage = RoutePaths.settingsStorage;

  /// Files checked against their records, under Storage.
  static const String settingsStorageCheck = RoutePaths.settingsStorageCheck;

  /// Files section (specification "Data"): export, import, uploads, merge.
  static const String settingsFiles = RoutePaths.settingsFiles;

  /// App lock under Settings.
  static const String settingsSecurity = RoutePaths.settingsSecurity;

  /// About under Settings.
  static const String settingsAbout = RoutePaths.settingsAbout;

  /// Open-source licences under About.
  static const String settingsLicences = RoutePaths.settingsLicences;

  /// Legacy account address, redirected to AI's expanded account section.
  static const String settingsAccount = RoutePaths.settingsAccount;

  /// The one sign-in, outside the shell like [lock].
  static const String signIn = RoutePaths.signIn;

  /// Encrypted relay controls under Settings.
  static const String settingsRelay = RoutePaths.settingsRelay;
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
  final BackendConfig? backend = ref.read(backendSessionProvider)?.config;
  final GoRouter router = GoRouter(
    initialLocation: _initialLocation(
      store,
      signInFirst:
          backend != null && backend.baseUrl.isNotEmpty && backend.needsSignIn,
    ),
    refreshListenable: refresh,
    redirect: (BuildContext _, GoRouterState state) async {
      final String? locked = _appLock(state, ref);
      if (locked != null) {
        return locked;
      }
      final String? scoped = await _legacyProjectLocation(state, ref);
      if (scoped != null) {
        return scoped;
      }
      final String? legacy = _legacyLocation(state);
      if (legacy != null) {
        return legacy;
      }
      for (final RouteGuard guard in appGuards()) {
        final String? to = await guard(state, ref);
        if (to != null) {
          return to;
        }
      }
      return null;
    },
    routes: _routes,
    errorBuilder: _notFound,
  );
  Future<void> pending = Future<void>.value();
  void persist() {
    final configuration = router.routerDelegate.currentConfiguration;
    if (configuration.error != null || configuration.matches.isEmpty) {
      return;
    }
    final String? projectId = router.state.pathParameters['projectId'];
    if (projectId != null && ref.read(openProjectIdProvider) != projectId) {
      unawaited(
        Future<void>.microtask(() {
          if (ref.mounted &&
              router
                      .routerDelegate
                      .currentConfiguration
                      .pathParameters['projectId'] ==
                  projectId) {
            ref.read(openProjectIdProvider.notifier).open(projectId);
          }
        }),
      );
    }
    final String location = router.state.uri.toString();
    pending = pending.then((_) => _persistLastLocation(store, location));
  }

  final LifecycleObserver lifecycle = ref.read(lifecycleObserverProvider);
  Future<void> flush() async => pending;
  lifecycle.addPauseFlush(flush);
  router.routerDelegate.addListener(persist);
  ref.onDispose(() {
    router.routerDelegate.removeListener(persist);
    lifecycle.removePauseFlush(flush);
    router.dispose();
  });
  return router;
});

/// Where a launch opens. A configured install with no page to resume opens
/// sign-in when it is not signed in: first run is gated, and only first run
/// (task 024 step 23). After that a launch resumes the last page, and an
/// enrolled device never sees sign-in again, offline or not.
String _initialLocation(SettingsStore store, {required bool signInFirst}) {
  final String stored = store.read(SettingKeys.lastLocation);
  if (stored.isEmpty && signInFirst) {
    return AppRoutes.signIn;
  }
  final Uri? uri = Uri.tryParse(stored);
  if (stored.isEmpty ||
      uri?.path == AppRoutes.lock ||
      uri?.path == AppRoutes.signIn) {
    return AppRoutes.projects;
  }
  if (!_isInternalLocation(stored)) {
    return AppRoutes.projects;
  }
  return stored;
}

Future<void> _persistLastLocation(SettingsStore store, String location) async {
  final Uri uri = Uri.parse(location);
  // The lock and the sign-in gate are never where work resumes.
  if (uri.path == AppRoutes.lock || uri.path == AppRoutes.signIn) {
    return;
  }
  if (!_isInternalLocation(location)) {
    return;
  }
  if (store.read(SettingKeys.lastLocation) == location) {
    return;
  }
  await store.write(SettingKeys.lastLocation, location);
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
    GoRoute(
      path: AppRoutes.signIn,
      builder: (BuildContext _, GoRouterState _) {
        return const SignInRoute();
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
                  path: 'import',
                  builder: (BuildContext _, GoRouterState _) {
                    return const ImportScreen();
                  },
                  routes: <RouteBase>[
                    GoRoute(
                      path: 'purpose',
                      builder: (BuildContext _, GoRouterState _) {
                        return const ImportPurposeStep();
                      },
                    ),
                    GoRoute(
                      path: 'records',
                      builder: (BuildContext _, GoRouterState _) {
                        return const RecordMappingScreen();
                      },
                    ),
                    GoRoute(
                      path: 'summary',
                      builder: (BuildContext _, GoRouterState _) {
                        return const ImportSummaryScreen();
                      },
                    ),
                  ],
                ),
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
                  path: 'filters',
                  redirect: (BuildContext _, GoRouterState _) =>
                      RoutePaths.projects,
                ),
                GoRoute(
                  path: ':projectId',
                  metadata: _projectScoped,
                  builder: (BuildContext _, GoRouterState _) {
                    return const ProjectHomeScreen();
                  },
                  routes: <RouteBase>[
                    GoRoute(
                      path: 'capture',
                      metadata: _projectScoped,
                      builder: (BuildContext _, GoRouterState state) =>
                          CaptureScreen(
                            projectId: state.pathParameters['projectId']!,
                          ),
                      routes: <RouteBase>[
                        GoRoute(
                          path: 'rapid',
                          redirect: (BuildContext _, GoRouterState state) =>
                              state.uri
                                  .replace(
                                    path: RoutePaths.projectCapture(
                                      state.pathParameters['projectId']!,
                                    ),
                                  )
                                  .toString(),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'details',
                      metadata: _projectScoped,
                      builder: (BuildContext _, GoRouterState state) {
                        return ProjectDetailsScreen(
                          projectId: state.pathParameters['projectId']!,
                        );
                      },
                    ),
                    GoRoute(
                      path: 'edit',
                      metadata: _projectScoped,
                      builder: (BuildContext _, GoRouterState state) {
                        return ProjectEditScreen(
                          projectId: state.pathParameters['projectId']!,
                        );
                      },
                    ),
                    GoRoute(
                      path: 'settings',
                      metadata: _projectScoped,
                      builder: (BuildContext _, GoRouterState _) {
                        return const ProjectSettingsScreen();
                      },
                      routes: <RouteBase>[
                        GoRoute(
                          path: 'relay',
                          metadata: _projectScoped,
                          builder: (BuildContext _, GoRouterState state) {
                            final String projectId =
                                state.pathParameters['projectId']!;
                            return RelayRoute(
                              key: ValueKey<String>('project-relay-$projectId'),
                              projectId: projectId,
                            );
                          },
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'records',
                      metadata: _projectScoped,
                      builder: (BuildContext _, GoRouterState state) {
                        return RecordsListScreen(
                          projectId: state.pathParameters['projectId']!,
                          initialStatus: _statusQuery(state),
                        );
                      },
                      routes: _recordRoutes(inProject: true),
                    ),
                    GoRoute(
                      path: 'duplicates',
                      metadata: _projectScoped,
                      builder: (BuildContext _, GoRouterState state) {
                        return DuplicatesScreen(
                          projectId: state.pathParameters['projectId']!,
                        );
                      },
                      routes: <RouteBase>[
                        GoRoute(
                          path: ':pairId',
                          metadata: _projectScoped,
                          builder: (BuildContext _, GoRouterState state) {
                            return DuplicateCompareScreen(
                              projectId: state.pathParameters['projectId']!,
                              pairId: state.pathParameters['pairId']!,
                            );
                          },
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'variance',
                      metadata: _projectScoped,
                      builder: (BuildContext _, GoRouterState state) {
                        return VarianceScreen(
                          projectId: state.pathParameters['projectId']!,
                          recordId:
                              state.uri.queryParameters[RoutePaths.recordQuery],
                        );
                      },
                    ),
                    GoRoute(
                      path: 'review',
                      metadata: _projectScoped,
                      builder: (BuildContext _, GoRouterState state) {
                        return BatchReviewScreen(
                          projectId: state.pathParameters['projectId']!,
                        );
                      },
                    ),
                    GoRoute(
                      path: 'meetings/new',
                      metadata: _projectScoped,
                      builder: (BuildContext _, GoRouterState state) {
                        return MeetingCreateScreen(
                          projectId: state.pathParameters['projectId']!,
                        );
                      },
                    ),
                    GoRoute(
                      path: 'meetings/:meetingId/review',
                      onExit: (BuildContext context, GoRouterState state) =>
                          ProviderScope.containerOf(context, listen: false)
                              .read(
                                meetingReviewControllerProvider(
                                  state.pathParameters['meetingId']!,
                                ).notifier,
                              )
                              .flush(),
                      metadata: _projectScoped,
                      builder: (BuildContext _, GoRouterState state) {
                        final Object? extra = state.extra;
                        return MeetingReviewScreen(
                          meeting: extra is Meeting ? extra : null,
                          meetingId: state.pathParameters['meetingId'],
                          projectId: state.pathParameters['projectId'],
                          requireActionDetails: true,
                        );
                      },
                    ),
                    GoRoute(
                      path: 'transcripts',
                      metadata: _projectScoped,
                      builder: (BuildContext _, GoRouterState state) {
                        return TranscriptsScreen(
                          projectId: state.pathParameters['projectId'],
                        );
                      },
                      routes: _transcriptRoutes(inProject: true),
                    ),
                    GoRoute(
                      path: 'quality',
                      metadata: _projectScoped,
                      builder: (BuildContext _, GoRouterState state) {
                        return QualitySummaryScreen(
                          projectId: state.pathParameters['projectId']!,
                        );
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
                      path: 'deliverable',
                      metadata: _projectScoped,
                      redirect: (BuildContext _, GoRouterState state) => Uri(
                        path: RoutePaths.projectDeliverables(
                          state.pathParameters['projectId']!,
                        ),
                        query: state.uri.hasQuery ? state.uri.query : null,
                        fragment: state.uri.hasFragment
                            ? state.uri.fragment
                            : null,
                      ).toString(),
                    ),
                    GoRoute(
                      path: 'exports',
                      metadata: _projectScoped,
                      builder: (BuildContext _, GoRouterState state) {
                        return ProjectExportScreen(
                          key: ValueKey<String>(
                            state.pathParameters['projectId']!,
                          ),
                          projectId: state.pathParameters['projectId']!,
                          startExport: state.extra == true,
                        );
                      },
                      routes: <RouteBase>[
                        GoRoute(
                          path: 'deliverable',
                          metadata: _projectScoped,
                          builder: (BuildContext _, GoRouterState state) =>
                              ExportWorkflowScreen(
                                projectId: state.pathParameters['projectId']!,
                              ),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'merge-history',
                      metadata: _projectScoped,
                      builder: (BuildContext _, GoRouterState state) =>
                          ProjectMergeHistoryScreen(
                            projectId: state.pathParameters['projectId']!,
                          ),
                    ),
                    GoRoute(
                      path: 'merge',
                      metadata: _projectScoped,
                      builder: (BuildContext _, GoRouterState state) {
                        return MergePreviewScreen(
                          projectId: state.pathParameters['projectId']!,
                        );
                      },
                      routes: <RouteBase>[
                        GoRoute(
                          path: 'conflicts',
                          metadata: _projectScoped,
                          builder: (BuildContext _, GoRouterState state) {
                            return ConflictScreen(
                              projectId: state.pathParameters['projectId']!,
                              conflictId: state.uri.queryParameters['conflict'],
                            );
                          },
                        ),
                      ],
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
                              projectId: state.pathParameters['projectId'],
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
                                      datasetId:
                                          state.pathParameters['datasetId']!,
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
              path: AppRoutes.more,
              builder: (BuildContext _, GoRouterState _) {
                return const SettingsScreen();
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
                  path: 'language',
                  builder: (BuildContext _, GoRouterState _) {
                    return const LanguageSettingsScreen();
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
                  routes: <RouteBase>[
                    GoRoute(
                      path: 'check',
                      redirect: (BuildContext _, GoRouterState _) =>
                          RoutePaths.settingsStorage,
                    ),
                  ],
                ),
                GoRoute(
                  path: 'files',
                  builder: (BuildContext _, GoRouterState _) {
                    return const FilesSettingsScreen();
                  },
                ),
                GoRoute(
                  path: 'destinations',
                  builder: (BuildContext _, GoRouterState _) {
                    return const DestinationListScreen();
                  },
                ),
                GoRoute(
                  path: 'uploads',
                  builder: (BuildContext _, GoRouterState _) {
                    return const UploadHistoryScreen();
                  },
                ),
                GoRoute(
                  path: 'security',
                  builder: (BuildContext _, GoRouterState _) {
                    return const AppLockScreen.manage();
                  },
                ),
                GoRoute(
                  path: 'privacy',
                  builder: (BuildContext _, GoRouterState _) {
                    return const PrivacySettingsScreen();
                  },
                ),
                GoRoute(
                  path: 'account',
                  redirect: (BuildContext _, GoRouterState _) =>
                      '${AppRoutes.settingsAi}?section=account',
                ),
                GoRoute(
                  path: 'relay',
                  builder: (BuildContext _, GoRouterState _) {
                    return const RelayRoute();
                  },
                ),
                GoRoute(
                  path: 'ai',
                  builder: (BuildContext _, GoRouterState state) {
                    final bool showAccount =
                        state.uri.queryParameters['section'] == 'account';
                    return AiProviderSettingsScreen(
                      key: ValueKey<bool>(showAccount),
                      initiallyShowAccount: showAccount,
                    );
                  },
                ),
                GoRoute(
                  path: 'provider-key',
                  redirect: (BuildContext _, GoRouterState _) =>
                      AppRoutes.settingsAi,
                ),
                GoRoute(
                  path: 'recycle-bin',
                  builder: (BuildContext _, GoRouterState _) {
                    return const RecycleBinScreen();
                  },
                ),
                GoRoute(
                  path: 'transcripts',
                  builder: (BuildContext _, GoRouterState _) {
                    return const TranscriptsScreen();
                  },
                  routes: _transcriptRoutes(inProject: false),
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
                  redirect: (BuildContext _, GoRouterState _) =>
                      RoutePaths.projects,
                ),
                GoRoute(
                  path: 'exports',
                  redirect: (BuildContext _, GoRouterState _) =>
                      AppRoutes.projects,
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

List<RouteBase> _templateChildRoutes() {
  return <RouteBase>[
    GoRoute(
      path: 'new',
      builder: (BuildContext _, GoRouterState state) {
        return TemplateCreateScreen(
          projectId: state.pathParameters['projectId'],
        );
      },
    ),
    GoRoute(
      path: 'library',
      builder: (BuildContext _, GoRouterState state) {
        return ShippedPickerScreen(
          projectId: state.pathParameters['projectId'],
        );
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
          path: state.extra is String ? state.extra as String : null,
          document: state.extra is PickedDocument
              ? state.extra as PickedDocument
              : null,
          targetTemplateId: state.uri.queryParameters['template'],
        );
      },
    ),
    GoRoute(
      path: ':templateId',
      builder: (BuildContext _, GoRouterState state) {
        return FieldListScreen(templateId: state.pathParameters['templateId']!);
      },
      routes: <RouteBase>[
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
                  templateId: state.pathParameters['templateId']!,
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

Future<String?> _legacyProjectLocation(GoRouterState state, Ref ref) async {
  final Uri uri = state.uri;
  if (uri.path != RoutePaths.captureRoot &&
      uri.path != RoutePaths.records &&
      !uri.path.startsWith('${RoutePaths.records}/')) {
    return null;
  }
  String? projectId = ref.read(openProjectIdProvider);
  String suffix = uri.path == RoutePaths.captureRoot ? '/capture' : '/records';
  if (uri.pathSegments.length > 1) {
    try {
      final RecordEntry? record =
          (await ref.read(recordRepositoryProvider).byId(uri.pathSegments[1]))
              .getOrThrow();
      if (record == null || record.status == RecordStatus.deleted) {
        return RoutePaths.projects;
      }
      projectId = record.projectId;
      suffix = uri.path;
    } on Object {
      return RoutePaths.projects;
    }
  }
  if (projectId == null || projectId.isEmpty) {
    return RoutePaths.projects;
  }
  return uri
      .replace(path: '${RoutePaths.project(projectId)}$suffix')
      .toString();
}

String? _legacyLocation(GoRouterState state) {
  final String path = state.uri.path;
  if (path == '/queue') {
    return RoutePaths.projects;
  }
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
      (from: '/exports', to: AppRoutes.exports),
      (from: '/templates', to: AppRoutes.templates),
    ];

Widget _notFound(BuildContext context, GoRouterState state) {
  final LocalizedCopy localCopy = Copy.of(context);

  return AppPage(
    title: localCopy.notFoundTitle,
    body: AppErrorState(
      failure: ValidationFailure(
        message: localCopy.notFoundMessage(state.uri.path.replaceAll('"', "'")),
        recoveryAction: localCopy.notFoundRecovery,
      ),
      onRetry: () => context.go(AppRoutes.projects),
    ),
  );
}

/// One record and the pages that change it (task 014). [inProject] keeps
/// the routes inside a project branch and behind the project-scope guard.
List<RouteBase> _recordRoutes({required bool inProject}) {
  final Map<String, dynamic>? scope = inProject ? _projectScoped : null;
  return <RouteBase>[
    GoRoute(
      path: ':recordId',
      metadata: scope,
      builder: (BuildContext _, GoRouterState state) {
        return RecordDetailScreen(
          recordId: state.pathParameters['recordId']!,
          projectId: inProject ? state.pathParameters['projectId'] : null,
        );
      },
      routes: <RouteBase>[
        if (inProject)
          GoRoute(
            path: 'edit',
            metadata: _projectScoped,
            builder: (BuildContext _, GoRouterState state) {
              return CaptureScreen(
                projectId: state.pathParameters['projectId']!,
                recordId: state.pathParameters['recordId']!,
              );
            },
          ),
        GoRoute(
          path: 'values',
          metadata: scope,
          builder: (BuildContext _, GoRouterState state) {
            return RecordEditScreen(
              recordId: state.pathParameters['recordId']!,
            );
          },
        ),
        if (inProject)
          GoRoute(
            path: 'review',
            metadata: _projectScoped,
            builder: (BuildContext _, GoRouterState state) {
              return ReviewScreen(
                projectId: state.pathParameters['projectId']!,
                recordId: state.pathParameters['recordId']!,
              );
            },
          ),
        GoRoute(
          path: 'history',
          metadata: scope,
          builder: (BuildContext _, GoRouterState state) {
            return RecordHistoryScreen(
              recordId: state.pathParameters['recordId']!,
            );
          },
        ),
      ],
    ),
  ];
}

/// Transcribe and one transcript (task 123). `new` is listed before the id
/// so it is not taken for one. [inProject] keeps the routes inside a project
/// branch and behind the project-scope guard; outside one, Transcribe
/// records into the open project.
List<RouteBase> _transcriptRoutes({required bool inProject}) {
  final Map<String, dynamic>? scope = inProject ? _projectScoped : null;
  return <RouteBase>[
    GoRoute(
      path: 'new',
      metadata: scope,
      builder: (BuildContext _, GoRouterState state) {
        return TranscribeScreen(
          projectId: inProject ? state.pathParameters['projectId'] : null,
        );
      },
    ),
    GoRoute(
      path: ':transcriptId',
      metadata: scope,
      builder: (BuildContext _, GoRouterState state) {
        return TranscriptDetailScreen(
          transcriptId: state.pathParameters['transcriptId']!,
          projectId: inProject ? state.pathParameters['projectId'] : null,
        );
      },
    ),
  ];
}

/// The `?filter=` status a records list opens on, or null when the route
/// names none.
RecordStatus? _statusQuery(GoRouterState state) {
  final String? raw = state.uri.queryParameters[AppRoutes.filterQuery];
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return RecordStatus.fromStored(raw);
}

const String _projectScopedKey = 'projectScoped';

const Map<String, dynamic> _projectScoped = <String, dynamic>{
  _projectScopedKey: true,
};
