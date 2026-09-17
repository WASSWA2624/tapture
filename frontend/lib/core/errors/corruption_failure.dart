part of 'failure.dart';

/// A file or row could not be read as the format it claims to be.
final class CorruptionFailure extends Failure {
  /// Creates a corruption failure.
  const CorruptionFailure({
    this.message = 'This file or row could not be read.',
    this.recoveryAction =
        'Keep the original. Export a copy and try opening it again.',
  });

  @override
  final String message;

  @override
  final String recoveryAction;
}
