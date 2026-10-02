part of 'failure.dart';

/// A file or row could not be read as the format it claims to be.
final class CorruptionFailure extends Failure {
  /// Creates a corruption failure.
  const CorruptionFailure({
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
                     key: 'failureCorruptionMessage',
                     fallback: "This file or row could not be read.",
                   )
                 : null),
         localizedRecovery:
             localizedRecovery ??
             (recoveryAction == null
                 ? const LocalizedMessage(
                     key: 'failureCorruptionRecovery',
                     fallback:
                         "Keep the original. Export a copy and try opening it again.",
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
