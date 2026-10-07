import 'dart:async';

import 'package:tapture/core/audio/audio_recording.dart';
import 'package:tapture/core/audio/capture_pause_reason.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/speech/speech.dart';

/// A live transcription service a test drives by hand (FE-TEST-03): each
/// start opens a [FakeLiveTranscriptionSession] the test drafts, finalizes,
/// pauses, stops and completes.
///
/// Shared by the dictation tests (task 120) and the live transcript
/// controller tests (task 122).
final class FakeLiveTranscriptionService implements LiveTranscriptionService {
  /// A service whose sessions publish [recording] when they stop.
  FakeLiveTranscriptionService({this.recording});

  /// What a stopped session publishes; null for memory-only dictation.
  AudioRecording? recording;

  /// Returned by every start instead of a session, while set.
  Failure? startFailure;

  /// While set, every start waits for it, as the microphone opening would.
  Completer<void>? holdStart;

  /// Runs at the start of every start, before the microphone would open,
  /// so a test can check what was already durable.
  void Function(LiveTranscriptionRequest request)? onStart;

  /// Every request started, in order.
  final List<LiveTranscriptionRequest> requests = <LiveTranscriptionRequest>[];

  /// Every session opened, in order.
  final List<FakeLiveTranscriptionSession> sessions =
      <FakeLiveTranscriptionSession>[];

  /// The most recent session.
  FakeLiveTranscriptionSession get session => sessions.last;

  @override
  Future<Result<LiveTranscriptionSession>> start(
    LiveTranscriptionRequest request,
  ) async {
    requests.add(request);
    onStart?.call(request);
    final Completer<void>? held = holdStart;
    if (held != null) {
      await held.future;
    }
    final Failure? failure = startFailure;
    if (failure != null) {
      return FailureResult<LiveTranscriptionSession>(failure);
    }
    final FakeLiveTranscriptionSession opened = FakeLiveTranscriptionSession(
      request,
      recording: recording,
    );
    sessions.add(opened);
    return Success<LiveTranscriptionSession>(opened);
  }

  @override
  Future<Result<AudioRecording?>> recoverAudio(String audioPath) async {
    return const Success<AudioRecording?>(null);
  }

  @override
  Stream<LiveTranscriptionEvent> transcribeRemaining(
    String audioPath, {
    required List<(int, int)> gaps,
    required int fromSample,
    required int nextSegmentId,
    required String languageTag,
    required TranscriptSink sink,
  }) {
    return const Stream<LiveTranscriptionEvent>.empty();
  }

  @override
  Future<void> dispose() async {
    for (final FakeLiveTranscriptionSession open in sessions) {
      await open.close();
    }
  }
}

/// One session of [FakeLiveTranscriptionService].
///
/// [draft] and [finalize] report words as the pipeline would, without
/// writing; [say] finishes an utterance through the request's sink first,
/// as the real pipeline does. [complete] ends the drain, finishing the sink
/// before [done]; [fail] ends the session as failed.
final class FakeLiveTranscriptionSession implements LiveTranscriptionSession {
  /// A session for [request] that publishes [recording] when it stops.
  FakeLiveTranscriptionSession(this.request, {this.recording});

  /// What the session was started with.
  final LiveTranscriptionRequest request;

  /// What [stop] publishes.
  final AudioRecording? recording;

  final StreamController<LiveTranscriptionEvent> _bus =
      StreamController<LiveTranscriptionEvent>.broadcast(sync: true);
  final Completer<Result<LiveTranscriptionResult>> _done =
      Completer<Result<LiveTranscriptionResult>>();
  final List<TranscriptSegment> _segments = <TranscriptSegment>[];
  final List<FinishedUtterance> _queued = <FinishedUtterance>[];
  LiveTranscriptionPhase _phase = LiveTranscriptionPhase.listening;
  CapturePauseReason? _pauseReason;
  Future<Result<StoppedCapture>>? _stopRun;
  int _nextSegment = 0;
  int _nextUtterance = 1;
  int _sample = 0;

  /// The stop fails with this, ending the session as failed.
  Failure? stopFailure;

  /// The next resume fails with this; a [PermissionFailure] keeps the
  /// session paused as `permissionRevoked`, as the real one does.
  Failure? resumeFailure;

  /// While set, a stop waits for it before publishing.
  Completer<void>? holdStop;

  /// How many times [stop] was called.
  int stops = 0;

  /// How many times [cancel] was called.
  int cancels = 0;

  /// Whether [skipRemaining] ran.
  bool skipped = false;

