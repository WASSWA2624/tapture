part of 'location_service.dart';

/// A time-boxed location sample with reported accuracy.
final class GeoFix {
  /// Creates a fix.
  const GeoFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyMetres,
    required this.capturedAt,
  });

  /// Degrees north.
  final double latitude;

  /// Degrees east.
  final double longitude;

  /// Horizontal accuracy in metres.
  final double accuracyMetres;

  /// When the fix was obtained.
  final DateTime capturedAt;
}
