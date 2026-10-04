import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'whisper_context_options.dart';
import 'whisper_cpu_facts.dart';
import 'whisper_decode_options.dart';
import 'whisper_log_level.dart';
import 'whisper_log_line.dart';
import 'whisper_memory_facts.dart';
import 'whisper_model_facts.dart';
import 'whisper_native_exception.dart';
import 'whisper_piece.dart';
import 'whisper_segment.dart';
import 'whisper_speech_span.dart';
import 'whisper_status.dart';
import 'whisper_strategy.dart';
import 'whisper_transcript.dart';
import 'whisper_vad_options.dart';

/// The ten POD structs of `src/tapture_whisper.h` and the only code that reads
/// or writes them.
///
/// The structs are private and every pointer is untyped, so no struct type
/// leaks past this file; callers allocate with [allocate] and hand the memory
/// to the matching `write*` or `read*` function. Struct ids equal
/// `tw_struct_id`.
abstract final class NativeTypes {
  /// `TW_STRUCT_CONTEXT_OPTIONS`.
  static const int contextOptions = 1;

  /// `TW_STRUCT_TRANSCRIBE_OPTIONS`.
  static const int transcribeOptions = 2;

  /// `TW_STRUCT_CPU_INFO`.
  static const int cpuFacts = 3;

  /// `TW_STRUCT_MEMORY_INFO`.
  static const int memoryFacts = 4;

  /// `TW_STRUCT_MODEL_FACTS`.
  static const int modelFacts = 5;

  /// `TW_STRUCT_SEGMENT`.
  static const int segment = 6;

  /// `TW_STRUCT_TOKEN`: one text piece of a result.
  static const int piece = 7;

  /// `TW_STRUCT_SPAN`.
  static const int span = 8;

  /// `TW_STRUCT_LOG_ENTRY`.
  static const int logEntry = 9;

  /// `TW_STRUCT_VAD_OPTIONS`.
  static const int vadOptions = 10;

  /// Every struct id, in order.
  static const List<int> ids = <int>[
    contextOptions,
    transcribeOptions,
    cpuFacts,
    memoryFacts,
    modelFacts,
    segment,
    piece,
    span,
    logEntry,
    vadOptions,
  ];

  /// `TW_SHA256_BYTES`.
  static const int sha256Bytes = 32;

  /// `TW_LANGUAGE_CAPACITY`, the language field's bytes with its NUL.
  static const int languageCapacity = 8;

  /// `TW_LOG_TEXT_CAPACITY`, a log line's bytes with its NUL.
  static const int logTextCapacity = 504;

  /// `TW_MAX_SAMPLES`, the most samples one call accepts.
  static const int maxSamples = 16000 * 600;

  /// The Dart layout size of struct [structId]; 0 for an unknown id.
  static int structSize(int structId) => switch (structId) {
    contextOptions => sizeOf<_NativeContextOptions>(),
    transcribeOptions => sizeOf<_NativeTranscribeOptions>(),
    cpuFacts => sizeOf<_NativeCpuFacts>(),
    memoryFacts => sizeOf<_NativeMemoryFacts>(),
    modelFacts => sizeOf<_NativeModelFacts>(),
    segment => sizeOf<_NativeSegment>(),
    piece => sizeOf<_NativePiece>(),
    span => sizeOf<_NativeSpan>(),
    logEntry => sizeOf<_NativeLogEntry>(),
    vadOptions => sizeOf<_NativeVadOptions>(),
    _ => 0,
  };

  /// Zeroed memory for [count] structs [structId] from [allocator], with
  /// `struct_size` set on the structs that carry one.
  static Pointer<Void> allocate(
    Allocator allocator,
    int structId, {
    int count = 1,
  }) {
    final int size = structSize(structId);
    if (size == 0 || count < 1) {
      throw ArgumentError.value(structId, 'structId', 'not a struct to hold');
    }
    final Pointer<Uint8> bytes = allocator<Uint8>(size * count);
    bytes.asTypedList(size * count).fillRange(0, size * count, 0);
    if (_sized.contains(structId)) {
      for (int index = 0; index < count; index++) {
        (bytes + index * size).cast<Uint32>().value = size;
      }
    }
    return bytes.cast<Void>();
  }

