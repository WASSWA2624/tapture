import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/location/location_service.dart';

void main() {
  late GeolocatorPlatform original;
  late _Platform platform;
  setUp(() {
    original = GeolocatorPlatform.instance;
    platform = _Platform();
    GeolocatorPlatform.instance = platform;
  });
  tearDown(() => GeolocatorPlatform.instance = original);

  test('disabled GPS makes no platform or permission calls', () async {
    final Result<GeoFix?> result = await LocationService().currentFix();
    expect((result as Success<GeoFix?>).value, isNull);
    expect(platform.calls, isEmpty);
  });

  test('platform fix preserves coordinates, accuracy and timeout', () async {
    final Result<GeoFix?> result = await LocationService(
      gpsEnabled: () => true,
    ).currentFix(timeout: const Duration(seconds: 2));
    final GeoFix fix = (result as Success<GeoFix?>).value!;
    expect(fix.latitude, 0.34);
    expect(fix.longitude, 32.58);
    expect(fix.accuracyMetres, 7);
    expect(fix.capturedAt.isUtc, isTrue);
    expect(platform.settings?.timeLimit, const Duration(seconds: 2));
    expect(platform.calls, <String>['enabled', 'check', 'request', 'fix']);
  });

  test('permission refusal and timeout leave capture without a fix', () async {
    platform.permission = LocationPermission.deniedForever;
    final LocationService location = LocationService(gpsEnabled: () => true);
    expect(((await location.currentFix()) as Success<GeoFix?>).value, isNull);
    expect(platform.calls, isNot(contains('fix')));
    platform.permission = LocationPermission.always;
    platform.timeout = true;
    expect(((await location.currentFix()) as Success<GeoFix?>).value, isNull);
  });

  test(
    'switching GPS off while permission is pending prevents location read',
    () async {
      bool enabled = true;
      platform.onRequest = () => enabled = false;
      final Result<GeoFix?> result = await LocationService(
        gpsEnabled: () => enabled,
      ).currentFix();
      expect((result as Success<GeoFix?>).value, isNull);
      expect(platform.calls, isNot(contains('fix')));
    },
  );
}

class _Platform extends GeolocatorPlatform {
  final List<String> calls = <String>[];
  LocationPermission permission = LocationPermission.denied;
  LocationSettings? settings;
  void Function()? onRequest;
  bool timeout = false;

  @override
  Future<bool> isLocationServiceEnabled() async {
    calls.add('enabled');
    return true;
  }

  @override
  Future<LocationPermission> checkPermission() async {
    calls.add('check');
    return permission;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    calls.add('request');
    onRequest?.call();
    return LocationPermission.whileInUse;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    calls.add('fix');
    settings = locationSettings;
    if (timeout) throw TimeoutException('test deadline');
    return Position(
      latitude: 0.34,
      longitude: 32.58,
      timestamp: DateTime.utc(2026, 9, 28),
      accuracy: 7,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}
