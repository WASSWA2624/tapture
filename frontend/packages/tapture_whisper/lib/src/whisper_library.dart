import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'cpu_preflight.dart';
import 'library_candidates.dart';
import 'native_types.dart';
import 'whisper_bindings.dart';
import 'whisper_context_options.dart';
import 'whisper_cpu_facts.dart';
import 'whisper_decode_options.dart';
import 'whisper_library_load.dart';
import 'whisper_live_objects.dart';
import 'whisper_log_level.dart';
import 'whisper_log_line.dart';
import 'whisper_memory_facts.dart';
import 'whisper_model_expectation.dart';
import 'whisper_model_facts.dart';
import 'whisper_native_exception.dart';
import 'whisper_speech_span.dart';
import 'whisper_status.dart';
import 'whisper_transcript.dart';
import 'whisper_unavailable_reason.dart';
import 'whisper_vad_options.dart';

part 'whisper_cell.dart';
part 'whisper_model.dart';
part 'whisper_vad.dart';

/// The native whisper library, opened and checked in this isolate.
///
/// Every isolate opens its own; only a cell's address crosses isolates. Every
/// refusal of the library arrives as a [WhisperNativeException].
final class WhisperLibrary {
  WhisperLibrary._(this._bindings);

  /// The C ABI version this package speaks (`TW_ABI_VERSION`).
  static const int abi = 1;

  /// The most samples one call accepts (`TW_MAX_SAMPLES`, 10 minutes).
  static const int maxSamples = NativeTypes.maxSamples;

  /// The sample rate every buffer is in, in hertz (`TW_SAMPLE_RATE`).
  static const int sampleRate = 16000;

  final WhisperBindings _bindings;

  /// Opens the library and checks it before anything uses it.
  ///
  /// On x86-64 the processor is checked first, and an unsupported one is
  /// refused without opening anything. Then the candidates of this operating
  /// system are tried, or [path] alone when it is given (tests). Once open,
  /// the ABI version, all ten struct sizes, `engine_built` and `supported`
  /// must agree with this package.
  static WhisperLibraryLoad open({String? path}) {
    final LibraryCandidates candidates = path == null
        ? LibraryCandidates.current()
        : LibraryCandidates(paths: <String>[path]);
    final ({DynamicLibrary? library, WhisperLibraryUnavailable? refusal})
    opened = candidates.open(preflight: CpuPreflight.current());
    final DynamicLibrary? library = opened.library;
    if (library == null) {
      return opened.refusal ??
          const WhisperLibraryUnavailable(
            WhisperUnavailableReason.libraryMissing,
            'no library was opened',
          );
    }
    return _checked(library);
  }

  static WhisperLibraryLoad _checked(DynamicLibrary library) {
    final WhisperBindings bindings;
    try {
      bindings = WhisperBindings(library);
    } on ArgumentError {
      return const WhisperLibraryUnavailable(
        WhisperUnavailableReason.abiMismatch,
        'the library lacks a tw_* function of ABI $abi',
      );
    }
    final int version = bindings.abiVersion();
    if (version != abi) {
      return WhisperLibraryUnavailable(
        WhisperUnavailableReason.abiMismatch,
        'the library speaks ABI $version, not $abi',
      );
    }
    for (final int id in NativeTypes.ids) {
      final int native = bindings.structSize(id);
      if (native != NativeTypes.structSize(id)) {
        return WhisperLibraryUnavailable(
          WhisperUnavailableReason.abiMismatch,
          'struct $id is $native bytes in the library and '
          '${NativeTypes.structSize(id)} here',
        );
      }
    }
    final WhisperLibrary opened = WhisperLibrary._(bindings);
    final WhisperCpuFacts cpu;
    try {
      cpu = opened.cpuFacts();
    } on WhisperNativeException catch (failure) {
      return WhisperLibraryUnavailable(
        WhisperUnavailableReason.abiMismatch,
        'the processor facts were refused (${failure.status.name})',
      );
    }
    if (!cpu.engineBuilt) {
      return const WhisperLibraryUnavailable(
        WhisperUnavailableReason.engineNotBuilt,
        'the library is a stub for this architecture',
      );
    }
    if (!cpu.supported) {
      return const WhisperLibraryUnavailable(
        WhisperUnavailableReason.unsupportedCpu,
        'the processor lacks a feature the engine needs',
      );
    }
    return WhisperLibraryLoaded(opened);
  }

  /// The C ABI version the library speaks.
  int get abiVersion => _bindings.abiVersion();

  /// The library's version line: ABI, whisper.cpp, commit and ggml.
  String get version => _bindings.version().toDartString();

  /// ggml's description of the processor features in use.
  String systemInfo() => _bindings.systemInfo().toDartString();