  /// Writes [options] into the `tw_context_options` at [at].
  static void writeContextOptions(
    Pointer<Void> at,
    WhisperContextOptions options,
  ) {
    final _NativeContextOptions native = at.cast<_NativeContextOptions>().ref
      ..structSize = structSize(contextOptions)
      ..nThreads = options.threads
      ..useGpu = 0
      ..flashAttn = options.flashAttention ? 1 : 0;
    for (int index = 0; index < 6; index++) {
      native.reserved[index] = 0;
    }
  }

  /// Writes [options] into the `tw_transcribe_options` at [at].
  static void writeTranscribeOptions(
    Pointer<Void> at,
    WhisperDecodeOptions options,
  ) {
    final _NativeTranscribeOptions native =
        at.cast<_NativeTranscribeOptions>().ref
          ..structSize = structSize(transcribeOptions)
          ..strategy = options.strategy == WhisperStrategy.beam ? 1 : 0
          ..nThreads = options.threads
          ..bestOf = options.bestOf
          ..beamSize = options.beamSize
          ..maxPieces = options.maxPieces
          ..audioCtx = options.audioContext
          ..nMaxTextCtx = options.maxTextContext
          ..temperature = options.temperature
          ..temperatureInc = options.temperatureIncrement
          ..entropyThold = options.entropyThreshold
          ..logprobThold = options.logProbabilityThreshold
          ..noSpeechThold = options.noSpeechThreshold
          ..lengthPenalty = options.lengthPenalty
          ..maxInitialTs = options.maxInitialTimestamp
          ..pieceTholdPt = options.pieceProbabilityThreshold
          ..pieceTholdPtsum = options.pieceProbabilitySumThreshold
          ..translate = _flag(options.translate)
          ..noContext = _flag(options.noContext)
          ..singleSegment = _flag(options.singleSegment)
          ..noTimestamps = _flag(options.noTimestamps)
          ..pieceTimestamps = _flag(options.pieceTimestamps)
          ..suppressBlank = _flag(options.suppressBlank)
          ..suppressNst = _flag(options.suppressNonSpeech)
          ..carryInitialPrompt = _flag(options.carryInitialPrompt);
    final List<int> code = ascii.encode(options.language);
    for (int index = 0; index < languageCapacity; index++) {
      native.language[index] = index < code.length ? code[index] : 0;
    }
  }

  /// Writes [options] into the `tw_vad_options` at [at].
  static void writeVadOptions(Pointer<Void> at, WhisperVadOptions options) {
    at.cast<_NativeVadOptions>().ref
      ..structSize = structSize(vadOptions)
      ..threshold = options.threshold
      ..minSpeechMs = options.minSpeechMs
      ..minSilenceMs = options.minSilenceMs
      ..maxSpeechS = options.maxSpeechSeconds
      ..speechPadMs = options.speechPadMs
      ..samplesOverlapS = options.overlapSeconds;
  }

  /// Reads the `tw_cpu_info` at [at].
  static WhisperCpuFacts readCpuFacts(Pointer<Void> at) {
    final _NativeCpuFacts native = at.cast<_NativeCpuFacts>().ref;
    return WhisperCpuFacts(
      logicalCores: native.nLogical,
      performanceCores: native.nPerformance,
      arch: native.arch,
      runtimeFeatures: native.runtimeFeatures,
      requiredFeatures: native.requiredFeatures,
      supported: native.supported != 0,
      engineBuilt: native.engineBuilt != 0,
    );
  }

  /// Reads the `tw_memory_info` at [at]; a negative figure reads as null.
  static WhisperMemoryFacts readMemoryFacts(Pointer<Void> at) {
    final _NativeMemoryFacts native = at.cast<_NativeMemoryFacts>().ref;
    return WhisperMemoryFacts(
      totalBytes: _known(native.totalBytes),
      availableBytes: _known(native.availableBytes),
      processLimitBytes: _known(native.processLimitBytes),
    );
  }

  /// Reads the `tw_model_facts` at [at].
  static WhisperModelFacts readModelFacts(Pointer<Void> at) {
    final _NativeModelFacts native = at.cast<_NativeModelFacts>().ref;
    return WhisperModelFacts(
      nVocab: native.nVocab,
      nAudioCtx: native.nAudioCtx,
      nAudioState: native.nAudioState,
      nAudioHead: native.nAudioHead,
      nAudioLayer: native.nAudioLayer,
      nTextCtx: native.nTextCtx,
      nTextState: native.nTextState,
      nTextHead: native.nTextHead,
      nTextLayer: native.nTextLayer,
      nMels: native.nMels,
      ftype: native.ftype,
      modelType: native.modelType,
      multilingual: native.multilingual != 0,
    );
  }

