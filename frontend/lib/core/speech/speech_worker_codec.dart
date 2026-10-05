import 'dart:convert';
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'speech_decode_profile.dart';
import 'speech_decode_request.dart';
import 'speech_decode_result.dart';
import 'speech_failures.dart';
import 'speech_model_entry.dart';
import 'speech_model_kind.dart';
import 'speech_model_shape.dart';
import 'speech_model_source.dart';
import 'speech_piece_text.dart';
import 'speech_segment.dart';

/// The protocol between the browser engine and `whisper_worker.js` (spec
/// §30.4.8), as pure functions over Dart maps so the virtual machine tests
/// every message.
///
/// A request is `{op, args}`; the engine adds the `id`. A reply is
/// `{id, ok: true, result}` or `{id, ok: false, error: {code, status,
/// whisperCode}}`, and an event is `{event: 'log', entries, dropped}`.
/// Numbers may arrive as doubles, because a browser has only one number
/// type. Nothing here touches JavaScript: the engine converts at its edge.
abstract final class SpeechWorkerCodec {
  /// The worker script, relative to the app's base URL.
  static const String workerScript = 'whisper/whisper_worker.js';

  /// The worker variant that picks threads when the page allows them.
  static const String variantAuto = 'auto';

  /// The single-thread worker variant.
  static const String variantSingle = 'st';

  /// The threaded worker variant.
  static const String variantThreaded = 'mt';

  /// The worker script's URL under [base], the page's base URL.
  static Uri workerUrl(Uri base) => base.resolve(workerScript);

  /// Whether [url] is an http or https URL of [base]'s origin.
  static bool isSameOrigin(Uri url, Uri base) {
    if (!_isWeb(url) || !_isWeb(base)) {
      return false;
    }
    return url.origin == base.origin;
  }

  /// The model URL for an asset served at [assetUrl], resolved against
  /// [base]. Anything outside [base]'s origin is refused with
  /// `speechUnavailable`: models never come from another origin.
  static Result<Uri> modelUrl(String assetUrl, {required Uri base}) {
    final Uri? resolved = Uri.tryParse(assetUrl);
    if (resolved == null) {
      return FailureResult<Uri>(speechUnavailable());
    }
    final Uri url = base.resolveUri(resolved);
    if (!isSameOrigin(url, base)) {
      return FailureResult<Uri>(speechUnavailable());
    }
    return Success<Uri>(url);
  }

  /// The browser cache entry of [entry]: its id and the first 12 hex
  /// characters of its SHA-256, so a changed model is fetched afresh.
  static String cacheKeyOf(SpeechModelEntry entry) =>
      '${entry.id}-${entry.sha256.substring(0, _cacheShaLength)}';

  /// Threads a web decode uses: one on the single-thread variant; otherwise
  /// [requested] capped at `clamp(hardwareConcurrency - 1, 1,
  /// webMaxThreads)`, so the page keeps a core.
  static int webThreads({
    required bool threaded,
    required int hardwareConcurrency,
    required int requested,
  }) {
    if (!threaded) {
      return 1;
    }
    final int cap = _clamp(
      hardwareConcurrency - 1,
      1,
      AppConstants.speechEngine.webMaxThreads,
    );
    return _clamp(requested, 1, cap);
  }

  // Requests.

  /// `init`: loads the WebAssembly [variant] (`auto`, `st` or `mt`).
  static Map<String, Object?> init({required String variant}) =>
      _request(_init, <String, Object?>{'variant': variant});

  /// `loadModel`: opens [source] with [threads], fetched by the worker from
  /// its same-origin URL (or its browser cache) and verified by size and
  /// SHA-256 before it is parsed. [base] is the page's base URL. A source
  /// without a URL, one the web may not load, or a URL of another origin is
  /// refused here, before any message is sent.
  static Result<Map<String, Object?>> loadModel(
    SpeechModelSource source, {
    required int threads,
    required Uri base,
  }) {
    final SpeechModelEntry entry = source.entry;
    final Uri? url = source.url;
    if (url == null || !entry.webAllowed) {
      return FailureResult<Map<String, Object?>>(speechModelMissing());
    }
    if (!isSameOrigin(url, base)) {
      return FailureResult<Map<String, Object?>>(speechUnavailable());
    }
    return Success<Map<String, Object?>>(
      _request(_loadModel, <String, Object?>{
        'kind': entry.kind == SpeechModelKind.vad ? _vadKind : _whisperKind,
        'url': url.toString(),
        'cacheKey': cacheKeyOf(entry),
        'sha256': entry.sha256,
        'bytes': entry.bytes,
        'threads': threads,
      }),
    );
  }

