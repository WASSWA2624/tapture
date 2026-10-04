import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// The raw `tw_*` functions of one opened library, written by hand in header
/// order (`src/tapture_whisper.h`). Not exported: only the classes of this
/// package call it.
///
/// Struct pointers and handles are untyped; `NativeTypes` reads and writes the
/// structs. `isLeaf` marks only short calls that never block, so a long open,
/// transcription or VAD call never holds up garbage collection in other
/// isolates. "Piece" names whisper's token throughout.
final class WhisperBindings {
  /// Looks every function up in [library]; throws an [ArgumentError] when one
  /// is missing.
  WhisperBindings(DynamicLibrary library)
    : abiVersion = library.lookupFunction<Int32 Function(), int Function()>(
        'tw_abi_version',
        isLeaf: true,
      ),
      structSize = library
          .lookupFunction<Int32 Function(Int32), int Function(int)>(
            'tw_struct_size',
            isLeaf: true,
          ),
      version = library
          .lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>(
            'tw_version',
          ),
      systemInfo = library
          .lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>(
            'tw_system_info',
          ),
      cpuInfoGet = library
          .lookupFunction<
            Int32 Function(Pointer<Void>),
            int Function(Pointer<Void>)
          >('tw_cpu_info_get', isLeaf: true),
      memoryInfoGet = library
          .lookupFunction<
            Int32 Function(Pointer<Void>),
            int Function(Pointer<Void>)
          >('tw_memory_info_get', isLeaf: true),
      debugSetCpuOverride = library
          .lookupFunction<Void Function(Int32), void Function(int)>(
            'tw_debug_set_cpu_override',
          ),
      debugAbortAfterChecks = library
          .lookupFunction<Void Function(Int32), void Function(int)>(
            'tw_debug_abort_after_checks',
          ),
      liveObjects = library
          .lookupFunction<Int32 Function(Int32), int Function(int)>(
            'tw_live_objects',
            isLeaf: true,
          ),
      langId = library
          .lookupFunction<
            Int32 Function(Pointer<Utf8>),
            int Function(Pointer<Utf8>)
          >('tw_lang_id'),
      sha256 = library
          .lookupFunction<
            Int32 Function(Pointer<Void>, Size, Pointer<Uint8>),
            int Function(Pointer<Void>, int, Pointer<Uint8>)
          >('tw_sha256'),
      sha256New = library
          .lookupFunction<Pointer<Void> Function(), Pointer<Void> Function()>(
            'tw_sha256_new',
          ),
      sha256Update = library
          .lookupFunction<
            Void Function(Pointer<Void>, Pointer<Void>, Size),
            void Function(Pointer<Void>, Pointer<Void>, int)
          >('tw_sha256_update'),
      sha256Finish = library
          .lookupFunction<
            Int32 Function(Pointer<Void>, Pointer<Uint8>),
            int Function(Pointer<Void>, Pointer<Uint8>)
          >('tw_sha256_finish'),
      logSetMinLevel = library
          .lookupFunction<Void Function(Int32), void Function(int)>(
            'tw_log_set_min_level',
            isLeaf: true,
          ),
      logDrain = library
          .lookupFunction<
            Int32 Function(Pointer<Void>, Int32),
            int Function(Pointer<Void>, int)
          >('tw_log_drain', isLeaf: true),
      logDropped = library.lookupFunction<Uint32 Function(), int Function()>(
        'tw_log_dropped',
        isLeaf: true,
      ),
      setCrashFile = library
          .lookupFunction<
            Int32 Function(Pointer<Utf8>),
            int Function(Pointer<Utf8>)
          >('tw_set_crash_file'),
      cellNew = library
          .lookupFunction<Pointer<Int32> Function(), Pointer<Int32> Function()>(
            'tw_cell_new',
            isLeaf: true,
          ),
      cellRetain = library
          .lookupFunction<
            Void Function(Pointer<Int32>),
            void Function(Pointer<Int32>)
          >('tw_cell_retain', isLeaf: true),
      cellRelease = library
          .lookupFunction<
            Void Function(Pointer<Int32>),
            void Function(Pointer<Int32>)
          >('tw_cell_release', isLeaf: true),
      cellStore = library
          .lookupFunction<
            Void Function(Pointer<Int32>, Int32),
            void Function(Pointer<Int32>, int)
          >('tw_cell_store', isLeaf: true),
      cellLoad = library
          .lookupFunction<
            Int32 Function(Pointer<Int32>),
            int Function(Pointer<Int32>)
          >('tw_cell_load', isLeaf: true),
      contextOptionsInit = library
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('tw_context_options_init'),
      contextOpenFile = library
          .lookupFunction<
            Int32 Function(
              Pointer<Utf8>,
              Int64,
              Pointer<Uint8>,
              Pointer<Void>,
              Pointer<Pointer<Void>>,
            ),
            int Function(
              Pointer<Utf8>,
              int,
              Pointer<Uint8>,
              Pointer<Void>,
              Pointer<Pointer<Void>>,
            )
          >('tw_context_open_file'),
      contextOpenBuffer = library
          .lookupFunction<
            Int32 Function(
              Pointer<Void>,
              Size,
              Pointer<Uint8>,
              Pointer<Void>,
              Pointer<Pointer<Void>>,
            ),
            int Function(
              Pointer<Void>,
              int,
              Pointer<Uint8>,
              Pointer<Void>,
              Pointer<Pointer<Void>>,
            )
          >('tw_context_open_buffer'),
      contextOpenJs = library
          .lookupFunction<
            Int32 Function(
              Int32,
              Int64,
              Pointer<Uint8>,
              Pointer<Void>,
              Pointer<Pointer<Void>>,
            ),
            int Function(
              int,
              int,
              Pointer<Uint8>,
              Pointer<Void>,
              Pointer<Pointer<Void>>,
            )
          >('tw_context_open_js'),
      contextClose = library
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('tw_context_close'),
      contextFacts = library
          .lookupFunction<
            Int32 Function(Pointer<Void>, Pointer<Void>),
            int Function(Pointer<Void>, Pointer<Void>)
          >('tw_context_facts'),
      contextPcmBuffer = library
          .lookupFunction<
            Pointer<Float> Function(Pointer<Void>, Int32),
            Pointer<Float> Function(Pointer<Void>, int)
          >('tw_context_pcm_buffer'),
      lastWhisperCode = library
          .lookupFunction<
            Int32 Function(Pointer<Void>),
            int Function(Pointer<Void>)
          >('tw_last_whisper_code'),
      transcribeOptionsInit = library
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('tw_transcribe_options_init'),
      transcribe = library
          .lookupFunction<
            Int32 Function(
              Pointer<Void>,
              Pointer<Float>,
              Int32,
              Pointer<Void>,
              Pointer<Utf8>,
              Pointer<Int32>,
              Int32,
              Pointer<Int32>,
              Int32,
              Pointer<Pointer<Void>>,
            ),
            int Function(
              Pointer<Void>,
              Pointer<Float>,
              int,
              Pointer<Void>,
              Pointer<Utf8>,
              Pointer<Int32>,
              int,
              Pointer<Int32>,
              int,
              Pointer<Pointer<Void>>,
            )
          >('tw_transcribe'),
      resultFree = library
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('tw_result_free'),
      resultSegments = library
          .lookupFunction<
            Pointer<Void> Function(Pointer<Void>, Pointer<Int32>),
            Pointer<Void> Function(Pointer<Void>, Pointer<Int32>)
          >('tw_result_segments', isLeaf: true),
      resultPieces = library
          .lookupFunction<
            Pointer<Void> Function(Pointer<Void>, Pointer<Int32>),
            Pointer<Void> Function(Pointer<Void>, Pointer<Int32>)
          >('tw_result_tokens', isLeaf: true),
      resultText = library
          .lookupFunction<
            Pointer<Uint8> Function(Pointer<Void>, Pointer<Int32>),
            Pointer<Uint8> Function(Pointer<Void>, Pointer<Int32>)
          >('tw_result_text', isLeaf: true),
      resultLanguage = library
          .lookupFunction<
            Pointer<Utf8> Function(Pointer<Void>),
            Pointer<Utf8> Function(Pointer<Void>)
          >('tw_result_language', isLeaf: true),
      resultWallMs = library
          .lookupFunction<
            Int64 Function(Pointer<Void>),
            int Function(Pointer<Void>)
          >('tw_result_wall_ms', isLeaf: true),
      vadOpenFile = library
          .lookupFunction<
            Int32 Function(
              Pointer<Utf8>,
              Int64,
              Pointer<Uint8>,
              Pointer<Void>,
              Pointer<Pointer<Void>>,
            ),
            int Function(
              Pointer<Utf8>,
              int,
              Pointer<Uint8>,
              Pointer<Void>,
              Pointer<Pointer<Void>>,
            )
          >('tw_vad_open_file'),
      vadOpenBuffer = library
          .lookupFunction<
            Int32 Function(
              Pointer<Void>,
              Size,
              Pointer<Uint8>,
              Pointer<Void>,
              Pointer<Pointer<Void>>,
            ),
            int Function(
              Pointer<Void>,
              int,
              Pointer<Uint8>,
              Pointer<Void>,
              Pointer<Pointer<Void>>,
            )
          >('tw_vad_open_buffer'),
      vadOpenJs = library
          .lookupFunction<
            Int32 Function(
              Int32,
              Int64,
              Pointer<Uint8>,
              Pointer<Void>,
              Pointer<Pointer<Void>>,
            ),
            int Function(
              int,
              int,
              Pointer<Uint8>,
              Pointer<Void>,
              Pointer<Pointer<Void>>,
            )
          >('tw_vad_open_js'),
      vadClose = library
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('tw_vad_close'),
      vadWindowSamples = library
          .lookupFunction<
            Int32 Function(Pointer<Void>),
            int Function(Pointer<Void>)
          >('tw_vad_window_samples', isLeaf: true),
      vadPcmBuffer = library
          .lookupFunction<
            Pointer<Float> Function(Pointer<Void>, Int32),
            Pointer<Float> Function(Pointer<Void>, int)
          >('tw_vad_pcm_buffer'),
      vadFeed = library
          .lookupFunction<
            Int32 Function(
              Pointer<Void>,
              Pointer<Float>,
              Int32,
              Pointer<Int32>,
            ),
            int Function(Pointer<Void>, Pointer<Float>, int, Pointer<Int32>)
          >('tw_vad_feed'),
      vadProbs = library
          .lookupFunction<
            Pointer<Float> Function(Pointer<Void>, Pointer<Int32>),
            Pointer<Float> Function(Pointer<Void>, Pointer<Int32>)
          >('tw_vad_probs', isLeaf: true),
      vadPendingSamples = library
          .lookupFunction<
            Int32 Function(Pointer<Void>),
            int Function(Pointer<Void>)
          >('tw_vad_pending_samples', isLeaf: true),
      vadReset = library
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('tw_vad_reset'),
      vadOptionsInit = library
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('tw_vad_options_init'),
      vadSegments = library
          .lookupFunction<
            Int32 Function(
              Pointer<Void>,
              Pointer<Float>,
              Int32,
              Pointer<Void>,
              Pointer<Pointer<Void>>,
            ),
            int Function(
              Pointer<Void>,
              Pointer<Float>,
              int,
              Pointer<Void>,
              Pointer<Pointer<Void>>,
            )
          >('tw_vad_segments'),
      spansData = library
          .lookupFunction<
            Pointer<Void> Function(Pointer<Void>, Pointer<Int32>),
            Pointer<Void> Function(Pointer<Void>, Pointer<Int32>)
          >('tw_spans_data'),
      spansFree = library
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('tw_spans_free'),
      contextFinalizer = NativeFinalizer(
        library.lookup<NativeFinalizerFunction>('tw_context_close'),
      ),
      vadFinalizer = NativeFinalizer(
        library.lookup<NativeFinalizerFunction>('tw_vad_close'),
      ),
      cellFinalizer = NativeFinalizer(
        library.lookup<NativeFinalizerFunction>('tw_cell_release'),
      );

