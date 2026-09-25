import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_search_field.dart';

import 'project_list_criteria.dart';
import 'project_list_criteria_controller.dart';

/// One search and filter toolbar reused by all project-list layouts.
final class ProjectListToolbar extends ConsumerWidget {
  /// Creates the toolbar.
  const ProjectListToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProjectListCriteria criteria = ref.watch(projectListCriteriaProvider);
    final String filterLabel = Copy.projectFilters(criteria.activeFilterCount);
    return AppSearchField(
      hint: Copy.projectSearchHint,
      text: criteria.query,
      onChanged: ref.read(projectListCriteriaProvider.notifier).setQuery,
      afterMic: AppIconButton(
        icon: AppIcons.filter,
        tooltip: filterLabel,
        semanticLabel: filterLabel,
        selected: criteria.activeFilterCount > 0 ? true : null,
        outlined: false,
        onPressed: () => context.push(RoutePaths.projectFilters),
      ),
    );
  }
}
