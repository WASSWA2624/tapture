import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/logging/logger.dart';

import 'speech_abort_cell.dart';
import 'speech_cpu_feature.dart';
import 'speech_decode_job.dart';
import 'speech_decode_request.dart';
import 'speech_decode_result.dart';
import 'speech_engine.dart';
import 'speech_engine_state.dart';
import 'speech_failures.dart';
import 'speech_load_report.dart';
import 'speech_model_entry.dart';
import 'speech_model_kind.dart';
import 'speech_model_shape.dart';
import 'speech_model_source.dart';
import 'speech_native_api.dart';
import 'speech_runtime_facts.dart';
import 'speech_unavailable_reason.dart';
import 'speech_vad_handle.dart';
import 'speech_vad_result.dart';
import 'speech_worker_channel_web.dart';
import 'speech_worker_codec.dart';

// The browser speech engine (spec §30.4.8, design §4.3): two module Workers
// running the WebAssembly build of the same shim, `decode` (the threaded
// variant when the page is cross-origin isolated) and `vad` (always single
// thread, one Silero detector per lease), so voice detection never queues
// behind a decode. The page keeps the decode queue and the state machine;
// model bytes travel from the same origin straight into the worker and never
// cross the Dart heap. Interop is dart:js_interop only.

/// The engine for a browser. The native test seams do not apply here.
SpeechEngine createSpeechEngine({
  String? libraryPath,
  SpeechNativeApi Function(String? libraryPath)? openApi,
  SpeechAbortCell Function(String? libraryPath)? openAbortCell,
}) => _WebSpeechEngine();

/// A browser runs the engine in Workers, which keep no crash file.
Future<int?> recordSpeechCrashes(String path) => Future<int?>.value();

/// Speech Workers this page is running, for leak checks: it returns to its
/// starting value once every engine is disposed.
@visibleForTesting
int get debugLiveSpeechWorkers => SpeechWorkerChannelWeb.live;

/// Hashes the browser's cached copy of [entry] in [engine]'s worker, for the
/// settings check: whether a copy is cached, and whether it has the expected
/// size and SHA-256. Any engine but the browser one is `speechUnavailable`.
Future<Result<({bool present, bool ok})>> verifyCachedSpeechModel(
  SpeechEngine engine,
  SpeechModelEntry entry,
) {
  if (engine is _WebSpeechEngine) {
    return engine._verifyCached(entry);
  }
  return Future<Result<({bool present, bool ok})>>.value(
    FailureResult<({bool present, bool ok})>(speechUnavailable()),
  );
}

const String _logTag = 'speech';

/// `tw_log_level` of an error line.
const int _errorLevel = 4;

/// The C ABI the shipped worker speaks; the worker refuses any other.
const int _abiVersion = 1;

/// Above every job id, so storing it aborts whatever is in flight.
const int _allJobs = 0x7fffffff;

/// The smallest module using a v128 instruction, as `whisper_worker.js`
/// probes it: `(func (result v128) i32.const 0 i8x16.splat i8x16.popcnt)`.
const List<int> _simdProbe = <int>[
  0, 97, 115, 109, 1, 0, 0, 0, 1, 5, 1, 96, 0, 1, 123, 3, 2, 1, 0, 10, 10, //
  1, 8, 0, 65, 0, 253, 15, 253, 98, 11,
];

const int _bytesPerGibibyte = 1024 * 1024 * 1024;

/// What a worker answered: the result or failure, and the worker's error
/// code, which tells a poisoned context from another failure.
typedef _Answer = ({Result<Map<Object?, Object?>> result, String? code});

/// A model the decode worker opened.
typedef _Opened = ({int handle, SpeechModelShape shape, Duration loadTime});

