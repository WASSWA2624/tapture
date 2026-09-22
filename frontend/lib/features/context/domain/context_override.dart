/// Per-record override of a context-prefilled field.
abstract final class ContextOverride {
  /// Marks [fieldKey] overridden on this record only.
  ///
  /// Returns the record field map with [newValue] and an override flag set.
  /// Project context and sibling records are never touched here.
  static Map<String, Object?> mark({
    required Map<String, Object?> recordFields,
    required String fieldKey,
    required String newValue,
    required String previousValue,
  }) {
    final Map<String, Object?> next = Map<String, Object?>.of(recordFields);
    next[fieldKey] = <String, Object?>{
      'value': newValue,
      'source': 'manual',
      'overridden': true,
      'previousValue': previousValue,
    };
    return next;
  }

  /// Whether [field] is marked overridden.
  static bool isOverridden(Object? field) {
    if (field is Map) {
      return field['overridden'] == true;
    }
    return false;
  }
}
