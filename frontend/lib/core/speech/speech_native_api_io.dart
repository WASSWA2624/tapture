import 'dart:ffi' show IntPtr, sizeOf;
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture_whisper/tapture_whisper.dart';

import 'speech_abort_cell.dart';
import 'speech_cpu_feature.dart';
import 'speech_decode_profile.dart';
import 'speech_decode_request.dart';
import 'speech_decode_result.dart';
import 'speech_failures.dart';
import 'speech_model_shape.dart';
import 'speech_native_api.dart';
import 'speech_piece.dart';
import 'speech_piece_text.dart';
import 'speech_runtime_facts.dart';
import 'speech_segment.dart';
import 'speech_unavailable_reason.dart';

// The only importer of package:tapture_whisper (FE-STR-11). Everything the
// engine needs from the library goes through SpeechNativeApi on a worker, or
// through SpeechAbortCell on the main isolate.

/// Opens the whisper library at [libraryPath] (the platform's own candidates
/// when null) for the calling isolate. Never throws: a library that cannot
/// be opened gives an API whose [SpeechNativeApi.facts] says why and whose
/// other calls fail with the matching failure.
SpeechNativeApi openSpeechNativeApi(String? libraryPath) {
  return switch (WhisperLibrary.open(path: libraryPath)) {
    WhisperLibraryLoaded(:final WhisperLibrary library) => _WhisperNativeApi(
      library,
    ),
    WhisperLibraryUnavailable(:final WhisperUnavailableReason reason) =>
      _UnavailableNativeApi(reason),
  };
}

/// Creates the main isolate's abort cell in the library at [libraryPath].
/// Throws `speechUnavailable()` or `speechDeviceUnsupported()` when the
/// library cannot be opened. The library is opened once per path.
SpeechAbortCell openSpeechAbortCell(String? libraryPath) {
  WhisperLibrary? library = _cellLibraries[libraryPath];
  if (library == null) {
    switch (WhisperLibrary.open(path: libraryPath)) {
      case WhisperLibraryLoaded(library: final WhisperLibrary opened):
        library = opened;
        _cellLibraries[libraryPath] = opened;
      case WhisperLibraryUnavailable(:final WhisperUnavailableReason reason):
        throw _unavailable(reason);
    }
  }
  try {
    return _WhisperAbortCell(library.newCell());
  } on WhisperNativeException catch (error) {
    throw _failureFor(error.status);
  }
}

/// Points the fatal-abort record of the library at [libraryPath] (the
/// platform's own when null) at the file [path]. The setting is
/// process-wide. False when the library cannot be opened or refuses.
bool armSpeechCrashFile(String path, {String? libraryPath}) {
  WhisperLibrary? library = _cellLibraries[libraryPath];
  if (library == null) {
    switch (WhisperLibrary.open(path: libraryPath)) {
      case WhisperLibraryLoaded(library: final WhisperLibrary opened):
        library = opened;
        _cellLibraries[libraryPath] = opened;
      case WhisperLibraryUnavailable():
        return false;
    }
  }
  try {
    library.setCrashFile(path);
    return true;
  } on WhisperNativeException {
    return false;
  }
}

/// Libraries the main isolate opened for its abort cells, by path.
final Map<String?, WhisperLibrary> _cellLibraries = <String?, WhisperLibrary>{};

/// The failure for a library that could not be opened.
Failure _unavailable(WhisperUnavailableReason reason) => switch (reason) {
  WhisperUnavailableReason.unsupportedCpu ||
  WhisperUnavailableReason.engineNotBuilt => speechDeviceUnsupported(),
  WhisperUnavailableReason.unsupportedPlatform ||
  WhisperUnavailableReason.libraryMissing ||
  WhisperUnavailableReason.abiMismatch => speechUnavailable(),
};

/// The failure for a native refusal (spec §30.4.4).
Failure _failureFor(WhisperStatus status) => switch (status) {
  WhisperStatus.aborted => speechCancelled(),
  WhisperStatus.modelMismatch ||
  WhisperStatus.modelInvalid => speechModelDamaged(),
  WhisperStatus.fileOpen => speechModelMissing(),
  WhisperStatus.modelLoad || WhisperStatus.outOfMemory => speechLowMemory(),
  WhisperStatus.unsupportedCpu ||
  WhisperStatus.engineNotBuilt => speechDeviceUnsupported(),
  WhisperStatus.abiMismatch => speechUnavailable(),
  WhisperStatus.invalidArgument ||
  WhisperStatus.audioTooLong => speechInvalidRequest(),
  WhisperStatus.ok ||
  WhisperStatus.inference ||
  WhisperStatus.internal ||
  WhisperStatus.busy ||
  WhisperStatus.poisoned => speechTranscriptionFailed(),
};

