part of 'failure.dart';

/// A service or provider this screen uses failed unexpectedly.
final class ProviderFailure extends Failure {
  /// Creates a provider failure.
  const ProviderFailure({
    String? message,
    String? recoveryAction,
    LocalizedMessage? localizedMessage,
    LocalizedMessage? localizedRecovery,
    this.kind = ProviderFailureKind.unknown,
  }) : _message = message,
       _recoveryAction = recoveryAction,
       super(
         localizedMessage:
             localizedMessage ??
             (message == null
                 ? const LocalizedMessage(
                     key: 'failureProviderMessage',
                     fallback: "A service this screen uses failed.",
                   )
                 : null),
         localizedRecovery:
             localizedRecovery ??
             (recoveryAction == null
                 ? const LocalizedMessage(
                     key: 'failureProviderRecovery',
                     fallback: "Try again. Nothing already captured was lost.",
                   )
                 : null),
       );

  final String? _message;
  final String? _recoveryAction;

  @override
  String get message => _message ?? localizedMessage!.fallback;

  @override
  String get recoveryAction => _recoveryAction ?? localizedRecovery!.fallback;

  /// The provider failure category when the service supplied one.
  final ProviderFailureKind kind;
}
