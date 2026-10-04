import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/result.dart';

import 'speech_abort_cell.dart';
import 'speech_decode_request.dart';
import 'speech_decode_result.dart';
import 'speech_engine_state.dart';
import 'speech_engine_stub.dart'
    if (dart.library.io) 'speech_engine_io.dart'
    if (dart.library.js_interop) 'speech_engine_web.dart'
    as platform;
import 'speech_failures.dart';
import 'speech_load_report.dart';
import 'speech_model_source.dart';
import 'speech_native_api.dart';
import 'speech_runtime_facts.dart';
import 'speech_unavailable_reason.dart';
import 'speech_vad_handle.dart';
import 'speech_vad_result.dart';

/// Offline speech recognition on this device (FE-STR-11, spec §30.4.2).
///
/// One engine per app: the model is loaded once and shared by every lease.
/// Each lease decodes under its own `leaseId` and opens its own voice
/// detector, so neither queue position nor detector state crosses from one
/// session into another. Every operation returns a typed failure, never a
/// throw (spec §30.4.4).
abstract interface class SpeechEngine {
  /// The engine this platform runs: native worker isolates on a device and
  /// Web Workers in a browser; [SpeechEngine.unavailable] elsewhere.
  ///
  /// Tests may load the library from [libraryPath], and may replace the
  /// native library behind the workers with [openApi] and the main
  /// isolate's abort cell with [openAbortCell].
  factory SpeechEngine.platform({
    @visibleForTesting String? libraryPath,
    @visibleForTesting SpeechNativeApi Function(String? libraryPath)? openApi,
    @visibleForTesting
    SpeechAbortCell Function(String? libraryPath)? openAbortCell,
  }) => platform.createSpeechEngine(
    libraryPath: libraryPath,
    openApi: openApi,
    openAbortCell: openAbortCell,
  );

  /// A stand-in that cannot transcribe, and the provider default
  /// (FE-TEST-03). Every operation fails with `speechUnavailable()`.
  const factory SpeechEngine.unavailable() = _UnavailableSpeechEngine;

  /// What the runtime offers (processor features, memory, cores, versions,
  /// browser threads and SIMD) without loading a model or starting a
  /// worker.
  Future<Result<SpeechRuntimeFacts>> probe();

  /// Verifies [model] by size and SHA-256 and loads it with [threads].
  /// Loading the model already loaded succeeds without work; another model
  /// replaces it.
  Future<Result<SpeechLoadReport>> load(
    SpeechModelSource model, {
    required int threads,
    CancellationToken? cancel,
  });

  /// Opens one voice detector for one lease from [vad].
  Future<Result<SpeechVadHandle>> openVad(SpeechModelSource vad);

  /// Transcribes one window for lease [leaseId]. One decode is in flight at
  /// a time. A newer interim replaces the same lease's pending interim, a
  /// committed request preempts an in-flight interim of any lease, and
  /// committed requests run in arrival order and are never dropped. A
  /// superseded or cancelled request fails with `CancelledFailure`.
  Future<Result<SpeechDecodeResult>> decode(
    SpeechDecodeRequest request, {
    required int leaseId,
    CancellationToken? cancel,
  });

  /// One speech probability per frame of [samples] on detector [vad].
  /// [samples] must hold a whole number of `vad.frameSamples` frames.
  /// [resetState] clears the detector's running state first.
  Future<Result<SpeechVadResult>> detectSpeech(
    SpeechVadHandle vad,
    Float32List samples, {
    bool resetState = false,
    CancellationToken? cancel,
  });

  /// Frees detector [vad]. Closing one already closed does nothing.
  Future<void> closeVad(SpeechVadHandle vad);

  /// Removes every pending job of lease [leaseId] and aborts its in-flight
  /// job; other leases' jobs are untouched. Synchronous.
  void abortLease(int leaseId);

  /// Frees the loaded model but keeps the workers.
  Future<Result<void>> unload();

  /// Frees everything, stops the workers and refuses every later call.
  Future<void> dispose();

  /// The loaded model, or null.
  SpeechLoadReport? get loaded;

  /// Lifecycle for the host and diagnostics. A broadcast stream.
  Stream<SpeechEngineState> get states;

  /// Engine handles alive process-wide (models, detectors, results), for
  /// leak tests.
  @visibleForTesting
  int get debugLiveHandles;
}

/// Points the native engine's record of a fatal abort at the file [path],
/// creating its folder, and returns how many lines the file already holds:
/// one per earlier fatal abort, kept for diagnostics only (the crash-loop
/// decision is the host's load marker). Null where no native engine runs,
/// as in a browser, or when the library cannot be opened.
Future<int?> recordSpeechCrashes(String path) =>
    platform.recordSpeechCrashes(path);

/// The app's speech engine. The stand-in until `main` overrides it with
/// [SpeechEngine.platform]. Kept alive: one engine and one loaded model per
/// process (FE-STATE-09).
final Provider<SpeechEngine> speechEngineProvider = Provider<SpeechEngine>((
  Ref _,
) {
  return const SpeechEngine.unavailable();
});

final class _UnavailableSpeechEngine implements SpeechEngine {
  const _UnavailableSpeechEngine();

  static Future<Result<T>> _refuse<T>() =>
      Future<Result<T>>.value(FailureResult<T>(speechUnavailable()));

  @override
  Future<Result<SpeechRuntimeFacts>> probe() {
    return Future<Result<SpeechRuntimeFacts>>.value(
      const Success<SpeechRuntimeFacts>(
        SpeechRuntimeFacts(
          available: false,
          unavailableReason: SpeechUnavailableReason.platform,
          is64Bit: false,
          logicalCores: 0,
        ),
      ),
    );
  }

  @override
  Future<Result<SpeechLoadReport>> load(
    SpeechModelSource model, {
    required int threads,
    CancellationToken? cancel,
  }) => _refuse<SpeechLoadReport>();

  @override
  Future<Result<SpeechVadHandle>> openVad(SpeechModelSource vad) =>
      _refuse<SpeechVadHandle>();

  @override
  Future<Result<SpeechDecodeResult>> decode(
    SpeechDecodeRequest request, {
    required int leaseId,
    CancellationToken? cancel,
  }) => _refuse<SpeechDecodeResult>();

  @override
  Future<Result<SpeechVadResult>> detectSpeech(
    SpeechVadHandle vad,
    Float32List samples, {
    bool resetState = false,
    CancellationToken? cancel,
  }) => _refuse<SpeechVadResult>();

  @override
  Future<void> closeVad(SpeechVadHandle vad) async {}

  @override
  void abortLease(int leaseId) {}

  @override
  Future<Result<void>> unload() => _refuse<void>();

  @override
  Future<void> dispose() async {}

  @override
  SpeechLoadReport? get loaded => null;

  @override
  Stream<SpeechEngineState> get states =>
      const Stream<SpeechEngineState>.empty();

  @override
  int get debugLiveHandles => 0;
}
