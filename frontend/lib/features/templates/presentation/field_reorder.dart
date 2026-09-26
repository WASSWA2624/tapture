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

  /// Moves a field within one section of the list. [slots] are the stored
  /// positions the section's fields hold, in order; [from] and [to] are
  /// places within the section, [to] counted after the field is lifted out.
  /// The section's fields are laid back into the same slots, so no field of
  /// another section moves, and a one-place move swaps exactly two fields.
  static List<FieldDef> movedWithin(
    List<FieldDef> fields,
    List<int> slots,
    int from,
    int to,
  ) {
    if (from < 0 ||
        to < 0 ||
        from >= slots.length ||
        to >= slots.length ||
        from == to ||
        slots.any((int slot) => slot < 0 || slot >= fields.length)) {
      return fields;
    }
    final List<FieldDef> section = <FieldDef>[
      for (final int slot in slots) fields[slot],
    ];
    final FieldDef moving = section.removeAt(from);
    section.insert(to, moving);
    final List<FieldDef> next = List<FieldDef>.of(fields);
    for (int index = 0; index < slots.length; index++) {
      next[slots[index]] = section[index];
    }
    return _numbered(next);
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
    return _numbered(next);
  }

  static List<FieldDef> _numbered(List<FieldDef> fields) {
    return <FieldDef>[
      for (int index = 0; index < fields.length; index++)
        fields[index].copyWith(sortOrder: index),
    ];
  }
}
