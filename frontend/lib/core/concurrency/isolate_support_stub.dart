import 'dart:async';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// Web stand-in: there is no isolate to count.
int debugLiveIsolates = 0;

/// Forwards progress through the current zone, if a listener is installed.
void reportProgress(double fraction) {
  final Object? report = Zone.current[#taptureIsolateProgress];
  if (report is void Function(double)) {
    report(fraction);
  }
}

/// Runs [task] on this isolate so the web binary still compiles.
Future<Result<R>> executeIsolate<M, R>(
  FutureOr<R> Function(M) task,
  M message,
  void Function(double)? onProgress,
  CancellationToken? cancel,
) async {
  debugLiveIsolates++;
  try {
    return await runZoned(() async {
      onProgress?.call(0);
      try {
        if (cancel?.isCancelled ?? false) {
          return FailureResult<R>(const CancelledFailure());
        }
        final Future<R> work = Future<R>.sync(() => task(message));
        if (cancel == null) {
          final R value = await work;
          onProgress?.call(1);
          return Success<R>(value);
        }
        final Result<R> raced = await Future.any<Result<R>>(<Future<Result<R>>>[
          work.then(Success<R>.new),
          cancel.whenCancelled.then((_) {
            return FailureResult<R>(const CancelledFailure());
          }),
        ]);
        if (raced is Success<R>) {
          onProgress?.call(1);
        }
        return raced;
      } on Object catch (error) {
        return FailureResult<R>(Failure.from(error));
      }
    }, zoneValues: <Object?, Object?>{#taptureIsolateProgress: onProgress});
  } finally {
    debugLiveIsolates--;
  }
}