final class _WebSpeechEngine implements SpeechEngine {
  final StreamController<SpeechEngineState> _states =
      StreamController<SpeechEngineState>.broadcast();
  final List<SpeechDecodeJob> _queue = <SpeechDecodeJob>[];
  final Set<int> _vadHandles = <int>{};
  SpeechEngineState _state = SpeechEngineState.idle;
  SpeechWorkerChannelWeb? _decode;
  Future<Result<SpeechWorkerChannelWeb>>? _decodeOpening;
  SpeechWorkerChannelWeb? _vad;
  Future<Result<SpeechWorkerChannelWeb>>? _vadOpening;
  Future<void>? _reviving;
  SpeechDecodeJob? _inFlight;

  /// The model to keep loaded, with the threads the caller asked for.
  ({SpeechModelSource source, int threads})? _wanted;

  /// The decode worker's handle of the loaded model.
  int? _model;
  SpeechLoadReport? _loaded;
  int _nextJobId = 0;
  int _restarts = 0;

  /// The variant the decode worker asks for: `auto` until the threaded one
  /// failed to start here.
  String _decodeVariant = SpeechWorkerCodec.variantAuto;
  bool _disposed = false;

  @override
  SpeechLoadReport? get loaded => _loaded;

  @override
  Stream<SpeechEngineState> get states => _states.stream;

  @override
  int get debugLiveHandles => (_decode?.objects ?? 0) + (_vad?.objects ?? 0);

  @override
  Future<Result<SpeechRuntimeFacts>> probe() async {
    if (_disposed) {
      return FailureResult<SpeechRuntimeFacts>(speechEngineStopped());
    }
    final bool workers = _workerConstructor != null;
    final bool simd = _simdSupported();
    final _Navigator? navigator = _navigator;
    final double? gibibytes = navigator?.deviceMemory?.toDartDouble;
    final bool available = workers && simd;
    return Success<SpeechRuntimeFacts>(
      SpeechRuntimeFacts(
        available: available,
        unavailableReason: !workers
            ? SpeechUnavailableReason.platform
            : (simd ? null : SpeechUnavailableReason.simd),
        abiVersion: available ? _abiVersion : null,
        cpuFeatures: <SpeechCpuFeature>{if (simd) SpeechCpuFeature.wasmSimd},
        is64Bit: false,
        totalMemoryBytes: gibibytes == null
            ? null
            : (gibibytes * _bytesPerGibibyte).round(),
        logicalCores: navigator?.hardwareConcurrency?.toDartDouble.toInt() ?? 0,
        // Isolation allows threads, but the threaded worker may still fail
        // to start its pool and fall back to one thread: once the decode
        // worker runs, its variant decides.
        webThreads:
            (_crossOriginIsolated?.toDart ?? false) &&
            _sharedArrayBuffer != null &&
            _decodeVariant != SpeechWorkerCodec.variantSingle &&
            (_decode?.threaded ?? true),
        webSimd: simd,
      ),
    );
  }

