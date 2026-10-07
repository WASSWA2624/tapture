import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/speech/speech.dart';

import '../spoken_script.dart';

/// A speech engine a test drives by hand (FE-TEST-03). It "hears" a
/// [SpokenScript]: a decode returns the script's words inside its window,
/// timed exactly, and voice detection reads the loudness of the samples it
/// is given.
///
/// **Queue.** It keeps the real engines' queue rules (spec §30.4.2): one
/// decode in flight; a newer interim replaces the same lease's pending
/// interim; a committed request preempts an in-flight interim of any lease;
/// committed requests run first, in arrival order, and are never dropped.
/// A dispatched decode finishes on a later event-loop turn, so a test that
/// awaits [states] reaching `busy` still finds it in flight. [hold] keeps
/// every dispatched decode in flight until [releaseHeld].
///
/// **Adversarial modes.** Each makes the output imperfect the way whisper
/// is, so a pipeline test cannot pass by echoing the script. Every random
/// choice comes from [seed] mixed with the window's offset, length and
/// kind, so a run repeats exactly whatever order decodes arrive in.
/// - [truncateEdgeWord]: a word cut by the window's edge keeps only the
///   letters inside the window ("country" cut late becomes "coun").
/// - [completeEdgeWord]: a cut word is returned whole, so the next window
///   repeats it.
/// - [dropEdgeWord]: a cut word is left out; it is recorded in
///   [droppedEdgeWords].
/// - With none of the three, a cut word belongs to the window holding its
///   midpoint. With several, each cut word picks one of them at random.
/// - [timeJitter]: every piece and segment time moves by up to this much
///   either way, then is clamped into the window, keeping word order.
/// - [echoPrompt]: with this probability a decode with a prompt starts
///   with the prompt's last one to three words: a weak segment of their
///   own, as whisper decodes an echo, or the start of the single segment
///   of a draft.
/// - [loopAtSpeechRate]: when above 0, a decode (with [loopChance]) says
///   its first phrase (up to three words) this many times at a believable
///   pace of [loopWordDuration] a word, the loop whisper falls into, then
///   the rest of its words. Only decodes of [loopKinds] loop.
/// - [hallucinate]: every decode, even of silence, ends with this text as a
///   weak extra segment, as whisper invents "Thank you." over noise.
/// - [computeTime] and [computeFactor]: the compute time a result reports,
///   fixed plus a multiple of the window's audio time. Never slept.
final class FakeSpeechEngine implements SpeechEngine {
  /// Creates an engine that hears [script].
  FakeSpeechEngine({
    SpokenScript? script,
    this.seed = 0,
    this.truncateEdgeWord = false,
    this.completeEdgeWord = false,
    this.dropEdgeWord = false,
    this.timeJitter = Duration.zero,
    this.echoPrompt = 0,
    this.loopAtSpeechRate = 0,
    this.loopChance = 1,
    this.loopWordDuration = const Duration(milliseconds: 330),
    this.loopKinds = const <SpeechDecodeKind>{
      SpeechDecodeKind.interim,
      SpeechDecodeKind.committed,
    },
    this.hallucinate,
    this.computeTime = Duration.zero,
    this.computeFactor = 0,
    this.vadFrameSamples = 512,
    this.speechFloorDbfs = -60,
    SpeechRuntimeFacts? facts,
  }) : script = script ?? SpokenScript.silence,
       facts = facts ?? defaultFacts;

  /// What a typical desktop reports.
  static const SpeechRuntimeFacts defaultFacts = SpeechRuntimeFacts(
    available: true,
    engineVersion: '1.9.4',
    abiVersion: 1,
    cpuFeatures: <SpeechCpuFeature>{
      SpeechCpuFeature.avx,
      SpeechCpuFeature.avx2,
      SpeechCpuFeature.fma,
      SpeechCpuFeature.f16c,
    },
    is64Bit: true,
    totalMemoryBytes: 16 * 1024 * 1024 * 1024,
    availableMemoryBytes: 8 * 1024 * 1024 * 1024,
    logicalCores: 8,
    performanceCores: 4,
  );

  /// What was said.
  final SpokenScript script;

  /// The seed every random choice derives from.
  final int seed;

  /// Whether a cut edge word keeps only its letters inside the window.
  final bool truncateEdgeWord;

  /// Whether a cut edge word is returned whole.
  final bool completeEdgeWord;

