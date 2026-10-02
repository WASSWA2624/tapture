import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'location_reader.dart';

export 'geo_fix.dart';

/// Time-boxed location fix. Features never call a geolocation plugin
/// (FE-STR-11). No permission is requested while GPS is off (FE-SEC-07).
abstract interface class LocationService implements LocationReader {
  /// Uses the platform's location service only while GPS is enabled.
  factory LocationService({bool Function()? gpsEnabled}) {
    return _PlatformLocationService(gpsEnabled ?? (() => false));
  }

  /// Scripted stand-in for tests.
  factory LocationService.fake({
    GeoFix? fix,
    Failure? failure,
    Duration delay = Duration.zero,
    bool Function()? gpsEnabled,
    List<String>? calls,
  }) {
    return _FakeLocationService(
      fix: fix,
      failure: failure,
      delay: delay,
      gpsEnabled: gpsEnabled ?? (() => true),
      calls: calls,
    );
  }

  /// Unavailable stand-in. Default until [main] swaps a real one.
  const factory LocationService.unavailable() = _UnavailableLocationService;

  /// Requests a fix, waiting at most [timeout]. Returns accuracy with the
  /// coordinates. Does nothing when GPS is off.
  @override
  Future<Result<GeoFix?>> currentFix({
    Duration timeout = AppConstants.locationTimeout,
  });
}

/// Process-wide location. Default is unavailable.
final Provider<LocationService> locationServiceProvider =
    Provider<LocationService>((Ref _) {
      return const LocationService.unavailable();
    });

final class _UnavailableLocationService implements LocationService {
  const _UnavailableLocationService();

  @override
  Future<Result<GeoFix?>> currentFix({
    Duration timeout = AppConstants.locationTimeout,
  }) async {
    return const Success<GeoFix?>(null);
  }
}

final class _PlatformLocationService implements LocationService {
  _PlatformLocationService(this._gpsEnabled);
  final bool Function() _gpsEnabled;

  @override
  Future<Result<GeoFix?>> currentFix({
    Duration timeout = AppConstants.locationTimeout,
  }) async {
    if (!_gpsEnabled() || timeout <= Duration.zero) {
      return const Success<GeoFix?>(null);
    }
    bool expired = false;
    final Stopwatch elapsed = Stopwatch()..start();
    bool active() => !expired && _gpsEnabled();
    try {
      final GeoFix? fix =
          await _readFix(
            active: active,
            remaining: () => timeout - elapsed.elapsed,
          ).timeout(
            timeout,
            onTimeout: () {
              // The plug-in cannot cancel a permission prompt. Its late result
              // must never start another platform call or attach a stale fix.
              expired = true;
              return null;
            },
          );
      return Success<GeoFix?>(fix);
    } on Object {
      // Location is advisory: denied, insecure and unavailable platforms
      // leave capture and context usable without coordinates (task 091).
      return const Success<GeoFix?>(null);
    } finally {
      expired = true;
      elapsed.stop();
    }
  }

  Future<GeoFix?> _readFix({
    required bool Function() active,
    required Duration Function() remaining,
  }) async {
    if (!await Geolocator.isLocationServiceEnabled() || !active()) {
      return null;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (!active()) {
      return null;
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!active() ||
        (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always)) {
      return null;
    }
    final Duration budget = remaining();
    if (budget <= Duration.zero) {
      return null;
    }
    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: budget,
      ),
    );
    return active()
        ? GeoFix(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracyMetres: position.accuracy,
            capturedAt: position.timestamp.toUtc(),
          )
        : null;
  }
}

final class _FakeLocationService implements LocationService {
  _FakeLocationService({
    required this.fix,
    required this.failure,
    required this.delay,
    required this._gpsEnabled,
    required this.calls,
  });

  final GeoFix? fix;
  final Failure? failure;
  final Duration delay;
  final bool Function() _gpsEnabled;
  final List<String>? calls;

  @override
  Future<Result<GeoFix?>> currentFix({
    Duration timeout = AppConstants.locationTimeout,
  }) async {
    calls?.add('currentFix');
    if (!_gpsEnabled()) {
      return const Success<GeoFix?>(null);
    }
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    final Failure? fail = failure;
    if (fail != null) {
      return FailureResult<GeoFix?>(fail);
    }
    return Success<GeoFix?>(fix);
  }
}
