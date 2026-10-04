import 'dart:async';
import 'dart:io' show File, FileSystemException;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/concurrency/worker_isolate.dart';
import 'package:tapture/core/concurrency/worker_port.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/logging/logger.dart';

import 'speech_abort_cell.dart';
import 'speech_decode_job.dart';
import 'speech_decode_kind.dart';
import 'speech_decode_profile.dart';
import 'speech_decode_request.dart';
import 'speech_decode_result.dart';
import 'speech_engine.dart';
import 'speech_engine_state.dart';
import 'speech_failures.dart';
import 'speech_load_report.dart';
import 'speech_model_entry.dart';
import 'speech_model_shape.dart';
import 'speech_model_source.dart';
import 'speech_model_verification.dart';
import 'speech_native_api.dart';
import 'speech_native_api_io.dart';
import 'speech_runtime_facts.dart';
import 'speech_vad_handle.dart';
import 'speech_vad_result.dart';

// The native speech engine (spec §30.4.2, design §4.2): two long-lived worker
// isolates, `speech-decode` (one whisper context) and `speech-vad` (one
// Silero detector per lease), so voice detection never queues behind a
// multi-second decode. The main isolate keeps the decode queue and the state
// machine and makes no native call except creating, storing to and closing
// the abort cell (FE-PERF-02).

/// The engine for a device: native workers over [openApi] (the whisper
/// library at [libraryPath] by default) and an abort cell from
/// [openAbortCell].
SpeechEngine createSpeechEngine({
  String? libraryPath,
  SpeechNativeApi Function(String? libraryPath)? openApi,
  SpeechAbortCell Function(String? libraryPath)? openAbortCell,
}) => _NativeSpeechEngine(
  libraryPath,
  openApi ?? openSpeechNativeApi,
  openAbortCell ?? openSpeechAbortCell,
);

/// Creates the folder of [path], counts the lines it holds and points the
/// library's fatal-abort record at it. The library is process-wide, so
/// every worker that later loads a model writes there.
Future<int?> recordSpeechCrashes(String path) async {
  final File file = File(path);
  try {
    await file.parent.create(recursive: true);
    final int lines = await file.exists()
        ? (await file.readAsLines())
              .where((String line) => line.isNotEmpty)
              .length
        : 0;
    return armSpeechCrashFile(path) ? lines : null;
  } on FileSystemException {
    return null;
  }
}

/// What a worker isolate needs to open the library.
typedef _LaneSetup = ({
  String? libraryPath,
  SpeechNativeApi Function(String? libraryPath) openApi,
});

/// What a worker reports after every command: the handles it holds and the
/// native log lines it forwards, already rate-limited.
typedef _LaneReport = ({int handles, List<({int level, String line})> lines});

/// A successful model load, as the decode worker reports it.
typedef _Loaded = ({SpeechModelShape shape, Duration loadTime});

const String _logTag = 'speech';

/// `tw_log_level` codes.
const int _warnLevel = 3;
const int _errorLevel = 4;

/// `TW_LOG_RING_CAPACITY`: one drain empties the native ring.
const int _logRingCapacity = 256;

/// Above every job id, so storing it aborts whatever is in flight.
const int _allJobs = 0x7fffffff;

final class _NativeSpeechEngine implements SpeechEngine {
  _NativeSpeechEngine(this._libraryPath, this._openApi, this._openAbortCell);

  final String? _libraryPath;
  final SpeechNativeApi Function(String? libraryPath) _openApi;
  final SpeechAbortCell Function(String? libraryPath) _openAbortCell;
  final StreamController<SpeechEngineState> _states =
      StreamController<SpeechEngineState>.broadcast();
  final List<SpeechDecodeJob> _queue = <SpeechDecodeJob>[];
  SpeechEngineState _state = SpeechEngineState.idle;
  _Lanes? _lanes;
  Future<Result<_Lanes>>? _starting;
  Future<void> _teardown = Future<void>.value();
  SpeechDecodeJob? _inFlight;
  SpeechLoadReport? _loaded;
  int _restarts = 0;
  int _decodeHandles = 0;
  int _vadHandles = 0;
  bool _disposed = false;

  _LaneSetup get _setup => (libraryPath: _libraryPath, openApi: _openApi);

