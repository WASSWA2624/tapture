import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:ui' show RootIsolateToken;

import 'package:flutter/services.dart' show BackgroundIsolateBinaryMessenger;
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'cancellation_token.dart';
import 'worker_isolate.dart';
import 'worker_port.dart';

// Worker to parent: ['ready', SendPort], ['reply', id, Result],
// ['ask', id, payload], ['event', payload], ['closed'].
// Parent to worker: ['call', id, payload], ['answer', id, Result], ['close'].
// The isolate's exit arrives on the parent's inbox as null.
const String _readyTag = 'ready';
const String _replyTag = 'reply';
const String _askTag = 'ask';
const String _eventTag = 'event';
const String _closedTag = 'closed';
const String _callTag = 'call';
const String _answerTag = 'answer';
const String _closeTag = 'close';

int _liveWorkers = 0;

/// Workers spawned by [spawnWorker] that have not yet exited.
int get debugLiveWorkers => _liveWorkers;

/// Starts [entry] on a new isolate and waits for it to serve.
Future<Result<WorkerIsolate>> spawnWorker<A>(
  Future<void> Function(WorkerPort port, A argument) entry,
  A argument, {
  required String debugName,
  Duration? startTimeout,
  RootIsolateToken? platformToken,
  Future<Result<Object?>> Function(Object? question)? answer,
}) async {
  final _ParentEnd worker = _ParentEnd(answer);
  try {
    worker.isolate = await Isolate.spawn<_Boot>(
      _boot,
      (
        parent: worker.inbox.sendPort,
        start: _bind<A>(entry, argument),
        platformToken: platformToken,
      ),
      debugName: debugName,
      onExit: worker.inbox.sendPort,
      onError: worker.faults.sendPort,
    );
  } on Object catch (error) {
    worker.release();
    return FailureResult<WorkerIsolate>(Failure.from(error));
  }
  if (await worker.started(
    startTimeout ?? AppConstants.speechEngine.workerStart,
  )) {
    return Success<WorkerIsolate>(worker);
  }
  await worker.kill();
  return const FailureResult<WorkerIsolate>(ProviderFailure());
}

/// Binds the entry and its argument in a scope that captures nothing else,
/// so the closure stays sendable.
Future<void> Function(WorkerPort port) _bind<A>(
  Future<void> Function(WorkerPort port, A argument) entry,
  A argument,
) =>
    (WorkerPort port) => entry(port, argument);

typedef _Boot = ({
  SendPort parent,
  Future<void> Function(WorkerPort port) start,
  RootIsolateToken? platformToken,
});

void _boot(_Boot boot) {
  unawaited(_run(boot));
}

Future<void> _run(_Boot boot) async {
  final RootIsolateToken? token = boot.platformToken;
  if (token != null) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  }
  final _WorkerEnd port = _WorkerEnd(boot.parent);
  // A failed entry needs no report: the parent fails pending work on exit.
  await Result.captureAsync<void>(() => boot.start(port));
  port.release();
  Isolate.exit();
}

/// Runs [body], turning a throw into a failure.
Future<Result<Object?>> _settle(Future<Result<Object?>> Function() body) async {
  try {
    return await body();
  } on Object catch (error) {
    return FailureResult<Object?>(Failure.from(error));
  }
}

/// Narrows a result that crossed the isolate boundary to [R].
Result<R> _typed<R>(Result<Object?> result) => switch (result) {
  Success<Object?>(:final Object? value) =>
    value is R ? Success<R>(value) : FailureResult<R>(const ProviderFailure()),
  FailureResult<Object?>(:final Failure failure) => FailureResult<R>(failure),
};

/// Sends a tagged result, replacing one that cannot cross the boundary.
void _sendResult(SendPort port, String tag, int id, Result<Object?> result) {
  try {
    port.send(<Object?>[tag, id, result]);
  } on ArgumentError {
    port.send(<Object?>[
      tag,
      id,
      const FailureResult<Object?>(ProviderFailure()),
    ]);
  }
}

