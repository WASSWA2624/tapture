// ignore_for_file: library_private_types_in_public_api

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/normalise/search_text.dart';

import '../domain/project_repository.dart';
import 'current_project.dart';
import 'project_list_criteria.dart';
import 'project_list_criteria_controller.dart';

/// Whether the landing list includes archived projects.
final class ProjectListFilter extends Notifier<bool> {
  /// Starts with archived projects hidden.
  @override
  bool build() => false;

  /// Shows or hides archived projects on the landing list.
  void set(bool value) {
    state = value;
    final ProjectListCriteria criteria = ref.read(projectListCriteriaProvider);
    ref
        .read(projectListCriteriaProvider.notifier)
        .set(
          criteria.copyWith(
            statuses: value
                ? const <ProjectStatus>{
                    ProjectStatus.active,
                    ProjectStatus.archived,
                  }
                : const <ProjectStatus>{ProjectStatus.active},
          ),
        );
  }
}

/// Filter the landing list reads. Off by default so archived rows stay
/// hidden until the operator asks.
final NotifierProvider<ProjectListFilter, bool>
projectListShowArchivedProvider = NotifierProvider<ProjectListFilter, bool>(
  ProjectListFilter.new,
  retry: (int _, Object _) => null,
);

/// The project-list search query. Survives a size-class change so the
/// pane can restore what was typed (FE-RESP-03).
final NotifierProvider<_ProjectListSearchQuery, String>
projectListSearchQueryProvider =
    NotifierProvider<_ProjectListSearchQuery, String>(
      _ProjectListSearchQuery.new,
      retry: (int _, Object _) => null,
    );

/// [projectListProvider] narrowed by the shared criteria in one linear pass.
final Provider<AsyncValue<List<ProjectListRow>>>
projectListFilteredProvider = Provider<AsyncValue<List<ProjectListRow>>>((
  Ref ref,
) {
  final ProjectListCriteria criteria = ref.watch(projectListCriteriaProvider);
  final String legacyQuery = ref.watch(projectListSearchQueryProvider);
  final AsyncValue<List<ProjectListRow>> list = ref.watch(projectListProvider);
  final String query = criteria.query.isEmpty ? legacyQuery : criteria.query;
  final String needle = foldSearchText(query.trim());
  return list.whenData((List<ProjectListRow> rows) {
    return <ProjectListRow>[
      for (final ProjectListRow row in rows)
        if (_matches(row.project, criteria, needle)) row,
    ];
  });
});

bool _matches(Project project, ProjectListCriteria criteria, String needle) {
  if (criteria.statuses.isNotEmpty &&
      !criteria.statuses.contains(project.status)) {
    return false;
  }
  final bool pinned = project.pinnedAt != null;
  if (criteria.pin == ProjectPinFilter.pinned && !pinned) {
    return false;
  }
  if (criteria.pin == ProjectPinFilter.unpinned && pinned) {
    return false;
  }
  final String organisation = project.organisation?.trim() ?? '';
  if (criteria.organisations.isNotEmpty &&
      !criteria.organisations.contains(organisation)) {
    return false;
  }
  if (needle.isEmpty) {
    return true;
  }
  return <String>[
    project.name,
    project.description ?? '',
    organisation,
  ].any((String value) => foldSearchText(value).contains(needle));
}

class _ProjectListSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  /// Replaces the query. The field owns debounce; this stores the last emit.
  void set(String value) {
    state = value;
    ref.read(projectListCriteriaProvider.notifier).setQuery(value);
  }
}
