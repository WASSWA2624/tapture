part of 'failure.dart';

/// The network is missing or a remote call did not finish.
final class NetworkFailure extends Failure {
  /// Creates a network failure.
  const NetworkFailure({
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
                     key: 'failureNetworkMessage',
                     fallback:
                         "The network is not available. Work on this device is saved.",
                   )
                 : null),
         localizedRecovery:
             localizedRecovery ??
             (recoveryAction == null
                 ? const LocalizedMessage(
                     key: 'failureNetworkRecovery',
                     fallback:
                         "Keep capturing. Processing will retry when you are back online.",
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
