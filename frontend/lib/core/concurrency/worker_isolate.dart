import 'dart:ui' show RootIsolateToken;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:tapture/core/errors/result.dart';

import 'cancellation_token.dart';
import 'worker_isolate_stub.dart'
    if (dart.library.io) 'worker_isolate_io.dart'
    as platform;
import 'worker_port.dart';

/// A long-lived worker isolate that keeps state between requests
/// (FE-PERF-02), for work that must not be rebuilt per job, such as a loaded
/// native model. One-shot jobs still go through `runIsolate`.
///
/// Every worker is released by [close] or by its own exit (FE-STATE-09).
abstract interface class WorkerIsolate {
  /// Starts [entry] with [argument] on a new isolate named [debugName] and
  /// waits until the entry calls [WorkerPort.serve]. An entry that has not
  /// served within [startTimeout] (default
  /// `AppConstants.speechEngine.workerStart`) is killed, and an entry that
  /// ends first fails too; both return a provider failure.
  ///
  /// [entry] must be a top-level or static function, and [argument] must be
  /// sendable between isolates. With a [platformToken] the worker can call
  /// platform channels. [answer] replies to [WorkerPort.ask]; a throw there
  /// becomes `Failure.from`. On the web this returns
  /// `ProviderFailure(kind: unavailable)`.
  static Future<Result<WorkerIsolate>> spawn<A>(
    Future<void> Function(WorkerPort port, A argument) entry,
    A argument, {
    required String debugName,
    Duration? startTimeout,
    RootIsolateToken? platformToken,
    Future<Result<Object?>> Function(Object? question)? answer,
  }) => platform.spawnWorker<A>(
    entry,
    argument,
    debugName: debugName,
    startTimeout: startTimeout,
    platformToken: platformToken,
    answer: answer,
  );

  /// Sends [payload] to the worker's handler and waits for its result. The
  /// worker serves requests one at a time, in arrival order.
  ///
  /// On [cancel] this calls [onCancel] synchronously, so the caller can stop
  /// native work, completes with `CancelledFailure` and drops the late reply.
  /// A worker that exits first fails the request with a provider failure, as
  /// does a closed worker or a reply that is not an [R].
  Future<Result<R>> request<R>(
    Object? payload, {
    CancellationToken? cancel,
    void Function()? onCancel,
  });

  /// Messages the worker sends outside any request ([WorkerPort.emit]). A
  /// broadcast stream that closes when the worker exits.
  Stream<Object?> get events;

  /// Stops accepting requests, fails pending ones with `CancelledFailure`
  /// and asks the worker to run its `onClose`. A worker still running after
  /// [grace] (default `AppConstants.speechEngine.workerCloseGrace`) is killed.
  /// Completes with [exited]. Safe to call more than once.
  Future<void> close({Duration? grace});

  /// Completes only when the isolate has actually ended. A kill cannot
  /// interrupt a native call, so callers that share native memory with the
  /// worker wait for this before freeing it.
  Future<void> get exited;

  /// Whether [request] still reaches the worker.
  bool get isOpen;
}

/// Workers started by [WorkerIsolate.spawn] that have not yet exited, so
/// tests can prove every worker was released. Always 0 on the web.
@visibleForTesting
int get debugLiveWorkers => platform.debugLiveWorkers;
