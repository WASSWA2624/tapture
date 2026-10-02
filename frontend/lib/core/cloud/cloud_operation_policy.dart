import 'dart:async';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'cloud_destination.dart';
import 'cloud_request_scope.dart';

/// Live outbound permissions for a user-selected destination.
final class CloudOperationPolicy {
  /// Uses current preferences and connectivity for each check.
  const CloudOperationPolicy({
    required this._offline,
    required this._allowsUpload,
    this.changes = const Stream<void>.empty(),
  });

  /// Stand-in for isolated backend tests. Production binds live permissions.
  const CloudOperationPolicy.unrestricted()
    : _offline = _online,
      _allowsUpload = _allowed,
      changes = const Stream<void>.empty();

  final bool Function() _offline;
  final bool Function(String) _allowsUpload;

  /// Committed preference or connectivity changes, including active uploads.
  final Stream<void> changes;

  /// Local copies work offline. Explicit probes do not enable content uploads.
  Result<void> check(Destination destination, {required bool upload}) {
    if (destination.kind == DestinationKind.localFolder) {
      return const Success<void>(null);
    }
    if (_offline()) {
      return FailureResult<void>(
        NetworkFailure(
          localizedMessage: Copy.messages.failureUploadsArePausedWhileTheAppIs,
          localizedRecovery:
              Copy.messages.failureGoOnlineThenConfirmTheUploadAgain,
        ),
      );
    }
    if (upload && !_allowsUpload(destination.id)) {
      return FailureResult<void>(
        PermissionFailure(
          localizedMessage:
              Copy.messages.failureUploadsToThisDestinationAreTurnedOff,
          localizedRecovery:
              Copy.messages.failureEnableTheDestinationOnThePrivacyPage,
        ),
      );
    }
    return const Success<void>(null);
  }

  /// Rechecks before every request and stops the active transport on revocation.
  Future<Result<T>> run<T>(
    Destination destination, {
    required bool upload,
    CancellationToken? cancel,
    required Future<Result<T>> Function(CancellationToken token) operation,
  }) async {
    final Result<void> permitted = check(destination, upload: upload);
    if (permitted case FailureResult<void>(:final Failure failure)) {
      return FailureResult<T>(failure);
    }
    final CancellationToken token = CancellationToken();
    final void Function()? detach = cancel?.register(token.cancel);
    final StreamSubscription<void> watched = changes.listen((_) {
      if (check(destination, upload: upload) is FailureResult<void>) {
        token.cancel();
      }
    });
    try {
      return await CloudRequestScope(
        cancel: token,
        authorize: () => check(destination, upload: upload).getOrThrow(),
      ).run(
        () => Result.captureAsync<T>(
          () async => (await operation(token)).getOrThrow(),
        ),
      );
    } finally {
      detach?.call();
      await watched.cancel();
    }
  }

  static bool _online() => false;
  static bool _allowed(String _) => true;
}
