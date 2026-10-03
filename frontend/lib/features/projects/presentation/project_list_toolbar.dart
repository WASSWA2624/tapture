import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_search_field.dart';

import '../domain/project_repository.dart';
import 'current_project.dart';
import 'project_list_criteria.dart';
import 'project_list_criteria_controller.dart';
import 'project_list_filter.dart';

/// One search and filter toolbar reused by all project-list layouts. The
/// filter button opens the shared filter sheet (FBK0000003).
final class ProjectListToolbar extends ConsumerWidget {
  /// Creates the toolbar.
  const ProjectListToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final ProjectListCriteria criteria = ref.watch(projectListCriteriaProvider);
    return AppSearchField(
      hint: localCopy.projectSearchHint,
      text: criteria.query,
      onChanged: ref.read(projectListCriteriaProvider.notifier).setQuery,
      onFilter: () => unawaited(
        showProjectListFilters(
          context,
          ref,
          ref.read(projectListProvider).asData?.value ??
              const <ProjectListRow>[],
        ),
      ),
      activeFilterCount: criteria.activeFilterCount,
    );
  }
}
