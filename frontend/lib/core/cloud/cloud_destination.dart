import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// One place a person can send a finished file (task 021).
///
/// Every backend implements this. Callers resolve one by [DestinationKind]
/// and never branch on the kind themselves.
abstract interface class CloudDestination {
  /// Which kind this backend serves.
  DestinationKind get kind;

  /// Writes and deletes a small probe so a bad configuration is refused
  /// before a real upload.
  Future<Result<void>> check(Destination destination);

  /// Sends [file] from [offset], reporting durable bytes through [onProgress].
  ///
  /// A cancelled [cancel] stops the transfer and leaves no partial object.
  Future<Result<Uri>> send(
    Destination destination,
    CloudBytes file, {
    required String remoteName,
    int offset = 0,
    void Function(int sent, int total)? onProgress,
    CancellationToken? cancel,
  });
}

/// The backends this app can send to. Adding one is a registry entry.
enum DestinationKind {
  /// An S3-compatible bucket.
  s3,

  /// A folder in the user's Google Drive.
  googleDrive,

  /// The app folder in the user's OneDrive.
  oneDrive,

  /// A folder in the user's Dropbox.
  dropbox,

  /// A WebDAV or generic HTTPS endpoint.
  webdav,

  /// A folder on this device or removable storage.
  localFolder,
}

/// A saved destination. [credentialRef] is the only secret handle; the
/// value itself lives in secure storage.
typedef Destination = ({
  String id,
  DestinationKind kind,
  String label,
  String folder,
  String credentialRef,
  String? lastCheck,
});

/// Bytes of a file, read in slices so an archive is never held whole.
typedef CloudBytes = ({
  int length,
  Future<List<int>> Function(int offset, int length) read,
});

/// One HTTP call a backend asks the transport to make. Redirects are not
/// followed; a 3xx comes back as [CloudReply.status].
typedef CloudCall = ({
  String method,
  Uri url,
  Map<String, String> headers,
  List<int> body,
});

/// The status, headers and body of one [CloudCall]. Header names are lower case.
typedef CloudReply = ({
  int status,
  Map<String, String> headers,
  List<int> body,
});

/// The transport every networked backend uses. Tests pass a fake.
typedef CloudSend = Future<CloudReply> Function(CloudCall call);

/// Reads one destination's credential. The value is not cached by the caller.
typedef SecretRead = Future<String?> Function(String credentialRef);

/// Resolves [kind] in [backends]. A missing backend is a [ValidationFailure],
/// never null.
Result<CloudDestination> resolveDestination(
  DestinationKind kind,
  Map<DestinationKind, CloudDestination> backends,
) {
  final CloudDestination? found = backends[kind];
  if (found == null) {
    return FailureResult<CloudDestination>(
      ValidationFailure(
        message: 'No upload destination is registered for ${kind.name}.',
        recoveryAction: 'Choose another destination.',
      ),
    );
  }
  return Success<CloudDestination>(found);
}

/// Maps an HTTP status onto a shared failure. 401, 403 and 404 are fatal.
/// Unreachable and 5xx are [NetworkFailure], which the runner may retry.
Failure cloudStatusFailure(int status) {
  if (status == 401 || status == 403) {
    return const PermissionFailure(
      message: 'The destination refused the sign-in.',
      recoveryAction: 'Check the key or sign in again.',
    );
  }
  if (status == 404) {
    return const ValidationFailure(
      message: 'That bucket or folder was not found.',
      recoveryAction: 'Check the name and try the connection again.',
    );
  }
  if (status == 429 || status >= 500) {
    return const NetworkFailure(
      message: 'The destination did not finish the upload.',
      recoveryAction: 'Try again.',
    );
  }
  if (status >= 300 && status < 400) {
    return const ValidationFailure(
      message: 'The server redirected the upload to another host.',
      recoveryAction: 'Check the address and try again.',
    );
  }
  return const ValidationFailure(
    message: 'The destination rejected the upload.',
    recoveryAction: 'Check the settings and try again.',
  );
}

/// Whether [failure] is worth retrying. Permission and validation are not.
bool cloudRetryable(Failure failure) => failure is NetworkFailure;

/// How long to wait before retry number [attempt], starting at zero.
Duration cloudBackoff(int attempt, {required int baseMs, required int capMs}) {
  var delay = baseMs;
  for (var step = 0; step < attempt; step++) {
    delay *= 2;
    if (delay >= capMs) {
      return AppConstants.millisecond * capMs;
    }
  }
  return AppConstants.millisecond * delay;
}
