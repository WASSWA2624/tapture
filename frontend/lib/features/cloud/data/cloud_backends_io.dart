import 'dart:io';

import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/cloud_oauth_redirect.dart';
import 'package:tapture/core/cloud/cloud_operation_policy.dart';
import 'package:tapture/core/cloud/cloud_settings.dart';
import 'package:tapture/core/cloud/cloud_transport_io.dart';
import 'package:tapture/core/cloud/cloud_upload_context.dart';
import 'package:tapture/core/cloud/destination_secret_lease.dart';
import 'package:tapture/core/cloud/destination_secrets.dart';
import 'package:tapture/core/cloud/dropbox_destination.dart';
import 'package:tapture/core/cloud/google_drive_destination.dart';
import 'package:tapture/core/cloud/local_destination.dart';
import 'package:tapture/core/cloud/native_google_authorization.dart';
import 'package:tapture/core/cloud/oauth_destination_client.dart';
import 'package:tapture/core/cloud/onedrive_destination.dart';
import 'package:tapture/core/cloud/s3_destination.dart';
import 'package:tapture/core/cloud/scoped_folder_destination.dart';
import 'package:tapture/core/cloud/webdav_destination.dart';
import 'package:tapture/core/cloud/worker_cloud_destination.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// Scheme registered in the Android manifest and the Apple URL types.
const String _scheme = 'tapture';

/// The six backends, resolved by kind. Every send runs on a worker isolate;
/// credentials are read from secure storage on each call.
Future<Map<DestinationKind, CloudDestination>> openCloudBackends(
  DestinationSecrets secrets, {
  required CloudSettings settings,
  CloudOperationPolicy policy = const CloudOperationPolicy.unrestricted(),
}) {
  return Future<Map<DestinationKind, CloudDestination>>.value(
    <DestinationKind, CloudDestination>{
      for (final DestinationKind kind in DestinationKind.values)
        kind: WorkerCloudDestination(
          build: _builder(kind, settings),
          secrets: secrets,
          policy: policy,
        ),
    },
  );
}

/// The authorisation client for [kind], or null when [kind] is not a
/// consumer provider or this build has no client id for it.
CloudOauth? openCloudOauth(
  DestinationKind kind,
  DestinationSecrets secrets, {
  required CloudSettings settings,
  CloudSend? transport,
  Map<DestinationKind, String>? redirects,
}) {
  final OauthProvider? provider = _oauthProvider(kind);
  final String clientId = settings.clientIds[kind] ?? '';
  final bool desktop =
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  final Uri? redirect = desktop
      ? CloudOauthRedirect.parse(kind, (redirects ?? cloudRedirectUris)[kind])
      : null;
  // Google's current Android/iOS flow requires its native identity integration
  // and provider-specific callbacks; the shared tapture callback is unsupported.
  if (provider == null ||
      clientId.isEmpty ||
      (desktop && redirect == null) ||
      (kind == DestinationKind.googleDrive &&
          (Platform.isAndroid || Platform.isIOS))) {
    return null;
  }
  return (
    client: _oauthClient(
      kind,
      settings,
      secrets,
      transport: transport,
      redirect: redirect,
    ),
    provider: provider,
  );
}

/// The one registry entry per kind. A new backend is one more case here.
CloudDestination cloudBackend(
  DestinationKind kind,
  CloudSettings settings,
  DestinationSecrets secrets,
) {
  Future<String?> readSecret(String ref) => _text(secrets.read(ref));
  return switch (kind) {
    DestinationKind.s3 => S3Destination(
      transport: sendCloud,
      readSecret: readSecret,
    ),
    DestinationKind.webdav => WebdavDestination(
      transport: sendCloud,
      streamTransport: sendCloudStream,
      readSecret: readSecret,
    ),
    DestinationKind.localFolder => ScopedFolderDestination(
      fallback: LocalDestination(rootPath: settings.rootPath),
    ),
    DestinationKind.googleDrive => GoogleDriveDestination(
      client: _oauthClient(kind, settings, secrets),
    ),
    DestinationKind.oneDrive => OnedriveDestination(
      client: _oauthClient(kind, settings, secrets),
    ),
    DestinationKind.dropbox => DropboxDestination(
      client: _oauthClient(kind, settings, secrets),
    ),
  };
}