  @override
  Future<Result<SpeechLoadReport>> load(
    SpeechModelSource model, {
    required int threads,
    CancellationToken? cancel,
  }) async {
    if (_disposed) {
      return FailureResult<SpeechLoadReport>(speechEngineStopped());
    }
    if (threads < 1 || model.entry.kind != SpeechModelKind.whisper) {
      return _refused<SpeechLoadReport>('load refused: invalid request');
    }
    final Result<Map<String, Object?>> checked = SpeechWorkerCodec.loadModel(
      model,
      threads: threads,
      base: Uri.base,
    );
    if (checked case FailureResult<Map<String, Object?>>(:final failure)) {
      Logger.current.warn(_logTag, 'load refused: ${failure.runtimeType}');
      return FailureResult<SpeechLoadReport>(failure);
    }
    // A worker restarting to reopen the model finishes first, so the two
    // never open a model each.
    await _reviving;
    final SpeechLoadReport? current = _loaded;
    final SpeechWorkerChannelWeb? running = _decode;
    if (current != null &&
        current.model.id == model.entry.id &&
        _wanted?.threads == threads &&
        _model != null &&
        running != null &&
        running.isOpen) {
      return Success<SpeechLoadReport>(current);
    }
    final SpeechWorkerChannelWeb channel;
    switch (await _decodeChannel()) {
      case FailureResult<SpeechWorkerChannelWeb>(:final Failure failure):
        return FailureResult<SpeechLoadReport>(failure);
      case Success<SpeechWorkerChannelWeb>(
        value: final SpeechWorkerChannelWeb opened,
      ):
        channel = opened;
    }
    _loaded = null;
    _wanted = null;
    _setState(SpeechEngineState.loading);
    await _closeModel(channel);
    final int effective = channel.threadsFor(threads);
    final Result<_Opened> opened = await _openModel(channel, model, effective);
    final Logger logger = Logger.current;
    switch (opened) {
      case FailureResult<_Opened>(:final Failure failure):
        logger.warn(_logTag, 'load failed: ${failure.runtimeType}');
        _settleState(channel, SpeechEngineState.ready);
        return FailureResult<SpeechLoadReport>(
          _disposed ? speechEngineStopped() : failure,
        );
      case Success<_Opened>(value: final _Opened done):
        if (_disposed) {
          return FailureResult<SpeechLoadReport>(speechEngineStopped());
        }
        if (cancel?.isCancelled ?? false) {
          await channel.send(SpeechWorkerCodec.close(handle: done.handle));
          await _refreshObjects(channel);
          _settleState(channel, SpeechEngineState.ready);
          return FailureResult<SpeechLoadReport>(speechCancelled());
        }
        _model = done.handle;
        _wanted = (source: model, threads: threads);
        final SpeechLoadReport report = SpeechLoadReport(
          model: model.entry,
          shape: done.shape,
          threads: effective,
          loadTime: done.loadTime,
        );
        _loaded = report;
        await _refreshObjects(channel);
        _settleState(channel, SpeechEngineState.loaded);
        final String modelId = model.entry.id;
        final int elapsedMs = done.loadTime.inMilliseconds;
        logger.info(
          _logTag,
          'model $modelId loaded in ${elapsedMs}ms with $effective threads '
          'on ${channel.variant}',
        );
        return Success<SpeechLoadReport>(report);
    }
  }

