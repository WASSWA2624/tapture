import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_viewport.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/settings/settings.dart';

import '../domain/project_repository.dart';
import 'current_project.dart';
import 'project_home_screen.dart';
import 'project_list_actions.dart';
import 'project_list_toolbar.dart';
import 'project_list_view.dart';

/// Landing list: every active project as one row with counts and
/// last-worked time. Archived rows sit behind the status filter.
class ProjectListScreen extends ConsumerWidget {
  /// Creates the landing list.
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool expanded = context.sizeClass == SizeClass.expanded;
    final AsyncValue<List<ProjectListRow>> value = ref.watch(
      projectListProvider,
    );
    final Project? open = expanded
        ? ref.watch(currentProjectDetailsProvider)
        : null;
    value.whenData((List<ProjectListRow> _) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resumeLastProject(context, ref);
      });
    });
    final String? from = GoRouterState.of(
      context,
    ).uri.queryParameters[RoutePaths.fromQuery];
    final bool diverted = from != null && from.isNotEmpty;
    if (expanded && open != null && !diverted) {
      return const ProjectHomeScreen();
    }
    return AppPage(
      key: const ValueKey<String>('route-projects'),
      title: localCopy.navProjects,
      showAppBar: !expanded,
      overflow: ProjectListActions.overflow(context, ref),
      inset: false,
      scrollable: false,
      footer: value.hasValue && !expanded
          ? AppPrimaryAction(
              label: localCopy.projectsCreate,
              onPressed: () => ProjectListActions.create(context),
            )
          : null,
      body: expanded
          ? AppEmptyState(
              icon: AppIcons.project,
              headline: localCopy.projectsPickHeadline,
              message: localCopy.projectsPickMessage,
              // The pane already offers Create when it has projects.
              actionLabel: value.asData?.value.isNotEmpty == true
                  ? localCopy.projectsImport
                  : localCopy.projectsCreate,
              onAction: () {
                if (value.asData?.value.isNotEmpty == true) {
                  context.go(RoutePaths.projectImport);
                } else {
                  ProjectListActions.create(context);
                }
              },
            )
          : const AppListViewport(
              header: Padding(
                padding: EdgeInsets.fromLTRB(
                  Space.x4,
                  Space.x1,
                  Space.x4,
                  Space.x2,
                ),
                child: ProjectListToolbar(),
              ),
              body: ProjectListView(filtered: true),
            ),
    );
  }
}

/// Reopens the last project once per session, from the persisted id.
void _resumeLastProject(BuildContext context, WidgetRef ref) {
  if (!context.mounted) {
    return;
  }
  final String? from = GoRouterState.of(
    context,
  ).uri.queryParameters[RoutePaths.fromQuery];
  if (from != null && from.isNotEmpty) {
    return;
  }
  final String stored = ref
      .read(projectSettingsStoreProvider)
      .read(SettingKeys.lastLocation);
  if (stored.isNotEmpty) {
    return;
  }
  final String? id = ref
      .read(currentProjectProvider.notifier)
      .consumeLaunchRestore();
  if (id == null) {
    return;
  }
  context.go(RoutePaths.project(id));
}
