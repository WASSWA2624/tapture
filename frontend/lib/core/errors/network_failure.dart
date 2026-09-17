part of 'failure.dart';

/// The network is missing or a remote call did not finish.
final class NetworkFailure extends Failure {
  /// Creates a network failure.
  const NetworkFailure({
    this.message =
        'The network is not available. Work on this device is saved.',
    this.recoveryAction =
        'Keep capturing. Processing will retry when you are back online.',
  });

  @override
  final String message;

  @override
  final String recoveryAction;
}
