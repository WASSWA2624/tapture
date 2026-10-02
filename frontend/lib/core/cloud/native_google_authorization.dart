import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'destination_secret_lease.dart';
import 'destination_secrets.dart';
import 'google_access.dart';
import 'google_access_request.dart';
import 'native_google_client_stub.dart'
    if (dart.library.io) 'native_google_client_io.dart'
    as platform;

export 'google_access.dart';
export 'google_access_request.dart';

/// Google owns mobile token renewal; no app/backend refresh token is fabricated.
final class NativeGoogleAuthorization {
  /// Creates the production adapter, or a deterministic SDK seam for tests.
  NativeGoogleAuthorization({bool? configured, GoogleAccessRequest? request})
    : configured = configured ?? platform.googleConfigured,
      _request = request ?? platform.requestGoogleAccess;

  /// Only builds with explicit mobile client registration offer Google sign-in.
  final bool configured;
  final GoogleAccessRequest _request;
  static const String _bindingPrefix = 'google-native:';

  /// Shared parent-isolate SDK adapter. SDK initialization runs exactly once.
  static final NativeGoogleAuthorization instance = NativeGoogleAuthorization();

  /// Whether a saved destination belongs to the mobile SDK rather than PKCE.
  static bool isNative(DestinationSecretLease lease) =>
      lease.refresh?.startsWith(_bindingPrefix) == true;

  /// Signs in and stores only the access token and an opaque account binding.
  Future<Result<void>> signIn(
    String ref,
    DestinationSecrets secrets, {
    CancellationToken? cancel,
  }) => Result.captureAsync(() async {
    if (cancel?.isCancelled ?? false) {
      throw const CancelledFailure();
    }
    if (!configured) throw _unavailable;
    final Future<GoogleAccess> requested = _request(interactive: true);
    // The SDK has no public abort API. Abandon the wait on disposal while its
    // late response remains read-only and cannot publish a credential.
    final GoogleAccess authorized = await (cancel == null
        ? requested
        : cancel.race<GoogleAccess>(
            requested,
            onCancel: () => throw const CancelledFailure(),
          ));
    if (cancel?.isCancelled ?? false) {
      throw const CancelledFailure();
    }
    if (authorized.accountId.isEmpty || authorized.token.isEmpty) {
      throw _unavailable;
    }
    (await secrets.put(ref, authorized.token)).getOrThrow();
    if (cancel?.isCancelled ?? false) {
      throw const CancelledFailure();
    }
    // The refresh slot contains account metadata, never a provider refresh token.
    (await secrets.putRefresh(
      ref,
      '$_bindingPrefix${authorized.accountId}',
    )).getOrThrow();
    if (cancel?.isCancelled ?? false) {
      throw const CancelledFailure();
    }
  });

  /// Silently renews the bound account; revoked scopes require a fresh sign-in.
  Future<Result<String>> access(
    DestinationSecretLease lease, {
    String? invalidToken,
  }) => Result.captureAsync(() async {
    if (!configured || !isNative(lease)) throw _unavailable;
    final String accountId = lease.refresh!.substring(_bindingPrefix.length);
    final GoogleAccess authorized = await _request(
      interactive: false,
      accountId: accountId,
      invalidToken: invalidToken,
    );
    if (authorized.accountId != accountId || authorized.token.isEmpty) {
      throw _unavailable;
    }
    return authorized.token;
  });
}

final PermissionFailure _unavailable = PermissionFailure(
  localizedMessage: Copy.messages.failureThisGoogleDriveSignInIsNo,
  localizedRecovery: Copy.messages.failureSignInToThisDestinationAgain,
);
