import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/location/location_service.dart';

/// A [LocationService] that records the time box each fix was asked for,
/// so a test can prove the caller bounded the wait (FE-TEST-03).
///
/// `LocationService.fake` scripts a fix but does not expose the timeout it
/// was given; this one does.
final class RecordingLocationService implements LocationService {
  /// Creates the fake. [fix] is what a call returns; [failure] wins when
  /// set.
  RecordingLocationService({this.fix, this.failure});

  /// The fix every call returns.
  final GeoFix? fix;

  /// When set, every call fails with this.
  final Failure? failure;

  /// The time box of every call, in call order.
  final List<Duration> timeouts = <Duration>[];

  /// How many fixes were asked for.
  int get calls => timeouts.length;

  @override
  Future<Result<GeoFix?>> currentFix({
    Duration timeout = AppConstants.locationTimeout,
  }) async {
    timeouts.add(timeout);
    final Failure? refused = failure;
    if (refused != null) {
      return FailureResult<GeoFix?>(refused);
    }
    return Success<GeoFix?>(fix);
  }
}