  @override
  SpeechLoadReport? get loaded => _loaded;

  @override
  Stream<SpeechEngineState> get states => _states.stream;

  @override
  int get debugLiveHandles => _decodeHandles + _vadHandles;

  @override
  Future<Result<SpeechRuntimeFacts>> probe() {
    if (_disposed) {
      return _stopped<SpeechRuntimeFacts>();
    }
    return runIsolate<_LaneSetup, SpeechRuntimeFacts>(_probeFacts, _setup);
  }

  @override
  Future<Result<SpeechLoadReport>> load(
    SpeechModelSource model, {
    required int threads,
    CancellationToken? cancel,
  }) async {
    if (_disposed) {
      return _stopped<SpeechLoadReport>();
    }
    final String? path = model.path;
    if (path == null) {
      return FailureResult<SpeechLoadReport>(speechModelMissing());
    }
    if (threads < 1) {
      return _refused<SpeechLoadReport>('load refused: invalid threads');
    }
    final SpeechLoadReport? current = _loaded;
    if (current != null &&
        current.model.id == model.entry.id &&
        current.threads == threads) {
      return Success<SpeechLoadReport>(current);
    }
    final Result<_Lanes> started = await _ensureLanes();
    final _Lanes lanes;
    switch (started) {
      case FailureResult<_Lanes>(:final Failure failure):
        return FailureResult<SpeechLoadReport>(failure);
      case Success<_Lanes>(value: final _Lanes running):
        lanes = running;
    }
    _loaded = null;
    _setState(SpeechEngineState.loading);
    final Result<_Loaded> reply = _settled(
      await lanes.decode.request<_Loaded>(
        _LoadCommand(path: path, entry: model.entry, threads: threads),
      ),
      lanes,
      lanes.decode,
    );
    final Logger logger = Logger.current;
    switch (reply) {
      case FailureResult<_Loaded>(:final Failure failure):
        logger.warn(_logTag, 'load failed: ${failure.runtimeType}');
        _settleState(lanes, SpeechEngineState.ready);
        return FailureResult<SpeechLoadReport>(failure);
      case Success<_Loaded>(value: final _Loaded done):
        if (_disposed) {
          return FailureResult<SpeechLoadReport>(speechEngineStopped());
        }
        if (cancel?.isCancelled ?? false) {
          await lanes.decode.request<Object?>(const _UnloadCommand());
          _settleState(lanes, SpeechEngineState.ready);
          return FailureResult<SpeechLoadReport>(speechCancelled());
        }
        final SpeechLoadReport report = SpeechLoadReport(
          model: model.entry,
          shape: done.shape,
          threads: threads,
          loadTime: done.loadTime,
        );
        _loaded = report;
        _settleState(lanes, SpeechEngineState.loaded);
        final String modelId = model.entry.id;
        final int elapsedMs = done.loadTime.inMilliseconds;
        logger.info(
          _logTag,
          'model $modelId loaded in ${elapsedMs}ms with $threads threads',
        );
        return Success<SpeechLoadReport>(report);
    }
  }

  @override
  Future<Result<SpeechVadHandle>> openVad(SpeechModelSource vad) async {
    if (_disposed) {
      return _stopped<SpeechVadHandle>();
    }
    final String? path = vad.path;
    if (path == null) {
      return FailureResult<SpeechVadHandle>(speechModelMissing());
    }
    final Result<_Lanes> started = await _ensureLanes();
    switch (started) {
      case FailureResult<_Lanes>(:final Failure failure):
        return FailureResult<SpeechVadHandle>(failure);
      case Success<_Lanes>(value: final _Lanes lanes):
        return _settled(
          await lanes.vad.request<SpeechVadHandle>(
            _OpenVadCommand(path: path, entry: vad.entry),
          ),
          lanes,
          lanes.vad,
        );
    }
  }

