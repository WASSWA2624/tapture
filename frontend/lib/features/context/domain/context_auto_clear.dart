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
}
