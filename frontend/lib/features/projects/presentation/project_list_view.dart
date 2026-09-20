import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;
import 'current_project.dart';
import 'project_archive_action.dart';
import 'project_delete_action.dart';
import 'project_list_filter.dart';
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
    final String query = filtered
        ? ref.watch(projectListSearchQueryProvider)
        : '';
    final AsyncValue<List<ProjectListRow>> value = ref.watch(
      filtered ? projectListFilteredProvider : projectListProvider,
    );
    return AsyncValueView<List<ProjectListRow>>(
      value: value,
      isEmpty: (List<ProjectListRow> rows) => rows.isEmpty,
      empty: () => SingleChildScrollView(
        child: _empty(context, searching: filtered && query.trim().isNotEmpty),
      ),
      onRetry: () => ref.invalidate(projectListProvider),
      data: (List<ProjectListRow> rows) {
        return SingleChildScrollView(
          child: Column(
            children: <Widget>[
              for (int index = 0; index < rows.length; index++)
                AppListTile(
                  key: ValueKey<String>(
                    'project-row-${rows[index].project.id}',
                  ),
                  leading: ExcludeSemantics(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        Copy.projectListNumber(index + 1),
                        style: AppText.label,
                      ),
                    ),
                  ),
                  title: rows[index].project.name,
                  subtitle: Copy.projectListSubtitle(
                    records: rows[index].recordCount,
                    unprocessed: rows[index].unprocessedCount,
                    lastWorked: Copy.projectLastWorked(
                      rows[index].lastWorkedAt,
                    ),
                  ),
                  trailing: AppOverflowMenu(
                    outlined: false,
                    items: _rowActions(context, ref, rows[index].project),
                  ),
                  onTap: () => _openRow(context, ref, rows[index].project.id),
                ),
            ],
          ),
        );
      },
    );
  }
}

Widget _empty(BuildContext context, {required bool searching}) {
  return AppEmptyState(
    icon: Icons.folder_open_outlined,
    headline: searching
        ? Copy.projectsNoMatchHeadline
        : Copy.projectsEmptyHeadline,
    message: searching
        ? Copy.projectsNoMatchMessage
        : Copy.projectsEmptyMessage,
    actionLabel: Copy.projectsCreate,
    onAction: () => context.go(_createLocation),
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
  final bool pinned = project.pinnedAt != null;
  return <AppOverflowAction>[
    AppOverflowAction(
      label: Copy.projectRename,
      icon: Icons.edit_outlined,
      onTap: () => unawaited(ProjectRenameAction.open(context, ref, project)),
    ),
    AppOverflowAction(
      label: pinned ? Copy.projectUnpin : Copy.projectPin,
      icon: Icons.push_pin_outlined,
      onTap: () => unawaited(
        ref.read(projectRepositoryProvider).setPinned(project.id, !pinned),
      ),
    ),
    AppOverflowAction(
      label: project.status == ProjectStatus.archived
          ? Copy.projectUnarchive
          : Copy.projectArchive,
      icon: Icons.inventory_2_outlined,
      onTap: () => unawaited(ProjectArchiveAction.apply(ref, project)),
    ),
    AppOverflowAction(
      label: Copy.projectDelete,
      icon: Icons.delete_outline,
      onTap: () =>
          unawaited(ProjectDeleteAction.confirm(context, ref, project)),
    ),
  ];
}

/// Must match [AppRoutes.project]. This file cannot import `router.dart`
/// — the router imports the screen.
String _projectHome(String id) {
  return '$_projectsRoot/${Uri.encodeComponent(id)}';
}

/// Must match [AppRoutes.projects], [AppRoutes.projectCreate] and
/// [AppRoutes.fromQuery].
const String _projectsRoot = '/projects';
const String _newSegment = 'new';
const String _createLocation = '$_projectsRoot/$_newSegment';
const String _fromQuery = 'from';
