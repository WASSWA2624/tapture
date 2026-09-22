import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/location/location_service.dart';

/// Optional GPS stamp for capture. Never requests permission while GPS is
/// off (FE-SEC-07). A slow or missing fix never delays the save.
abstract final class GpsCapture {
  /// Returns a fix when [gpsEnabled], otherwise null without calling
  /// [location].
  static Future<Result<GeoFix?>> maybeFix({
    required bool gpsEnabled,
    required LocationService location,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (!gpsEnabled) {
      return const Success<GeoFix?>(null);
    }
    return location.currentFix(timeout: timeout);
  }
}
