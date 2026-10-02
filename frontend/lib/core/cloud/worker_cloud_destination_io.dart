import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui' show RootIsolateToken;

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show BackgroundIsolateBinaryMessenger;
import 'package:tapture/core/concurrency/isolate_runner.dart';
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

const String _ready = 'ready';
const String _progress = 'progress';
const String _secret = 'secret';
const String _permit = 'permit';
const String _ack = 'ack';
const String _done = 'done';
const String _cancel = 'cancel';
const String _nativeToken = 'native-token';
const String _nativeAck = 'native-ack';

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
  final ReceivePort events = ReceivePort();
  final Completer<void> drained = Completer<void>();
  Future<void> pendingWrite = Future<void>.value();
  SendPort? commands;
  var stopping = cancel?.isCancelled ?? false;
  final StreamSubscription<Object?> listening = events.listen((Object? event) {
    if (event is! List<Object?> || event.isEmpty) {
      return;
    }
    final Object? kind = event.first;
    if (kind == _ready && event.length > 1 && event[1] is SendPort) {
      final SendPort port = event[1]! as SendPort;
      commands = port;
      if (stopping) {
        port.send(_cancel);
      }
    } else if (kind == _progress && event.length > 2) {
      onProgress?.call(event[1]! as int, event[2]! as int);
    } else if (kind == _permit && event.length > 1) {
      final int id = event[1]! as int;
      pendingWrite = pendingWrite.then((_) async {
        final Result<void> result = Result.capture<void>(
          () => permit?.call().getOrThrow(),
        );
        commands?.send(<Object?>[_ack, id, result]);
      });
    } else if (kind == _nativeToken && event.length > 2) {
      final int id = event[1]! as int;
      final String invalidToken = event[2]! as String;
      pendingWrite = pendingWrite.then((_) async {
        final Result<String> result = await Result.captureAsync<String>(
          () async {
            if (stopping) throw const CancelledFailure();
            permit?.call().getOrThrow();
            if (refreshNative == null) {
              throw PermissionFailure(
                localizedMessage:
                    Copy.messages.failureThisDestinationNeedsAFreshSignIn,
              );
            }
            final Future<Result<String>> renewal = refreshNative(invalidToken)
                .then<Result<String>>((Result<String> result) => result)
                .timeout(AppConstants.cloudUpload.requestTimeout);
            final Result<String> renewed = cancel == null
                ? await renewal
                : await cancel.race<Result<String>>(
                    renewal,
                    onCancel: () =>
                        const FailureResult<String>(CancelledFailure()),
                  );
            return renewed.getOrThrow();
          },
        );
        commands?.send(<Object?>[_nativeAck, id, result]);
      });
    } else if (kind == _secret && event.length > 2) {
      final int id = event[1]! as int;
      final CloudSecretWrite write = event[2]! as CloudSecretWrite;
      pendingWrite = pendingWrite.then((_) async {
        final Result<void> result;
        try {
          // Normalize covariant futures: a callback may return Future<Success>
          // while the timeout must also be able to return FailureResult.
          result = await persist(write)
              .then<Result<void>>((Result<void> saved) => saved)
              .timeout(
                checkpointTimeout ?? AppConstants.cloudUpload.checkpointTimeout,
                onTimeout: () => FailureResult<void>(
                  StorageFailure(
                    localizedMessage:
                        Copy.messages.failureTheUploadCheckpointCouldNotBeSaved,
                    localizedRecovery:
                        Copy.messages.failureCheckSecureStorageThenTryAgain,
                  ),
                ),
              );
        } on Object catch (error) {
          commands?.send(<Object?>[
            _ack,
            id,
            FailureResult<void>(Failure.from(error)),
          ]);
          return;
        }
        commands?.send(<Object?>[_ack, id, result]);
      });
    } else if (kind == _done && !drained.isCompleted) {
      drained.complete();
    }
  });
  final void Function()? detach = cancel?.register(() {
    stopping = true;
    commands?.send(_cancel);
  });
  try {
    final Result<Result<Uri>> ran =
        await runIsolate<_Work, Result<Uri>>(_work, (
          job: job,
          events: events.sendPort,
          platformToken:
              (Platform.isAndroid || Platform.isIOS) &&
                  job.destination.kind == DestinationKind.localFolder
              ? RootIsolateToken.instance
              : null,
        ));
    if (ran is Success<Result<Uri>>) {
      await drained.future;
    }
    await pendingWrite;
    return ran.fold(FailureResult<Uri>.new, (Result<Uri> sent) => sent);
  } finally {
    detach?.call();
    await listening.cancel();
    events.close();
  }
}

typedef _Work = ({
  CloudWorkerJob job,
  SendPort events,
  RootIsolateToken? platformToken,
});

Future<Result<Uri>> _work(_Work work) => CloudUploadContext.runWorker(() async {
  if (work.platformToken != null) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(work.platformToken!);
  }
  final SendPort events = work.events;
  final ReceivePort commands = ReceivePort();
  final CancellationToken token = CancellationToken();
  final Map<int, Completer<Result<void>>> acknowledgements = {};
  final Map<int, Completer<Result<String>>> nativeReplies = {};
  var nextWrite = 0;
  commands.listen((Object? command) {
    if (command == _cancel) {
      token.cancel();
    } else if (command is List<Object?> &&
        command.length > 2 &&
        command.first == _nativeAck) {
      nativeReplies.remove(command[1])?.complete(command[2]! as Result<String>);
    } else if (command is List<Object?> &&
        command.length > 2 &&
        command.first == _ack) {
      acknowledgements
          .remove(command[1])
          ?.complete(command[2]! as Result<void>);
    }
  });
  events.send(<Object?>[_ready, commands.sendPort]);
  final CloudWorkerJob job = work.job;
  Future<void> authorize() {
    final int id = nextWrite++;
    final Completer<Result<void>> reply = Completer<Result<void>>();
    acknowledgements[id] = reply;
    events.send(<Object?>[_permit, id]);
    return reply.future.then((Result<void> result) => result.getOrThrow());
  }

  final CloudWorkerSecrets secrets = CloudWorkerSecrets(job, (
    CloudSecretWrite write,
  ) {
    final int id = nextWrite++;
    final Completer<Result<void>> reply = Completer<Result<void>>();
    acknowledgements[id] = reply;
    events.send(<Object?>[_secret, id, write]);
    return reply.future;
  });
  try {
    final Result<Uri> result = await Result.captureAsync<Uri>(() async {
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
          final int id = nextWrite++;
          final Completer<Result<String>> reply = Completer<Result<String>>();
          nativeReplies[id] = reply;
          events.send(<Object?>[_nativeToken, id, invalidToken]);
          final String access = (await reply.future).getOrThrow();
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
              onProgress: (int sent, int total) {
                events.send(<Object?>[_progress, sent, total]);
              },
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
      events.send(const <Object?>[_done]);
      commands.close();
    }
  }
});

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
