import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/shell_header_scope.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/context/context.dart';
import 'package:tapture/features/templates/templates.dart';

import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;
import 'captured_items.dart';
import 'current_project.dart';
import 'project_archive_action.dart';
import 'project_delete_action.dart';
import 'project_duplicate_action.dart';
import 'project_open_externally_action.dart';
import 'project_record_filter.dart';

/// Open-project home: what to do next, with one primary capture action.
class ProjectHomeScreen extends ConsumerWidget {
  /// Creates the open-project home.
  const ProjectHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Project? details = ref.watch(currentProjectDetailsProvider);
    final AsyncValue<Project?> value = ref.watch(projectHomeProvider);
    final Project? project = value.asData?.value;
    final int records =
        ref.watch(projectHomeRecordCountProvider).asData?.value ?? 0;
    final String? openId = details?.id;
    final AsyncValue<List<TemplateDef>> homeTemplates = ref.watch(
      projectHomeTemplatesProvider(openId ?? ''),
    );
    final bool canCapture = homeTemplates.maybeWhen(
      data: (List<TemplateDef> loaded) => loaded.isNotEmpty,
      orElse: () => false,
    );
    return AppPage(
      key: const ValueKey<String>('route-project'),
      title: details?.name ?? Copy.navProjects,
      showAppBar: false,
      overflow: project == null
          ? const <AppOverflowAction>[]
          : _projectHomeMenu(context, ref, project),
      scrollable: false,
      footer: project == null
          ? null
          : AppPrimaryAction(
              label: records == 0 ? Copy.captureStart : Copy.captureMore,
              caption: homeTemplates.hasValue && !canCapture
                  ? Copy.captureNeedsTemplate
                  : null,
              onPressed: canCapture
                  ? () => context.go(_capture(project.id))
                  : null,
            ),
      body: AsyncValueView<Project?>(
        value: value,
        isEmpty: (Project? loaded) => loaded == null,
        empty: () => AppEmptyState(
          icon: AppIcons.project,
          headline: Copy.homeEmptyHeadline,
          message: Copy.homeEmptyMessage,
          actionLabel: Copy.navProjects,
          onAction: () => context.go(RoutePaths.projects),
        ),
        onRetry: () => ref.invalidate(projectListProvider),
        data: (Project? loaded) => _HomeBody(project: loaded!),
      ),
    );
  }
}

/// Templates of [projectId], for the footer's capture gate.
final projectHomeTemplatesProvider =
    StreamProvider.family<List<TemplateDef>, String>((
      Ref ref,
      String projectId,
    ) {
      return ref.watch(templateRepositoryProvider).watchByProject(projectId);
    }, retry: (int _, Object _) => null);

const List<String> _homeRecordStatuses = <String>[
  'draft',
  'captured',
  'CAPTURED',
  'queued',
  'processing',
  'needsReview',
  'approved',
];

/// How many records the open project already holds. Derived (FE-STATE-06).
final StreamProvider<int> projectHomeRecordCountProvider = StreamProvider<int>((
  Ref ref,
) {
  final String? id = ref.watch(currentProjectProvider);
  if (id == null) {
    return Stream<int>.value(0);
  }
  return ref
      .watch(projectRepositoryProvider)
      .watchRecords(id, statuses: _homeRecordStatuses)
      .map((List<ProjectRecordRow> rows) => rows.length);
}, retry: (int _, Object _) => null);

/// The open project once the list has loaded. Null when none is open;
/// loading and failure follow the list (FE-STATE-06).
final Provider<AsyncValue<Project?>> projectHomeProvider =
    Provider<AsyncValue<Project?>>((Ref ref) {
      final Project? details = ref.watch(currentProjectDetailsProvider);
      final AsyncValue<List<ProjectListRow>> list = ref.watch(
        projectListProvider,
      );
      return list.when(
        data: (List<ProjectListRow> _) => AsyncData<Project?>(details),
        error: AsyncError<Project?>.new,
        loading: () => const AsyncLoading<Project?>(),
      );
    });

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool shellOwns = ShellHeaderScope.ownsHeaderOf(context);
    final double gutter = AppPage.gutter(context);
    final String query = ref.watch(capturedItemsQueryProvider);
    final int activeFilters = ref.watch(projectRecordFilterProvider).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!shellOwns)
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, Space.x2, gutter, Space.x0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: Text(project.name, style: AppText.title)),
                AppOverflowMenu(items: _projectHomeMenu(context, ref, project)),
              ],
            ),
          ),
        // Pinned at the very top so a long home scrolls under it.
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, Space.x1, gutter, Space.x2),
          child: AppSearchField(
            key: const ValueKey<String>('home-search'),
            hint: Copy.projectRecordsSearchHint,
            text: query,
            onChanged: (String text) {
              ref.read(capturedItemsQueryProvider.notifier).set(text);
            },
            onFilter: () => unawaited(
              showProjectRecordFilters(
                context,
                ref,
                ref.read(capturedItemsProvider(project.id)).asData?.value ??
                    const <ProjectRecordRow>[],
              ),
            ),
            activeFilterCount: activeFilters,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: CapturedItems(projectId: project.id),
          ),
        ),
      ],
    );
  }
}

