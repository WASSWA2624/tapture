import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/project_status.dart';

/// Pinned-state predicate for the project landing list.
enum ProjectPinFilter { all, pinned, unpinned }

/// Immutable search and filter state shared by every responsive list branch.
final class ProjectListCriteria {
  /// Creates criteria. Active projects are the default landing view.
  factory ProjectListCriteria({
    String query = '',
    Set<ProjectStatus> statuses = const <ProjectStatus>{ProjectStatus.active},
    ProjectPinFilter pin = ProjectPinFilter.all,
    Set<String> organisations = const <String>{},
  }) {
    return ProjectListCriteria._(
      query: query,
      statuses: Set<ProjectStatus>.unmodifiable(statuses),
      pin: pin,
      organisations: Set<String>.unmodifiable(organisations),
    );
  }

  const ProjectListCriteria._({
    required this.query,
    required this.statuses,
    required this.pin,
    required this.organisations,
  });

  /// Free-text query.
  final String query;

  /// Included lifecycle states.
  final Set<ProjectStatus> statuses;

  /// Pinned-state predicate.
  final ProjectPinFilter pin;

  /// Included organisation names. Empty means every organisation.
  final Set<String> organisations;

  /// Number displayed on the Filters action. Search is visible separately.
  int get activeFilterCount {
    var count = 0;
    if (statuses.length != 1 || !statuses.contains(ProjectStatus.active)) {
      count += 1;
    }
    if (pin != ProjectPinFilter.all) {
      count += 1;
    }
    if (organisations.isNotEmpty) {
      count += 1;
    }
    return count;
  }

  /// Whether any search or secondary predicate is active.
  bool get isActive => query.trim().isNotEmpty || activeFilterCount > 0;

  /// Returns a changed snapshot.
  ProjectListCriteria copyWith({
    String? query,
    Set<ProjectStatus>? statuses,
    ProjectPinFilter? pin,
    Set<String>? organisations,
  }) {
    return ProjectListCriteria(
      query: query ?? this.query,
      statuses: statuses ?? this.statuses,
      pin: pin ?? this.pin,
      organisations: organisations ?? this.organisations,
    );
  }
}

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
