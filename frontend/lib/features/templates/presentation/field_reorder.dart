import '../domain/field_def.dart';

/// Capture and export order of a template's fields.
///
/// Reordering writes a new list order only. Stored values and
/// [FieldDef.outputColumn] stay as they were.
abstract final class FieldReorder {
  /// Moves [from] to [to] after the list has already been shortened.
  static List<FieldDef> moved(List<FieldDef> fields, int from, int to) {
    return _placed(fields, from, to);
  }

  /// Swaps [index] with the previous field when there is one.
  static List<FieldDef> movedUp(List<FieldDef> fields, int index) {
    return _placed(fields, index, index - 1);
  }

  /// Swaps [index] with the next field when there is one.
  static List<FieldDef> movedDown(List<FieldDef> fields, int index) {
    return _placed(fields, index, index + 1);
  }

  static List<FieldDef> _placed(List<FieldDef> fields, int from, int to) {
    if (from < 0 ||
        to < 0 ||
        from >= fields.length ||
        to >= fields.length ||
        from == to) {
      return fields;
    }
    final List<FieldDef> next = List<FieldDef>.of(fields);
    final FieldDef field = next.removeAt(from);
    next.insert(to, field);
    return <FieldDef>[
      for (int index = 0; index < next.length; index++)
        next[index].copyWith(sortOrder: index),
    ];
  }
}
