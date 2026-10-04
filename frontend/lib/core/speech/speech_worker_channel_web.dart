import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'speech_failures.dart';
import 'speech_worker_codec.dart';

/// Workers running for speech on this page.
int _liveWorkers = 0;

const String _moduleType = 'module';

/// One speech Worker running `whisper_worker.js`: its requests in flight,
/// what `init` reported, and on the threaded variant the shared abort cell.
/// The browser engine's transport; requests and replies are
/// [SpeechWorkerCodec] maps, converted to JavaScript only here.
final class SpeechWorkerChannel {
  SpeechWorkerChannel._(this._worker, this._onLog, this._onCrash);

  final _Worker _worker;
  final void Function(List<({int level, String line})> lines) _onLog;
  final void Function(SpeechWorkerChannel channel) _onCrash;
  final Map<
    int,
    Completer<({Result<Map<Object?, Object?>> result, String? code})>
  >
  _pending =
      <
        int,
        Completer<({Result<Map<Object?, Object?>> result, String? code})>
      >{};
  int _nextId = 0;
  bool _closed = false;
  bool _ready = false;
  int _logDropped = 0;
  int _abortedThrough = 0;
  _WasmMemory? _memory;
  int? _abortIndex;

  /// Speech Workers this page runs now, for leak checks.
  static int get live => _liveWorkers;

  /// The variant the worker loaded: `st` or `mt`.
  String variant = SpeechWorkerCodec.variantSingle;

  /// The browser's logical cores, as the worker read them.
  int logicalCores = 1;

  /// Engine objects alive in this worker, as last read.
  int objects = 0;

  /// Whether the worker still runs; a terminated one answers nothing.
  bool get isOpen => !_closed;

  /// Whether the worker runs the threaded variant, which aborts through the
  /// shared cell.
  bool get threaded => variant == SpeechWorkerCodec.variantThreaded;

  /// The threads a model opened here uses when [requested] are asked for.
  int threadsFor(int requested) => SpeechWorkerCodec.webThreads(
    threaded: threaded,
    hardwareConcurrency: logicalCores,
    requested: requested,
  );

  /// Starts a Worker and loads the WebAssembly [variant]. A Worker that
  /// cannot be created, fails to load, or does not answer within
  /// `workerStart` is `speechUnavailable`; a browser without SIMD is
  /// `speechDeviceUnsupported`.
  static Future<Result<SpeechWorkerChannel>> open({
    required String variant,
    required void Function(List<({int level, String line})> lines) onLog,
    required void Function(SpeechWorkerChannel channel) onCrash,
  }) async {
    final _Worker worker;
    try {
      worker = _Worker(
        SpeechWorkerCodec.workerUrl(Uri.base).toString().toJS,
        _WorkerOptions(type: _moduleType.toJS),
      );
    } on Object {
      return FailureResult<SpeechWorkerChannel>(speechUnavailable());
    }
    _liveWorkers++;
    final SpeechWorkerChannel channel = SpeechWorkerChannel._(
      worker,
      onLog,
      onCrash,
    );
    worker
      ..onmessage = channel._receive.toJS
      ..onerror = channel._fail.toJS;
    final ({Result<Map<Object?, Object?>> result, String? code}) answer =
        await channel
            .send(SpeechWorkerCodec.init(variant: variant))
            .timeout(
              AppConstants.speechEngine.workerStart,
              onTimeout: () => (
                result: FailureResult<Map<Object?, Object?>>(
                  speechUnavailable(),
                ),
                code: null,
              ),
            );
    final Result<SpeechWorkerChannel> started = answer.result
        .flatMap(SpeechWorkerCodec.decodeInit)
        .map((info) {
          channel
            ..variant = info.variant
            ..logicalCores = info.logicalCores
            .._abortIndex = info.abortCellOffset == null
                ? null
                : info.abortCellOffset! >> 2
            .._ready = true;
          return channel;
        });
    if (started case FailureResult<SpeechWorkerChannel>(
      :final Failure failure,
    )) {
      channel.terminate(failure);
      return FailureResult<SpeechWorkerChannel>(failure);
    }
    if (channel.threaded && channel._memory == null) {
      channel.terminate(speechUnavailable());
      return FailureResult<SpeechWorkerChannel>(speechUnavailable());
    }
    return started;
  }

  /// Posts [request] and completes with the worker's answer: the result or
  /// failure, and the worker's error code, which tells a poisoned context
  /// from another failure. The samples a request carries are transferred,
  /// never copied. A worker that ended answers with the failure it ended
  /// with.
  Future<({Result<Map<Object?, Object?>> result, String? code})> send(
    Map<String, Object?> request,
  ) {
    if (_closed) {
      return Future<
        ({Result<Map<Object?, Object?>> result, String? code})
      >.value((
        result: FailureResult<Map<Object?, Object?>>(speechEngineStopped()),
        code: null,
      ));
    }
    final int id = ++_nextId;
    final Completer<({Result<Map<Object?, Object?>> result, String? code})>
    answer =
        Completer<({Result<Map<Object?, Object?>> result, String? code})>();
    _pending[id] = answer;
    try {
      final Map<String, Object?> args = Map<String, Object?>.of(
        request['args']! as Map<String, Object?>,
      );
      final Object? pcm = args.remove('pcm');
      final JSObject jsArgs = args.jsify()! as JSObject;
      final List<JSObject> transfer = <JSObject>[];
      if (pcm is Float32List) {
        final JSFloat32Array samples = pcm.toJS;
        _Args._(jsArgs).pcm = samples;
        transfer.add(_TypedArray._(samples).buffer);
      }
      _worker.postMessage(
        _Envelope(
          id: id.toJS,
          op: (request['op']! as String).toJS,
          args: jsArgs,
        ),
        transfer.toJS,
      );
    } on Object {
      _pending.remove(id);
      return Future<
        ({Result<Map<Object?, Object?>> result, String? code})
      >.value((
        result: FailureResult<Map<Object?, Object?>>(
          speechTranscriptionFailed(),
        ),
        code: null,
      ));
    }
    return answer.future;
  }

