import 'context_state.dart';

/// Prefills record fields from the current context with source CONTEXT.
abstract final class ContextApplication {
  /// Provenance written on every prefilled field. Never a later edit.
  static const String source = 'CONTEXT';

  /// Field writes for a new record, plus a snapshot of the whole context.
  ///
  /// The snapshot is what the record keeps. Later context edits must not
  /// be written back over it.
  static ({
    List<({String fieldKey, String value, String source})> fields,
    Map<String, Object?> snapshot,
  })
  apply(ContextState state) {
    final List<({String fieldKey, String value, String source})> fields =
        <({String fieldKey, String value, String source})>[
          for (final MapEntry<String, String> entry in state.values.entries)
            if (entry.value.isNotEmpty)
              (fieldKey: entry.key, value: entry.value, source: source),
          for (final MapEntry<String, String> entry in state.pinned.entries)
            if (entry.value.isNotEmpty)
              (fieldKey: entry.key, value: entry.value, source: source),
        ];
    final Map<String, Object?> snapshot = <String, Object?>{
      'levels': <Map<String, Object?>>[
        for (final ContextLevel level in state.levels)
          <String, Object?>{
            'fieldKey': level.fieldKey,
            'order': level.order,
            'datasetId': level.datasetId,
            'label': level.label,
            'value': state.values[level.fieldKey],
          },
      ],
      'pinned': Map<String, String>.of(state.pinned),
      'values': Map<String, String>.of(state.values),
    };
    return (fields: fields, snapshot: snapshot);
  }
}
