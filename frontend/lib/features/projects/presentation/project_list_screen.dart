import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';

import '../domain/project_repository.dart';
import 'current_project.dart';
import 'project_home_screen.dart';
import 'project_list_filter.dart';
import 'project_list_view.dart';

/// Landing list: every active project as one row with counts and
/// last-worked time. Archived rows sit behind [Copy.projectShowArchived].
class ProjectListScreen extends ConsumerWidget {
  /// Creates the landing list.
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool expanded = context.sizeClass == SizeClass.expanded;
    final bool showArchived = ref.watch(projectListShowArchivedProvider);
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
    ).uri.queryParameters[_fromQuery];
    final bool diverted = from != null && from.isNotEmpty;
    if (expanded && open != null && !diverted) {
      return const ProjectHomeScreen();
    }
    final List<ProjectListRow>? rows = value.asData?.value;
    final bool hasRows = rows != null && rows.isNotEmpty;
    return AppPage(
      key: const ValueKey<String>('route-projects'),
      title: Copy.navProjects,
      showAppBar: false,
      inset: false,
      scrollable: false,
      footer: value.hasValue && (!hasRows || !expanded)
          ? AppPrimaryAction(
              label: Copy.projectsCreate,
              onPressed: () => context.go(_createLocation),
            )
          : null,
      body: Column(
        children: <Widget>[
          if (!expanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.x4),
              child: AppSwitchTile.checkbox(
                title: Copy.projectShowArchived,
                value: showArchived,
                dense: true,
                controlFirst: true,
                onChanged: ref
                    .read(projectListShowArchivedProvider.notifier)
                    .set,
              ),
            ),
          Expanded(
            child: expanded && hasRows
                ? const SizedBox.shrink()
                : const ProjectListView(),
          ),
        ],
      ),
    );
  }
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

/// Must match [AppRoutes.projects] and [AppRoutes.projectCreate].
const String _projectsRoot = '/projects';
const String _newSegment = 'new';
const String _createLocation = '$_projectsRoot/$_newSegment';
const String _fromQuery = 'from';
