import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/project_repository.dart';
import 'current_project.dart';

/// Landing list: every active project as one row with counts and
/// last-worked time.
class ProjectListScreen extends ConsumerWidget {
  /// Creates the landing list.
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: AsyncValueView<List<ProjectListRow>>(
        value: value,
        isEmpty: (List<ProjectListRow> rows) => rows.isEmpty,
        empty: _empty,
        onRetry: () => ref.invalidate(projectListProvider),
        data: (List<ProjectListRow> rows) {
          return Column(
            children: <Widget>[
              for (final ProjectListRow row in rows)
                AppListTile(
                  title: row.project.name,
                  subtitle: Copy.projectListSubtitle(
                    records: row.recordCount,
                    unprocessed: row.unprocessedCount,
                    lastWorked: Copy.projectLastWorked(row.lastWorkedAt),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openRow(context, ref, row.project.id),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _empty() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppEmptyState(
          icon: Icons.folder_open_outlined,
          headline: Copy.projectsEmptyHeadline,
          message: Copy.projectsEmptyMessage,
          actionLabel: Copy.projectsCreate,
          onAction: _noop,
        ),
        AppButton(
          label: Copy.projectsImport,
          variant: AppButtonVariant.secondary,
          onPressed: _noop,
        ),
      ],
    );
  }
}

void _noop() {}

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

/// Must match [AppRoutes.projects] and [AppRoutes.fromQuery].
const String _projectsRoot = '/projects';
const String _fromQuery = 'from';
