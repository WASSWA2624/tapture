import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui' show RootIsolateToken;

import 'package:crypto/crypto.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/concurrency/worker_isolate.dart';
import 'package:tapture/core/concurrency/worker_port.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'cloud_destination.dart';
import 'cloud_file_range_io.dart';
import 'cloud_request_scope.dart';
import 'cloud_upload_context.dart';
import 'cloud_worker_secrets.dart';
import 'worker_cloud_destination.dart';

const String _debugName = 'cloud-upload';
const String _send = 'send';
const String _cancelPort = 'cancel-port';
const String _permit = 'permit';
const String _secret = 'secret';
const String _nativeToken = 'native-token';

/// How long a cancelled transfer may keep cleaning up (aborting the provider
/// session, clearing its checkpoint) before its worker is killed.
final Duration _cleanupGrace =
    AppConstants.cloudUpload.requestTimeout *
        AppConstants.cloudUpload.maxAttempts +
    AppConstants.cloudUpload.checkpointTimeout;

/// Runs the transfer on a worker. Secret writes are serialized and explicitly
/// acknowledged; the worker waits before sending the next provider chunk.
Future<Result<Uri>> sendOnWorker(
  CloudWorkerJob job, {
  void Function(int sent, int total)? onProgress,
  CancellationToken? cancel,
  required Future<Result<void>> Function(CloudSecretWrite write) persist,
  Result<void> Function()? permit,
  Future<Result<String>> Function(String invalidToken)? refreshNative,
  Duration? checkpointTimeout,
}) async {
  final _CloudParent parent = _CloudParent(
    cancel: cancel,
    persist: persist,
    permit: permit,
    refreshNative: refreshNative,
    checkpointTimeout:
        checkpointTimeout ?? AppConstants.cloudUpload.checkpointTimeout,
  );
  final Result<WorkerIsolate> spawned =
      await WorkerIsolate.spawn<CloudWorkerJob>(
        _work,
        job,
        debugName: _debugName,
        platformToken:
            (Platform.isAndroid || Platform.isIOS) &&
                job.destination.kind == DestinationKind.localFolder
            ? RootIsolateToken.instance
            : null,
        answer: parent.answer,
      );
  final WorkerIsolate worker;
  switch (spawned) {
    case FailureResult<WorkerIsolate>(:final Failure failure):
      return FailureResult<Uri>(failure);
    case Success<WorkerIsolate>(:final WorkerIsolate value):
      worker = value;
  }
  final StreamSubscription<Object?> progress = worker.events.listen((
    Object? event,
  ) {
    if (event case (final int sent, final int total)) {
      onProgress?.call(sent, total);
    }
  });
  try {
    // A send cancelled before it starts still runs, already stopped, so the
    // worker clears the resume checkpoint as a later cancel would.
    final bool cancelled = cancel?.isCancelled ?? false;
    if (cancelled) {
      parent.stop();
    }
    return await worker.request<Uri>(
      _send,
      cancel: cancelled ? null : cancel,
      onCancel: parent.stop,
    );
  } finally {
    // A cancelled transfer is still cleaning up; close waits for it.
    await worker.close(grace: _cleanupGrace);
    await progress.cancel();
    await parent.settled;
  }
}

/// The parent's answers to one worker's questions. The worker isolate
/// serialises them, so each secret write is durable before the next.
final class _CloudParent {
  _CloudParent({
    required this.cancel,
    required this.persist,
    required this.permit,
    required this.refreshNative,
    required this.checkpointTimeout,
  });

  final CancellationToken? cancel;
  final Future<Result<void>> Function(CloudSecretWrite write) persist;
  final Result<void> Function()? permit;
  final Future<Result<String>> Function(String invalidToken)? refreshNative;
  final Duration checkpointTimeout;
  SendPort? _cancels;
  bool _stopping = false;

  /// Completes when the latest answer has been given.
  Future<void> settled = Future<void>.value();

  /// Forwards a cancel to the worker's own token.
  void stop() {
    _stopping = true;
    _cancels?.send(null);
  }

  Future<Result<Object?>> answer(Object? question) {
    final Future<Result<Object?>> reply = Result.captureAsync<Object?>(
      () => _answer(question),
    );
    settled = reply;
    return reply;
  }

  Future<Object?> _answer(Object? question) async {
    switch (question) {
      case [_cancelPort, final SendPort port]:
        _cancels = port;
        return _stopping;
      case _permit:
        permit?.call().getOrThrow();
        return null;
      case [_nativeToken, final String invalidToken]:
        return _renew(invalidToken);
      case [_secret, final CloudSecretWrite write]:
        // Normalize covariant futures: a callback may return Future<Success>
        // while the timeout must also be able to return FailureResult.
        final Result<void> saved = await persist(write)
            .then<Result<void>>((Result<void> value) => value)
            .timeout(
              checkpointTimeout,
              onTimeout: () => FailureResult<void>(
                StorageFailure(
                  localizedMessage:
                      Copy.messages.failureTheUploadCheckpointCouldNotBeSaved,
                  localizedRecovery:
                      Copy.messages.failureCheckSecureStorageThenTryAgain,
                ),
              ),
            );
        saved.getOrThrow();
        return null;
    }
    throw const ProviderFailure();
  }