  /// What the processor offers and what the engine needs.
  WhisperCpuFacts cpuFacts() => using((Arena arena) {
    final Pointer<Void> facts = NativeTypes.allocate(
      arena,
      NativeTypes.cpuFacts,
    );
    _check(_bindings.cpuInfoGet(facts));
    return NativeTypes.readCpuFacts(facts);
  });

  /// The device's memory.
  WhisperMemoryFacts memoryFacts() => using((Arena arena) {
    final Pointer<Void> facts = NativeTypes.allocate(
      arena,
      NativeTypes.memoryFacts,
    );
    _check(_bindings.memoryInfoGet(facts));
    return NativeTypes.readMemoryFacts(facts);
  });

  /// Opens the whisper model at [path] after the library has checked that it
  /// holds exactly the bytes [expect] describes.
  ///
  /// Throws [WhisperNativeException]: [WhisperStatus.fileOpen] for a missing
  /// file, [WhisperStatus.modelMismatch] for the wrong size or SHA-256,
  /// [WhisperStatus.modelInvalid] for a bad header and
  /// [WhisperStatus.modelLoad] for a file whisper cannot load.
  WhisperModel openModel(
    String path,
    WhisperModelExpectation expect, {
    WhisperContextOptions options = const WhisperContextOptions(),
  }) {
    final Pointer<Void> handle = using((Arena arena) {
      final Pointer<Pointer<Void>> out = arena<Pointer<Void>>();
      _check(
        _bindings.contextOpenFile(
          path.toNativeUtf8(allocator: arena),
          expect.bytes,
          _digest(expect.sha256Hex, arena),
          _contextOptions(options, arena),
          out,
        ),
      );
      return out.value;
    });
    return WhisperModel._adopt(this, handle, expect.bytes);
  }

  /// Opens a whisper model held in [bytes]; with [expect] the library checks
  /// the size and SHA-256 first, without it nothing is hashed (test
  /// fixtures).
  WhisperModel openModelBytes(
    Uint8List bytes, {
    WhisperModelExpectation? expect,
    WhisperContextOptions options = const WhisperContextOptions(),
  }) {
    if (expect != null && expect.bytes != bytes.length) {
      throw const WhisperNativeException(WhisperStatus.modelMismatch);
    }
    if (bytes.isEmpty) {
      throw const WhisperNativeException(WhisperStatus.invalidArgument);
    }
    final Pointer<Void> handle = using((Arena arena) {
      final Pointer<Uint8> data = arena<Uint8>(bytes.length);
      data.asTypedList(bytes.length).setAll(0, bytes);
      final Pointer<Pointer<Void>> out = arena<Pointer<Void>>();
      _check(
        _bindings.contextOpenBuffer(
          data.cast<Void>(),
          bytes.length,
          expect == null ? nullptr : _digest(expect.sha256Hex, arena),
          _contextOptions(options, arena),
          out,
        ),
      );
      return out.value;
    }, malloc);
    return WhisperModel._adopt(this, handle, bytes.length);
  }

  /// Opens the Silero VAD model at [path] after the library has checked
  /// that it holds exactly the bytes [expect] describes, computing on
  /// [threads] threads.
  WhisperVad openVad(
    String path,
    WhisperModelExpectation expect, {
    int threads = 1,
  }) {
    final Pointer<Void> handle = using((Arena arena) {
      final Pointer<Pointer<Void>> out = arena<Pointer<Void>>();
      _check(
        _bindings.vadOpenFile(
          path.toNativeUtf8(allocator: arena),
          expect.bytes,
          _digest(expect.sha256Hex, arena),
          _contextOptions(
            WhisperContextOptions(threads: threads, flashAttention: false),
            arena,
          ),
          out,
        ),
      );
      return out.value;
    });
    return WhisperVad._adopt(this, handle, expect.bytes);
  }

  /// A new abort cell holding 0, owned by this isolate.
  WhisperCell newCell() {
    final Pointer<Int32> cell = _bindings.cellNew();
    if (cell == nullptr) {
      throw const WhisperNativeException(WhisperStatus.outOfMemory);
    }
    return WhisperCell._(this, cell);
  }

  /// A reference to the cell at [address], made in another isolate.
  ///
  /// Borrowing retains the cell and closing releases it, so the cell stays
  /// alive until every isolate has closed its reference. The owner must not
  /// close its own before this call returns.
  WhisperCell borrowCell(int address) {
    if (address == 0) {
      throw const WhisperNativeException(WhisperStatus.invalidArgument);
    }
    final Pointer<Int32> cell = Pointer<Int32>.fromAddress(address);
    _bindings.cellRetain(cell);
    return WhisperCell._(this, cell);
  }

