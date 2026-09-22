import 'context_state.dart';

/// Cascade clearing: which lower levels a higher-level change clears.
abstract final class ContextCascade {
  /// Levels strictly below [changedFieldKey], with their current values.
  ///
  /// Pins are ignored. Changing the lowest level returns an empty list.
  static List<({ContextLevel level, String value})> affected({
    required ContextState state,
    required String changedFieldKey,
  }) {
    final List<ContextLevel> ordered = List<ContextLevel>.of(state.levels)
      ..sort((ContextLevel a, ContextLevel b) => a.order.compareTo(b.order));
    final int index = ordered.indexWhere(
      (ContextLevel level) => level.fieldKey == changedFieldKey,
    );
    if (index < 0) {
      return const <({ContextLevel level, String value})>[];
    }
    return <({ContextLevel level, String value})>[
      for (final ContextLevel level in ordered.skip(index + 1))
        (level: level, value: state.values[level.fieldKey] ?? ''),
    ];
  }

  /// Applies [newValue] at [changedFieldKey] and clears every affected level.
  static ContextState apply({
    required ContextState state,
    required String changedFieldKey,
    required String newValue,
  }) {
    final List<({ContextLevel level, String value})> below = affected(
      state: state,
      changedFieldKey: changedFieldKey,
    );
    final Map<String, String> next = Map<String, String>.of(state.values);
    next[changedFieldKey] = newValue;
    for (final ({ContextLevel level, String value}) item in below) {
      next.remove(item.level.fieldKey);
    }
    return state.copyWith(values: next);
  }
}
