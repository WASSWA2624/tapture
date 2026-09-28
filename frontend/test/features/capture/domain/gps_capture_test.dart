import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/location/location_service.dart';
import 'package:tapture/features/capture/domain/gps_capture.dart';

import '../../../support/fakes/fake_location_service.dart';
import '../../../support/matchers.dart';

final GeoFix _fix = GeoFix(
  latitude: 0.3476,
  longitude: 32.5825,
  accuracyMetres: 12,
  capturedAt: DateTime.utc(2026, 9, 28, 12),
);

void main() {
  group('with GPS off', () {
    test('no location call is made and the save gets no fix', () async {
      final List<String> calls = <String>[];

      final Result<GeoFix?> result = await GpsCapture.maybeFix(
        gpsEnabled: false,
        location: LocationService.fake(fix: _fix, calls: calls),
      );

      expect(valueOf(result), isNull);
      expect(calls, isEmpty);
    });

    test('a broken location service cannot fail or delay the save', () async {
      final RecordingLocationService location = RecordingLocationService(
        failure: const PermissionFailure(),
      );

      final Result<GeoFix?> result = await GpsCapture.maybeFix(
        gpsEnabled: false,
        location: location,
      );

      expect(valueOf(result), isNull);
      expect(location.calls, 0);
    });
  });

  group('with GPS on', () {
    test('the fix is returned with its accuracy', () async {
      final Result<GeoFix?> result = await GpsCapture.maybeFix(
        gpsEnabled: true,
        location: RecordingLocationService(fix: _fix),
      );

      final GeoFix? fix = valueOf(result);
      expect(fix?.latitude, 0.3476);
      expect(fix?.longitude, 32.5825);
      expect(fix?.accuracyMetres, 12);
    });

    test('the wait is time-boxed by the location timeout by default', () async {
      final RecordingLocationService location = RecordingLocationService(
        fix: _fix,
      );

      await GpsCapture.maybeFix(gpsEnabled: true, location: location);

      expect(location.timeouts, <Duration>[AppConstants.locationTimeout]);
    });

    test('a caller can shorten the time box', () async {
      final RecordingLocationService location = RecordingLocationService(
        fix: _fix,
      );

      await GpsCapture.maybeFix(
        gpsEnabled: true,
        location: location,
        timeout: const Duration(milliseconds: 500),
      );

      expect(location.timeouts, <Duration>[const Duration(milliseconds: 500)]);
    });

    test('an absent fix saves without coordinates', () async {
      final Result<GeoFix?> result = await GpsCapture.maybeFix(
        gpsEnabled: true,
        location: RecordingLocationService(),
      );

      expect(valueOf(result), isNull);
    });

    test('a location failure is reported rather than thrown', () async {
      final Result<GeoFix?> result = await GpsCapture.maybeFix(
        gpsEnabled: true,
        location: RecordingLocationService(failure: const PermissionFailure()),
      );

      expect(result, isFailure<GeoFix?, PermissionFailure>());
    });

    test('each capture asks for one fix only', () async {
      final RecordingLocationService location = RecordingLocationService(
        fix: _fix,
      );

      await GpsCapture.maybeFix(gpsEnabled: true, location: location);

      expect(location.calls, 1);
    });
  });
}
