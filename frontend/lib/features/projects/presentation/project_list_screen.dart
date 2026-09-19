import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/project_repository.dart';
import 'current_project.dart';
import 'project_archive_action.dart';
import 'project_delete_action.dart';
import 'project_list_filter.dart';

/// Landing list: every active project as one row with counts and
/// last-worked time. Archived rows sit behind [Copy.projectShowArchived].
class ProjectListScreen extends ConsumerWidget {
  /// Creates the landing list.
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool showArchived = ref.watch(projectListShowArchivedProvider);
    final AsyncValue<List<ProjectListRow>> value = ref.watch(
      projectListProvider,
    );
    value.whenData((List<ProjectListRow> _) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resumeLastProject(context, ref);
      });
    });
    return AppPage(
      key: const ValueKey<String>('route-projects'),
      title: Copy.navProjects,
      showAppBar: false,
      inset: false,
      scrollable: false,
      footer: value.hasValue
          ? AppPrimaryAction(
              label: Copy.projectsCreate,
              onPressed: () => context.go(_createLocation),
            )
          : null,
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x4),
            child: AppSwitchTile.checkbox(
              title: Copy.projectShowArchived,
              value: showArchived,
              dense: true,
              controlFirst: true,
              onChanged: ref.read(projectListShowArchivedProvider.notifier).set,
            ),
          ),
          Expanded(
            child: AsyncValueView<List<ProjectListRow>>(
              value: value,
              isEmpty: (List<ProjectListRow> rows) => rows.isEmpty,
              empty: () => _empty(context),
              onRetry: () => ref.invalidate(projectListProvider),
              data: (List<ProjectListRow> rows) {
                return SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      for (final ProjectListRow row in rows)
                        AppListTile(
                          title: row.project.name,
                          subtitle: Copy.projectListSubtitle(
                            records: row.recordCount,
                            unprocessed: row.unprocessedCount,
                            lastWorked: Copy.projectLastWorked(
                              row.lastWorkedAt,
                            ),
                          ),
                          trailing: AppOverflowMenu(
                            items: <AppOverflowAction>[
                              AppOverflowAction(
                                label: Copy.projectEditTitle,
                                icon: Icons.edit_outlined,
                                onTap: () =>
                                    _openDetails(context, ref, row.project.id),
                              ),
                              AppOverflowAction(
                                label:
                                    row.project.status == ProjectStatus.archived
                                    ? Copy.projectUnarchive
                                    : Copy.projectArchive,
                                icon: Icons.inventory_2_outlined,
                                onTap: () => unawaited(
                                  ProjectArchiveAction.apply(ref, row.project),
                                ),
                              ),
                              AppOverflowAction(
                                label: Copy.projectDelete,
                                icon: Icons.delete_outline,
                                onTap: () => unawaited(
                                  ProjectDeleteAction.confirm(
                                    context,
                                    ref,
                                    row.project,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _openRow(context, ref, row.project.id),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return AppEmptyState(
      icon: Icons.folder_open_outlined,
      headline: Copy.projectsEmptyHeadline,
      message: Copy.projectsEmptyMessage,
      actionLabel: Copy.projectsCreate,
      onAction: () => context.go(_createLocation),
    );
  }
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

void _openDetails(BuildContext context, WidgetRef ref, String id) {
  ref.read(currentProjectProvider.notifier).open(id);
  context.go(_projectEdit(id));
}

void _resumeLastProject(BuildContext context, WidgetRef ref) {
  if (!context.mounted) {
    return;
  }
  final String? from = GoRouterState.of(
    context,
  ).uri.queryParameters[_fromQuery];
  if (from != null && from.isNotEmpty) {
    return;
  }
  final String? id = ref
      .read(currentProjectProvider.notifier)
      .consumeLaunchRestore();
  if (id == null) {
    return;
  }
  context.go(_projectHome(id));
}

/// Must match [AppRoutes.project]. This file cannot import `router.dart`
/// — the router imports the screen.
String _projectHome(String id) {
  return '$_projectsRoot/${Uri.encodeComponent(id)}';
}

/// Must match [AppRoutes.projectEdit].
String _projectEdit(String id) {
  return '$_projectsRoot/${Uri.encodeComponent(id)}/$_editSegment';
}

/// Must match [AppRoutes.projects], [AppRoutes.projectCreate],
/// [AppRoutes.projectEdit] and [AppRoutes.fromQuery].
const String _projectsRoot = '/projects';
const String _newSegment = 'new';
const String _editSegment = 'edit';
const String _createLocation = '$_projectsRoot/$_newSegment';
const String _fromQuery = 'from';
