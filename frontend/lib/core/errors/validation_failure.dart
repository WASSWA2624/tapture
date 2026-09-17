part of 'failure.dart';

/// A value the operator entered is not valid.
final class ValidationFailure extends Failure {
  /// Creates a validation failure.
  const ValidationFailure({
    this.message = 'That value is not valid.',
    this.recoveryAction = 'Correct the highlighted field and save again.',
  });

  @override
  final String message;

  @override
  final String recoveryAction;
}