/// Whether this process runs 64-bit code.
bool get _is64Bit => sizeOf<IntPtr>() == 8;

/// The library's feature bits the engine reports, in [SpeechCpuFeature]
/// terms.
const Map<SpeechCpuFeature, int> _featureBits = <SpeechCpuFeature, int>{
  SpeechCpuFeature.avx: WhisperCpuFacts.avx,
  SpeechCpuFeature.avx2: WhisperCpuFacts.avx2,
  SpeechCpuFeature.fma: WhisperCpuFacts.fma,
  SpeechCpuFeature.f16c: WhisperCpuFacts.f16c,
  SpeechCpuFeature.neon: WhisperCpuFacts.neon,
  SpeechCpuFeature.armFma: WhisperCpuFacts.armFma,
  SpeechCpuFeature.dotProd: WhisperCpuFacts.dotProd,
  SpeechCpuFeature.fp16: WhisperCpuFacts.fp16VectorArithmetic,
  SpeechCpuFeature.wasmSimd: WhisperCpuFacts.wasmSimd,
};

/// A library that could not be opened: it reports why and refuses the rest.
final class _UnavailableNativeApi implements SpeechNativeApi {
  _UnavailableNativeApi(this._reason);

  final WhisperUnavailableReason _reason;

  Never _refuse() => throw _unavailable(_reason);

  @override
  SpeechRuntimeFacts facts() => SpeechRuntimeFacts(
    available: false,
    unavailableReason: switch (_reason) {
      WhisperUnavailableReason.unsupportedPlatform =>
        SpeechUnavailableReason.platform,
      WhisperUnavailableReason.libraryMissing =>
        SpeechUnavailableReason.library,
      WhisperUnavailableReason.abiMismatch => SpeechUnavailableReason.abi,
      WhisperUnavailableReason.unsupportedCpu => SpeechUnavailableReason.cpu,
      WhisperUnavailableReason.engineNotBuilt =>
        SpeechUnavailableReason.engineNotBuilt,
    },
    is64Bit: _is64Bit,
    logicalCores: Platform.numberOfProcessors,
  );

  @override
  int loadModel(
    String path, {
    required int threads,
    required int bytes,
    required String sha256,
  }) => _refuse();

  @override
  SpeechModelShape shape(int model) => _refuse();

  @override
  int loadVad(String path, {required int bytes, required String sha256}) =>
      _refuse();

  @override
  int vadWindow(int vad) => _refuse();

  @override
  SpeechDecodeResult decode(
    int model,
    SpeechDecodeRequest request, {
    required int abortAddress,
    required int jobId,
  }) => _refuse();

  @override
  Float32List detectSpeech(
    int vad,
    Float32List samples, {
    required bool reset,
  }) => _refuse();

  @override
  void release(int handle) {}

  @override
  List<({int level, String line})> drainLog(int max) =>
      const <({int level, String line})>[];

  @override
  int get droppedLogLines => 0;

  @override
  int get liveHandles => 0;

  @override
  void close() {}
}

/// Where a model was opened from, so a poisoned context can be reopened.
typedef _ModelOrigin = ({
  String path,
  int threads,
  WhisperModelExpectation expect,
});

/// The library opened in one worker isolate.
final class _WhisperNativeApi implements SpeechNativeApi {
  _WhisperNativeApi(this._library) {
    _library.logLevel = WhisperLogLevel.warn;
  }

  final WhisperLibrary _library;
  final Map<int, WhisperModel> _models = <int, WhisperModel>{};
  final Map<int, _ModelOrigin> _origins = <int, _ModelOrigin>{};
  final Map<int, WhisperVad> _vads = <int, WhisperVad>{};
  final Map<int, WhisperCell> _cells = <int, WhisperCell>{};
  int _nextHandle = 1;
  bool _closed = false;