  @override
  Stream<LiveTranscriptionEvent> get events {
    StreamSubscription<LiveTranscriptionEvent>? forwarded;
    late final StreamController<LiveTranscriptionEvent> out;
    out = StreamController<LiveTranscriptionEvent>(
      onListen: () {
        out.add(TranscriptionStateChanged(phase: _phase, reason: _pauseReason));
        if (_bus.isClosed) {
          unawaited(out.close());
          return;
        }
        forwarded = _bus.stream.listen(
          out.add,
          onDone: () => unawaited(out.close()),
        );
      },
      onCancel: () => forwarded?.cancel(),
    );
    return out.stream;
  }

  @override
  LiveTranscriptionPhase get phase => _phase;

  @override
  CapturePauseReason? get pauseReason => _pauseReason;

  @override
  Future<Result<LiveTranscriptionResult>> get done => _done.future;

  /// Reports [event] to every listener.
  void emit(LiveTranscriptionEvent event) {
    if (!_bus.isClosed) {
      _bus.add(event);
    }
  }

  /// Moves to [phase], paused for [reason].
  void setPhase(LiveTranscriptionPhase phase, {CapturePauseReason? reason}) {
    _phase = phase;
    _pauseReason = phase == LiveTranscriptionPhase.paused ? reason : null;
    emit(TranscriptionStateChanged(phase: phase, reason: _pauseReason));
  }

  /// Pauses without being asked, as the app going to the background, a
  /// call or a lost microphone would.
  void pauseFor(CapturePauseReason reason) {
    if (_phase == LiveTranscriptionPhase.listening) {
      setPhase(LiveTranscriptionPhase.paused, reason: reason);
    }
  }

  /// A draft of utterance [utteranceId]: [stable] words, then [tentative]
  /// ones.
  void draft(int utteranceId, String stable, String tentative) {
    emit(
      InterimTranscript(
        utteranceId: utteranceId,
        startSample: _sample,
        stable: stable,
        tentative: tentative,
      ),
    );
  }

  /// Utterance [utteranceId] finished as [texts], one segment each, with
  /// [confidence]; nothing is written to the sink.
  void finalize(int utteranceId, List<String> texts, {double? confidence}) {
    final FinishedUtterance utterance = _utterance(
      utteranceId,
      texts,
      confidence: confidence,
    );
    _report(utterance, durable: true);
  }

  /// Finishes the next utterance as [texts], one segment of [samplesEach]
  /// samples each, written through the request's sink as the pipeline
  /// writes it: in order, after any utterance whose write failed before.
  /// Returns whether this utterance's write was durable; a failed write is
  /// reported with a `transcriptUnsaved` warning and retried first next
  /// time.
  Future<bool> say(List<String> texts, {int samplesEach = 16000}) async {
    final FinishedUtterance utterance = _utterance(
      _nextUtterance,
      texts,
      samplesEach: samplesEach,
    );
    _queued.add(utterance);
    final TranscriptSink? sink = request.sink;
    Failure? failed;
    while (_queued.isNotEmpty && sink != null) {
      final Result<void> written = await sink.appendUtterance(_queued.first);
      if (written case FailureResult<void>(:final Failure failure)) {
        failed = failure;
        break;
      }
      _queued.removeAt(0);
    }
    if (sink == null) {
      _queued.clear();
    }
    final bool durable = failed == null;
    _report(utterance, durable: durable);
    if (failed != null) {
      emit(
        TranscriptionWarning(
          kind: TranscriptionWarningKind.transcriptUnsaved,
          cause: failed,
        ),
      );
    }
    return durable;
  }

  FinishedUtterance _utterance(
    int utteranceId,
    List<String> texts, {
    double? confidence,
    int samplesEach = 16000,
  }) {
    if (utteranceId >= _nextUtterance) {
      _nextUtterance = utteranceId + 1;
    }
    final int from = _sample;
    final List<TranscriptSegment> segments = <TranscriptSegment>[
      for (final String text in texts)
        TranscriptSegment(
          id: request.nextSegmentId + _nextSegment++,
          utteranceId: utteranceId,
          startSample: _sample,
          endSample: _sample += samplesEach,
          text: text,
          languageTag: request.languageTag,
          modelId: 'fake',
          confidence: confidence,
        ),
    ];
    return FinishedUtterance(
      utteranceId: utteranceId,
      fromSample: from,
      toSample: _sample,
      segments: segments,
    );
  }