  @override
  Future<Result<SpeechDecodeResult>> decode(
    SpeechDecodeRequest request, {
    required int leaseId,
    CancellationToken? cancel,
  }) {
    if (_disposed) {
      return _stopped<SpeechDecodeResult>();
    }
    if (!request.isWellFormed) {
      return _refused<SpeechDecodeResult>('decode refused: invalid request');
    }
    if (_loaded == null) {
      return Future<Result<SpeechDecodeResult>>.value(
        FailureResult<SpeechDecodeResult>(speechUnavailable()),
      );
    }
    if (cancel?.isCancelled ?? false) {
      return Future<Result<SpeechDecodeResult>>.value(
        FailureResult<SpeechDecodeResult>(speechCancelled()),
      );
    }
    final SpeechDecodeJob job = SpeechDecodeJob(leaseId, request);
    if (job.committed) {
      final SpeechDecodeJob? running = _inFlight;
      if (running != null && !running.committed) {
        _abort(running);
      }
    } else {
      for (final SpeechDecodeJob pending in _queue.toList()) {
        if (!pending.committed && pending.leaseId == leaseId) {
          _queue.remove(pending);
          pending.finish(FailureResult<SpeechDecodeResult>(speechCancelled()));
        }
      }
    }
    _queue.add(job);
    job.detach = cancel?.register(() => _cancel(job));
    _pump();
    return job.done.future;
  }

  @override
  Future<Result<SpeechVadResult>> detectSpeech(
    SpeechVadHandle vad,
    Float32List samples, {
    bool resetState = false,
    CancellationToken? cancel,
  }) async {
    if (_disposed) {
      return _stopped<SpeechVadResult>();
    }
    if (vad.frameSamples < 1 || samples.length % vad.frameSamples != 0) {
      return _refused<SpeechVadResult>('voice batch refused: partial frame');
    }
    final _Lanes? lanes = _lanes;
    if (lanes == null || !lanes.vad.isOpen) {
      return _stopped<SpeechVadResult>();
    }
    if (samples.isEmpty) {
      return Success<SpeechVadResult>(
        SpeechVadResult(
          probabilities: Float32List(0),
          frameSamples: vad.frameSamples,
        ),
      );
    }
    final Result<Float32List> reply = _settled(
      await lanes.vad.request<Float32List>(
        _DetectCommand(
          vad: vad.id,
          samples: TransferableTypedData.fromList(<TypedData>[samples]),
          reset: resetState,
        ),
        cancel: cancel,
      ),
      lanes,
      lanes.vad,
    );
    return switch (reply) {
      FailureResult<Float32List>(:final Failure failure) =>
        FailureResult<SpeechVadResult>(failure),
      Success<Float32List>(value: final Float32List probabilities) =>
        Success<SpeechVadResult>(
          SpeechVadResult(
            probabilities: probabilities,
            frameSamples: vad.frameSamples,
          ),
        ),
    };
  }

  @override
  Future<void> closeVad(SpeechVadHandle vad) async {
    final _Lanes? lanes = _lanes;
    if (lanes == null || !lanes.vad.isOpen) {
      return;
    }
    await lanes.vad.request<Object?>(_CloseVadCommand(vad.id));
  }

  @override
  void abortLease(int leaseId) {
    for (final SpeechDecodeJob pending in _queue.toList()) {
      if (pending.leaseId == leaseId) {
        _queue.remove(pending);
        pending.finish(FailureResult<SpeechDecodeResult>(speechCancelled()));
      }
    }
    final SpeechDecodeJob? running = _inFlight;
    if (running != null && running.leaseId == leaseId) {
      _abort(running);
    }
  }

  @override
  Future<Result<void>> unload() async {
    if (_disposed) {
      return _stopped<void>();
    }
    _loaded = null;
    final _Lanes? lanes = _lanes;
    if (lanes == null || !lanes.decode.isOpen) {
      return const Success<void>(null);
    }
    _failQueue(speechCancelled());
    final SpeechDecodeJob? running = _inFlight;
    if (running != null) {
      _abort(running);
    }
    _setState(SpeechEngineState.unloading);
    final Result<Object?> reply = _settled(
      await lanes.decode.request<Object?>(const _UnloadCommand()),
      lanes,
      lanes.decode,
    );
    _settleState(lanes, SpeechEngineState.ready);
    return switch (reply) {
      FailureResult<Object?>(:final Failure failure) => FailureResult<void>(
        failure,
      ),
      Success<Object?>() => const Success<void>(null),
    };
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _loaded = null;
    _failQueue(speechEngineStopped());
    await _starting;
    final _Lanes? lanes = _lanes;
    _lanes = null;
    if (lanes != null) {
      _teardown = _closeLanes(lanes);
    }
    await _teardown;
    _setState(SpeechEngineState.disposed);
    await _states.close();
  }

