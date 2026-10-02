import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'cloud_destination.dart';
import 'cloud_operation_policy.dart';
import 'destination_secret_lease.dart';
import 'destination_secrets.dart';
import 'native_google_authorization.dart';
import 'worker_cloud_destination_stub.dart'
    if (dart.library.io) 'worker_cloud_destination_io.dart'
    as worker;

/// A backend whose transfers run on a worker isolate through `runIsolate`
/// (task 021 step 6, FE-PERF-02), so reading, hashing and sending a large
/// archive never holds the interface thread.
///
/// [check] is a small probe and runs here. [send] reads the destination's
/// credential from secure storage for this call only, rebuilds the backend
/// in the worker, streams byte progress back, forwards a cancel so the
/// backend can clean up, and writes any refreshed token back to [secrets].
final class WorkerCloudDestination implements CloudDestination {
  /// Creates the wrapper. [build] makes the backend here and in the worker.
  WorkerCloudDestination({
    required this.build,
    required this.secrets,
    this.policy = const CloudOperationPolicy.unrestricted(),
  }) : _here = build(secrets);

  /// Builds the backend from a set of credentials.
  final CloudBackendBuilder build;

  /// Secure storage for credentials.
  final DestinationSecrets secrets;

  /// Live permissions bound by the composition root.
  final CloudOperationPolicy policy;

  final CloudDestination _here;
  static final Map<String, Future<void>> _transfers = <String, Future<void>>{};

  @override
  DestinationKind get kind => _here.kind;

  @override
  Future<Result<void>> check(Destination destination) {
    return policy.run<void>(
      destination,
      upload: false,
      operation: (_) =>
          _locked(destination.credentialRef, () => _here.check(destination)),
    );
  }

  static Future<Result<T>> _locked<T>(
    String key,
    Future<Result<T>> Function() operation,
  ) async {
    final Future<void>? previous = _transfers[key];
    final Completer<void> release = Completer<void>();
    _transfers[key] = release.future;
    await previous;
    try {
      return await operation();
    } finally {
      release.complete();
      if (identical(_transfers[key], release.future)) {
        _transfers.remove(key);
      }
    }
  }

  @override
  Future<Result<Uri>> send(
    Destination destination,
    CloudBytes file, {
    required String remoteName,
    int offset = 0,
    void Function(int sent, int total)? onProgress,
    CancellationToken? cancel,
  }) async {
    if (cancel?.isCancelled ?? false) {
      return const FailureResult<Uri>(CancelledFailure());
    }
    final String ref = destination.credentialRef;
    final String sessionKey = sha256
        .convert(
          utf8.encode(
            jsonEncode(<Object>[
              destination.kind.name,
              destination.folder,
              remoteName,
            ]),
          ),
        )
        .toString();
    // Refresh-token rotation is shared by all objects in a destination.
    // Serialize by sign-in, including connection checks, not only filename.
    return policy.run<Uri>(
      destination,
      upload: true,
      cancel: cancel,
      operation: (CancellationToken token) => _locked(ref, () async {
        if (token.isCancelled) {
          return const FailureResult<Uri>(CancelledFailure());
        }
        final Result<DestinationSecretLease> taken = await secrets.lease(
          ref,
          sessionKey,
        );
        if (taken is FailureResult<DestinationSecretLease>) {
          return FailureResult<Uri>(taken.failure);
        }
        final DestinationSecretLease lease =
            (taken as Success<DestinationSecretLease>).value;
        final bool nativeGoogle =
            destination.kind == DestinationKind.googleDrive &&
            NativeGoogleAuthorization.isNative(lease);
        Future<Result<String>> renewNative(String? invalidToken) async {
          if (token.isCancelled) {
            return const FailureResult<String>(CancelledFailure());
          }
          final Result<String> renewed = await token.race<Result<String>>(
            NativeGoogleAuthorization.instance
                .access(lease, invalidToken: invalidToken)
                .then<Result<String>>((Result<String> value) => value)
                .timeout(
                  AppConstants.cloudUpload.requestTimeout,
                  onTimeout: () => FailureResult<String>(
                    PermissionFailure(
                      localizedMessage:
                          Copy.messages.failureGoogleDriveSignInCouldNotFinish,
                      localizedRecovery:
                          Copy.messages.failureSignInToThisDestinationAgain,
                    ),
                  ),
                ),
            onCancel: () => const FailureResult<String>(CancelledFailure()),
          );
          if (token.isCancelled) {
            return const FailureResult<String>(CancelledFailure());
          }
          if (renewed case Success<String>(:final String value)) {
            final Result<void> saved = await secrets.putLeased(
              lease,
              value: value,
            );
            if (saved case FailureResult<void>(:final Failure failure)) {
              return FailureResult<String>(failure);
            }
          }
          return renewed;
        }

        DestinationSecretLease sendingLease = lease;
        if (nativeGoogle) {
          final Result<String> current = await renewNative(null);
          if (current case FailureResult<String>(:final Failure failure)) {
            return FailureResult<Uri>(failure);
          }
          sendingLease = DestinationSecretLease(
            ref: lease.ref,
            generation: lease.generation,
            sessionKey: lease.sessionKey,
            access: (current as Success<String>).value,
            refresh: lease.refresh,
            session: lease.session,
          );
        }
        return worker.sendOnWorker(
          (
            build: build,
            destination: destination,
            file: file,
            remoteName: remoteName,
            offset: offset,
            lease: sendingLease,
          ),
          onProgress: onProgress,
          cancel: token,
          permit: () => policy.check(destination, upload: true),
          refreshNative: nativeGoogle
              ? (String invalid) => renewNative(invalid)
              : null,
          persist: (CloudSecretWrite write) async {
            return secrets.putLeased(
              lease,
              value: write.value,
              refresh: write.refresh,
              session: write.session,
            );
          },
        );
      }),
    );
  }
}

/// Makes one backend from [secrets]. A worker isolate calls it with the
/// credentials copied into it, so it captures only plain values and
/// top-level functions.
typedef CloudBackendBuilder =
    CloudDestination Function(DestinationSecrets secrets);

/// One send handed to the worker: the backend to build, what to send, and
/// the credential values the backend may read while it runs.
typedef CloudWorkerJob = ({
  CloudBackendBuilder build,
  Destination destination,
  CloudBytes file,
  String remoteName,
  int offset,
  DestinationSecretLease lease,
});

/// A credential the worker changed — a refreshed token — for the caller to
/// write back to secure storage. [refresh] names the refresh-token slot.
typedef CloudSecretWrite = ({
  bool refresh,
  bool session,
  String ref,
  String? value,
});