List<AppOverflowAction> _projectHomeMenu(
  BuildContext context,
  WidgetRef ref,
  Project project,
) {
  final AppOverflowAction? open = projectOpenExternallyMenuItem(
    context,
    ref,
    project,
  );
  return <AppOverflowAction>[
    AppOverflowAction(
      label: Copy.navTemplates,
      icon: AppIcons.template,
      onTap: () => context.push(_templates(project.id)),
    ),
    AppOverflowAction(
      label: Copy.contextPinnedTitle,
      icon: AppIcons.pin,
      onTap: () => unawaited(
        showPinnedFieldsSheet(context: context, projectId: project.id),
      ),
    ),
    AppOverflowAction(
      label: Copy.contextHierarchyTitle,
      icon: AppIcons.context,
      onTap: () => unawaited(context.push(_context(project.id))),
    ),
    AppOverflowAction(
      label: Copy.projectExport,
      icon: AppIcons.export,
      onTap: () => context.push(RoutePaths.projectExports(project.id)),
    ),
    AppOverflowAction(
      label: Copy.projectsDuplicate,
      icon: AppIcons.duplicate,
      onTap: () => ProjectDuplicateAction.open(
        context,
        sourceId: project.id,
        sourceName: project.name,
      ),
    ),
    AppOverflowAction(
      label: Copy.projectEditTitle,
      icon: AppIcons.edit,
      onTap: () => context.go(_edit(project.id)),
    ),
    AppOverflowAction(
      label: Copy.projectSettingsTitle,
      icon: AppIcons.settings,
      onTap: () => context.go(_settings(project.id)),
    ),
    ?open,
    AppOverflowAction(
      label: project.status == ProjectStatus.archived
          ? Copy.projectUnarchive
          : Copy.projectArchive,
      icon: project.status == ProjectStatus.archived
          ? AppIcons.unarchive
          : AppIcons.archive,
      onTap: () => unawaited(_archiveThenList(context, ref, project)),
    ),
    AppOverflowAction(
      label: Copy.projectDeleteMenu,
      icon: AppIcons.delete,
      onTap: () => unawaited(_deleteThenList(context, ref, project)),
    ),
  ];
}

Future<void> _archiveThenList(
  BuildContext context,
  WidgetRef ref,
  Project project,
) async {
  await ProjectArchiveAction.apply(ref, project);
  if (context.mounted) {
    context.go(RoutePaths.projects);
  }
}

Future<void> _deleteThenList(
  BuildContext context,
  WidgetRef ref,
  Project project,
) async {
  await ProjectDeleteAction.confirm(context, ref, project);
  if (!context.mounted) {
    return;
  }
  if (ref.read(currentProjectProvider) != project.id) {
    context.go(RoutePaths.projects);
  }
}

/// Must match [AppRoutes.capture]. This file cannot import `router.dart`.
String _capture(String id) {
  return RoutePaths.projectCapture(id);
}

/// Must match the project context route. This file cannot import `router.dart`.
String _context(String id) {
  return RoutePaths.projectContext(id);
}

/// Must match [AppRoutes.projectTemplates].
String _templates(String id) {
  return RoutePaths.projectTemplates(id);
}

/// Must match [AppRoutes.projectEdit].
String _edit(String id) {
  return RoutePaths.projectEdit(id);
}

/// Must match [AppRoutes.projectSettings].
String _settings(String id) {
  return RoutePaths.projectSettings(id);
}
