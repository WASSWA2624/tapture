import 'package:tapture/core/widgets/record_status.dart';

/// The choices a project's filter sheet offers, read from its records
/// (task 014 step 2, D15). Deleted records contribute nothing.
final class RecordFacets {
  /// Creates the facets.
  const RecordFacets({
    this.templates = const <({String id, String name})>[],
    this.contextLevels =
        const <({String key, String label, List<String> values})>[],
    this.operators = const <({String id, String label})>[],
    this.conditions = const <String>[],
    this.statuses = const <RecordStatus>{},
  });

  /// Facets of a project with no records.
  static const RecordFacets empty = RecordFacets();

  /// Templates the records are filled against, by id with their names.
  final List<({String id, String name})> templates;

  /// Context levels the records carry: the level key, its label and the
  /// values seen at that level.
  final List<({String key, String label, List<String> values})> contextLevels;

  /// Who captured the records: the stored id and the label to show for it.
  final List<({String id, String label})> operators;

  /// Condition codes seen on the condition fields.
  final List<String> conditions;

  /// The statuses the records are in.
  final Set<RecordStatus> statuses;

  /// Whether there is nothing to choose from at all.
  bool get isEmpty =>
      templates.isEmpty &&
      contextLevels.isEmpty &&
      operators.isEmpty &&
      conditions.isEmpty &&
      statuses.isEmpty;

  /// Returns a copy with the provided fields replaced.
  RecordFacets copyWith({
    List<({String id, String name})>? templates,
    List<({String key, String label, List<String> values})>? contextLevels,
    List<({String id, String label})>? operators,
    List<String>? conditions,
    Set<RecordStatus>? statuses,
  }) {
    return RecordFacets(
      templates: templates ?? this.templates,
      contextLevels: contextLevels ?? this.contextLevels,
      operators: operators ?? this.operators,
      conditions: conditions ?? this.conditions,
      statuses: statuses ?? this.statuses,
    );
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(templates),
    Object.hashAll(<Object>[
      for (final ({String key, String label, List<String> values}) level
          in contextLevels)
        Object.hash(level.key, level.label, Object.hashAll(level.values)),
    ]),
    Object.hashAll(operators),
    Object.hashAll(conditions),
    Object.hashAllUnordered(statuses),
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RecordFacets &&
            _sameList(other.templates, templates) &&
            other.contextLevels.length == contextLevels.length &&
            _sameLevels(other.contextLevels, contextLevels) &&
            _sameList(other.operators, operators) &&
            _sameList(other.conditions, conditions) &&
            other.statuses.length == statuses.length &&
            other.statuses.containsAll(statuses));
  }

  /// Counts only: facet values never reach a log (FE-CODE-08).
  @override
  String toString() =>
      'RecordFacets(${templates.length} templates, '
      '${contextLevels.length} levels, ${operators.length} operators)';
}

bool _sameList<T>(List<T> left, List<T> right) {
  if (left.length != right.length) {
    return false;
  }
  for (int index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

bool _sameLevels(
  List<({String key, String label, List<String> values})> left,
  List<({String key, String label, List<String> values})> right,
) {
  for (int index = 0; index < left.length; index++) {
    if (left[index].key != right[index].key ||
        left[index].label != right[index].label ||
        !_sameList(left[index].values, right[index].values)) {
      return false;
    }
  }
  return true;
}