  /// Reads entry [index] of the `tw_log_entry` array at [at].
  static WhisperLogLine readLogLine(Pointer<Void> at, int index) {
    final _NativeLogEntry native =
        (at.cast<Uint8>() + index * structSize(logEntry))
            .cast<_NativeLogEntry>()
            .ref;
    final int length = native.length.clamp(0, logTextCapacity - 1);
    final Uint8List text = Uint8List(length);
    for (int offset = 0; offset < length; offset++) {
      text[offset] = native.text[offset];
    }
    return WhisperLogLine(
      level: WhisperLogLevel.fromCode(native.level),
      message: utf8.decode(text, allowMalformed: true).trimRight(),
    );
  }

  /// Reads [count] `tw_span`s at [at].
  static List<WhisperSpeechSpan> readSpans(Pointer<Void> at, int count) {
    final Pointer<_NativeSpan> spans = at.cast<_NativeSpan>();
    return <WhisperSpeechSpan>[
      for (int index = 0; index < count; index++)
        WhisperSpeechSpan(
          startMs: (spans + index).ref.t0Ms,
          endMs: (spans + index).ref.t1Ms,
        ),
    ];
  }

  /// Copies a result out of native memory: [segmentCount] `tw_segment`s at
  /// [segments], [pieceCount] `tw_token`s at [pieces] and the [textLength]
  /// bytes of text at [text] that both point into.
  ///
  /// Nothing returned refers to native memory, so the result may be freed as
  /// soon as this returns. An offset outside the text, or a piece range
  /// outside the pieces, throws [WhisperNativeException] with
  /// [WhisperStatus.internal].
  static WhisperTranscript readTranscript({
    required Pointer<Void> segments,
    required int segmentCount,
    required Pointer<Void> pieces,
    required int pieceCount,
    required Pointer<Uint8> text,
    required int textLength,
    required String language,
    required int wallMs,
  }) {
    final Uint8List blob = textLength > 0
        ? Uint8List.fromList(text.asTypedList(textLength))
        : Uint8List(0);
    final Pointer<_NativeSegment> segmentArray = segments
        .cast<_NativeSegment>();
    final Pointer<_NativePiece> pieceArray = pieces.cast<_NativePiece>();
    final List<WhisperSegment> read = <WhisperSegment>[];
    for (int index = 0; index < segmentCount; index++) {
      final _NativeSegment native = (segmentArray + index).ref;
      final Uint8List textBytes = _slice(
        blob,
        native.textOffset,
        native.textLength,
      );
      final int first = native.pieceOffset;
      final int count = native.pieceCount;
      if (first < 0 || count < 0 || first + count > pieceCount) {
        throw const WhisperNativeException(WhisperStatus.internal);
      }
      read.add(
        WhisperSegment(
          startMs: native.t0Ms,
          endMs: native.t1Ms,
          textBytes: textBytes,
          text: utf8.decode(textBytes, allowMalformed: true),
          noSpeechProbability: native.noSpeechProb,
          averageLogProbability: native.avgLogprob,
          meanProbability: native.meanP,
          minProbability: native.minP,
          pieces: <WhisperPiece>[
            for (int offset = first; offset < first + count; offset++)
              _readPiece((pieceArray + offset).ref, blob),
          ],
        ),
      );
    }
    return WhisperTranscript(
      segments: read,
      language: language,
      wallMs: wallMs,
    );
  }

  /// Struct ids whose first field is `struct_size`.
  static const Set<int> _sized = <int>{
    contextOptions,
    transcribeOptions,
    cpuFacts,
    memoryFacts,
    modelFacts,
    vadOptions,
  };

  static int _flag(bool value) => value ? 1 : 0;

  static int? _known(int value) => value < 0 ? null : value;

  static WhisperPiece _readPiece(_NativePiece native, Uint8List blob) =>
      WhisperPiece(
        id: native.id,
        bytes: _slice(blob, native.bytesOffset, native.bytesLength),
        probability: native.p,
        startMs: native.t0Ms,
        endMs: native.t1Ms,
      );

  static Uint8List _slice(Uint8List blob, int offset, int length) {
    if (offset < 0 || length < 0 || offset + length > blob.length) {
      throw const WhisperNativeException(WhisperStatus.internal);
    }
    return blob.sublist(offset, offset + length);
  }
}

