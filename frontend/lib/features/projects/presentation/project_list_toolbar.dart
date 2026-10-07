import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_search_field.dart';

import 'project_list_criteria.dart';
import 'project_list_criteria_controller.dart';

/// The shared search toolbar for every project-list layout.
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
    );
  }
}