  /// `tw_abi_version`.
  final int Function() abiVersion;

  /// `tw_struct_size`.
  final int Function(int structId) structSize;

  /// `tw_version`: a static string.
  final Pointer<Utf8> Function() version;

  /// `tw_system_info`: valid until the next call.
  final Pointer<Utf8> Function() systemInfo;

  /// `tw_cpu_info_get`.
  final int Function(Pointer<Void> out) cpuInfoGet;

  /// `tw_memory_info_get`.
  final int Function(Pointer<Void> out) memoryInfoGet;

  /// `tw_debug_set_cpu_override`: 0 forces unsupported, anything else clears.
  final void Function(int supported) debugSetCpuOverride;

  /// `tw_debug_abort_after_checks`: arms only the next transcription.
  final void Function(int checks) debugAbortAfterChecks;

  /// `tw_live_objects`.
  final int Function(int kind) liveObjects;

  /// `tw_lang_id`: -1 when unknown.
  final int Function(Pointer<Utf8> code) langId;

  /// `tw_sha256`.
  final int Function(Pointer<Void> data, int length, Pointer<Uint8> out) sha256;

  /// `tw_sha256_new`.
  final Pointer<Void> Function() sha256New;

  /// `tw_sha256_update`.
  final void Function(Pointer<Void> hasher, Pointer<Void> data, int length)
  sha256Update;