/// A builder that captures only [kind] and [settings], so the worker
/// isolate can receive it.
CloudBackendBuilder _builder(DestinationKind kind, CloudSettings settings) {
  return (DestinationSecrets secrets) => cloudBackend(kind, settings, secrets);
}

OauthProvider? _oauthProvider(DestinationKind kind) {
  return switch (kind) {
    DestinationKind.googleDrive => GoogleDriveDestination.oauth,
    DestinationKind.oneDrive => OnedriveDestination.oauth,
    DestinationKind.dropbox => DropboxDestination.oauth,
    DestinationKind.s3 ||
    DestinationKind.webdav ||
    DestinationKind.localFolder => null,
  };
}

OauthDestinationClient _oauthClient(
  DestinationKind kind,
  CloudSettings settings,
  DestinationSecrets secrets, {
  CloudSend? transport,
  Uri? redirect,
}) {
  DestinationSecretLease? refreshLease;
  final bool worker = CloudUploadContext.isWorker;
  Future<String?> readAccess(String ref) async {
    if (worker) {
      return _text(secrets.read(ref));
    }
    refreshLease = (await secrets.lease(ref, 'oauth-token')).getOrThrow();
    if (kind == DestinationKind.googleDrive &&
        NativeGoogleAuthorization.isNative(refreshLease!)) {
      final String access = (await NativeGoogleAuthorization.instance.access(
        refreshLease!,
      )).getOrThrow();
      (await secrets.putLeased(refreshLease!, value: access)).getOrThrow();
      return access;
    }
    return refreshLease!.access;
  }

  Future<void> refreshed(
    String ref,
    String token, {
    bool refresh = false,
  }) async {
    if (worker) {
      (await (refresh
              ? secrets.putRefresh(ref, token)
              : secrets.put(ref, token)))
          .getOrThrow();
      return;
    }
    final DestinationSecretLease? lease = refreshLease;
    if (lease == null || lease.ref != ref) {
      throw PermissionFailure(
        message: 'This destination sign-in changed.',
        localizedMessage: Copy.messages.cloudSignInChanged,
        recoveryAction: 'Sign in again.',
        localizedRecovery: Copy.messages.cloudSignInAgain,
      );
    }
    (await secrets.putLeased(
      lease,
      value: token,
      refresh: refresh,
    )).getOrThrow();
  }

  return OauthDestinationClient(
    uploadFingerprint: CloudUploadContext.current?.fingerprint,
    readUploadSession: CloudUploadContext.current?.readSession,
    writeUploadSession: CloudUploadContext.current?.writeSession,
    send: transport ?? sendCloud,
    scheme: _scheme,
    redirect: redirect,
    clientId: settings.clientIds[kind] ?? '',
    refreshAccess:
        kind == DestinationKind.googleDrive &&
            (Platform.isAndroid || Platform.isIOS)
        ? (String ref, String invalidToken) =>
              Result.captureAsync<String>(() async {
                if (worker) {
                  final renew = CloudUploadContext.current?.refreshNativeAccess;
                  if (renew == null) {
                    throw PermissionFailure(
                      message: 'This Google Drive sign-in needs renewal.',
                      localizedMessage: Copy.messages.cloudGoogleSignInRenewal,
                    );
                  }
                  return renew(invalidToken);
                }
                final DestinationSecretLease lease =
                    refreshLease ??
                    (await secrets.lease(ref, 'oauth-token')).getOrThrow();
                final String access =
                    (await NativeGoogleAuthorization.instance.access(
                      lease,
                      invalidToken: invalidToken,
                    )).getOrThrow();
                (await secrets.putLeased(lease, value: access)).getOrThrow();
                return access;
              })
        : null,
    readAccess: readAccess,
    writeRefreshedAccess: (String ref, String token) => refreshed(ref, token),
    writeRefreshedRefresh: (String ref, String token) =>
        refreshed(ref, token, refresh: true),
    writeAccess: (String ref, String token) async {
      (await secrets.put(ref, token)).getOrThrow();
    },
    readRefresh: (String ref) async => !worker && refreshLease?.ref == ref
        ? refreshLease?.refresh
        : _text(secrets.readRefresh(ref)),
    writeRefresh: (String ref, String token) async {
      (await secrets.putRefresh(ref, token)).getOrThrow();
    },
  );
}

Future<String?> _text(Future<Result<String?>> result) async {
  final Result<String?> value = await result;
  return value.fold((_) => null, (String? stored) => stored);
}
