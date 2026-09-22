import 'dart:math' as math;

/// Reads one fix. Callers pass this only after [ContextMovementPrompt.evaluate]
/// says a read is allowed, so an off switch never touches location.
typedef ContextFixReader = ({double latitude, double longitude})? Function();

/// Asks the operator to confirm context after travelling a configured distance.
///
/// Never changes the context itself — only decides whether to prompt and
/// whether a location read is allowed.
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

  /// Decides whether to read a fix and whether to prompt.
  ///
  /// [readFix] is not called while the feature, GPS or permission is off.
  static ({bool prompt, bool readFix}) evaluate({
    required bool enabled,
    required bool gpsEnabled,
    required bool locationGranted,
    required double thresholdMetres,
    required ContextFixReader readFix,
    ({double latitude, double longitude})? origin,
  }) {
    if (!enabled || !gpsEnabled || !locationGranted) {
      return (prompt: false, readFix: false);
    }
    final ({double latitude, double longitude})? current = readFix();
    if (origin == null || current == null || thresholdMetres <= 0) {
      return (prompt: false, readFix: true);
    }
    final double metres = metresBetween(origin, current);
    return (prompt: metres >= thresholdMetres, readFix: true);
  }

  /// Great-circle distance in metres between two fixes.
  static double metresBetween(
    ({double latitude, double longitude}) a,
    ({double latitude, double longitude}) b,
  ) {
    const double earthRadiusMetres = 6371000;
    final double p1 = a.latitude * math.pi / 180;
    final double p2 = b.latitude * math.pi / 180;
    final double dLat = (b.latitude - a.latitude) * math.pi / 180;
    final double dLon = (b.longitude - a.longitude) * math.pi / 180;
    final double sinLat = math.sin(dLat / 2);
    final double sinLon = math.sin(dLon / 2);
    final double h =
        sinLat * sinLat + math.cos(p1) * math.cos(p2) * sinLon * sinLon;
    return 2 * earthRadiusMetres * math.asin(math.min(1, math.sqrt(h)));
  }
}