  /// `tw_sha256_finish`: frees the hasher.
  final int Function(Pointer<Void> hasher, Pointer<Uint8> out) sha256Finish;

  /// `tw_log_set_min_level`.
  final void Function(int level) logSetMinLevel;

  /// `tw_log_drain`.
  final int Function(Pointer<Void> out, int capacity) logDrain;

  /// `tw_log_dropped`.
  final int Function() logDropped;

  /// `tw_set_crash_file`: a null path disables it.
  final int Function(Pointer<Utf8> path) setCrashFile;

  /// `tw_cell_new`: value 0, one reference.
  final Pointer<Int32> Function() cellNew;

  /// `tw_cell_retain`.
  final void Function(Pointer<Int32> cell) cellRetain;

  /// `tw_cell_release`: frees at the last reference.
  final void Function(Pointer<Int32> cell) cellRelease;

  /// `tw_cell_store`.
  final void Function(Pointer<Int32> cell, int value) cellStore;

  /// `tw_cell_load`.
  final int Function(Pointer<Int32> cell) cellLoad;

  /// `tw_context_options_init`.
  final void Function(Pointer<Void> options) contextOptionsInit;

  /// `tw_context_open_file`: a verified open of a model file.
  final int Function(
    Pointer<Utf8> path,
    int expectedBytes,
    Pointer<Uint8> expectedSha256,
    Pointer<Void> options,
    Pointer<Pointer<Void>> out,
  )
  contextOpenFile;