  /// The running lanes, starting them (or restarting them after a worker
  /// ended, within the restart budget) when there are none.
  Future<Result<_Lanes>> _ensureLanes() {
    final _Lanes? lanes = _lanes;
    if (lanes != null && lanes.isOpen) {
      return Future<Result<_Lanes>>.value(Success<_Lanes>(lanes));
    }
    return _starting ??= _start().whenComplete(() => _starting = null);
  }

  Future<Result<_Lanes>> _start() async {
    await _teardown;
    if (_disposed) {
      return FailureResult<_Lanes>(speechEngineStopped());
    }
    final SpeechEngineState before = _state;
    if (before == SpeechEngineState.failed) {
      if (_restarts >= AppConstants.speechEngine.maxWorkerRestarts) {
        return FailureResult<_Lanes>(speechEngineStopped());
      }
      _restarts++;
    }
    _setState(SpeechEngineState.starting);
    final Stopwatch watch = Stopwatch()..start();
    final List<Result<WorkerIsolate>> spawned =
        await Future.wait(<Future<Result<WorkerIsolate>>>[
          WorkerIsolate.spawn<_LaneSetup>(
            _serveLane,
            _setup,
            debugName: 'speech-decode',
          ),
          WorkerIsolate.spawn<_LaneSetup>(
            _serveLane,
            _setup,
            debugName: 'speech-vad',
          ),
        ]);
    final List<WorkerIsolate> workers = <WorkerIsolate>[
      for (final Result<WorkerIsolate> worker in spawned)
        if (worker case Success<WorkerIsolate>(
          value: final WorkerIsolate running,
        ))
          running,
    ];
    Failure? refusal = workers.length == spawned.length
        ? null
        : speechUnavailable();
    SpeechAbortCell? cell;
    if (refusal == null && !_disposed) {
      try {
        cell = _openAbortCell(_libraryPath);
      } on Failure catch (failure) {
        refusal = failure;
      } on Object {
        refusal = speechUnavailable();
      }
    }
    if (cell == null) {
      await Future.wait(<Future<void>>[
        for (final WorkerIsolate worker in workers) worker.close(),
      ]);
      _setState(
        before == SpeechEngineState.failed ? before : SpeechEngineState.idle,
      );
      return FailureResult<_Lanes>(refusal ?? speechEngineStopped());
    }
    final _Lanes lanes = _Lanes(workers[0], workers[1], cell);
    lanes.decode.events.listen((Object? event) => _onReport(event, true));
    lanes.vad.events.listen((Object? event) => _onReport(event, false));
    unawaited(lanes.decode.exited.then((_) => _onExit(lanes)));
    unawaited(lanes.vad.exited.then((_) => _onExit(lanes)));
    _lanes = lanes;
    _setState(SpeechEngineState.ready);
    final int elapsedMs = watch.elapsedMilliseconds;
    Logger.current.info(_logTag, 'worker lanes started in ${elapsedMs}ms');
    return Success<_Lanes>(lanes);
  }

  /// A worker ended. When nobody asked it to, fails what waits on it, forgets
  /// the model and stops the other worker; the next load starts both again.
  void _onExit(_Lanes lanes) {
    if (lanes.closing) {
      return;
    }
    if (identical(_lanes, lanes)) {
      _lanes = null;
    }
    _loaded = null;
    _failQueue(speechEngineStopped());
    Logger.current.warn(_logTag, 'worker exited unexpectedly');
    _teardown = _closeLanes(lanes);
    if (!_disposed) {
      _setState(SpeechEngineState.failed);
    }
  }

  /// Aborts whatever runs, closes both workers, waits until both isolates
  /// have ended (a kill cannot interrupt a native call), and only then
  /// releases the main isolate's reference to the abort cell.
  Future<void> _closeLanes(_Lanes lanes) async {
    lanes.closing = true;
    lanes.cell.abortThrough(_allJobs);
    await Future.wait(<Future<void>>[lanes.decode.close(), lanes.vad.close()]);
    await Future.wait(<Future<void>>[lanes.decode.exited, lanes.vad.exited]);
    lanes.cell.close();
  }

