import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/cloud_settings.dart';
import 'package:tapture/core/cloud/native_google_authorization.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../cloud.dart'
    show
        DestinationRepositoryImpl,
        cloudBackendsProvider,
        cloudOauthProvider,
        cloudOperationPolicyProvider,
        cloudSignInProvider,
        destinationRepositoryProvider;
import '../domain/destination_check.dart';
import 'destination_remove_action.dart';

/// Row actions on the destinations page: a fresh connection check whose
/// outcome is kept on the row, and removal with undo (task 021 step 2).
///
/// The state is the ids whose check is running.
final class DestinationListController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  /// Runs [destination]'s probe upload again and stores the outcome on its
  /// row, passed or with the plain-language reason it failed.
  Future<Result<void>> check(Destination destination) async {
    final Result<void> permitted = ref
        .read(cloudOperationPolicyProvider)
        .check(destination, upload: false);
    if (permitted is FailureResult<void>) return permitted;
    final DestinationRepositoryImpl store = ref.read(
      destinationRepositoryProvider,
    );
    state = <String>{...state, destination.id};
    final Result<void> checked = switch (await _backend(destination.kind)) {
      Success<CloudDestination>(:final CloudDestination value) =>
        await value.check(destination),
      FailureResult<CloudDestination>(:final Failure failure) =>
        FailureResult<void>(failure),
    };
    final DestinationCheck outcome = DestinationCheck(
      at: store.clock.nowUtc(),
      reason: checked.fold((Failure failure) => failure.message, (_) => null),
      localizedReason: checked.fold(
        (Failure failure) => failure.localizedMessage,
        (_) => null,
      ),
    );
    final Result<void> saved = await store.save((
      id: destination.id,
      kind: destination.kind,
      label: destination.label,
      folder: destination.folder,
      credentialRef: destination.credentialRef,
      lastCheck: outcome.encode(),
    ));
    if (ref.mounted) {
      state = <String>{
        for (final String id in state)
          if (id != destination.id) id,
      };
    }
    return saved.flatMap((_) => checked);
  }

  /// Removes [destination]'s row and sign-in together. Success carries the
  /// undo, which holds the sign-in only until it is used or dropped; a
  /// half-finished removal fails with the half that remains.
  Future<Result<DestinationUndo>> remove(Destination destination) async {
    final DestinationRepositoryImpl store = ref.read(
      destinationRepositoryProvider,
    );
    final String reference = destination.credentialRef;
    final String? access = (await store.secrets.read(
      reference,
    )).getOrElse(() => null);
    final String? refresh = (await store.secrets.readRefresh(
      reference,
    )).getOrElse(() => null);
    final Result<void> removed = await DestinationRemoveAction.apply(
      destinations: store,
      id: destination.id,
      confirmed: true,
    );
    return removed.map(
      (_) =>
          () => _restore(store, destination.id, reference, access, refresh),
    );
  }

  Future<Result<CloudDestination>> _backend(DestinationKind kind) async {
    final Map<DestinationKind, CloudDestination> backends = await ref.read(
      cloudBackendsProvider.future,
    );
    return resolveDestination(kind, backends);
  }

  static Future<Result<void>> _restore(
    DestinationRepositoryImpl store,
    String id,
    String reference,
    String? access,
    String? refresh,
  ) async {
    if (access != null) {
      final Result<void> put = await store.secrets.put(reference, access);
      if (put is FailureResult<void>) {
        return put;
      }
    }
    if (refresh != null) {
      final Result<void> put = await store.secrets.putRefresh(
        reference,
        refresh,
      );
      if (put is FailureResult<void>) {
        return put;
      }
    }
    return store.restore(id);
  }
}

/// Puts a removed destination back, with its sign-in.
typedef DestinationUndo = Future<Result<void>> Function();

/// The page's controller.
final NotifierProvider<DestinationListController, Set<String>>
destinationListControllerProvider =
    NotifierProvider.autoDispose<DestinationListController, Set<String>>(
      DestinationListController.new,
    );

/// Every saved destination, in label order.
final StreamProvider<List<Destination>> destinationListProvider =
    StreamProvider.autoDispose<List<Destination>>((Ref ref) {
      return ref.watch(destinationRepositoryProvider).watchAll();
    });

/// The destination types this device can add, most used first. Google
/// Drive, OneDrive and Dropbox are offered only with a browser sign-in and
/// a client id for that provider.
final FutureProvider<List<DestinationKind>> destinationKindsProvider =
    FutureProvider.autoDispose<List<DestinationKind>>((Ref ref) async {
      final Map<DestinationKind, CloudDestination> backends = await ref.watch(
        cloudBackendsProvider.future,
      );
      final CloudSignIn? signIn = ref.watch(cloudSignInProvider);
      final List<DestinationKind> kinds = <DestinationKind>[];
      for (final DestinationKind kind in destinationKindOrder) {
        if (!backends.containsKey(kind)) {
          continue;
        }
        if (destinationSignsIn(kind)) {
          if (kind == DestinationKind.googleDrive &&
              NativeGoogleAuthorization.instance.configured) {
            kinds.add(kind);
            continue;
          }
          final CloudOauth? oauth = await ref.watch(
            cloudOauthProvider(kind).future,
          );
          if (signIn == null || oauth == null) {
            continue;
          }
        }
        kinds.add(kind);
      }
      return kinds;
    });

/// The order the add form lists types in.
const List<DestinationKind> destinationKindOrder = <DestinationKind>[
  DestinationKind.localFolder,
  DestinationKind.s3,
  DestinationKind.webdav,
  DestinationKind.googleDrive,
  DestinationKind.oneDrive,
  DestinationKind.dropbox,
];

/// Whether [kind] signs in with the person's own provider account.
bool destinationSignsIn(DestinationKind kind) {
  return switch (kind) {
    DestinationKind.googleDrive ||
    DestinationKind.oneDrive ||
    DestinationKind.dropbox => true,
    DestinationKind.s3 ||
    DestinationKind.webdav ||
    DestinationKind.localFolder => false,
  };
}
