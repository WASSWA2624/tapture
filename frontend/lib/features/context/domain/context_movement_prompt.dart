/// Asks the operator to confirm context after travelling a configured distance.
///
/// Never changes the context itself — only decides whether to prompt.
abstract final class ContextMovementPrompt {
  /// Whether a confirmation prompt should be shown.
  static bool shouldPrompt({
    required bool enabled,
    required bool gpsEnabled,
    required bool locationGranted,
    required double distanceMetres,
    required double thresholdMetres,
  }) {
    if (!enabled || !gpsEnabled || !locationGranted) {
      return false;
    }
    if (thresholdMetres <= 0) {
      return false;
    }
    return distanceMetres >= thresholdMetres;
  }
}