  void _onReport(Object? event, bool decodeLane) {
    if (event is! _LaneReport) {
      return;
    }
    if (decodeLane) {
      _decodeHandles = event.handles;
    } else {
      _vadHandles = event.handles;
    }
    final Logger logger = Logger.current;
    for (final ({int level, String line}) native in event.lines) {
      final String line = native.line;
      if (native.level >= _errorLevel) {
        logger.error(_logTag, line);
      } else {
        logger.warn(_logTag, line);
      }
    }
  }

  /// Sends the next job to the decode worker when none is in flight:
  /// committed requests first, in arrival order, then interims.
  void _pump() {
    if (_inFlight != null || _queue.isEmpty) {
      return;
    }
    final _Lanes? lanes = _lanes;
    if (lanes == null || !lanes.decode.isOpen) {
      _failQueue(speechEngineStopped());
      return;
    }
    if (_loaded == null) {
      _failQueue(speechUnavailable());
      return;
    }
    final SpeechDecodeJob job = _queue.firstWhere(
      (SpeechDecodeJob waiting) => waiting.committed,
      orElse: () => _queue.first,
    );
    _queue.remove(job);
    job.jobId = ++lanes.nextJobId;
    _inFlight = job;
    _setState(SpeechEngineState.busy);
    unawaited(_dispatch(lanes, job));
  }

  Future<void> _dispatch(_Lanes lanes, SpeechDecodeJob job) async {
    final SpeechDecodeRequest request = job.request;
    final Result<SpeechDecodeResult> reply = _settled(
      await lanes.decode.request<SpeechDecodeResult>(
        _DecodeCommand(
          samples: TransferableTypedData.fromList(<TypedData>[request.samples]),
          language: request.language,
          kind: request.kind,
          profile: request.profile,
          offset: request.offsetSamples,
          prompt: request.prompt,
          pieceTimings: request.pieceTimings,
          abortAddress: lanes.cell.address,
          jobId: job.jobId,
        ),
      ),
      lanes,
      lanes.decode,
    );
    _inFlight = null;
    job.finish(
      job.aborted
          ? FailureResult<SpeechDecodeResult>(speechCancelled())
          : reply,
    );
    if (_queue.isEmpty && _loaded != null) {
      _settleState(lanes, SpeechEngineState.loaded);
    }
    _pump();
  }

  void _cancel(SpeechDecodeJob job) {
    if (_queue.remove(job)) {
      job.finish(FailureResult<SpeechDecodeResult>(speechCancelled()));
    } else if (identical(_inFlight, job)) {
      _abort(job);
    }
  }

  /// Aborts the in-flight [job] through the abort cell.
  void _abort(SpeechDecodeJob job) {
    if (job.aborted) {
      return;
    }
    job.aborted = true;
    _lanes?.cell.abortThrough(job.jobId);
  }

  void _failQueue(Failure failure) {
    final List<SpeechDecodeJob> waiting = _queue.toList();
    _queue.clear();
    for (final SpeechDecodeJob job in waiting) {
      job.finish(FailureResult<SpeechDecodeResult>(failure));
    }
  }

  /// A failure from [worker] once it has ended, or once [lanes] are torn
  /// down because a worker ended unasked (which cancels what the other
  /// worker still had), means the engine stopped.
  Result<T> _settled<T>(Result<T> result, _Lanes lanes, WorkerIsolate worker) {
    if (result case FailureResult<T>(:final Failure failure)
        when !_disposed &&
            (failure is ProviderFailure || failure is CancelledFailure) &&
            (lanes.closing || !worker.isOpen)) {
      return FailureResult<T>(speechEngineStopped());
    }
    return result;
  }

  /// Moves to [state] unless [lanes] were replaced or the engine is gone.
  void _settleState(_Lanes lanes, SpeechEngineState state) {
    if (identical(_lanes, lanes) && lanes.isOpen && !_disposed) {
      _setState(state);
    }
  }

  void _setState(SpeechEngineState state) {
    if (_state == state || _states.isClosed) {
      return;
    }
    _state = state;
    _states.add(state);
  }

  static Future<Result<T>> _stopped<T>() =>
      Future<Result<T>>.value(FailureResult<T>(speechEngineStopped()));

