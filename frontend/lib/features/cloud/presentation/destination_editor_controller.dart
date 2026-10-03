import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/cloud_oauth_redirect.dart';
import 'package:tapture/core/cloud/cloud_settings.dart';
import 'package:tapture/core/cloud/native_google_authorization.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
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
import 'destination_list_controller.dart' show destinationSignsIn;

/// Adds or changes one destination (task 021 step 2).
///
/// A configuration is saved only after its probe upload succeeds. A new
/// sign-in goes to secure storage under a fresh credential reference; the
/// old one is forgotten only once the new one has been saved, and a failed
/// check forgets the new one, so neither leaves an orphan credential.
///
/// The state is why the last save was refused, or null.
final class DestinationEditorController extends Notifier<String?> {
  LocalizedMessage? _errorMessage;
  final CancellationToken _cancel = CancellationToken();

  /// Semantic reason retained beside the compatible English state string.
  LocalizedMessage? get errorMessage => _errorMessage;

  @override
  String? build() {
    ref.onDispose(_cancel.cancel);
    return null;
  }

  /// Checks [draft], then saves it. Completes with the saved destination,
  /// or null with the reason in [state].
  Future<Destination?> save(DestinationDraft draft) async {
    _errorMessage = null;
    state = null;
    final Destination intended =
        draft.existing ??
        (
          id: '',
          kind: draft.kind,
          label: draft.label,
          folder: draft.folder,
          credentialRef: '',
          lastCheck: null,
        );
    final Result<void> permitted = ref
        .read(cloudOperationPolicyProvider)
        .check(intended, upload: false);
    if (permitted case FailureResult<void>(:final Failure failure)) {
      return _refuse(failure);
    }
    final DestinationRepositoryImpl store = ref.read(
      destinationRepositoryProvider,
    );
    final Map<DestinationKind, CloudDestination> backends = await ref.read(
      cloudBackendsProvider.future,
    );
    if (!ref.mounted) {
      return null;
    }
    final Result<CloudDestination> resolved = resolveDestination(
      draft.kind,
      backends,
    );
    if (resolved is FailureResult<CloudDestination>) {
      return _refuse(resolved.failure);
    }
    final Destination? existing = draft.existing;
    final String? previous = existing?.credentialRef;
    final bool freshSignIn =
        draft.connection != null ||
        (destinationSignsIn(draft.kind) && (existing == null || draft.signIn));
    final String reference = previous == null || freshSignIn
        ? store.ids.newId()
        : previous;
    final String? connection = draft.connection;
    if (connection != null) {
      final Result<void> put = await store.secrets.put(reference, connection);
      if (put is FailureResult<void>) {
        return _refuse(put.failure);
      }
    } else if (freshSignIn) {
      final Result<void> signedIn = await ref
          .read(cloudOperationPolicyProvider)
          .run<void>(
            intended,
            upload: false,
            cancel: _cancel,
            operation: (CancellationToken token) =>
                _signIn(draft.kind, reference, token),
          );
      if (signedIn is FailureResult<void>) {
        await store.secrets.forget(reference);
        return _refuse(signedIn.failure);
      }
    }
    if (!ref.mounted || _cancel.isCancelled) {
      if (reference != previous) {
        await store.secrets.forget(reference);
      }
      return null;
    }
    final Destination candidate = (
      id: existing?.id ?? store.ids.newId(),
      kind: draft.kind,
      label: draft.label.trim(),
      folder: draft.folder.trim(),
      credentialRef: reference,
      lastCheck: DestinationCheck(at: store.clock.nowUtc()).encode(),
    );
    final Result<void> checked = await (resolved as Success<CloudDestination>)
        .value
        .check(candidate);
    if (checked is FailureResult<void>) {
      if (reference != previous) {
        await store.secrets.forget(reference);
      }
      return _refuse(checked.failure);
    }
    if (!ref.mounted || _cancel.isCancelled) {
      if (reference != previous) {
        await store.secrets.forget(reference);
      }
      return null;
    }
    final Result<void> saved = await store.save(candidate);
    if (saved is FailureResult<void>) {
      if (reference != previous) {
        await store.secrets.forget(reference);
      }
      return _refuse(saved.failure);
    }
    if (previous != null && previous != reference) {
      await store.secrets.forget(previous);
    }
    return candidate;
  }

  /// Runs the provider's authorisation-code-with-PKCE sign-in and stores
  /// the tokens under [reference].
  Future<Result<void>> _signIn(
    DestinationKind kind,
    String reference,
    CancellationToken cancel,
  ) async {
    if (kind == DestinationKind.googleDrive &&
        NativeGoogleAuthorization.instance.configured) {
      return NativeGoogleAuthorization.instance.signIn(
        reference,
        ref.read(destinationRepositoryProvider).secrets,
        cancel: cancel,
      );
    }
    final CloudSignIn? signIn = ref.read(cloudSignInProvider);
    final String expected = ref.read(destinationRepositoryProvider).ids.newId();
    final CloudOauth? oauth = await ref.read(cloudOauthProvider(kind).future);
    if (signIn == null || oauth == null) {
      return FailureResult<void>(
        PermissionFailure(
          message: Copy.destinationSignInUnavailable,
          localizedMessage: Copy.messages.destinationSignInUnavailable,
          recoveryAction: Copy.tryAgain,
          localizedRecovery: Copy.messages.tryAgain,
        ),
      );
    }
    final ({Uri url, String verifier}) flow = oauth.client.start(
      oauth.provider,
      expected,
    );
    final Result<Uri> back = await signIn(flow.url, oauth.client.redirectUri);
    if (back is FailureResult<Uri>) {
      return FailureResult<void>(back.failure);
    }
    if (cancel.isCancelled || !ref.mounted) {
      return const FailureResult<void>(CancelledFailure());
    }
    final Uri callback = (back as Success<Uri>).value;
    final Map<String, List<String>> answer = callback.queryParametersAll;
    final List<String>? codes = answer['code'];
    final Uri? redirect = CloudOauthRedirect.fromCallback(
      oauth.client.redirectUri,
      callback,
    );
    if (redirect == null ||
        answer['state']?.length != 1 ||
        answer['state']?.single != expected ||
        codes?.length != 1 ||
        codes!.single.isEmpty ||
        answer['error'] != null) {
      return FailureResult<void>(
        PermissionFailure(
          message: Copy.destinationSignInMismatch,
          localizedMessage: Copy.messages.destinationSignInMismatch,
          recoveryAction: Copy.tryAgain,
          localizedRecovery: Copy.messages.tryAgain,
        ),
      );
    }
    return oauth.client.exchange(
      provider: oauth.provider,
      credentialRef: reference,
      code: codes.single,
      verifier: flow.verifier,
      redirect: redirect,
    );
  }

  Destination? _refuse(Failure failure) {
    if (ref.mounted) {
      _errorMessage = failure.explanation;
      state = failure.message;
    }
    return null;
  }
}

/// What the form collected. [connection] is the sign-in payload for secure
/// storage, or null to keep the saved one (or when the type has none).
/// [signIn] asks a provider destination being edited to sign in again.
typedef DestinationDraft = ({
  Destination? existing,
  DestinationKind kind,
  String label,
  String folder,
  String? connection,
  bool signIn,
});

/// The form's controller, alive while the form is open.
final NotifierProvider<DestinationEditorController, String?>
destinationEditorControllerProvider =
    NotifierProvider.autoDispose<DestinationEditorController, String?>(
      DestinationEditorController.new,
    );
