import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/normalise/search_text.dart';

import '../domain/project_repository.dart';
import 'current_project.dart';
import 'project_list_criteria.dart';
import 'project_list_criteria_controller.dart';

/// [projectListProvider] narrowed by the shared criteria in one linear pass.
final Provider<AsyncValue<List<ProjectListRow>>> projectListFilteredProvider =
    Provider<AsyncValue<List<ProjectListRow>>>((Ref ref) {
      final ProjectListCriteria criteria = ref.watch(
        projectListCriteriaProvider,
      );
      final AsyncValue<List<ProjectListRow>> list = ref.watch(
        projectListProvider,
      );
      final String needle = foldSearchText(criteria.query.trim());
      return list.whenData((List<ProjectListRow> rows) {
        return <ProjectListRow>[
          for (final ProjectListRow row in rows)
            if (_matches(row.project, criteria, needle)) row,
        ];
      });
    });

bool _matches(Project project, ProjectListCriteria criteria, String needle) {
  if (!criteria.showArchived && project.status == ProjectStatus.archived) {
    return false;
  }
  return needle.isEmpty ||
      <String>[
        project.name,
        project.description ?? '',
        project.organisation ?? '',
      ].any((String value) => foldSearchText(value).contains(needle));
}