  @override
  Future<Result<SpeechVadHandle>> openVad(SpeechModelSource vad) async {
    if (_disposed) {
      return FailureResult<SpeechVadHandle>(speechEngineStopped());
    }
    if (vad.entry.kind != SpeechModelKind.vad) {
      return _refused<SpeechVadHandle>('voice detector refused: not a VAD');
    }
    final Result<Map<String, Object?>> request = SpeechWorkerCodec.loadModel(
      vad,
      threads: 1,
      base: Uri.base,
    );
    if (request case FailureResult<Map<String, Object?>>(:final failure)) {
      return FailureResult<SpeechVadHandle>(failure);
    }
    final SpeechWorkerChannelWeb channel;
    switch (await _vadChannel()) {
      case FailureResult<SpeechWorkerChannelWeb>(:final Failure failure):
        return FailureResult<SpeechVadHandle>(failure);
      case Success<SpeechWorkerChannelWeb>(
        value: final SpeechWorkerChannelWeb opened,
      ):
        channel = opened;
    }
    final _Answer answer = await channel.send(
      (request as Success<Map<String, Object?>>).value,
    );
    final Result<({int handle, int windowSamples})> opened = answer.result
        .flatMap(SpeechWorkerCodec.decodeVad);
    await _refreshObjects(channel);
    switch (opened) {
      case FailureResult<({int handle, int windowSamples})>(:final failure):
        return FailureResult<SpeechVadHandle>(failure);
      case Success<({int handle, int windowSamples})>(:final value):
        _vadHandles.add(value.handle);
        return Success<SpeechVadHandle>(
          SpeechVadHandle(id: value.handle, frameSamples: value.windowSamples),
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
      // Only the threaded variant can stop a running interim; the single
      // thread one lets it finish, because it is short.
      final SpeechDecodeJob? running = _inFlight;
      if (running != null && !running.committed && _threaded) {
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
      return FailureResult<SpeechVadResult>(speechEngineStopped());
    }
    if (vad.frameSamples < 1 || samples.length % vad.frameSamples != 0) {
      return _refused<SpeechVadResult>('voice batch refused: partial frame');
    }
    final SpeechWorkerChannelWeb? channel = _vad;
    if (channel == null || !channel.isOpen || !_vadHandles.contains(vad.id)) {
      return FailureResult<SpeechVadResult>(speechEngineStopped());
    }
    if (samples.isEmpty) {
      return Success<SpeechVadResult>(
        SpeechVadResult(
          probabilities: Float32List(0),
          frameSamples: vad.frameSamples,
        ),
      );
    }
    if (cancel?.isCancelled ?? false) {
      return FailureResult<SpeechVadResult>(speechCancelled());
    }
    // The worker serves requests in order, so a reset sent first applies
    // before the feed without a second round trip.
    final Future<_Answer>? reset = resetState
        ? channel.send(SpeechWorkerCodec.vadReset(handle: vad.id))
        : null;
    final Future<_Answer> feed = channel.send(
      SpeechWorkerCodec.vadFeed(handle: vad.id, samples: samples),
    );
    final Future<Result<Float32List>> work = () async {
      final _Answer? cleared = await reset;
      if (cleared?.result case FailureResult<Map<Object?, Object?>>(
        :final failure,
      )) {
        return FailureResult<Float32List>(failure);
      }
      return (await feed).result.flatMap(
        (Map<Object?, Object?> result) => SpeechWorkerCodec.decodeProbabilities(
          result,
          frames: samples.length ~/ vad.frameSamples,
        ),
      );
    }();
    final Result<Float32List> probabilities = cancel == null
        ? await work
        : await cancel.race(
            work,
            onCancel: () => FailureResult<Float32List>(speechCancelled()),
          );
    return switch (probabilities) {
      FailureResult<Float32List>(:final Failure failure) =>
        FailureResult<SpeechVadResult>(failure),
      Success<Float32List>(value: final Float32List values) =>
        Success<SpeechVadResult>(
          SpeechVadResult(
            probabilities: values,
            frameSamples: vad.frameSamples,
          ),
        ),
    };
  }

  @override
  Future<void> closeVad(SpeechVadHandle vad) async {
    final SpeechWorkerChannelWeb? channel = _vad;
    if (!_vadHandles.remove(vad.id) || channel == null || !channel.isOpen) {
      return;
    }
    await channel.send(SpeechWorkerCodec.close(handle: vad.id));
    await _refreshObjects(channel);
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
      return FailureResult<void>(speechEngineStopped());
    }
    _loaded = null;
    _wanted = null;
    _failQueue(speechCancelled());
    final SpeechWorkerChannelWeb? channel = _decode;
    if (channel == null || !channel.isOpen) {
      _model = null;
      return const Success<void>(null);
    }
    final SpeechDecodeJob? running = _inFlight;
    if (running != null) {
      _abort(running);
    }
    if (!channel.isOpen) {
      // A single-thread worker was stopped to abort a final: the model went
      // with it.
      _setState(SpeechEngineState.ready);
      return const Success<void>(null);
    }
    _setState(SpeechEngineState.unloading);
    await _closeModel(channel);
    _settleState(channel, SpeechEngineState.ready);
    return const Success<void>(null);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _loaded = null;
    _wanted = null;
    _failQueue(speechEngineStopped());
    await _decodeOpening;
    await _vadOpening;
    final SpeechWorkerChannelWeb? decode = _decode;
    final SpeechWorkerChannelWeb? vad = _vad;
    _decode = null;
    _vad = null;
    _model = null;
    _vadHandles.clear();
    decode?.abortThrough(_allJobs);
    decode?.terminate(speechEngineStopped());
    vad?.terminate(speechEngineStopped());
    _setState(SpeechEngineState.disposed);
    await _states.close();
  }

  /// The settings check of [entry]'s cached copy, on the detector worker so
  /// it never waits behind a decode.
  Future<Result<({bool present, bool ok})>> _verifyCached(
    SpeechModelEntry entry,
  ) async {
    if (_disposed) {
      return FailureResult<({bool present, bool ok})>(speechEngineStopped());
    }
    switch (await _vadChannel()) {
      case FailureResult<SpeechWorkerChannelWeb>(:final Failure failure):
        return FailureResult<({bool present, bool ok})>(failure);
      case Success<SpeechWorkerChannelWeb>(
        value: final SpeechWorkerChannelWeb channel,
      ):
        final _Answer answer = await channel.send(
          SpeechWorkerCodec.verify(entry),
        );
        return answer.result.flatMap(SpeechWorkerCodec.decodeVerify);
    }
  }

  bool get _threaded => _decode?.threaded ?? false;

  /// The running decode worker, starting it (or restarting it after it
  /// failed, within the restart budget) when there is none.
  Future<Result<SpeechWorkerChannelWeb>> _decodeChannel() {
    final SpeechWorkerChannelWeb? channel = _decode;
    if (channel != null && channel.isOpen) {
      return Future<Result<SpeechWorkerChannelWeb>>.value(
        Success<SpeechWorkerChannelWeb>(channel),
      );
    }
    return _decodeOpening ??= _openDecode().whenComplete(
      () => _decodeOpening = null,
    );
  }

  Future<Result<SpeechWorkerChannelWeb>> _openDecode() async {
    final SpeechEngineState before = _state;
    if (before == SpeechEngineState.failed) {
      if (_restarts >= AppConstants.speechEngine.maxWorkerRestarts) {
        return FailureResult<SpeechWorkerChannelWeb>(speechEngineStopped());
      }
      _restarts++;
    }
    _setState(SpeechEngineState.starting);
    final Stopwatch watch = Stopwatch()..start();
    Result<SpeechWorkerChannelWeb> opened = await SpeechWorkerChannelWeb.open(
      variant: _decodeVariant,
      onLog: _onLog,
      onCrash: _onDecodeCrash,
    );
    if (opened is FailureResult<SpeechWorkerChannelWeb> &&
        _decodeVariant != SpeechWorkerCodec.variantSingle &&
        !_disposed) {
      // A browser that is cross-origin isolated but cannot start the
      // threaded variant's nested workers never answers `init`: fall back
      // to the single-thread variant, and keep it for later restarts.
      Logger.current.warn(_logTag, 'threaded worker failed; single thread');
      _decodeVariant = SpeechWorkerCodec.variantSingle;
      opened = await SpeechWorkerChannelWeb.open(
        variant: _decodeVariant,
        onLog: _onLog,
        onCrash: _onDecodeCrash,
      );
    }
    switch (opened) {
      case FailureResult<SpeechWorkerChannelWeb>(:final Failure failure):
        _setState(
          before == SpeechEngineState.failed ? before : SpeechEngineState.idle,
        );
        Logger.current.warn(
          _logTag,
          'decode worker did not start: ${failure.runtimeType}',
        );
        return opened;
      case Success<SpeechWorkerChannelWeb>(
        value: final SpeechWorkerChannelWeb channel,
      ):
        if (_disposed) {
          channel.terminate(speechEngineStopped());
          return FailureResult<SpeechWorkerChannelWeb>(speechEngineStopped());
        }
        _decode = channel;
        _setState(SpeechEngineState.ready);
        final int elapsedMs = watch.elapsedMilliseconds;
        Logger.current.info(
          _logTag,
          'decode worker (${channel.variant}) started in ${elapsedMs}ms',
        );
        return opened;
    }
  }

  /// The running detector worker, started once; a failed one starts again.
  Future<Result<SpeechWorkerChannelWeb>> _vadChannel() {
    final SpeechWorkerChannelWeb? channel = _vad;
    if (channel != null && channel.isOpen) {
      return Future<Result<SpeechWorkerChannelWeb>>.value(
        Success<SpeechWorkerChannelWeb>(channel),
      );
    }
    return _vadOpening ??= _openVad().whenComplete(() => _vadOpening = null);
  }

  Future<Result<SpeechWorkerChannelWeb>> _openVad() async {
    final Result<SpeechWorkerChannelWeb> opened =
        await SpeechWorkerChannelWeb.open(
          variant: SpeechWorkerCodec.variantSingle,
          onLog: _onLog,
          onCrash: _onVadCrash,
        );
    if (opened case Success<SpeechWorkerChannelWeb>(
      value: final SpeechWorkerChannelWeb channel,
    )) {
      if (_disposed) {
        channel.terminate(speechEngineStopped());
        return FailureResult<SpeechWorkerChannelWeb>(speechEngineStopped());
      }
      _vad = channel;
    }
    return opened;
  }

  /// Opens [source] in [channel] with [threads] and checks its shape; a
  /// model of the wrong shape is closed again.
  Future<Result<_Opened>> _openModel(
    SpeechWorkerChannelWeb channel,
    SpeechModelSource source,
    int threads,
  ) async {
    final Stopwatch watch = Stopwatch()..start();
    final Result<Map<String, Object?>> request = SpeechWorkerCodec.loadModel(
      source,
      threads: threads,
      base: Uri.base,
    );
    if (request case FailureResult<Map<String, Object?>>(:final failure)) {
      return FailureResult<_Opened>(failure);
    }
    final _Answer answer = await channel.send(
      (request as Success<Map<String, Object?>>).value,
    );
    final Map<Object?, Object?> result;
    switch (answer.result) {
      case FailureResult<Map<Object?, Object?>>(:final Failure failure):
        return FailureResult<_Opened>(failure);
      case Success<Map<Object?, Object?>>(:final Map<Object?, Object?> value):
        result = value;
    }
    final Result<({int handle, SpeechModelShape shape, String servedFrom})>
    decoded = SpeechWorkerCodec.decodeModel(result, source.entry);
    switch (decoded) {
      case FailureResult<
        ({int handle, SpeechModelShape shape, String servedFrom})
      >(
        :final Failure failure,
      ):
        // A model of the wrong shape is open; close it again.
        final int? handle = SpeechWorkerCodec.handleOf(result);
        if (handle != null) {
          await channel.send(SpeechWorkerCodec.close(handle: handle));
        }
        return FailureResult<_Opened>(failure);
      case Success<({int handle, SpeechModelShape shape, String servedFrom})>(
        value: (
          :final int handle,
          :final SpeechModelShape shape,
          :final String servedFrom,
        ),
      ):
        Logger.current.info(_logTag, 'model bytes served from $servedFrom');
        return Success<_Opened>((
          handle: handle,
          shape: shape,
          loadTime: watch.elapsed,
        ));
    }
  }

  /// Closes the loaded model in [channel], if there is one.
  Future<void> _closeModel(SpeechWorkerChannelWeb channel) async {
    final int? model = _model;
    _model = null;
    if (model != null && channel.isOpen) {
      await channel.send(SpeechWorkerCodec.close(handle: model));
      await _refreshObjects(channel);
    }
  }

  /// Sends the next job when none is in flight: committed requests first,
  /// in arrival order, then interims. A decode worker stopped to abort a
  /// final is started again first, reopening the model from the browser
  /// cache.
  void _pump() {
    if (_inFlight != null || _queue.isEmpty || _reviving != null) {
      return;
    }
    if (_loaded == null) {
      _failQueue(speechUnavailable());
      return;
    }
    final SpeechWorkerChannelWeb? channel = _decode;
    final int? model = _model;
    if (channel == null || !channel.isOpen || model == null) {
      _revive();
      return;
    }
    final SpeechDecodeJob job = _queue.firstWhere(
      (SpeechDecodeJob waiting) => waiting.committed,
      orElse: () => _queue.first,
    );
    _queue.remove(job);
    job.jobId = ++_nextJobId;
    _inFlight = job;
    _setState(SpeechEngineState.busy);
    unawaited(_dispatch(channel, model, job));
  }

  /// Restarts the decode worker and reopens the wanted model, then pumps.
  void _revive() {
    final ({SpeechModelSource source, int threads})? wanted = _wanted;
    if (wanted == null) {
      _loaded = null;
      _failQueue(speechUnavailable());
      return;
    }
    _reviving = _reopenWanted(wanted).whenComplete(() {
      _reviving = null;
      _pump();
    });
  }

  Future<void> _reopenWanted(
    ({SpeechModelSource source, int threads}) wanted,
  ) async {
    final Result<_Opened> opened = switch (await _decodeChannel()) {
      FailureResult<SpeechWorkerChannelWeb>(:final Failure failure) =>
        FailureResult<_Opened>(failure),
      Success<SpeechWorkerChannelWeb>(
        value: final SpeechWorkerChannelWeb channel,
      ) =>
        await _openModel(
          channel,
          wanted.source,
          channel.threadsFor(wanted.threads),
        ),
    };
    final SpeechWorkerChannelWeb? channel = _decode;
    switch (opened) {
      case FailureResult<_Opened>(:final Failure failure):
        Logger.current.warn(
          _logTag,
          'model reopen failed: ${failure.runtimeType}',
        );
        _loaded = null;
        _wanted = null;
        _failQueue(failure);
        if (!_disposed) {
          _setState(SpeechEngineState.ready);
        }
      case Success<_Opened>() when _disposed || channel == null:
        break;
      case Success<_Opened>(value: final _Opened done)
          when !identical(_wanted, wanted):
        // Unloaded or replaced meanwhile: this copy is not wanted.
        await channel!.send(SpeechWorkerCodec.close(handle: done.handle));
      case Success<_Opened>(value: final _Opened done):
        _model = done.handle;
        await _refreshObjects(channel!);
        _setState(SpeechEngineState.loaded);
    }
  }

  Future<void> _dispatch(
    SpeechWorkerChannelWeb channel,
    int model,
    SpeechDecodeJob job,
  ) async {
    _Answer answer = await channel.send(_transcribe(job, model));
    if (answer.code == _poisoned && !job.aborted && channel.isOpen) {
      // whisper lost the context's state: close it, reopen the same model
      // from the browser cache and retry once (spec §30.4.4).
      final int? reopened = await _reopen(channel);
      if (reopened != null && !job.aborted) {
        job.jobId = ++_nextJobId;
        answer = await channel.send(_transcribe(job, reopened));
      }
    }
    if (identical(_inFlight, job)) {
      _inFlight = null;
    }
    job.finish(
      job.aborted
          ? FailureResult<SpeechDecodeResult>(speechCancelled())
          : answer.result.flatMap(
              (Map<Object?, Object?> result) =>
                  SpeechWorkerCodec.decodeTranscript(result, job.request),
            ),
    );
    if (!_disposed && _state == SpeechEngineState.busy && _queue.isEmpty) {
      _setState(
        _loaded == null ? SpeechEngineState.ready : SpeechEngineState.loaded,
      );
    }
    _pump();
  }

  Map<String, Object?> _transcribe(SpeechDecodeJob job, int model) =>
      SpeechWorkerCodec.transcribe(
        job.request,
        handle: model,
        jobId: job.jobId,
        leaseId: job.leaseId,
        threads: _loaded?.threads ?? 1,
      );

  /// Replaces the poisoned model with a fresh one from the browser cache;
  /// null when that failed.
  Future<int?> _reopen(SpeechWorkerChannelWeb channel) async {
    final ({SpeechModelSource source, int threads})? wanted = _wanted;
    await _closeModel(channel);
    if (wanted == null || !channel.isOpen) {
      return null;
    }
    await _reopenWanted(wanted);
    return identical(_decode, channel) ? _model : null;
  }

  void _cancel(SpeechDecodeJob job) {
    if (_queue.remove(job)) {
      job.finish(FailureResult<SpeechDecodeResult>(speechCancelled()));
    } else if (identical(_inFlight, job)) {
      _abort(job);
    }
  }

  /// Aborts the in-flight [job]. The threaded variant stores its id in the
  /// shared abort cell. The single-thread variant cannot be interrupted: a
  /// final is stopped by terminating the worker (the next decode restarts
  /// it from the browser cache), and an interim is left to finish, its
  /// result discarded.
  void _abort(SpeechDecodeJob job) {
    if (job.aborted) {
      return;
    }
    job.aborted = true;
    final SpeechWorkerChannelWeb? channel = _decode;
    if (channel != null && channel.threaded) {
      channel.abortThrough(job.jobId);
      return;
    }
    if (job.committed) {
      _terminateDecode();
    } else {
      job.finish(FailureResult<SpeechDecodeResult>(speechCancelled()));
    }
  }

  /// Stops the single-thread decode worker to abort a running final, which
  /// fails with `CancelledFailure`. The model stays wanted: other leases'
  /// pending jobs wait while the next pump restarts the worker and reopens
  /// the model from the browser cache, so one lease's abort never cancels
  /// another's work.
  void _terminateDecode() {
    final SpeechWorkerChannelWeb? channel = _decode;
    if (channel == null) {
      return;
    }
    _decode = null;
    _model = null;
    channel.terminate(speechCancelled());
    Logger.current.info(_logTag, 'decode worker stopped to abort a final');
  }

  void _onDecodeCrash(SpeechWorkerChannelWeb channel) {
    if (!identical(_decode, channel)) {
      return;
    }
    _decode = null;
    _model = null;
    _loaded = null;
    _wanted = null;
    _failQueue(speechEngineStopped());
    Logger.current.warn(_logTag, 'decode worker failed unexpectedly');
    if (!_disposed) {
      _setState(SpeechEngineState.failed);
    }
  }

  void _onVadCrash(SpeechWorkerChannelWeb channel) {
    if (!identical(_vad, channel)) {
      return;
    }
    _vad = null;
    _vadHandles.clear();
    Logger.current.warn(_logTag, 'voice worker failed unexpectedly');
  }

  void _onLog(List<({int level, String line})> lines) {
    final Logger logger = Logger.current;
    for (final ({int level, String line}) native in lines) {
      final String line = native.line;
      if (native.level >= _errorLevel) {
        logger.error(_logTag, line);
      } else {
        logger.warn(_logTag, line);
      }
    }
  }

  /// Reads how many engine objects [channel]'s worker holds.
  Future<void> _refreshObjects(SpeechWorkerChannelWeb channel) async {
    if (!channel.isOpen) {
      return;
    }
    final _Answer answer = await channel.send(SpeechWorkerCodec.liveObjects());
    if (answer.result.flatMap(SpeechWorkerCodec.decodeLiveObjects)
        case Success<int>(:final int value)) {
      channel.objects = value;
    }
  }

  void _failQueue(Failure failure) {
    final List<SpeechDecodeJob> waiting = _queue.toList();
    _queue.clear();
    for (final SpeechDecodeJob job in waiting) {
      job.finish(FailureResult<SpeechDecodeResult>(failure));
    }
  }

  /// Moves to [state] unless [channel] was replaced or the engine is gone.
  void _settleState(SpeechWorkerChannelWeb channel, SpeechEngineState state) {
    if (identical(_decode, channel) && channel.isOpen && !_disposed) {
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

/// The worker error code of a context that lost its state.
const String _poisoned = 'poisoned';

bool _simdSupported() {
  try {
    return _WebAssembly.validate(Uint8List.fromList(_simdProbe).toJS);
  } on Object {
    return false;
  }
}

// JavaScript interop for the probe: reading what the browser offers.

@JS('WebAssembly')
extension type _WebAssembly._(JSObject _) implements JSObject {
  external static bool validate(JSUint8Array bytes);
}

extension type _Navigator._(JSObject _) implements JSObject {
  external JSNumber? get hardwareConcurrency;
  external JSNumber? get deviceMemory;
}

@JS('navigator')
external _Navigator? get _navigator;

@JS('crossOriginIsolated')
external JSBoolean? get _crossOriginIsolated;

@JS('SharedArrayBuffer')
external JSAny? get _sharedArrayBuffer;

@JS('Worker')
external JSAny? get _workerConstructor;