  /// Whether a cut edge word is left out.
  final bool dropEdgeWord;

  /// How far any reported time may move either way.
  final Duration timeJitter;

  /// The chance, from 0 to 1, that a decode echoes its prompt.
  final double echoPrompt;

  /// How many times a looping decode repeats its phrase; 0 never loops.
  final int loopAtSpeechRate;

  /// The chance, from 0 to 1, that a decode with words loops.
  final double loopChance;

  /// How long each looped word lasts.
  final Duration loopWordDuration;

  /// The kinds of decode that loop: drafts alone repeat themselves the way
  /// drafts decoded with a carried prompt once did.
  final Set<SpeechDecodeKind> loopKinds;

  /// Text invented at the end of every decode, or null.
  final String? hallucinate;

  /// Compute time every result reports.
  final Duration computeTime;

  /// Compute time reported per unit of audio time, on top of
  /// [computeTime]: 2 reports twice real time.
  final double computeFactor;

  /// Samples per voice-detection frame.
  final int vadFrameSamples;

  /// The loudness, in dBFS, from which a frame counts as speech.
  final double speechFloorDbfs;

  /// What [probe] reports.
  final SpeechRuntimeFacts facts;

  /// Every model asked for, in order.
  final List<SpeechModelSource> loads = <SpeechModelSource>[];

  /// While set, every load waits for it, as a slow model load would.
  Completer<void>? holdLoad;

  /// Every decode asked for, in order, including refused ones.
  final List<({SpeechDecodeRequest request, int leaseId})> decodes =
      <({SpeechDecodeRequest request, int leaseId})>[];

  /// Every lease aborted, in order.
  final List<int> abortedLeases = <int>[];

  /// Edge words [dropEdgeWord] left out, in the order decodes dropped them.
  final List<SpokenWord> droppedEdgeWords = <SpokenWord>[];

  /// How many voice-detection batches were answered.
  int vadBatches = 0;

  final Queue<Failure> _nextDecodeFailures = Queue<Failure>();
  final List<_Job> _pending = <_Job>[];
  final Map<int, double> _vadStates = <int, double>{};
  final StreamController<SpeechEngineState> _states =
      StreamController<SpeechEngineState>.broadcast();
  Failure? _nextLoadFailure;
  SpeechLoadReport? _loaded;
  _Job? _inFlight;
  bool _holding = false;
  bool _disposed = false;
  int _nextVadId = 0;

  /// The decode in flight, or null.
  SpeechDecodeRequest? get inFlight => _inFlight?.request;

  /// How many decodes wait behind the one in flight.
  int get pendingCount => _pending.length;

  /// The next load fails with [failure].
  void failLoad(Failure failure) => _nextLoadFailure = failure;

  /// The next dispatched decode fails with [failure]; calls queue up.
  void failNext(Failure failure) => _nextDecodeFailures.add(failure);

  /// Keeps every dispatched decode in flight until [releaseHeld].
  void hold() => _holding = true;

  /// Lets the decode in flight, and every later one, finish.
  void releaseHeld() {
    _holding = false;
    final _Job? job = _inFlight;
    if (job != null) {
      Timer.run(() => _finish(job));
    }
  }

  @override
  Future<Result<SpeechRuntimeFacts>> probe() async {
    if (_disposed) {
      return FailureResult<SpeechRuntimeFacts>(speechEngineStopped());
    }
    return Success<SpeechRuntimeFacts>(facts);
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
    loads.add(model);
    final Completer<void>? held = holdLoad;
    if (held != null) {
      await held.future;
    }
    if (cancel?.isCancelled ?? false) {
      return FailureResult<SpeechLoadReport>(speechCancelled());
    }
    final Failure? failure = _nextLoadFailure;
    if (failure != null) {
      _nextLoadFailure = null;
      return FailureResult<SpeechLoadReport>(failure);
    }
    final SpeechLoadReport? current = _loaded;
    if (current != null &&
        current.model.id == model.entry.id &&
        current.threads == threads) {
      return Success<SpeechLoadReport>(current);
    }
    _states.add(SpeechEngineState.loading);
    final SpeechLoadReport report = SpeechLoadReport(
      model: model.entry,
      shape: _shapeOf(model.entry),
      threads: threads,
      loadTime: Duration.zero,
    );
    _loaded = report;
    _states.add(SpeechEngineState.loaded);
    return Success<SpeechLoadReport>(report);
  }