  /// The SHA-256 of [bytes], from the library's own implementation.
  Uint8List sha256(Uint8List bytes) => using((Arena arena) {
    final Pointer<Uint8> data = arena<Uint8>(bytes.isEmpty ? 1 : bytes.length);
    data.asTypedList(bytes.length).setAll(0, bytes);
    final Pointer<Uint8> digest = arena<Uint8>(NativeTypes.sha256Bytes);
    _check(_bindings.sha256(data.cast<Void>(), bytes.length, digest));
    return Uint8List.fromList(digest.asTypedList(NativeTypes.sha256Bytes));
  }, malloc);

  /// Whether whisper knows the language [code]. An empty code and `auto` are
  /// never known: the library never detects a language.
  bool isKnownLanguage(String code) {
    if (code.isEmpty ||
        code.toLowerCase() == 'auto' ||
        code.length > WhisperDecodeOptions.maxLanguageLength ||
        code.codeUnits.any((int unit) => unit < 0x21 || unit > 0x7e)) {
      return false;
    }
    return using(
      (Arena arena) =>
          _bindings.langId(code.toNativeUtf8(allocator: arena)) >= 0,
    );
  }

  /// The lowest level the library keeps in its log ring; WARN by default.
  set logLevel(WhisperLogLevel level) => _bindings.logSetMinLevel(level.code);

  /// Takes up to [max] lines out of the library's log ring, oldest first.
  List<WhisperLogLine> drainLog({int max = 64}) {
    if (max < 1) {
      return const <WhisperLogLine>[];
    }
    return using((Arena arena) {
      final Pointer<Void> entries = NativeTypes.allocate(
        arena,
        NativeTypes.logEntry,
        count: max,
      );
      final int count = _bindings.logDrain(entries, max);
      return <WhisperLogLine>[
        for (int index = 0; index < count; index++)
          NativeTypes.readLogLine(entries, index),
      ];
    });
  }

  /// Lines the full log ring has dropped since the library loaded.
  int get droppedLogLines => _bindings.logDropped();

  /// Sends the library's last words before a fatal ggml abort to the file at
  /// [path]; null stops it.
  void setCrashFile(String? path) {
    if (path == null) {
      _check(_bindings.setCrashFile(nullptr));
      return;
    }
    using(
      (Arena arena) =>
          _check(_bindings.setCrashFile(path.toNativeUtf8(allocator: arena))),
    );
  }

  /// How many native objects of each kind are alive in this process.
  WhisperLiveObjects liveObjects() => WhisperLiveObjects(
    contexts: _bindings.liveObjects(_contextKind),
    results: _bindings.liveObjects(_resultKind),
    vads: _bindings.liveObjects(_vadKind),
    spans: _bindings.liveObjects(_spansKind),
    cells: _bindings.liveObjects(_cellKind),
    hashers: _bindings.liveObjects(_hasherKind),
  );

  /// Makes the library report this processor as unsupported, so every open
  /// is refused; null or false restores the real answer.
  @visibleForTesting
  void debugForceUnsupportedCpu(bool? unsupported) =>
      _bindings.debugSetCpuOverride((unsupported ?? false) ? 0 : 1);

  /// Makes the next transcription abort after [checks] abort checks; 0 turns
  /// it off.
  @visibleForTesting
  void debugAbortAfterChecks(int checks) =>
      _bindings.debugAbortAfterChecks(checks);

  static const int _contextKind = 0;
  static const int _resultKind = 1;
  static const int _vadKind = 2;
  static const int _spansKind = 3;
  static const int _cellKind = 4;
  static const int _hasherKind = 5;

  /// 64 hex digits per SHA-256.
  static final RegExp _sha256Hex = RegExp(r'^[0-9a-fA-F]{64}$');

  static Pointer<Void> _contextOptions(
    WhisperContextOptions options,
    Allocator allocator,
  ) {
    final Pointer<Void> native = NativeTypes.allocate(
      allocator,
      NativeTypes.contextOptions,
    );
    NativeTypes.writeContextOptions(native, options);
    return native;
  }

  static Pointer<Uint8> _digest(String hex, Allocator allocator) {
    if (!_sha256Hex.hasMatch(hex)) {
      throw const WhisperNativeException(WhisperStatus.invalidArgument);
    }
    final Pointer<Uint8> digest = allocator<Uint8>(NativeTypes.sha256Bytes);
    for (int index = 0; index < NativeTypes.sha256Bytes; index++) {
      digest[index] = int.parse(
        hex.substring(index * 2, index * 2 + 2),
        radix: 16,
      );
    }
    return digest;
  }
}

/// Throws the [WhisperNativeException] for a non-zero [status].
void _check(int status, {int whisperCode = 0}) {
  if (status != WhisperStatus.ok.code) {
    throw WhisperNativeException(
      WhisperStatus.fromCode(status),
      whisperCode: whisperCode,
    );
  }
}