  void _report(FinishedUtterance utterance, {required bool durable}) {
    _segments.addAll(utterance.segments);
    for (final TranscriptSegment segment in utterance.segments) {
      emit(SegmentFinalized(segment: segment, durable: durable));
    }
    emit(
      UtteranceFinalized(
        utteranceId: utterance.utteranceId,
        fromSample: utterance.fromSample,
        toSample: utterance.toSample,
        segmentCount: utterance.segments.length,
        durable: durable,
      ),
    );
  }

  @override
  Future<Result<void>> pause() async {
    if (_phase != LiveTranscriptionPhase.listening) {
      return const FailureResult<void>(ValidationFailure());
    }
    setPhase(LiveTranscriptionPhase.paused, reason: CapturePauseReason.user);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> resume() async {
    if (_phase != LiveTranscriptionPhase.paused) {
      return const FailureResult<void>(ValidationFailure());
    }
    final Failure? failure = resumeFailure;
    if (failure != null) {
      resumeFailure = null;
      if (failure is PermissionFailure) {
        setPhase(
          LiveTranscriptionPhase.paused,
          reason: CapturePauseReason.permissionRevoked,
        );
      }
      return FailureResult<void>(failure);
    }
    setPhase(LiveTranscriptionPhase.listening);
    return const Success<void>(null);
  }

  @override
  Future<Result<StoppedCapture>> stop() {
    stops++;
    return _stopRun ??= _stop(StopReason.user);
  }

  /// Stops by itself for [reason], as silence, a limit or storage would;
  /// a later [stop] returns the same stop.
  Future<Result<StoppedCapture>> autoStop({
    StopReason reason = StopReason.silence,
  }) {
    return _stopRun ??= _stop(reason);
  }

  Future<Result<StoppedCapture>> _stop(StopReason reason) async {
    setPhase(LiveTranscriptionPhase.stopping);
    final Completer<void>? held = holdStop;
    if (held != null) {
      await held.future;
    }
    final Failure? failure = stopFailure;
    if (failure != null) {
      await fail(failure);
      return FailureResult<StoppedCapture>(failure);
    }
    setPhase(LiveTranscriptionPhase.draining);
    emit(const TranscriptionDraining(pending: Duration.zero));
    return Success<StoppedCapture>(
      StoppedCapture(audio: recording, captured: _captured, reason: reason),
    );
  }

  /// Ends the drain: the sink records how the transcript ended, then
  /// [done] completes with the segments, stopped for [reason].
  Future<void> complete({
    StopReason reason = StopReason.user,
    bool transcriptComplete = true,
  }) async {
    if (_done.isCompleted) {
      return;
    }
    await request.sink?.finish(
      TranscriptOutcome(
        complete: transcriptComplete,
        captured: _captured,
        coveredToSample: _sample,
        languageTag: request.languageTag,
        modelId: 'fake',
      ),
    );
    setPhase(LiveTranscriptionPhase.completed);
    _done.complete(
      Success<LiveTranscriptionResult>(
        LiveTranscriptionResult(
          segments: List<TranscriptSegment>.unmodifiable(_segments),
          languageTag: request.languageTag,
          modelId: 'fake',
          captured: _captured,
          transcriptComplete: transcriptComplete,
          coveredToSample: _sample,
          unsaved: const <FinishedUtterance>[],
          stopReason: reason,
        ),
      ),
    );
    unawaited(_bus.close());
  }

  /// Ends the session as failed with [failure].
  Future<void> fail(Failure failure) async {
    if (_done.isCompleted) {
      return;
    }
    emit(TranscriptionFailed(failure: failure));
    setPhase(LiveTranscriptionPhase.failed);
    _done.complete(FailureResult<LiveTranscriptionResult>(failure));
    unawaited(_bus.close());
  }

  @override
  void skipRemaining() {
    skipped = true;
  }

  @override
  Future<Result<CancelledTranscription>> cancel() async {
    cancels++;
    if (_done.isCompleted) {
      return const FailureResult<CancelledTranscription>(ValidationFailure());
    }
    setPhase(LiveTranscriptionPhase.cancelled);
    _done.complete(
      const FailureResult<LiveTranscriptionResult>(CancelledFailure()),
    );
    unawaited(_bus.close());
    final String? path = request.audioPath;
    return Success<CancelledTranscription>(
      CancelledTranscription(
        keptStagingPath: path == null ? null : '$path.recording',
        captured: _captured,
      ),
    );
  }

  /// Closes the event stream.
  Future<void> close() async {
    unawaited(_bus.close());
  }

  Duration get _captured =>
      Duration(microseconds: _sample * Duration.microsecondsPerSecond ~/ 16000);
}