  @override
  Future<Result<SpeechVadHandle>> openVad(SpeechModelSource vad) async {
    if (_disposed) {
      return FailureResult<SpeechVadHandle>(speechEngineStopped());
    }
    final int id = ++_nextVadId;
    _vadStates[id] = 0;
    return Success<SpeechVadHandle>(
      SpeechVadHandle(id: id, frameSamples: vadFrameSamples),
    );
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
    final double? state = _vadStates[vad.id];
    if (state == null ||
        samples.isEmpty ||
        samples.length % vad.frameSamples != 0) {
      return FailureResult<SpeechVadResult>(speechInvalidRequest());
    }
    if (cancel?.isCancelled ?? false) {
      return FailureResult<SpeechVadResult>(speechCancelled());
    }
    final int frames = samples.length ~/ vad.frameSamples;
    final Float32List probabilities = Float32List(frames);
    double running = resetState ? 0 : state;
    for (int frame = 0; frame < frames; frame++) {
      final bool loud =
          _dbfs(samples, frame * vad.frameSamples, vad.frameSamples) >=
          speechFloorDbfs;
      final double heard = loud ? _speechProbability : _silenceProbability;
      // A detector carries state across frames, like Silero's LSTM: after
      // speech the probability decays rather than dropping at once.
      running = heard >= running ? heard : max(heard, running * _vadDecay);
      probabilities[frame] = running;
    }
    _vadStates[vad.id] = running;
    vadBatches++;
    return Success<SpeechVadResult>(
      SpeechVadResult(
        probabilities: probabilities,
        frameSamples: vad.frameSamples,
      ),
    );
  }

  @override
  Future<void> closeVad(SpeechVadHandle vad) async {
    _vadStates.remove(vad.id);
  }

  @override
  Future<Result<SpeechDecodeResult>> decode(
    SpeechDecodeRequest request, {
    required int leaseId,
    CancellationToken? cancel,
  }) {
    if (_disposed) {
      return _refuse(speechEngineStopped());
    }
    decodes.add((request: request, leaseId: leaseId));
    if (!request.isWellFormed) {
      return _refuse(speechInvalidRequest());
    }
    if (_loaded == null) {
      return _refuse(speechUnavailable());
    }
    if (cancel?.isCancelled ?? false) {
      return _refuse(speechCancelled());
    }
    final _Job job = _Job(request, leaseId);
    if (request.kind == SpeechDecodeKind.interim) {
      final List<_Job> superseded = _pending
          .where(
            (_Job other) =>
                other.leaseId == leaseId &&
                other.request.kind == SpeechDecodeKind.interim,
          )
          .toList();
      for (final _Job other in superseded) {
        _pending.remove(other);
        other.complete(FailureResult<SpeechDecodeResult>(speechCancelled()));
      }
    } else {
      final _Job? running = _inFlight;
      if (running != null && running.request.kind == SpeechDecodeKind.interim) {
        _inFlight = null;
        running.complete(FailureResult<SpeechDecodeResult>(speechCancelled()));
      }
    }
    _pending.add(job);
    if (cancel != null) {
      job.detach = cancel.register(() => _cancel(job));
    }
    _pump();
    return job.result;
  }

  @override
  void abortLease(int leaseId) {
    abortedLeases.add(leaseId);
    final List<_Job> doomed = <_Job>[
      for (final _Job job in _pending)
        if (job.leaseId == leaseId) job,
    ];
    for (final _Job job in doomed) {
      _pending.remove(job);
      job.complete(FailureResult<SpeechDecodeResult>(speechCancelled()));
    }
    final _Job? running = _inFlight;
    if (running != null && running.leaseId == leaseId) {
      _inFlight = null;
      running.complete(FailureResult<SpeechDecodeResult>(speechCancelled()));
    }
    _pump();
  }

  @override
  Future<Result<void>> unload() async {
    if (_disposed) {
      return FailureResult<void>(speechEngineStopped());
    }
    if (_loaded != null) {
      _states.add(SpeechEngineState.unloading);
      _failAll(speechEngineStopped());
      _loaded = null;
      _states.add(SpeechEngineState.ready);
    }
    return const Success<void>(null);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _failAll(speechEngineStopped());
    _vadStates.clear();
    _loaded = null;
    _states.add(SpeechEngineState.disposed);
    await _states.close();
  }

