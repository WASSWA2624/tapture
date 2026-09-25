import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/permissions/permissions_service.dart';

part 'geo_fix.dart';

/// Time-boxed location fix. Features never call a geolocation plugin
/// (FE-STR-11). No permission is requested while GPS is off (FE-SEC-07).
abstract interface class LocationService {
  /// Platform stand-in that reports unavailable. [main] may override.
  factory LocationService({
    PermissionsService? permissions,
    bool Function()? gpsEnabled,
  }) {
    return _StubLocationService(
      permissions: permissions ?? PermissionsService(gpsEnabled: gpsEnabled),
      gpsEnabled: gpsEnabled ?? (() => false),
    );
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

final class _StubLocationService implements LocationService {
  _StubLocationService({required this._permissions, required this._gpsEnabled});

  final PermissionsService _permissions;
  final bool Function() _gpsEnabled;

  @override
  Future<Result<GeoFix?>> currentFix({
    Duration timeout = AppConstants.locationTimeout,
  }) async {
    if (!_gpsEnabled()) {
      return const Success<GeoFix?>(null);
    }
    final Result<PermissionState> granted = await _permissions.request(
      AppPermission.location,
    );
    return granted.fold((Failure failure) => FailureResult<GeoFix?>(failure), (
      PermissionState state,
    ) async {
      if (state != PermissionState.granted) {
        return const Success<GeoFix?>(null);
      }
      // No geolocator package on the allowlist; capture proceeds without
      // coordinates rather than blocking (task 012).
      return const Success<GeoFix?>(null);
    });
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
