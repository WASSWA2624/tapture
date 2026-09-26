part of 'failure.dart';

/// A service or provider this screen uses failed unexpectedly.
final class ProviderFailure extends Failure {
  /// Creates a provider failure.
  const ProviderFailure({
    this.message = 'A service this screen uses failed.',
    this.recoveryAction = 'Try again. Nothing already captured was lost.',
    this.kind = ProviderFailureKind.unknown,
  });

  @override
  final String message;

  @override
  final String recoveryAction;

  /// What went wrong, when the provider said. [ProviderFailureKind.unknown]
  /// otherwise.
  final ProviderFailureKind kind;
}
