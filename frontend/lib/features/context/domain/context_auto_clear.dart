import 'context_state.dart';

/// Clears the lowest hierarchy level after idle, at most once per period.
abstract final class ContextAutoClear {
  /// Whether auto-clear should fire now.
  static bool shouldClear({
    required bool enabled,
    required Duration idleInterval,
    required DateTime lastActivity,
    required DateTime now,
    required bool alreadyFiredThisPeriod,
  }) {
    if (!enabled || idleInterval <= Duration.zero) {
      return false;
    }
    if (alreadyFiredThisPeriod) {
      return false;
    }
    return now.difference(lastActivity) >= idleInterval;
  }

  /// Field key of the lowest level, or null when there is none.
  static String? lowestFieldKey(List<({String fieldKey, int order})> levels) {
    if (levels.isEmpty) {
      return null;
    }
    final List<({String fieldKey, int order})> ordered =
        List<({String fieldKey, int order})>.of(levels)..sort(
          (
            ({String fieldKey, int order}) a,
            ({String fieldKey, int order}) b,
          ) => a.order.compareTo(b.order),
        );
    return ordered.last.fieldKey;
  }

  /// Removes only the lowest level's value. Pins and higher levels stay.
  static ({ContextState next, String? fieldKey, String? value}) clearLowest(
    ContextState state,
  ) {
    final String? key = lowestFieldKey(<({String fieldKey, int order})>[
      for (final ContextLevel level in state.levels)
        (fieldKey: level.fieldKey, order: level.order),
    ]);
    if (key == null) {
      return (next: state, fieldKey: null, value: null);
    }
    final String? value = state.values[key];
    if (value == null || value.isEmpty) {
      return (next: state, fieldKey: key, value: null);
    }
    final Map<String, String> next = Map<String, String>.of(state.values)
      ..remove(key);
    return (next: state.copyWith(values: next), fieldKey: key, value: value);
  }

  /// Puts [value] back on [fieldKey] after an undo.
  static ContextState restore({
    required ContextState state,
    required String fieldKey,
    required String value,
  }) {
    return state.copyWith(
      values: <String, String>{...state.values, fieldKey: value},
    );
  }
}