  @override
  SpeechLoadReport? get loaded => _loaded;

  @override
  Stream<SpeechEngineState> get states => _states.stream;

  @override
  int get debugLiveHandles => (_loaded == null ? 0 : 1) + _vadStates.length;

  Future<Result<SpeechDecodeResult>> _refuse(Failure failure) =>
      Future<Result<SpeechDecodeResult>>.value(
        FailureResult<SpeechDecodeResult>(failure),
      );

  void _cancel(_Job job) {
    if (_pending.remove(job)) {
      job.complete(FailureResult<SpeechDecodeResult>(speechCancelled()));
      return;
    }
    if (identical(_inFlight, job)) {
      _inFlight = null;
      job.complete(FailureResult<SpeechDecodeResult>(speechCancelled()));
      _pump();
    }
  }

  void _failAll(Failure failure) {
    final List<_Job> jobs = <_Job>[?_inFlight, ..._pending];
    _inFlight = null;
    _pending.clear();
    for (final _Job job in jobs) {
      job.complete(FailureResult<SpeechDecodeResult>(failure));
    }
  }

  /// Dispatches the next job: committed requests first, in arrival order.
  void _pump() {
    if (_inFlight != null || _pending.isEmpty || _disposed) {
      if (_inFlight == null && _pending.isEmpty && _loaded != null) {
        _states.add(SpeechEngineState.loaded);
      }
      return;
    }
    final _Job next = _pending.firstWhere(
      (_Job job) => job.request.kind == SpeechDecodeKind.committed,
      orElse: () => _pending.first,
    );
    _pending.remove(next);
    _inFlight = next;
    _states.add(SpeechEngineState.busy);
    if (!_holding) {
      Timer.run(() => _finish(next));
    }
  }

  void _finish(_Job job) {
    if (!identical(_inFlight, job) || _holding) {
      return;
    }
    _inFlight = null;
    if (_nextDecodeFailures.isNotEmpty) {
      job.complete(
        FailureResult<SpeechDecodeResult>(_nextDecodeFailures.removeFirst()),
      );
    } else {
      job.complete(Success<SpeechDecodeResult>(_transcribe(job.request)));
    }
    _pump();
  }

  SpeechDecodeResult _transcribe(SpeechDecodeRequest request) {
    final _Window window = _Window(
      request,
      Random(
        _mix(<int>[
          seed,
          request.offsetSamples,
          request.samples.length,
          request.kind.index,
        ]),
      ),
    );
    List<_Heard> words = _wordsIn(window);
    final int maxPieces = request.profile.maxPiecesFor(request.samples.length);
    if (maxPieces > 0 && words.length > maxPieces) {
      words = words.sublist(0, maxPieces);
    }
    final bool looping =
        loopAtSpeechRate > 0 &&
        loopKinds.contains(request.kind) &&
        words.isNotEmpty &&
        window.random.nextDouble() < loopChance;
    List<_Heard> echoed = const <_Heard>[];
    if (echoPrompt > 0 &&
        request.prompt.trim().isNotEmpty &&
        window.random.nextDouble() < echoPrompt) {
      echoed = _echo(window, request.prompt);
    }
    final bool single = request.profile.singleSegment;
    int lead = 0;
    if (single && echoed.isNotEmpty) {
      lead = echoed.length;
      words = <_Heard>[...echoed, ...words];
      echoed = const <_Heard>[];
    }
    if (timeJitter > Duration.zero) {
      final List<_Heard> moved = _jitter(window, <_Heard>[...echoed, ...words]);
      echoed = moved.sublist(0, echoed.length);
      words = moved.sublist(echoed.length);
    }
    if (looping) {
      // The loop is said over the heard words' own (jittered) times.
      words = <_Heard>[
        ...words.take(lead),
        ..._loop(window, words.sublist(lead)),
      ];
    }
    final List<SpeechSegment> segments = <SpeechSegment>[
      // Whisper decodes an echo of its prompt as a weak segment of its own.
      if (echoed.isNotEmpty)
        _segment(
          window,
          echoed,
          noSpeech: _inventedNoSpeech,
          logProbability: _inventedLogProbability,
        ),
      if (words.isNotEmpty) _segment(window, words, noSpeech: _heardNoSpeech),
    ];
    final String? invented = hallucinate;
    if (invented != null) {
      final int from = max(window.start, window.end - window.second);
      final List<_Heard> made = <_Heard>[
        for (final String word in invented.split(' '))
          _Heard(word, from, window.end, _weakProbability),
      ];
      final SpeechSegment extra = _segment(
        window,
        made,
        noSpeech: _inventedNoSpeech,
        logProbability: _inventedLogProbability,
      );
      if (request.profile.singleSegment && segments.isNotEmpty) {
        segments[0] = _segment(window, <_Heard>[
          ...words,
          ...made,
        ], noSpeech: _heardNoSpeech);
      } else {
        segments.add(extra);
      }
    }
    return SpeechDecodeResult(
      segments: segments,
      language: request.language,
      offsetSamples: request.offsetSamples,
      sampleCount: request.samples.length,
      elapsed:
          computeTime +
          Duration(
            microseconds: (window.audioMicroseconds * computeFactor).round(),
          ),
    );
  }