  /// `verify`: hashes the cached copy of [entry] in the worker.
  static Map<String, Object?> verify(SpeechModelEntry entry) =>
      _request(_verify, <String, Object?>{
        'cacheKey': cacheKeyOf(entry),
        'sha256': entry.sha256,
        'bytes': entry.bytes,
      });

  /// `transcribe`: decodes [request] on model [handle] as job [jobId] of
  /// lease [leaseId] with at most [threads] threads.
  ///
  /// The samples are copied, zero-padded to whisper's minimum, so the
  /// engine may transfer the copy without touching the caller's buffer.
  /// Language detection is never asked for and no context carries over
  /// between windows.
  static Map<String, Object?> transcribe(
    SpeechDecodeRequest request, {
    required int handle,
    required int jobId,
    required int leaseId,
    required int threads,
  }) {
    final Float32List samples = request.samples;
    final int minimum = AppConstants.speechEngine.minDecodeSamples;
    final Float32List padded = Float32List(
      samples.length < minimum ? minimum : samples.length,
    )..setRange(0, samples.length, samples);
    final SpeechDecodeProfile profile = request.profile;
    final bool beam = profile.beamSize > 0;
    return _request(_transcribe, <String, Object?>{
      'handle': handle,
      'jobId': jobId,
      'leaseId': leaseId,
      'pcm': padded,
      'initialPrompt': request.prompt.isEmpty ? null : request.prompt,
      'options': <String, Object?>{
        'strategy': beam ? _beamStrategy : _greedyStrategy,
        'threads': _clamp(profile.threads, 1, threads < 1 ? 1 : threads),
        'bestOf': profile.bestOf < 1 ? 1 : profile.bestOf,
        'beamSize': beam ? profile.beamSize : 1,
        'maxPieces': profile.maxPiecesFor(padded.length),
        'audioCtx': profile.audioContextFor(padded.length),
        'temperature': 0.0,
        'temperatureInc': profile.temperatureStep,
        'entropyThold': profile.entropyThreshold,
        'logprobThold': profile.logprobThreshold,
        'noSpeechThold': profile.noSpeechThreshold,
        'noContext': true,
        'singleSegment': profile.singleSegment,
        'noTimestamps': !profile.timestamps,
        'pieceTimestamps': request.pieceTimings,
        'suppressBlank': profile.suppressBlank,
        'suppressNst': profile.suppressNonSpeech,
        'language': request.language,
      },
    });
  }

  /// `vadFeed`: one probability per whole frame of [samples] on detector
  /// [handle]. The samples are copied so the engine may transfer them.
  static Map<String, Object?> vadFeed({
    required int handle,
    required Float32List samples,
  }) => _request(_vadFeed, <String, Object?>{
    'handle': handle,
    'pcm': Float32List.fromList(samples),
  });

  /// `vadReset`: clears detector [handle]'s running state.
  static Map<String, Object?> vadReset({required int handle}) =>
      _request(_vadReset, <String, Object?>{'handle': handle});

  /// `abort`: drops lease [leaseId]'s queued transcriptions, every one or,
  /// with [jobId], those up to it. A running one is aborted elsewhere.
  static Map<String, Object?> abort({required int leaseId, int? jobId}) =>
      _request(_abort, <String, Object?>{'leaseId': leaseId, 'jobId': ?jobId});

  /// `memory`: the WebAssembly heap size.
  static Map<String, Object?> memory() =>
      _request(_memory, const <String, Object?>{});

  /// `liveObjects`: the engine objects alive in the worker.
  static Map<String, Object?> liveObjects() =>
      _request(_liveObjects, const <String, Object?>{});

  /// `close`: frees model or detector [handle].
  static Map<String, Object?> close({required int handle}) =>
      _request(_close, <String, Object?>{'handle': handle});

  /// `dispose`: frees everything; the worker then closes itself.
  static Map<String, Object?> dispose() =>
      _request(_dispose, const <String, Object?>{});

