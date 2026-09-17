part of 'failure.dart';

/// The operator or a cancellation token stopped the action.
final class CancelledFailure extends Failure {
  /// Creates a cancelled failure.
  const CancelledFailure({
    this.message = 'The action was cancelled.',
    this.recoveryAction = 'Start the action again if you still need it.',
  });

  @override
  final String message;

  @override
  final String recoveryAction;
}