  List<_Heard> _wordsIn(_Window window) {
    final List<_Heard> heard = <_Heard>[];
    final List<String> edgeModes = <String>[
      if (truncateEdgeWord) _truncate,
      if (completeEdgeWord) _complete,
      if (dropEdgeWord) _drop,
    ];
    for (final SpokenWord word in script.overlapping(
      window.start,
      window.end,
    )) {
      final int start = window.clampStart(word.startSample);
      final int end = window.clampEnd(word.endSample);
      final bool cut =
          word.startSample < window.start || word.endSample > window.end;
      if (!cut) {
        heard.add(_Heard(word.word, start, end, _heardProbability));
        continue;
      }
      if (edgeModes.isEmpty) {
        final int middle = (word.startSample + word.endSample) ~/ 2;
        if (middle >= window.start && middle < window.end) {
          heard.add(_Heard(word.word, start, end, _heardProbability));
        }
        continue;
      }
      switch (edgeModes[window.random.nextInt(edgeModes.length)]) {
        case _truncate:
          heard.add(
            _Heard(_cutText(word, window), start, end, _weakProbability),
          );
        case _complete:
          heard.add(_Heard(word.word, start, end, _heardProbability));
        default:
          droppedEdgeWords.add(word);
      }
    }
    return heard;
  }

  /// The letters of [word] that fall inside [window], at least one.
  static String _cutText(SpokenWord word, _Window window) {
    final int length = word.word.length;
    final int inside =
        min(word.endSample, window.end) - max(word.startSample, window.start);
    final double fraction = inside / (word.endSample - word.startSample);
    final int keep = (length * fraction).ceil().clamp(1, max(1, length - 1));
    return word.startSample < window.start
        ? word.word.substring(length - keep)
        : word.word.substring(0, keep);
  }

  List<_Heard> _loop(_Window window, List<_Heard> words) {
    final List<_Heard> phrase = words.take(_loopPhraseWords).toList();
    final int step = SpokenScript.samplesOf(loopWordDuration);
    final int from = phrase.first.start;
    return <_Heard>[
      for (int index = 0; index < loopAtSpeechRate * phrase.length; index++)
        _Heard(
          phrase[index % phrase.length].text,
          window.clampStart(from + index * step),
          window.clampEnd(from + (index + 1) * step),
          _loopProbability,
        ),
      ...words.skip(phrase.length),
    ];
  }

  List<_Heard> _echo(_Window window, String prompt) {
    final List<String> promptWords = prompt.trim().split(RegExp(r'\s+'));
    final int count =
        1 + window.random.nextInt(min(_echoWords, promptWords.length));
    final int step = window.second ~/ _echoWordsPerSecond;
    return <_Heard>[
      for (int index = 0; index < count; index++)
        _Heard(
          promptWords[promptWords.length - count + index],
          window.clampStart(window.start + index * step),
          window.clampEnd(window.start + (index + 1) * step),
          _weakProbability,
        ),
    ];
  }

  List<_Heard> _jitter(_Window window, List<_Heard> words) {
    final List<_Heard> moved = <_Heard>[];
    int floor = window.start;
    for (final _Heard word in words) {
      final int start = max(
        floor,
        window.clampStart(window.jitter(word.start, timeJitter)),
      );
      final int end = max(
        start,
        window.clampEnd(window.jitter(word.end, timeJitter)),
      );
      moved.add(_Heard(word.text, start, end, word.probability));
      floor = start;
    }
    return moved;
  }