  @override
  SpeechRuntimeFacts facts() {
    _open();
    return _guard(() {
      final WhisperCpuFacts cpu = _library.cpuFacts();
      final WhisperMemoryFacts memory = _library.memoryFacts();
      return SpeechRuntimeFacts(
        available: true,
        engineVersion: _library.version,
        abiVersion: _library.abiVersion,
        cpuFeatures: <SpeechCpuFeature>{
          for (final MapEntry<SpeechCpuFeature, int> feature
              in _featureBits.entries)
            if (cpu.has(feature.value)) feature.key,
        },
        is64Bit: _is64Bit,
        totalMemoryBytes: memory.totalBytes,
        availableMemoryBytes: memory.availableBytes,
        processLimitBytes: memory.processLimitBytes,
        logicalCores: cpu.logicalCores,
        performanceCores: cpu.performanceCores > 0
            ? cpu.performanceCores
            : null,
      );
    });
  }

  @override
  int loadModel(
    String path, {
    required int threads,
    required int bytes,
    required String sha256,
  }) {
    _open();
    final _ModelOrigin origin = (
      path: path,
      threads: threads,
      expect: WhisperModelExpectation(bytes: bytes, sha256Hex: sha256),
    );
    final WhisperModel model = _guard(() => _openModel(origin));
    final int handle = _nextHandle++;
    _models[handle] = model;
    _origins[handle] = origin;
    return handle;
  }

  WhisperModel _openModel(_ModelOrigin origin) => _library.openModel(
    origin.path,
    origin.expect,
    options: WhisperContextOptions(threads: origin.threads),
  );

  @override
  SpeechModelShape shape(int model) {
    final WhisperModelFacts facts = _model(model).facts;
    return SpeechModelShape(
      nVocab: facts.nVocab,
      nAudioCtx: facts.nAudioCtx,
      nAudioState: facts.nAudioState,
      nAudioLayer: facts.nAudioLayer,
      nTextLayer: facts.nTextLayer,
      nMels: facts.nMels,
      ftype: facts.ftype % _ftypeVersionStep,
      multilingual: facts.multilingual,
    );
  }

  @override
  int loadVad(String path, {required int bytes, required String sha256}) {
    _open();
    final WhisperVad vad = _guard(
      () => _library.openVad(
        path,
        WhisperModelExpectation(bytes: bytes, sha256Hex: sha256),
      ),
    );
    // whisper allocates the detector's LSTM state without clearing it, so a
    // fresh detector starts from zero only after a reset.
    try {
      _guard(vad.reset);
    } on Failure {
      vad.close();
      rethrow;
    }
    final int handle = _nextHandle++;
    _vads[handle] = vad;
    return handle;
  }

  @override
  int vadWindow(int vad) => _vad(vad).windowSamples;

  @override
  SpeechDecodeResult decode(
    int model,
    SpeechDecodeRequest request, {
    required int abortAddress,
    required int jobId,
  }) {
    _model(model);
    final WhisperDecodeOptions options = _guard(() => _options(request));
    final WhisperCell? cell = abortAddress == 0 ? null : _borrow(abortAddress);
    WhisperTranscript transcribe() => _model(model).transcribe(
      request.samples,
      options,
      initialPrompt: request.prompt.isEmpty ? null : request.prompt,
      abort: cell,
      jobId: jobId,
    );
    try {
      return _result(request, transcribe());
    } on WhisperNativeException catch (error) {
      if (error.status != WhisperStatus.poisoned) {
        throw _failureFor(error.status);
      }
    } on StateError {
      throw speechEngineStopped();
    } on ArgumentError {
      throw speechInvalidRequest();
    }
    _reopen(model);
    return _result(request, _guard(transcribe));
  }

  /// Replaces the poisoned context of [model] with a fresh one from the
  /// same, re-verified file (spec §30.4.4: close, reopen, retry once).
  void _reopen(int model) {
    final _ModelOrigin origin = _origins[model]!;
    _models.remove(model)?.close();
    _models[model] = _guard(() => _openModel(origin));
  }

  @override
  Float32List detectSpeech(
    int vad,
    Float32List samples, {
    required bool reset,
  }) {
    final WhisperVad detector = _vad(vad);
    return _guard(() {
      if (reset) {
        detector.reset();
      }
      return detector.feed(samples);
    });
  }

  @override
  void release(int handle) {
    _origins.remove(handle);
    _models.remove(handle)?.close();
    _vads.remove(handle)?.close();
  }

  @override
  List<({int level, String line})> drainLog(int max) {
    if (_closed) {
      return const <({int level, String line})>[];
    }
    return <({int level, String line})>[
      for (final WhisperLogLine line in _library.drainLog(max: max))
        (level: line.level.code, line: line.message),
    ];
  }

  @override
  int get droppedLogLines => _closed ? 0 : _library.droppedLogLines;