  /// A caller's defect: logged as an error and refused (spec §30.4.4).
  static Future<Result<T>> _refused<T>(String reason) {
    Logger.current.error(_logTag, reason);
    return Future<Result<T>>.value(FailureResult<T>(speechInvalidRequest()));
  }
}

/// One generation of the two workers and the abort cell they share. Job ids
/// start at 1 for every generation, so a new cell is made with new workers.
final class _Lanes {
  _Lanes(this.decode, this.vad, this.cell);

  final WorkerIsolate decode;
  final WorkerIsolate vad;
  final SpeechAbortCell cell;
  int nextJobId = 0;
  bool closing = false;

  bool get isOpen => !closing && decode.isOpen && vad.isOpen;
}

// Commands, sent within the isolate group.

final class _LoadCommand {
  const _LoadCommand({
    required this.path,
    required this.entry,
    required this.threads,
  });

  final String path;
  final SpeechModelEntry entry;
  final int threads;
}

final class _UnloadCommand {
  const _UnloadCommand();
}

final class _DecodeCommand {
  const _DecodeCommand({
    required this.samples,
    required this.language,
    required this.kind,
    required this.profile,
    required this.offset,
    required this.prompt,
    required this.pieceTimings,
    required this.abortAddress,
    required this.jobId,
  });

  final TransferableTypedData samples;
  final String language;
  final SpeechDecodeKind kind;
  final SpeechDecodeProfile profile;
  final int offset;
  final String prompt;
  final bool pieceTimings;
  final int abortAddress;
  final int jobId;
}

final class _OpenVadCommand {
  const _OpenVadCommand({required this.path, required this.entry});

  final String path;
  final SpeechModelEntry entry;
}

final class _DetectCommand {
  const _DetectCommand({
    required this.vad,
    required this.samples,
    required this.reset,
  });

  final int vad;
  final TransferableTypedData samples;
  final bool reset;
}

final class _CloseVadCommand {
  const _CloseVadCommand(this.vad);

  final int vad;
}

/// The facts a one-shot isolate reads without starting the workers.
SpeechRuntimeFacts _probeFacts(_LaneSetup setup) {
  final SpeechNativeApi api = setup.openApi(setup.libraryPath);
  try {
    return api.facts();
  } finally {
    api.close();
  }
}

/// A worker's entry: opens the library in this isolate and serves commands
/// until the engine closes it. A library that cannot be opened still
/// serves, refusing every command with its failure.
Future<void> _serveLane(WorkerPort port, _LaneSetup setup) async {
  final _LaneServer server = _LaneServer(
    port,
    Result.capture<SpeechNativeApi>(() => setup.openApi(setup.libraryPath)),
  );
  await port.serve(handle: server.handle, onClose: server.close);
}

/// The worker side of one lane.
final class _LaneServer {
  _LaneServer(this._port, this._opened);

  final WorkerPort _port;
  final Result<SpeechNativeApi> _opened;
  final Set<int> _vads = <int>{};
  int? _model;
  int _dropped = 0;

  Future<Result<Object?>> handle(Object? command) async {
    final Result<Object?> result = await Result.captureAsync<Object?>(
      () => _run(command),
    );
    _report();
    return result;
  }

  Future<void> close() async {
    if (_opened case Success<SpeechNativeApi>(
      value: final SpeechNativeApi api,
    )) {
      _releaseModel(api);
      for (final int vad in _vads) {
        api.release(vad);
      }
      _vads.clear();
      _report();
      api.close();
    }
  }

  Future<Object?> _run(Object? command) async {
    final SpeechNativeApi api = switch (_opened) {
      Success<SpeechNativeApi>(value: final SpeechNativeApi opened) => opened,
      FailureResult<SpeechNativeApi>(:final Failure failure) => throw failure,
    };
    return switch (command) {
      final _LoadCommand load => await _load(api, load),
      _UnloadCommand() => _releaseModel(api),
      final _DecodeCommand decode => _decode(api, decode),
      final _OpenVadCommand open => await _openVad(api, open),
      final _DetectCommand detect => _detect(api, detect),
      final _CloseVadCommand close => _closeVad(api, close),
      _ => throw speechInvalidRequest(),
    };
  }

