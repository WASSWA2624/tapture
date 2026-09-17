import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'cancellation_token.dart';
import 'isolate_support_stub.dart'
    if (dart.library.io) 'isolate_support_io.dart'
    as support;

export 'cancellation_token.dart';

/// The off-thread runner every heavy job goes through (FE-PERF-02).
abstract final class IsolateRunner {
  /// Reports [fraction] (0–1) from inside a running isolate task.
  static void reportProgress(double fraction) {
    support.reportProgress(fraction);
  }
}

/// Isolates still running, so tests can prove cancel left none behind.
@visibleForTesting
int get debugLiveIsolates => support.debugLiveIsolates;

/// Runs [task] off the UI thread with optional progress and cancellation.
///
/// [task] must be a top-level or static function. Thrown errors become a
/// [Failure]. Cancel completes with [CancelledFailure] and always tears the
/// isolate down (FE-STATE-09, FE-CODE-07).
Future<Result<R>> runIsolate<M, R>(
  FutureOr<R> Function(M) task,
  M message, {
  void Function(double)? onProgress,
  CancellationToken? cancel,
}) async {
  if (cancel?.isCancelled ?? false) {
    return FailureResult<R>(const CancelledFailure());
  }
  return support.executeIsolate<M, R>(task, message, onProgress, cancel);
}