  @override
  int get liveHandles => _models.length + _vads.length;

  @override
  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    for (final int handle in <int>[..._models.keys, ..._vads.keys]) {
      release(handle);
    }
    for (final WhisperCell cell in _cells.values) {
      cell.close();
    }
    _cells.clear();
  }

  void _open() {
    if (_closed) {
      throw speechEngineStopped();
    }
  }

  WhisperModel _model(int handle) {
    _open();
    return _models[handle] ?? (throw speechEngineStopped());
  }

  WhisperVad _vad(int handle) {
    _open();
    return _vads[handle] ?? (throw speechEngineStopped());
  }

  /// This worker's reference to the main isolate's cell at [address],
  /// retained on first use and released by [close].
  WhisperCell _borrow(int address) =>
      _cells[address] ??= _guard(() => _library.borrowCell(address));

  /// The library options for [request]: greedy unless the profile asks for
  /// a beam, never detecting the language, and never carrying context
  /// between windows.
  static WhisperDecodeOptions _options(SpeechDecodeRequest request) {
    final SpeechDecodeProfile profile = request.profile;
    final bool beam = profile.beamSize > 0;
    return WhisperDecodeOptions(
      language: request.language,
      strategy: beam ? WhisperStrategy.beam : WhisperStrategy.greedy,
      threads: profile.threads,
      bestOf: profile.bestOf < 1 ? 1 : profile.bestOf,
      beamSize: beam ? profile.beamSize : 1,
      maxPieces: profile.maxPiecesFor(request.samples.length),
      audioContext: profile.audioContextFor(request.samples.length),
      temperatureIncrement: profile.temperatureStep,
      entropyThreshold: profile.entropyThreshold,
      logProbabilityThreshold: profile.logprobThreshold,
      noSpeechThreshold: profile.noSpeechThreshold,
      singleSegment: profile.singleSegment,
      noTimestamps: !profile.timestamps,
      pieceTimestamps: request.pieceTimings,
      suppressBlank: profile.suppressBlank,
      suppressNonSpeech: profile.suppressNonSpeech,
    );
  }

  /// Copies [decoded] onto the session timeline of [request].
  static SpeechDecodeResult _result(
    SpeechDecodeRequest request,
    WhisperTranscript decoded,
  ) {
    final int offset = request.offsetSamples;
    int at(int milliseconds) =>
        offset +
        milliseconds *
            AppConstants.audio.sampleRate ~/
            Duration.millisecondsPerSecond;
    return SpeechDecodeResult(
      segments: <SpeechSegment>[
        for (final WhisperSegment segment in decoded.segments)
          SpeechSegment(
            startSample: at(segment.startMs),
            endSample: at(segment.endMs),
            text: segment.text,
            noSpeechProbability: segment.noSpeechProbability,
            averageLogProbability: segment.averageLogProbability,
            confidence: segment.meanProbability,
            pieces: request.pieceTimings
                ? SpeechPieceText.group(<
                    ({
                      List<int> bytes,
                      int startSample,
                      int endSample,
                      double probability,
                    })
                  >[
                    for (final WhisperPiece piece in segment.pieces)
                      (
                        bytes: piece.bytes,
                        startSample: at(piece.startMs),
                        endSample: at(piece.endMs),
                        probability: piece.probability,
                      ),
                  ])
                : const <SpeechPiece>[],
          ),
      ],
      language: decoded.language,
      offsetSamples: offset,
      sampleCount: request.samples.length,
      elapsed: Duration(milliseconds: decoded.wallMs),
    );
  }

  /// Runs [body], turning a native refusal into its failure.
  static T _guard<T>(T Function() body) {
    try {
      return body();
    } on WhisperNativeException catch (error) {
      throw _failureFor(error.status);
    } on StateError {
      throw speechEngineStopped();
    } on ArgumentError {
      throw speechInvalidRequest();
    }
  }
}

/// `ftype` carries the quantisation version in its thousands.
const int _ftypeVersionStep = 1000;

/// The main isolate's reference to one native abort cell.
final class _WhisperAbortCell implements SpeechAbortCell {
  _WhisperAbortCell(this._cell);

  final WhisperCell _cell;
  int _through = 0;

  @override
  int get address => _cell.address;

  @override
  void abortThrough(int jobId) {
    if (jobId <= _through || _cell.isClosed) {
      return;
    }
    _through = jobId;
    _cell.store(jobId);
  }

  @override
  void close() => _cell.close();
}