  /// Size and header first, then the verified native open, then the shape.
  Future<_Loaded> _load(SpeechNativeApi api, _LoadCommand command) async {
    final Stopwatch watch = Stopwatch()..start();
    final SpeechModelEntry entry = command.entry;
    await _precheck(command.path, entry);
    _releaseModel(api);
    final int model = api.loadModel(
      command.path,
      threads: command.threads,
      bytes: entry.bytes,
      sha256: entry.sha256,
    );
    final SpeechModelShape shape;
    try {
      shape = api.shape(model);
    } on Object {
      api.release(model);
      rethrow;
    }
    if (shape != SpeechModelShape.expectedFor(entry)) {
      api.release(model);
      throw speechModelDamaged();
    }
    _model = model;
    return (shape: shape, loadTime: watch.elapsed);
  }

  Object? _releaseModel(SpeechNativeApi api) {
    final int? model = _model;
    _model = null;
    if (model != null) {
      api.release(model);
    }
    return null;
  }

  /// Pads short windows to whisper's minimum and clamps the result back to
  /// the samples the request really carried.
  SpeechDecodeResult _decode(SpeechNativeApi api, _DecodeCommand command) {
    final int model = _model ?? (throw speechUnavailable());
    final Float32List samples = command.samples.materialize().asFloat32List();
    final int count = samples.length;
    final int minimum = AppConstants.speechEngine.minDecodeSamples;
    final Float32List padded = count >= minimum
        ? samples
        : (Float32List(minimum)..setRange(0, count, samples));
    final SpeechDecodeResult raw = api.decode(
      model,
      SpeechDecodeRequest(
        samples: padded,
        language: command.language,
        kind: command.kind,
        profile: command.profile,
        offsetSamples: command.offset,
        prompt: command.prompt,
        pieceTimings: command.pieceTimings,
      ),
      abortAddress: command.abortAddress,
      jobId: command.jobId,
    );
    return raw.clampedTo(count);
  }

  Future<SpeechVadHandle> _openVad(
    SpeechNativeApi api,
    _OpenVadCommand command,
  ) async {
    await _precheck(command.path, command.entry);
    final int vad = api.loadVad(
      command.path,
      bytes: command.entry.bytes,
      sha256: command.entry.sha256,
    );
    final int window;
    try {
      window = api.vadWindow(vad);
    } on Object {
      api.release(vad);
      rethrow;
    }
    _vads.add(vad);
    return SpeechVadHandle(id: vad, frameSamples: window);
  }

  Float32List _detect(SpeechNativeApi api, _DetectCommand command) {
    if (!_vads.contains(command.vad)) {
      throw speechEngineStopped();
    }
    return api.detectSpeech(
      command.vad,
      command.samples.materialize().asFloat32List(),
      reset: command.reset,
    );
  }

  Object? _closeVad(SpeechNativeApi api, _CloseVadCommand command) {
    if (_vads.remove(command.vad)) {
      api.release(command.vad);
    }
    return null;
  }

  /// Sends the handle count and at most `logLinesPerDrain` native lines of
  /// at most `logLineChars`, plus one line counting the rest.
  void _report() {
    if (_opened case Success<SpeechNativeApi>(
      value: final SpeechNativeApi api,
    )) {
      final List<({int level, String line})> drained = api.drainLog(
        _logRingCapacity,
      );
      final int dropped = api.droppedLogLines;
      final int perDrain = AppConstants.speechEngine.logLinesPerDrain;
      final int chars = AppConstants.speechEngine.logLineChars;
      final int kept = drained.length < perDrain ? drained.length : perDrain;
      final int suppressed =
          drained.length - kept + (dropped > _dropped ? dropped - _dropped : 0);
      _dropped = dropped;
      _port.emit((
        handles: api.liveHandles,
        lines: <({int level, String line})>[
          for (final ({int level, String line}) native in drained.take(kept))
            (
              level: native.level,
              line: native.line.length > chars
                  ? native.line.substring(0, chars)
                  : native.line,
            ),
          if (suppressed > 0)
            (level: _warnLevel, line: '$suppressed native lines suppressed'),
        ],
      ));
    }
  }

  static Future<void> _precheck(String path, SpeechModelEntry entry) async {
    final Result<void> checked = await precheckSpeechModelFile(path, entry);
    if (checked case FailureResult<void>(:final Failure failure)) {
      throw failure;
    }
  }
}