  // Replies.

  /// Whether [message] is an event rather than a reply.
  static bool isEvent(Map<Object?, Object?> message) =>
      message['event'] is String;

  /// The request id [message] answers, or null when it carries none.
  static int? replyId(Map<Object?, Object?> message) => _int(message['id']);

  /// The `result` of a successful reply, or the failure of a refused one.
  static Result<Map<Object?, Object?>> replyResult(
    Map<Object?, Object?> message,
  ) {
    if (message['ok'] == true) {
      final Object? result = message['result'];
      return Success<Map<Object?, Object?>>(
        result is Map<Object?, Object?> ? result : <Object?, Object?>{},
      );
    }
    return FailureResult<Map<Object?, Object?>>(
      failureFor(replyErrorCode(message) ?? ''),
    );
  }

  /// The worker's error code in a refused reply, or null.
  static String? replyErrorCode(Map<Object?, Object?> message) {
    final Object? error = message['error'];
    if (message['ok'] == true || error is! Map<Object?, Object?>) {
      return null;
    }
    final Object? code = error['code'];
    return code is String ? code : null;
  }

  /// The failure for the worker error [code] (spec §30.4.4): the snake-case
  /// `tw_status` names plus `no_simd`, `fetch_failed`, `storage` and
  /// `cross_origin`. An unknown code is a transcription failure.
  static Failure failureFor(String code) => switch (code) {
    'aborted' => speechCancelled(),
    'invalid_argument' || 'audio_too_long' => speechInvalidRequest(),
    'abi_mismatch' || 'fetch_failed' || 'cross_origin' => speechUnavailable(),
    'unsupported_cpu' ||
    'engine_not_built' ||
    'no_simd' => speechDeviceUnsupported(),
    'file_open' => speechModelMissing(),
    'model_invalid' || 'model_mismatch' => speechModelDamaged(),
    'model_load' || 'out_of_memory' => speechLowMemory(),
    'storage' => speechStorageFailed(),
    _ => speechTranscriptionFailed(),
  };

  /// The `init` result: the variant the worker loaded, how many threads it
  /// allows, the browser's cores and memory, and on the threaded variant
  /// the byte offset of the shared abort cell. A malformed result means the
  /// worker never became ready: `speechUnavailable`.
  static Result<
    ({
      String variant,
      int maxThreads,
      int logicalCores,
      double? deviceMemoryGb,
      String version,
      int? abortCellOffset,
    })
  >
  decodeInit(Map<Object?, Object?> result) {
    final String? variant = _string(result['variant']);
    final int? maxThreads = _int(result['maxThreads']);
    final int? logicalCores = _int(result['logicalCores']);
    final Object? cell = result['abortCell'];
    final int? abortCellOffset = cell is Map<Object?, Object?>
        ? _int(cell['byteOffset'])
        : null;
    final bool threaded = variant == variantThreaded;
    if ((variant != variantSingle && !threaded) ||
        maxThreads == null ||
        maxThreads < 1 ||
        logicalCores == null ||
        threaded != (abortCellOffset != null)) {
      return FailureResult<
        ({
          String variant,
          int maxThreads,
          int logicalCores,
          double? deviceMemoryGb,
          String version,
          int? abortCellOffset,
        })
      >(speechUnavailable());
    }
    return Success<
      ({
        String variant,
        int maxThreads,
        int logicalCores,
        double? deviceMemoryGb,
        String version,
        int? abortCellOffset,
      })
    >((
      variant: variant!,
      maxThreads: maxThreads,
      logicalCores: logicalCores,
      deviceMemoryGb: _double(result['deviceMemoryGb']),
      version: _string(result['version']) ?? '',
      abortCellOffset: abortCellOffset,
    ));
  }

