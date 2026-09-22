import 'context_state.dart';

/// Prefills record fields from the current context with source CONTEXT.
abstract final class ContextApplication {
  /// Field map to write onto a new record, plus a snapshot of the whole context.
  static ({Map<String, String> fields, Map<String, Object?> snapshot}) apply(
    ContextState state,
  ) {
    final Map<String, String> fields = <String, String>{
      ...state.values,
      ...state.pinned,
    };
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
      'pinned': state.pinned,
      'values': state.values,
    };
    return (fields: fields, snapshot: snapshot);
  }
}