/// The parent's handle on one worker isolate.
final class _ParentEnd implements WorkerIsolate {
  _ParentEnd(this._answer) {
    _liveWorkers++;
    inbox.listen(_receive);
    faults.listen((Object? _) => _failPending(const ProviderFailure()));
  }

  final Future<Result<Object?>> Function(Object? question)? _answer;
  final ReceivePort inbox = ReceivePort();
  final ReceivePort faults = ReceivePort();
  final StreamController<Object?> _events =
      StreamController<Object?>.broadcast();
  final Completer<SendPort?> _ready = Completer<SendPort?>();
  final Completer<void> _exited = Completer<void>();
  final Map<int, Completer<Result<Object?>>> _pending =
      <int, Completer<Result<Object?>>>{};
  Future<void> _answering = Future<void>.value();
  Isolate? isolate;
  SendPort? _commands;
  int _nextId = 0;
  bool _closing = false;

  @override
  bool get isOpen => _commands != null && !_closing && !_exited.isCompleted;

  @override
  Stream<Object?> get events => _events.stream;

  @override
  Future<void> get exited => _exited.future;

  /// Waits up to [timeout] for the worker to serve; false when it did not.
  Future<bool> started(Duration timeout) async {
    final Timer timer = Timer(timeout, () {
      if (!_ready.isCompleted) {
        _ready.complete(null);
      }
    });
    final SendPort? commands = await _ready.future;
    timer.cancel();
    return commands != null;
  }

  @override
  Future<Result<R>> request<R>(
    Object? payload, {
    CancellationToken? cancel,
    void Function()? onCancel,
  }) async {
    final SendPort? commands = _commands;
    if (commands == null || !isOpen) {
      return FailureResult<R>(const ProviderFailure());
    }
    if (cancel?.isCancelled ?? false) {
      return FailureResult<R>(const CancelledFailure());
    }
    final int id = _nextId++;
    final Completer<Result<Object?>> reply = Completer<Result<Object?>>();
    _pending[id] = reply;
    try {
      commands.send(<Object?>[_callTag, id, payload]);
    } on ArgumentError catch (error) {
      _pending.remove(id);
      return FailureResult<R>(Failure.from(error));
    }
    final void Function()? detach = cancel?.register(() {
      final Completer<Result<Object?>>? waiting = _pending.remove(id);
      if (waiting == null) {
        return;
      }
      try {
        onCancel?.call();
      } finally {
        waiting.complete(const FailureResult<Object?>(CancelledFailure()));
      }
    });
    try {
      return _typed<R>(await reply.future);
    } finally {
      detach?.call();
    }
  }

  @override
  Future<void> close({Duration? grace}) async {
    if (!_closing && !_exited.isCompleted) {
      _closing = true;
      _failPending(const CancelledFailure());
      _commands?.send(const <Object?>[_closeTag]);
      final Timer timer = Timer(
        grace ?? AppConstants.speechEngine.workerCloseGrace,
        () => isolate?.kill(priority: Isolate.immediate),
      );
      await _exited.future;
      timer.cancel();
    }
    await _exited.future;
  }

  /// Kills a worker that never served and waits for it to end.
  Future<void> kill() async {
    _closing = true;
    isolate?.kill(priority: Isolate.immediate);
    await _exited.future;
  }

  /// Releases both ports once the isolate has ended, or never started.
  void release() {
    if (_exited.isCompleted) {
      return;
    }
    _failPending(const ProviderFailure());
    _commands = null;
    if (!_ready.isCompleted) {
      _ready.complete(null);
    }
    inbox.close();
    faults.close();
    unawaited(_events.close());
    _liveWorkers--;
    _exited.complete();
  }

  void _receive(Object? message) {
    switch (message) {
      case null:
        release();
      case [_readyTag, final SendPort commands]:
        _commands = commands;
        if (!_ready.isCompleted) {
          _ready.complete(commands);
        }
      case [_replyTag, final int id, final Result<Object?> result]:
        _pending.remove(id)?.complete(result);
      case [_askTag, final int id, final Object? question]:
        _answering = _answering.then((_) => _reply(id, question));
      case [_eventTag, final Object? event]:
        if (!_events.isClosed) {
          _events.add(event);
        }
    }
  }