  /// The `loadModel` result for whisper model [entry]: its handle, the shape
  /// the worker read, and where the bytes came from (`opfs`, `network` or
  /// `memory`). A shape other than the catalogue's is
  /// `speechModelDamaged`; the caller closes the handle.
  static Result<({int handle, SpeechModelShape shape, String servedFrom})>
  decodeModel(Map<Object?, Object?> result, SpeechModelEntry entry) {
    final int? handle = _int(result['handle']);
    final Object? facts = result['facts'];
    if (handle == null || facts is! Map<Object?, Object?>) {
      return FailureResult<
        ({int handle, SpeechModelShape shape, String servedFrom})
      >(speechTranscriptionFailed());
    }
    final int? ftype = _int(facts['ftype']);
    final SpeechModelShape shape = SpeechModelShape(
      nVocab: _int(facts['nVocab']) ?? 0,
      nAudioCtx: _int(facts['nAudioCtx']) ?? 0,
      nAudioState: _int(facts['nAudioState']) ?? 0,
      nAudioLayer: _int(facts['nAudioLayer']) ?? 0,
      nTextLayer: _int(facts['nTextLayer']) ?? 0,
      nMels: _int(facts['nMels']) ?? 0,
      ftype: ftype == null ? -1 : ftype % _ftypeVersionStep,
      multilingual: facts['multilingual'] == true,
    );
    if (shape != SpeechModelShape.expectedFor(entry)) {
      return FailureResult<
        ({int handle, SpeechModelShape shape, String servedFrom})
      >(speechModelDamaged());
    }
    return Success<({int handle, SpeechModelShape shape, String servedFrom})>((
      handle: handle,
      shape: shape,
      servedFrom: _string(result['servedFrom']) ?? '',
    ));
  }

  /// The handle in a `loadModel` result, or null when it has none.
  static int? handleOf(Map<Object?, Object?> result) => _int(result['handle']);

  /// The `loadModel` result for a voice-activity model: its handle and the
  /// samples in one frame.
  static Result<({int handle, int windowSamples})> decodeVad(
    Map<Object?, Object?> result,
  ) {
    final int? handle = _int(result['handle']);
    final int? window = _int(result['windowSamples']);
    if (handle == null || window == null || window < 1) {
      return FailureResult<({int handle, int windowSamples})>(
        speechTranscriptionFailed(),
      );
    }
    return Success<({int handle, int windowSamples})>((
      handle: handle,
      windowSamples: window,
    ));
  }

  /// The `verify` result: whether the browser caches the model, and whether
  /// that copy has the expected size and SHA-256.
  static Result<({bool present, bool ok})> decodeVerify(
    Map<Object?, Object?> result,
  ) {
    final Object? present = result['present'];
    final Object? ok = result['ok'];
    if (present is! bool || ok is! bool) {
      return FailureResult<({bool present, bool ok})>(
        speechTranscriptionFailed(),
      );
    }
    return Success<({bool present, bool ok})>((present: present, ok: ok));
  }

  /// The `transcribe` result for [request], on the session timeline and
  /// limited to the samples [request] carried (padding is dropped). Text is
  /// decoded leniently and pieces are grouped into whole code points.
  static Result<SpeechDecodeResult> decodeTranscript(
    Map<Object?, Object?> result,
    SpeechDecodeRequest request,
  ) {
    final Object? rawSegments = result['segments'];
    final Object? rawPieces = result['pieces'];
    final Uint8List? text = _bytes(result['textBytes']);
    if (rawSegments is! List<Object?> ||
        rawPieces is! List<Object?> ||
        text == null) {
      return FailureResult<SpeechDecodeResult>(speechTranscriptionFailed());
    }
    final int offset = request.offsetSamples;
    int at(int milliseconds) =>
        offset +
        milliseconds *
            AppConstants.audio.sampleRate ~/
            Duration.millisecondsPerSecond;
    final List<SpeechSegment> segments = <SpeechSegment>[];
    for (final Object? raw in rawSegments) {
      final SpeechSegment? segment = raw is Map<Object?, Object?>
          ? _segment(raw, rawPieces, text, request.pieceTimings, at)
          : null;
      if (segment == null) {
        return FailureResult<SpeechDecodeResult>(speechTranscriptionFailed());
      }
      segments.add(segment);
    }
    final int wallMs = _int(result['wallMs']) ?? 0;
    return Success<SpeechDecodeResult>(
      SpeechDecodeResult(
        segments: segments,
        language: _string(result['language']) ?? request.language,
        offsetSamples: offset,
        sampleCount: request.samples.length,
        elapsed: Duration(milliseconds: wallMs),
      ).clampedTo(request.samples.length),
    );
  }

