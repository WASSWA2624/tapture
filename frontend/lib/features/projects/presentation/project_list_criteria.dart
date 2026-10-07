/// Search and archive visibility shared by every responsive project list.
final class ProjectListCriteria {
  /// Active projects are the default landing view.
  const ProjectListCriteria({this.query = '', this.showArchived = false});

  /// Free-text query across project name, description and organisation.
  final String query;

  /// Includes archived projects beside active projects when true.
  final bool showArchived;

  /// Whether the visible search narrows the list.
  bool get isActive => query.trim().isNotEmpty;

  /// Returns a changed snapshot.
  ProjectListCriteria copyWith({String? query, bool? showArchived}) =>
      ProjectListCriteria(
        query: query ?? this.query,
        showArchived: showArchived ?? this.showArchived,
      );
}