  /// Aborts the running threaded job [jobId] and every earlier one through
  /// the shared abort cell. Does nothing on the single-thread variant or
  /// for an id already stored.
  void abortThrough(int jobId) {
    final _WasmMemory? memory = _memory;
    final int? index = _abortIndex;
    if (_closed ||
        memory == null ||
        index == null ||
        jobId <= _abortedThrough) {
      return;
    }
    _abortedThrough = jobId;
    // The heap's buffer is replaced when it grows: view it afresh.
    _Atomics.store(_Int32View(memory.buffer), index, jobId);
  }

  /// Stops the worker at once. Every request still waiting is answered with
  /// [failure].
  void terminate(Failure failure) {
    if (_closed) {
      return;
    }
    _closed = true;
    objects = 0;
    _worker
      ..onmessage = null
      ..onerror = null
      ..terminate();
    _liveWorkers--;
    final List<
      Completer<({Result<Map<Object?, Object?>> result, String? code})>
    >
    waiting = _pending.values.toList();
    _pending.clear();
    for (final Completer<({Result<Map<Object?, Object?>> result, String? code})>
        answer
        in waiting) {
      answer.complete((
        result: FailureResult<Map<Object?, Object?>>(failure),
        code: null,
      ));
    }
  }

  void _receive(_MessageEvent event) {
    final JSObject? data = event.data;
    if (data == null || _closed) {
      return;
    }
    final Object? message = data.dartify();
    if (message is! Map<Object?, Object?>) {
      return;
    }
    if (SpeechWorkerCodec.isEvent(message)) {
      final ({List<({int level, String line})> lines, int dropped}) log =
          SpeechWorkerCodec.decodeLog(message, droppedBefore: _logDropped);
      _logDropped = log.dropped;
      _onLog(log.lines);
      return;
    }
    final int? id = SpeechWorkerCodec.replyId(message);
    final Completer<({Result<Map<Object?, Object?>> result, String? code})>?
    answer = id == null ? null : _pending.remove(id);
    if (answer == null) {
      return;
    }
    if (!_ready) {
      // Only `init` returns the WebAssembly memory the abort cell lives in.
      _memory ??= _Reply._(data).result?.memory;
    }
    answer.complete((
      result: SpeechWorkerCodec.replyResult(message),
      code: SpeechWorkerCodec.replyErrorCode(message),
    ));
  }

  /// The worker failed to load or threw outside a request: it is stopped.
  /// Before it was ready that means the engine is unavailable; after, that
  /// it stopped.
  void _fail(_Event event) {
    event.preventDefault();
    final bool wasReady = _ready;
    terminate(wasReady ? speechEngineStopped() : speechUnavailable());
    if (wasReady) {
      _onCrash(this);
    }
  }
}

// JavaScript interop: extension types over the few browser objects used.

@JS('Worker')
extension type _Worker._(JSObject _) implements JSObject {
  external factory _Worker(JSString url, _WorkerOptions options);
  external void postMessage(JSAny? message, JSArray<JSObject> transfer);
  external void terminate();
  external set onmessage(JSFunction? handler);
  external set onerror(JSFunction? handler);
}

extension type _WorkerOptions._(JSObject _) implements JSObject {
  external factory _WorkerOptions({JSString type});
}

extension type _Envelope._(JSObject _) implements JSObject {
  external factory _Envelope({JSNumber id, JSString op, JSObject args});
}

extension type _Args._(JSObject _) implements JSObject {
  external set pcm(JSFloat32Array value);
}

extension type _TypedArray._(JSObject _) implements JSObject {
  external JSArrayBuffer get buffer;
}

extension type _MessageEvent._(JSObject _) implements JSObject {
  external JSObject? get data;
}

extension type _Event._(JSObject _) implements JSObject {
  external void preventDefault();
}

extension type _Reply._(JSObject _) implements JSObject {
  external _InitResult? get result;
}

extension type _InitResult._(JSObject _) implements JSObject {
  external _WasmMemory? get memory;
}

extension type _WasmMemory._(JSObject _) implements JSObject {
  external JSObject get buffer;
}

@JS('Int32Array')
extension type _Int32View._(JSObject _) implements JSObject {
  external factory _Int32View(JSObject buffer);
}

@JS('Atomics')
extension type _Atomics._(JSObject _) implements JSObject {
  external static int store(_Int32View view, int index, int value);
}