  SpeechSegment _segment(
    _Window window,
    List<_Heard> words, {
    required double noSpeech,
    double logProbability = _heardLogProbability,
  }) {
    int start = words.first.start;
    int end = words.map((_Heard word) => word.end).reduce(max);
    if (timeJitter > Duration.zero) {
      start = window.clampStart(window.jitter(start, timeJitter));
      end = max(start, window.clampEnd(window.jitter(end, timeJitter)));
    }
    final List<SpeechPiece> pieces = <SpeechPiece>[
      for (final _Heard word in words)
        SpeechPiece(
          startSample: word.start,
          endSample: word.end,
          text: ' ${word.text}',
          probability: word.probability,
        ),
    ];
    return SpeechSegment(
      startSample: start,
      endSample: end,
      text: pieces.map((SpeechPiece piece) => piece.text).join(),
      noSpeechProbability: noSpeech,
      averageLogProbability: logProbability,
      confidence:
          words
              .map((_Heard word) => word.probability)
              .reduce((double a, double b) => a + b) /
          words.length,
      pieces: window.request.pieceTimings ? pieces : const <SpeechPiece>[],
    );
  }

  static SpeechModelShape _shapeOf(SpeechModelEntry entry) => SpeechModelShape(
    nVocab: entry.nVocab,
    nAudioCtx: AppConstants.speechEngine.maxAudioContext,
    nAudioState: entry.nAudioState,
    nAudioLayer: entry.nAudioLayer,
    nTextLayer: entry.nTextLayer,
    nMels: entry.nMels,
    ftype: entry.ftype,
    multilingual: entry.multilingual,
  );

  /// RMS loudness of [count] samples from [from], in dBFS.
  static double _dbfs(Float32List samples, int from, int count) {
    double sum = 0;
    for (int index = from; index < from + count; index++) {
      sum += samples[index] * samples[index];
    }
    final double rms = sqrt(sum / count);
    return rms <= 0 ? double.negativeInfinity : 20 * log(rms) / ln10;
  }

  /// A stable 31-bit hash of [parts]: the same on every run, unlike
  /// `Object.hash`.
  static int _mix(List<int> parts) {
    int hash = 0x2545F491;
    for (final int part in parts) {
      hash = ((hash ^ part) * 0x01000193) & 0x7FFFFFFF;
    }
    return hash;
  }
}

/// One decode in the queue.
final class _Job {
  _Job(this.request, this.leaseId);

  final SpeechDecodeRequest request;
  final int leaseId;
  final Completer<Result<SpeechDecodeResult>> _done =
      Completer<Result<SpeechDecodeResult>>();
  void Function()? detach;

  Future<Result<SpeechDecodeResult>> get result => _done.future;

  void complete(Result<SpeechDecodeResult> outcome) {
    detach?.call();
    detach = null;
    if (!_done.isCompleted) {
      _done.complete(outcome);
    }
  }
}

/// The window one decode covers, with its own seeded randomness.
final class _Window {
  _Window(this.request, this.random)
    : start = request.offsetSamples,
      end = request.offsetSamples + request.samples.length;

  final SpeechDecodeRequest request;
  final Random random;
  final int start;
  final int end;

  int get second => AppConstants.audio.sampleRate;

  double get audioMicroseconds =>
      (end - start) * Duration.microsecondsPerSecond / second;

  int clampStart(int sample) => sample.clamp(start, end - 1);

  int clampEnd(int sample) => sample.clamp(start, end);

  int jitter(int sample, Duration spread) {
    final int samples = SpokenScript.samplesOf(spread);
    return sample + random.nextInt(2 * samples + 1) - samples;
  }
}

/// A word as the fake reports it.
final class _Heard {
  const _Heard(this.text, this.start, this.end, this.probability);

  final String text;
  final int start;
  final int end;
  final double probability;
}

const String _truncate = 'truncate';
const String _complete = 'complete';
const String _drop = 'drop';
const int _loopPhraseWords = 3;
const int _echoWords = 3;
const int _echoWordsPerSecond = 10;
const double _speechProbability = 0.9;
const double _silenceProbability = 0.02;
const double _vadDecay = 0.5;
const double _heardProbability = 0.9;
const double _weakProbability = 0.45;
const double _loopProbability = 0.8;
const double _heardNoSpeech = 0.02;
const double _heardLogProbability = -0.2;
const double _inventedNoSpeech = 0.3;
const double _inventedLogProbability = -0.9;
