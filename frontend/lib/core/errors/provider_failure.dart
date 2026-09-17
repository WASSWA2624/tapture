part of 'failure.dart';

/// A service or provider this screen uses failed unexpectedly.
final class ProviderFailure extends Failure {
  /// Creates a provider failure.
  const ProviderFailure({
    this.message = 'A service this screen uses failed.',
    this.recoveryAction = 'Try again. Nothing already captured was lost.',
  });

  @override
  final String message;

  @override
  final String recoveryAction;
}