  /// `tw_context_open_buffer`: hashes only when a SHA-256 is given.
  final int Function(
    Pointer<Void> data,
    int size,
    Pointer<Uint8> expectedSha256,
    Pointer<Void> options,
    Pointer<Pointer<Void>> out,
  )
  contextOpenBuffer;

  /// `tw_context_open_js`: WebAssembly only; native builds refuse it.
  final int Function(
    int fileId,
    int expectedBytes,
    Pointer<Uint8> expectedSha256,
    Pointer<Void> options,
    Pointer<Pointer<Void>> out,
  )
  contextOpenJs;

  /// `tw_context_close`: deferred while a call runs.
  final void Function(Pointer<Void> context) contextClose;

  /// `tw_context_facts`.
  final int Function(Pointer<Void> context, Pointer<Void> out) contextFacts;

  /// `tw_context_pcm_buffer`: null while the context is busy.
  final Pointer<Float> Function(Pointer<Void> context, int samples)
  contextPcmBuffer;

  /// `tw_last_whisper_code`.
  final int Function(Pointer<Void> context) lastWhisperCode;

  /// `tw_transcribe_options_init`.
  final void Function(Pointer<Void> options) transcribeOptionsInit;

  /// `tw_transcribe`.
  final int Function(
    Pointer<Void> context,
    Pointer<Float> pcm,
    int samples,
    Pointer<Void> options,
    Pointer<Utf8> initialPrompt,
    Pointer<Int32> promptPieces,
    int promptPieceCount,
    Pointer<Int32> abortCell,
    int jobId,
    Pointer<Pointer<Void>> out,
  )
  transcribe;

