import 'dart:async';
import 'dart:isolate';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// Isolates started by [executeIsolate] that have not yet exited.
int debugLiveIsolates = 0;

/// Sends [fraction] to the parent through the zone's [SendPort].
void reportProgress(double fraction) {
  final Object? port = Zone.current[#taptureIsolateProgress];
  if (port is SendPort) {
    port.send(<Object?>['progress', fraction]);
  }
}

/// Spawns [task] on a worker isolate, then always kills it.
Future<Result<R>> executeIsolate<M, R>(
  FutureOr<R> Function(M) task,
  M message,
  void Function(double)? onProgress,
  CancellationToken? cancel,
) async {
  final ReceivePort replies = ReceivePort();
  final ReceivePort exits = ReceivePort();
  debugLiveIsolates++;
  late final Isolate isolate;
  try {
    isolate = await Isolate.spawn(_isolateBoot, <Object?>[
      replies.sendPort,
      task,
      message,
    ], onExit: exits.sendPort);
  } on Object catch (error) {
    debugLiveIsolates--;
    replies.close();
    exits.close();
    return FailureResult<R>(Failure.from(error));
  }

  final Completer<Result<R>> done = Completer<Result<R>>();

  void complete(Result<R> result) {
    if (!done.isCompleted) {
      done.complete(result);
    }
  }

  final StreamSubscription<dynamic> repliesSub = replies.listen((Object? raw) {
    if (raw is! List<Object?> || raw.isEmpty) {
      return;
    }
    final Object? kind = raw.first;
    if (kind == 'progress' && raw.length > 1 && raw[1] is double) {
      onProgress?.call(raw[1]! as double);
      return;
    }
    if (kind == 'ok' && raw.length > 1) {
      complete(Success<R>(raw[1] as R));
      return;
    }
    if (kind == 'err' && raw.length > 1) {
      complete(FailureResult<R>(Failure.from(StateError('${raw[1]}'))));
    }
  });

  final StreamSubscription<void>? cancelSub = cancel == null
      ? null
      : Stream<void>.fromFuture(cancel.whenCancelled).listen((_) {
          complete(FailureResult<R>(const CancelledFailure()));
        });

  try {
    return await done.future;
  } finally {
    await cancelSub?.cancel();
    await repliesSub.cancel();
    replies.close();
    isolate.kill(priority: Isolate.immediate);
    await exits.first;
    exits.close();
    debugLiveIsolates--;
  }
}

void _isolateBoot(List<Object?> args) {
  final SendPort send = args[0]! as SendPort;
  final Function task = args[1]! as Function;
  final Object? message = args[2];
  unawaited(_isolateMain(send, task, message));
}

Future<void> _isolateMain(SendPort send, Function task, Object? message) async {
  await runZoned(() async {
    send.send(<Object?>['progress', 0.0]);
    try {
      final Object? pending = Function.apply(task, <Object?>[message]);
      final Object? result = pending is Future<Object?>
          ? await pending
          : pending;
      send.send(<Object?>['ok', result]);
    } on Object catch (error) {
      send.send(<Object?>['err', error.toString()]);
    }
  }, zoneValues: <Object?, Object?>{#taptureIsolateProgress: send});
}