  /// The `vadFeed` result: one probability per whole frame of the
  /// [frames] frames sent. Any other count is a transcription failure.
  static Result<Float32List> decodeProbabilities(
    Map<Object?, Object?> result, {
    required int frames,
  }) {
    final Object? probabilities = result['probs'];
    final Float32List? values = probabilities is Float32List
        ? probabilities
        : (probabilities is List<Object?> ? _floats(probabilities) : null);
    if (values == null || values.length != frames) {
      return FailureResult<Float32List>(speechTranscriptionFailed());
    }
    return Success<Float32List>(values);
  }

  /// The `abort` result: how many queued transcriptions were dropped.
  static Result<int> decodeAbort(Map<Object?, Object?> result) {
    final int? dropped = _int(result['dropped']);
    return dropped == null
        ? FailureResult<int>(speechTranscriptionFailed())
        : Success<int>(dropped);
  }

  /// The `memory` result: the WebAssembly heap in bytes, and the browser's
  /// rough device memory in GiB when it tells.
  static Result<({int heapBytes, double? deviceMemoryGb})> decodeMemory(
    Map<Object?, Object?> result,
  ) {
    final int? heap = _int(result['heapBytes']);
    if (heap == null) {
      return FailureResult<({int heapBytes, double? deviceMemoryGb})>(
        speechTranscriptionFailed(),
      );
    }
    return Success<({int heapBytes, double? deviceMemoryGb})>((
      heapBytes: heap,
      deviceMemoryGb: _double(result['deviceMemoryGb']),
    ));
  }

  /// The `liveObjects` result as engine handles: models, detectors and
  /// undisposed results, as the native engine counts them.
  static Result<int> decodeLiveObjects(Map<Object?, Object?> result) {
    final int? contexts = _int(result['contexts']);
    final int? vads = _int(result['vads']);
    final int? results = _int(result['results']);
    if (contexts == null || vads == null || results == null) {
      return FailureResult<int>(speechTranscriptionFailed());
    }
    return Success<int>(contexts + vads + results);
  }

  /// The `close` result: whether the handle was open.
  static Result<bool> decodeClose(Map<Object?, Object?> result) {
    final Object? closed = result['closed'];
    return closed is bool
        ? Success<bool>(closed)
        : FailureResult<bool>(speechTranscriptionFailed());
  }

  /// The warning and error lines of a log [event], at most
  /// `logLinesPerDrain` of at most `logLineChars` characters, plus one line
  /// counting the rest and the lines the worker dropped since
  /// [droppedBefore]. Also returns the worker's running dropped count.
  static ({List<({int level, String line})> lines, int dropped}) decodeLog(
    Map<Object?, Object?> event, {
    required int droppedBefore,
  }) {
    final Object? entries = event['entries'];
    final List<({int level, String line})> kept =
        <({int level, String line})>[];
    int over = 0;
    final int perDrain = AppConstants.speechEngine.logLinesPerDrain;
    final int chars = AppConstants.speechEngine.logLineChars;
    if (entries is List<Object?>) {
      for (final Object? entry in entries) {
        if (entry is! Map<Object?, Object?>) {
          continue;
        }
        final int level = _int(entry['level']) ?? 0;
        final String line = _string(entry['text']) ?? '';
        if (level < _warnLevel) {
          continue;
        }
        if (kept.length >= perDrain) {
          over++;
          continue;
        }
        kept.add((
          level: level,
          line: line.length > chars ? line.substring(0, chars) : line,
        ));
      }
    }
    final int dropped = _int(event['dropped']) ?? droppedBefore;
    final int suppressed =
        over + (dropped > droppedBefore ? dropped - droppedBefore : 0);
    if (suppressed > 0) {
      kept.add((
        level: _warnLevel,
        line: '$suppressed native lines suppressed',
      ));
    }
    return (lines: kept, dropped: dropped);
  }

  /// `tw_log_level` of a warning; quieter lines are not forwarded.
  static const int _warnLevel = 3;

  static Map<String, Object?> _request(String op, Map<String, Object?> args) =>
      <String, Object?>{'op': op, 'args': args};

