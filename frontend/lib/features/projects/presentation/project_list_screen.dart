import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/features/settings/settings.dart';

import '../domain/project_repository.dart';
import 'current_project.dart';
import 'project_home_screen.dart';
import 'project_list_actions.dart';
import 'project_list_toolbar.dart';
import 'project_list_view.dart';

/// Landing list: every active project as one row with counts and
/// last-worked time. Archived rows sit behind [Copy.projectShowArchived].
class ProjectListScreen extends ConsumerWidget {
  /// Creates the landing list.
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    ).uri.queryParameters[_fromQuery];
    final bool diverted = from != null && from.isNotEmpty;
    if (expanded && open != null && !diverted) {
      return const ProjectHomeScreen();
    }
    return AppPage(
      key: const ValueKey<String>('route-projects'),
      title: Copy.navProjects,
      showAppBar: !expanded,
      actions: expanded
          ? const <Widget>[]
          : ProjectListActions.barActions(context),
      overflow: ProjectListActions.overflow(ref),
      inset: false,
      scrollable: false,
      footer: value.hasValue && !expanded
          ? AppPrimaryAction(
              label: Copy.projectsCreate,
              onPressed: () => context.go(_createLocation),
            )
          : null,
      body: expanded
          ? const SizedBox.shrink()
          : const Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    Space.x4,
                    Space.x1,
                    Space.x4,
                    Space.x2,
                  ),
                  child: ProjectListToolbar(),
                ),
                Expanded(child: ProjectListView(filtered: true)),
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
