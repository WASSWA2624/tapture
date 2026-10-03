import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/record_thumb.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;
import 'current_project.dart';
import 'project_archive_action.dart';
import 'project_delete_action.dart';
import 'project_list_criteria.dart';
import 'project_list_criteria_controller.dart';
import 'project_list_filter.dart';
import 'project_open_externally_action.dart';
import 'project_rename_action.dart';

/// The project rows the landing screen and the expanded list pane share
/// (FE-CONS-02).
class ProjectListView extends ConsumerWidget {
  /// Creates the list. [filtered] applies the pane search query.
  const ProjectListView({this.filtered = false, super.key});

  /// When true, rows are narrowed by [projectListSearchQueryProvider].
  final bool filtered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProjectListCriteria criteria = ref.watch(projectListCriteriaProvider);
    final String? openId = ref.watch(currentProjectProvider);
    final AsyncValue<List<ProjectListRow>> value = ref.watch(
      filtered ? projectListFilteredProvider : projectListProvider,
    );
    return AsyncValueView<List<ProjectListRow>>(
      value: value,
      isEmpty: (List<ProjectListRow> rows) => rows.isEmpty,
      empty: () => SingleChildScrollView(
        child: _empty(context, searching: filtered && criteria.isActive),
      ),
      onRetry: () => ref.invalidate(projectListProvider),
      data: (List<ProjectListRow> rows) {
        final LocalizedCopy localCopy = Copy.of(context);

        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (BuildContext context, int index) {
            final ProjectListRow row = rows[index];
            return AppListTile(
              key: ValueKey<String>('project-row-${row.project.id}'),
              leading: ExcludeSemantics(
                child: _leading(
                  row.project,
                  index + 1,
                  localizedCopy: localCopy,
                ),
              ),
              title: row.project.name,
              wrapText: true,
              current: row.project.id == openId,
              subtitle: localCopy.projectListSubtitle(
                records: row.recordCount,
                unprocessed: row.unprocessedCount,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (row.project.status == ProjectStatus.archived) ...<Widget>[
                    Semantics(
                      container: true,
                      label: localCopy.projectStatusArchived,
                      child: const ExcludeSemantics(
                        child: Icon(AppIcons.archive, size: Space.x5),
                      ),
                    ),
                    const SizedBox(width: Space.x2),
                  ],
                  if (row.project.pinnedAt != null) ...<Widget>[
                    Semantics(
                      container: true,
                      label: localCopy.pinnedProject,
                      child: const ExcludeSemantics(
                        child: Icon(AppIcons.pinned, size: Space.x5),
                      ),
                    ),
                    const SizedBox(width: Space.x2),
                  ],
                  AppOverflowMenu(
                    outlined: false,
                    items: _rowActions(context, ref, row.project),
                  ),
                ],
              ),
              onTap: () => _openRow(context, ref, row.project.id),
            );
          },
        );
      },
    );
  }
}

Widget _empty(BuildContext context, {required bool searching}) {
  final LocalizedCopy localCopy = Copy.of(context);

  final bool expanded = context.sizeClass == SizeClass.expanded;
  return AppEmptyState(
    icon: AppIcons.project,
    headline: searching
        ? localCopy.projectsNoMatchHeadline
        : localCopy.projectsEmptyHeadline,
    message: searching
        ? localCopy.projectsNoMatchMessage
        : localCopy.projectsEmptyMessage,
    // Import complements the body's Create action when the whole list is empty.
    // A pane search still offers Create when its filter matches no projects.
    actionLabel: expanded && searching
        ? localCopy.projectsCreate
        : searching
        ? null
        : localCopy.projectsImport,
    onAction: expanded && searching
        ? () => context.go(_createLocation)
        : searching
        ? null
        : () => context.go(_importLocation),
  );
}

void _openRow(BuildContext context, WidgetRef ref, String id) {
  ref.read(currentProjectProvider.notifier).open(id);
  final String? from = GoRouterState.of(
    context,
  ).uri.queryParameters[_fromQuery];
  if (from != null && from.isNotEmpty) {
    return;
  }
  context.go(_projectHome(id));
}

List<AppOverflowAction> _rowActions(
  BuildContext context,
  WidgetRef ref,
  Project project,
) {
  final LocalizedCopy localCopy = Copy.of(context);

  final bool pinned = project.pinnedAt != null;
  final AppOverflowAction? open = projectOpenExternallyMenuItem(
    context,
    ref,
    project,
  );
  return <AppOverflowAction>[
    AppOverflowAction(
      label: localCopy.projectExport,
      icon: AppIcons.export,
      onTap: () => context.push(RoutePaths.projectExports(project.id)),
    ),
    AppOverflowAction(
      label: localCopy.projectRename,
      icon: AppIcons.edit,
      onTap: () => unawaited(ProjectRenameAction.open(context, ref, project)),
    ),
    AppOverflowAction(
      label: pinned ? localCopy.projectUnpin : localCopy.projectPin,
      icon: AppIcons.pin,
      onTap: () => unawaited(
        ref.read(projectRepositoryProvider).setPinned(project.id, !pinned),
      ),
    ),
    ?open,
    AppOverflowAction(
      label: project.status == ProjectStatus.archived
          ? localCopy.projectUnarchive
          : localCopy.projectArchive,
      icon: AppIcons.archive,
      onTap: () => unawaited(ProjectArchiveAction.apply(ref, project)),
    ),
    AppOverflowAction(
      label: localCopy.projectDeleteMenu,
      icon: AppIcons.delete,
      onTap: () =>
          unawaited(ProjectDeleteAction.confirm(context, ref, project)),
    ),
  ];
}

/// Must match [AppRoutes.project]. This file cannot import `router.dart`
/// — the router imports the screen.
String _projectHome(String id) => RoutePaths.project(id);

/// Must match [AppRoutes.projects], [AppRoutes.projectCreate] and
/// [AppRoutes.fromQuery].
const String _createLocation = RoutePaths.projectCreate;
const String _importLocation = RoutePaths.projectImport;
const String _fromQuery = RoutePaths.fromQuery;

/// A project's photo in the number circle when it has one (FBK0000154),
/// and its list number otherwise.
Widget _leading(Project project, int number, {LocalizedCopy? localizedCopy}) {
  final ProjectCoverPhoto? cover = project.settings.coverPhoto;
  if (cover != null) {
    return RecordThumb(
      key: ValueKey<String>('project-photo-${project.id}'),
      sha256: cover.sha256,
      storagePath: cover.path,
    );
  }
  return FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      (localizedCopy ?? Copy.english).projectListNumber(number),
      style: AppText.label,
    ),
  );
}
