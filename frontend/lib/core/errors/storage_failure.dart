part of 'failure.dart';

/// A write or read on this device did not complete.
final class StorageFailure extends Failure {
  /// Creates a storage failure.
  const StorageFailure({
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
                     key: 'failureStorageMessage',
                     fallback: "The photo could not be saved on this device.",
                   )
                 : null),
         localizedRecovery:
             localizedRecovery ??
             (recoveryAction == null
                 ? const LocalizedMessage(
                     key: 'failureStorageRecovery',
                     fallback:
                         "Free up space or export a project, then try again.",
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