  static SpeechSegment? _segment(
    Map<Object?, Object?> raw,
    List<Object?> pieces,
    Uint8List text,
    bool pieceTimings,
    int Function(int milliseconds) at,
  ) {
    final int? start = _int(raw['t0Ms']);
    final int? end = _int(raw['t1Ms']);
    final int? textOffset = _int(raw['textOffset']);
    final int? textLength = _int(raw['textLength']);
    final int? first = _int(raw['pieceOffset']);
    final int? count = _int(raw['pieceCount']);
    if (start == null ||
        end == null ||
        !_fits(textOffset, textLength, text.length) ||
        !_fits(first, count, pieces.length)) {
      return null;
    }
    final List<
      ({List<int> bytes, int startSample, int endSample, double probability})
    >
    timed =
        <
          ({
            List<int> bytes,
            int startSample,
            int endSample,
            double probability,
          })
        >[];
    if (pieceTimings) {
      for (int index = first!; index < first + count!; index++) {
        final Object? piece = pieces[index];
        if (piece is! Map<Object?, Object?>) {
          return null;
        }
        final int? bytesOffset = _int(piece['bytesOffset']);
        final int? bytesLength = _int(piece['bytesLength']);
        if (!_fits(bytesOffset, bytesLength, text.length)) {
          return null;
        }
        timed.add((
          bytes: Uint8List.sublistView(
            text,
            bytesOffset!,
            bytesOffset + bytesLength!,
          ),
          startSample: at(_int(piece['t0Ms']) ?? start),
          endSample: at(_int(piece['t1Ms']) ?? end),
          probability: _double(piece['p']) ?? 0,
        ));
      }
    }
    return SpeechSegment(
      startSample: at(start),
      endSample: at(end),
      text: utf8.decode(
        Uint8List.sublistView(text, textOffset!, textOffset + textLength!),
        allowMalformed: true,
      ),
      noSpeechProbability: _double(raw['noSpeechProb']) ?? 0,
      averageLogProbability: _double(raw['avgLogprob']) ?? 0,
      confidence: _double(raw['meanP']) ?? 0,
      pieces: pieceTimings ? SpeechPieceText.group(timed) : const [],
    );
  }

  /// Whether `[offset, offset + length)` lies inside `[0, limit)`.
  static bool _fits(int? offset, int? length, int limit) =>
      offset != null &&
      length != null &&
      offset >= 0 &&
      length >= 0 &&
      offset + length <= limit;

  static bool _isWeb(Uri url) =>
      (url.scheme == 'http' || url.scheme == 'https') && url.host.isNotEmpty;

  static int _clamp(int value, int low, int high) =>
      value < low ? low : (value > high ? high : value);

  /// An integral number, whichever number type it arrived as.
  static int? _int(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is double && value.isFinite && value == value.truncate()) {
      return value.toInt();
    }
    return null;
  }

  static double? _double(Object? value) =>
      value is num && value.isFinite ? value.toDouble() : null;

  static String? _string(Object? value) => value is String ? value : null;

  static Uint8List? _bytes(Object? value) {
    if (value is Uint8List) {
      return value;
    }
    if (value is List<Object?>) {
      final Uint8List bytes = Uint8List(value.length);
      for (int index = 0; index < value.length; index++) {
        final int? byte = _int(value[index]);
        if (byte == null || byte < 0 || byte > _byteMax) {
          return null;
        }
        bytes[index] = byte;
      }
      return bytes;
    }
    return null;
  }

  static Float32List? _floats(List<Object?> values) {
    final Float32List floats = Float32List(values.length);
    for (int index = 0; index < values.length; index++) {
      final Object? value = values[index];
      if (value is! num) {
        return null;
      }
      floats[index] = value.toDouble();
    }
    return floats;
  }

  static const String _init = 'init';
  static const String _loadModel = 'loadModel';
  static const String _verify = 'verify';
  static const String _transcribe = 'transcribe';
  static const String _vadFeed = 'vadFeed';
  static const String _vadReset = 'vadReset';
  static const String _abort = 'abort';
  static const String _memory = 'memory';
  static const String _liveObjects = 'liveObjects';
  static const String _close = 'close';
  static const String _dispose = 'dispose';
  static const String _whisperKind = 'whisper';
  static const String _vadKind = 'vad';
  static const int _greedyStrategy = 0;
  static const int _beamStrategy = 1;
  static const int _cacheShaLength = 12;
  static const int _byteMax = 255;

  /// `ftype` carries the quantisation version in its thousands.
  static const int _ftypeVersionStep = 1000;
}
