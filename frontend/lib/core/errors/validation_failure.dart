part of 'failure.dart';

/// A value the operator entered is not valid.
final class ValidationFailure extends Failure {
  /// Creates a validation failure.
  const ValidationFailure({
    String? message,
    String? recoveryAction,
    LocalizedMessage? localizedMessage,
    LocalizedMessage? localizedRecovery,
  }) : _message = message,
       _recoveryAction = recoveryAction,
       super(
         localizedMessage:
             localizedMessage ??
             (message == null
                 ? const LocalizedMessage(
                     key: 'failureValidationMessage',
                     fallback: "That value is not valid.",
                   )
                 : null),
         localizedRecovery:
             localizedRecovery ??
             (recoveryAction == null
                 ? const LocalizedMessage(
                     key: 'failureValidationRecovery',
                     fallback: "Correct the highlighted field and save again.",
                   )
                 : null),
       );

  final String? _message;
  final String? _recoveryAction;

  @override
  String get message => _message ?? localizedMessage!.fallback;

  @override
  String get recoveryAction => _recoveryAction ?? localizedRecovery!.fallback;
}