  /// `tw_result_free`.
  final void Function(Pointer<Void> result) resultFree;

  /// `tw_result_segments`.
  final Pointer<Void> Function(Pointer<Void> result, Pointer<Int32> count)
  resultSegments;

  /// `tw_result_tokens`: the result's text pieces.
  final Pointer<Void> Function(Pointer<Void> result, Pointer<Int32> count)
  resultPieces;

  /// `tw_result_text`.
  final Pointer<Uint8> Function(Pointer<Void> result, Pointer<Int32> length)
  resultText;

  /// `tw_result_language`.
  final Pointer<Utf8> Function(Pointer<Void> result) resultLanguage;

  /// `tw_result_wall_ms`.
  final int Function(Pointer<Void> result) resultWallMs;

  /// `tw_vad_open_file`: a verified open of a Silero model file.
  final int Function(
    Pointer<Utf8> path,
    int expectedBytes,
    Pointer<Uint8> expectedSha256,
    Pointer<Void> options,
    Pointer<Pointer<Void>> out,
  )
  vadOpenFile;

  /// `tw_vad_open_buffer`.
  final int Function(
    Pointer<Void> data,
    int size,
    Pointer<Uint8> expectedSha256,
    Pointer<Void> options,
    Pointer<Pointer<Void>> out,
  )
  vadOpenBuffer;

  /// `tw_vad_open_js`: WebAssembly only; native builds refuse it.
  final int Function(
    int fileId,
    int expectedBytes,
    Pointer<Uint8> expectedSha256,
    Pointer<Void> options,
    Pointer<Pointer<Void>> out,
  )
  vadOpenJs;

  /// `tw_vad_close`: deferred while a call runs.
  final void Function(Pointer<Void> vad) vadClose;

  /// `tw_vad_window_samples`.
  final int Function(Pointer<Void> vad) vadWindowSamples;

  /// `tw_vad_pcm_buffer`: null while the handle is busy.
  final Pointer<Float> Function(Pointer<Void> vad, int samples) vadPcmBuffer;

  /// `tw_vad_feed`.
  final int Function(
    Pointer<Void> vad,
    Pointer<Float> pcm,
    int samples,
    Pointer<Int32> probabilityCount,
  )
  vadFeed;

  /// `tw_vad_probs`: the probabilities of the last feed.
  final Pointer<Float> Function(Pointer<Void> vad, Pointer<Int32> count)
  vadProbs;

  /// `tw_vad_pending_samples`.
  final int Function(Pointer<Void> vad) vadPendingSamples;

  /// `tw_vad_reset`.
  final void Function(Pointer<Void> vad) vadReset;

  /// `tw_vad_options_init`.
  final void Function(Pointer<Void> options) vadOptionsInit;

  /// `tw_vad_segments`.
  final int Function(
    Pointer<Void> vad,
    Pointer<Float> pcm,
    int samples,
    Pointer<Void> options,
    Pointer<Pointer<Void>> out,
  )
  vadSegments;

  /// `tw_spans_data`.
  final Pointer<Void> Function(Pointer<Void> spans, Pointer<Int32> count)
  spansData;

  /// `tw_spans_free`.
  final void Function(Pointer<Void> spans) spansFree;

  /// Closes a whisper context nobody closed (`tw_context_close`).
  final NativeFinalizer contextFinalizer;

  /// Closes a VAD handle nobody closed (`tw_vad_close`).
  final NativeFinalizer vadFinalizer;

  /// Releases one cell reference nobody released (`tw_cell_release`); it
  /// never frees a cell another reference still holds.
  final NativeFinalizer cellFinalizer;
}