  Future<void> _reply(int id, Object? question) async {
    final Future<Result<Object?>> Function(Object? question)? answer = _answer;
    final Result<Object?> result = answer == null
        ? const FailureResult<Object?>(ProviderFailure())
        : await _settle(() => answer(question));
    final SendPort? commands = await _ready.future;
    if (commands != null && !_exited.isCompleted) {
      _sendResult(commands, _answerTag, id, result);
    }
  }

  void _failPending(Failure failure) {
    final List<Completer<Result<Object?>>> waiting = _pending.values.toList();
    _pending.clear();
    for (final Completer<Result<Object?>> reply in waiting) {
      reply.complete(FailureResult<Object?>(failure));
    }
  }
}

/// The worker's end: serves calls one at a time and asks the parent.
final class _WorkerEnd implements WorkerPort {
  _WorkerEnd(this._parent) {
    _inbox.listen(_receive);
  }

  final SendPort _parent;
  final ReceivePort _inbox = ReceivePort();
  final Queue<({int id, Object? payload})> _calls =
      Queue<({int id, Object? payload})>();
  final Map<int, Completer<Result<Object?>>> _asks =
      <int, Completer<Result<Object?>>>{};
  Completer<void>? _wake;
  int _nextAsk = 0;
  bool _serving = false;
  bool _closing = false;
  bool _released = false;

  @override
  Future<void> serve({
    required Future<Result<Object?>> Function(Object? payload) handle,
    required Future<void> Function() onClose,
  }) async {
    if (_serving || _released) {
      return;
    }
    _serving = true;
    _parent.send(<Object?>[_readyTag, _inbox.sendPort]);
    while (!_closing) {
      if (_calls.isEmpty) {
        final Completer<void> wake = _wake = Completer<void>();
        await wake.future;
        continue;
      }
      final ({int id, Object? payload}) call = _calls.removeFirst();
      final Result<Object?> result = await _settle(() => handle(call.payload));
      _sendResult(_parent, _replyTag, call.id, result);
    }
    try {
      await onClose();
    } finally {
      _parent.send(const <Object?>[_closedTag]);
      release();
    }
  }

  @override
  void emit(Object? event) {
    if (!_released) {
      _parent.send(<Object?>[_eventTag, event]);
    }
  }

  @override
  Future<Result<R>> ask<R>(Object? question) async {
    if (_released) {
      return FailureResult<R>(const ProviderFailure());
    }
    final int id = _nextAsk++;
    final Completer<Result<Object?>> reply = Completer<Result<Object?>>();
    _asks[id] = reply;
    try {
      _parent.send(<Object?>[_askTag, id, question]);
    } on ArgumentError catch (error) {
      _asks.remove(id);
      return FailureResult<R>(Failure.from(error));
    }
    return _typed<R>(await reply.future);
  }

  /// Closes the port and fails questions still waiting for an answer.
  void release() {
    if (_released) {
      return;
    }
    _released = true;
    _closing = true;
    _calls.clear();
    _inbox.close();
    final List<Completer<Result<Object?>>> waiting = _asks.values.toList();
    _asks.clear();
    for (final Completer<Result<Object?>> reply in waiting) {
      reply.complete(const FailureResult<Object?>(ProviderFailure()));
    }
    _signal();
  }

  void _receive(Object? message) {
    switch (message) {
      case [_callTag, final int id, final Object? payload] when !_closing:
        _calls.add((id: id, payload: payload));
        _signal();
      case [_answerTag, final int id, final Result<Object?> result]:
        _asks.remove(id)?.complete(result);
      case [_closeTag]:
        _closing = true;
        _calls.clear();
        _signal();
    }
  }

  void _signal() {
    final Completer<void>? wake = _wake;
    _wake = null;
    if (wake != null && !wake.isCompleted) {
      wake.complete();
    }
  }
}
