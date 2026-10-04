import 'package:tapture/core/errors/result.dart';

/// The worker's side of a `WorkerIsolate`: the entry passed to
/// `WorkerIsolate.spawn` receives one and serves requests on it.
abstract interface class WorkerPort {
  /// Tells the parent this worker is ready, then serves requests strictly one
  /// at a time, in arrival order, until the parent closes the worker.
  ///
  /// Each payload goes to [handle]; a thrown error becomes
  /// `FailureResult(Failure.from(error))`. On close, the request in progress
  /// finishes, queued requests are dropped (the parent has already failed
  /// them), and [onClose] runs before this completes. A reply that cannot
  /// cross the isolate boundary becomes a provider failure.
  Future<void> serve({
    required Future<Result<Object?>> Function(Object? payload) handle,
    required Future<void> Function() onClose,
  });

  /// Sends [event] to the parent's `WorkerIsolate.events`, outside any
  /// request (progress, log lines). Events sent before [serve] begins reach
  /// no listener. [event] must be sendable between isolates.
  void emit(Object? event);

  /// Asks the parent's `answer` callback about [question] and waits for its
  /// result. Questions are answered one at a time, in the order asked, once
  /// [serve] has begun. Fails with a provider failure when the parent has no
  /// answer callback, the result is not an [R], or the worker has stopped.
  Future<Result<R>> ask<R>(Object? question);
}