  Future<String> _renew(String invalidToken) async {
    if (_stopping) throw const CancelledFailure();
    permit?.call().getOrThrow();
    final Future<Result<String>> Function(String invalidToken)? refresh =
        refreshNative;
    if (refresh == null) {
      throw PermissionFailure(
        localizedMessage: Copy.messages.failureThisDestinationNeedsAFreshSignIn,
      );
    }
    final Future<Result<String>> renewal = refresh(invalidToken)
        .then<Result<String>>((Result<String> result) => result)
        .timeout(AppConstants.cloudUpload.requestTimeout);
    final CancellationToken? token = cancel;
    final Result<String> renewed = token == null
        ? await renewal
        : await token.race<Result<String>>(
            renewal,
            onCancel: () => const FailureResult<String>(CancelledFailure()),
          );
    return renewed.getOrThrow();
  }
}

Future<void> _work(WorkerPort port, CloudWorkerJob job) => port.serve(
  handle: (Object? payload) async => payload == _send
      ? await CloudUploadContext.runWorker(() => _transfer(port, job))
      : const FailureResult<Object?>(ProviderFailure()),
  onClose: () async {},
);

Future<Result<Uri>> _transfer(WorkerPort port, CloudWorkerJob job) async {
  final CancellationToken token = CancellationToken();
  final ReceivePort cancels = ReceivePort();
  cancels.listen((Object? _) => token.cancel());
  Future<void> authorize() async =>
      (await port.ask<Object?>(_permit)).getOrThrow();

  final CloudWorkerSecrets secrets = CloudWorkerSecrets(
    job,
    (CloudSecretWrite write) async =>
        (await port.ask<Object?>(<Object?>[_secret, write])).map<void>((_) {}),
  );
  try {
    final Result<Uri> result = await Result.captureAsync<Uri>(() async {
      if ((await port.ask<bool>(<Object?>[
        _cancelPort,
        cancels.sendPort,
      ])).getOrThrow()) {
        token.cancel();
      }
      await authorize();
      final bool needsSession =
          job.destination.kind != DestinationKind.webdav &&
          job.destination.kind != DestinationKind.localFolder;
      final Digest? hash = needsSession
          ? await sha256.bind(_source(job.file, token)).first
          : null;
      final CloudUploadContext context = CloudUploadContext(
        fingerprint: '${job.file.length}:$hash',
        readSession: secrets.readSession,
        writeSession: secrets.writeSession,
        refreshNativeAccess: (String invalidToken) async {
          await authorize();
          final String access = (await port.ask<String>(<Object?>[
            _nativeToken,
            invalidToken,
          ])).getOrThrow();
          secrets.acknowledgedAccess(access);
          return access;
        },
      );
      return context.run(
        () => CloudRequestScope(cancel: token, authorize: authorize).run(
          () async {
            final CloudDestination backend = job.build(secrets);
            return (await backend.send(
              job.destination,
              job.file,
              remoteName: job.remoteName,
              offset: job.offset,
              cancel: token,
              onProgress: (int sent, int total) => port.emit((sent, total)),
            )).getOrThrow();
          },
        ),
      );
    });
    if (job.lease.generation.isNotEmpty &&
        (job.destination.kind != DestinationKind.webdav &&
            job.destination.kind != DestinationKind.localFolder) &&
        (result is Success<Uri> || token.isCancelled)) {
      // Provider cleanup already ran. Clear even if the provider forgot to;
      // sign-in removal may reject this write, which is already cleared there.
      try {
        await secrets.writeSession(null);
      } on Failure {
        if (result is Success<Uri>) {
          rethrow;
        }
      }
    }
    return token.isCancelled
        ? const FailureResult<Uri>(CancelledFailure())
        : result;
  } on Object catch (error) {
    return token.isCancelled
        ? const FailureResult<Uri>(CancelledFailure())
        : FailureResult<Uri>(Failure.from(error));
  } finally {
    try {
      closeCloudFileRanges();
    } finally {
      cancels.close();
    }
  }
}

Stream<List<int>> _source(CloudBytes file, CancellationToken token) async* {
  for (var offset = 0; offset < file.length;) {
    if (token.isCancelled) {
      throw const CancelledFailure();
    }
    final int size = min(
      AppConstants.cloudUpload.partBytes,
      file.length - offset,
    );
    final List<int> bytes = await file.read(offset, size);
    if (bytes.length != size) {
      throw cloudReadFailure;
    }
    yield bytes;
    offset += size;
  }
  if (token.isCancelled) {
    throw const CancelledFailure();
  }
}
