import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

part 'geo_fix.dart';

/// Time-boxed location fix. Features never call a geolocation plugin
/// (FE-STR-11). No permission is requested while GPS is off (FE-SEC-07).
abstract interface class LocationService {
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
    if (!_gpsEnabled()) {
      return const Success<GeoFix?>(null);
    }
    try {
      if (!await Geolocator.isLocationServiceEnabled() || !_gpsEnabled()) {
        return const Success<GeoFix?>(null);
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && _gpsEnabled()) {
        permission = await Geolocator.requestPermission();
      }
      if (!_gpsEnabled() ||
          (permission != LocationPermission.whileInUse &&
              permission != LocationPermission.always)) {
        return const Success<GeoFix?>(null);
      }
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      if (!_gpsEnabled()) {
        return const Success<GeoFix?>(null);
      }
      return Success<GeoFix?>(
        GeoFix(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMetres: position.accuracy,
          capturedAt: position.timestamp.toUtc(),
        ),
      );
    } on TimeoutException {
      return const Success<GeoFix?>(null);
    } on UnsupportedError {
      return const Success<GeoFix?>(null);
    } on LocationServiceDisabledException {
      return const Success<GeoFix?>(null);
    } on PermissionDeniedException {
      return const FailureResult<GeoFix?>(PermissionFailure());
    } on Object catch (error) {
      return FailureResult<GeoFix?>(Failure.from(error));
    }
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
