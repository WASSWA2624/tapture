part of 'failure.dart';

/// A write or read on this device did not complete.
final class StorageFailure extends Failure {
  /// Creates a storage failure.
  const StorageFailure({
    this.message = 'The photo could not be saved on this device.',
    this.recoveryAction = 'Free up space or export a project, then try again.',
  });

  @override
  final String message;

  @override
  final String recoveryAction;
}
