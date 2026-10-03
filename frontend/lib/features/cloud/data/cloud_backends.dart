import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/cloud_operation_policy.dart';
import 'package:tapture/core/cloud/cloud_settings.dart';
import 'package:tapture/core/cloud/cloud_sign_in.dart';
import 'package:tapture/core/cloud/destination_secrets.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'cloud_backends_stub.dart'
    if (dart.library.io) 'cloud_backends_io.dart'
    as impl;
import 'cloud_operation_policy_provider.dart';
import 'destination_repository_impl.dart';

/// Builds the destination registry for this platform. Every send it makes
/// runs on a worker isolate.
Future<Map<DestinationKind, CloudDestination>> openCloudBackends(
  DestinationSecrets secrets, {
  required CloudSettings settings,
  CloudOperationPolicy policy = const CloudOperationPolicy.unrestricted(),
}) {
  return impl.openCloudBackends(secrets, settings: settings, policy: policy);
}

/// The authorisation client for [kind], or null when [kind] signs in with
/// no provider account or has no client id on this build.
CloudOauth? openCloudOauth(
  DestinationKind kind,
  DestinationSecrets secrets, {
  required CloudSettings settings,
  Map<DestinationKind, String>? redirects,
}) {
  return impl.openCloudOauth(
    kind,
    secrets,
    settings: settings,
    redirects: redirects,
  );
}

/// The storage root the app is configured with, and the client ids.
final FutureProvider<CloudSettings> cloudSettingsProvider =
    FutureProvider<CloudSettings>((Ref ref) async {
      final StorageRoot root = ref.watch(storageRootProvider);
      final String rootPath = (await root.resolve()).fold(
        (_) => '',
        (resolved) => resolved.path,
      );
      return (rootPath: rootPath, clientIds: cloudClientIds);
    });

/// Every registered backend, resolved by kind.
final FutureProvider<Map<DestinationKind, CloudDestination>>
cloudBackendsProvider = FutureProvider<Map<DestinationKind, CloudDestination>>((
  Ref ref,
) async {
  final CloudSettings settings = await ref.watch(cloudSettingsProvider.future);
  return openCloudBackends(
    ref.watch(destinationRepositoryProvider).secrets,
    settings: settings,
    policy: ref.watch(cloudOperationPolicyProvider),
  );
});

/// The authorisation client of one consumer provider, when configured.
final cloudOauthProvider = FutureProvider.family<CloudOauth?, DestinationKind>((
  Ref ref,
  DestinationKind kind,
) async {
  final CloudSettings settings = await ref.watch(cloudSettingsProvider.future);
  return openCloudOauth(
    kind,
    ref.watch(destinationRepositoryProvider).secrets,
    settings: settings,
  );
});

/// The platform browser sign-in for Google Drive, OneDrive and Dropbox.
///
/// Mobile uses its native callback; desktop requires configured loopback URIs.
final Provider<CloudSignIn?> cloudSignInProvider = Provider<CloudSignIn?>(
  (Ref _) => platformCloudSignIn(),
);