/// `tw_context_options`.
final class _NativeContextOptions extends Struct {
  @Uint32()
  external int structSize;
  @Int32()
  external int nThreads;
  @Uint8()
  external int useGpu;
  @Uint8()
  external int flashAttn;
  @Array(6)
  external Array<Uint8> reserved;
}

/// `tw_transcribe_options`.
final class _NativeTranscribeOptions extends Struct {
  @Uint32()
  external int structSize;
  @Int32()
  external int strategy;
  @Int32()
  external int nThreads;
  @Int32()
  external int bestOf;
  @Int32()
  external int beamSize;
  @Int32()
  external int maxPieces;
  @Int32()
  external int audioCtx;
  @Int32()
  external int nMaxTextCtx;
  @Float()
  external double temperature;
  @Float()
  external double temperatureInc;
  @Float()
  external double entropyThold;
  @Float()
  external double logprobThold;
  @Float()
  external double noSpeechThold;
  @Float()
  external double lengthPenalty;
  @Float()
  external double maxInitialTs;
  @Float()
  external double pieceTholdPt;
  @Float()
  external double pieceTholdPtsum;
  @Uint8()
  external int translate;
  @Uint8()
  external int noContext;
  @Uint8()
  external int singleSegment;
  @Uint8()
  external int noTimestamps;
  @Uint8()
  external int pieceTimestamps;
  @Uint8()
  external int suppressBlank;
  @Uint8()
  external int suppressNst;
  @Uint8()
  external int carryInitialPrompt;
  @Array(8)
  external Array<Uint8> language;
}

/// `tw_cpu_info`.
final class _NativeCpuFacts extends Struct {
  @Uint32()
  external int structSize;
  @Int32()
  external int nLogical;
  @Int32()
  external int nPerformance;
  @Uint32()
  external int arch;
  @Uint64()
  external int runtimeFeatures;
  @Uint64()
  external int requiredFeatures;
  @Uint8()
  external int supported;
  @Uint8()
  external int engineBuilt;
  @Array(6)
  external Array<Uint8> reserved;
}

/// `tw_memory_info`.
final class _NativeMemoryFacts extends Struct {
  @Uint32()
  external int structSize;
  @Uint32()
  external int reserved;
  @Int64()
  external int totalBytes;
  @Int64()
  external int availableBytes;
  @Int64()
  external int processLimitBytes;
}

/// `tw_model_facts`.
final class _NativeModelFacts extends Struct {
  @Uint32()
  external int structSize;
  @Int32()
  external int nVocab;
  @Int32()
  external int nAudioCtx;
  @Int32()
  external int nAudioState;
  @Int32()
  external int nAudioHead;
  @Int32()
  external int nAudioLayer;
  @Int32()
  external int nTextCtx;
  @Int32()
  external int nTextState;
  @Int32()
  external int nTextHead;
  @Int32()
  external int nTextLayer;
  @Int32()
  external int nMels;
  @Int32()
  external int ftype;
  @Int32()
  external int modelType;
  @Int32()
  external int multilingual;
}

/// `tw_segment`.
final class _NativeSegment extends Struct {
  @Int64()
  external int t0Ms;
  @Int64()
  external int t1Ms;
  @Int32()
  external int textOffset;
  @Int32()
  external int textLength;
  @Int32()
  external int pieceOffset;
  @Int32()
  external int pieceCount;
  @Float()
  external double noSpeechProb;
  @Float()
  external double avgLogprob;
  @Float()
  external double meanP;
  @Float()
  external double minP;
}

/// `tw_token`: one text piece.
final class _NativePiece extends Struct {
  @Int32()
  external int id;
  @Int32()
  external int bytesOffset;
  @Int32()
  external int bytesLength;
  @Float()
  external double p;
  @Int64()
  external int t0Ms;
  @Int64()
  external int t1Ms;
}

/// `tw_span`.
final class _NativeSpan extends Struct {
  @Int64()
  external int t0Ms;
  @Int64()
  external int t1Ms;
}

/// `tw_log_entry`.
final class _NativeLogEntry extends Struct {
  @Int32()
  external int level;
  @Int32()
  external int length;
  @Array(504)
  external Array<Uint8> text;
}

/// `tw_vad_options`.
final class _NativeVadOptions extends Struct {
  @Uint32()
  external int structSize;
  @Float()
  external double threshold;
  @Int32()
  external int minSpeechMs;
  @Int32()
  external int minSilenceMs;
  @Float()
  external double maxSpeechS;
  @Int32()
  external int speechPadMs;
  @Float()
  external double samplesOverlapS;
}
