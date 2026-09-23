import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'project_list_criteria.dart';

/// Owns one criteria snapshot across rotation and size-class changes.
final class ProjectListCriteriaController
    extends Notifier<ProjectListCriteria> {
  @override
  ProjectListCriteria build() => ProjectListCriteria();

  /// Replaces all criteria atomically.
  void set(ProjectListCriteria value) => state = value;

  /// Changes only search text.
  void setQuery(String value) => state = state.copyWith(query: value);

  /// Restores the standard active-project list.
  void clear() => state = ProjectListCriteria();
}

/// Shared project criteria.
final NotifierProvider<ProjectListCriteriaController, ProjectListCriteria>
projectListCriteriaProvider =
    NotifierProvider<ProjectListCriteriaController, ProjectListCriteria>(
      ProjectListCriteriaController.new,
      retry: (int _, Object _) => null,
    );
