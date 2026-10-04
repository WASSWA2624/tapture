import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:tapture/core/audio/capture_pause_reason.dart';
import 'package:tapture/core/audio/pcm_store.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/logging/logger.dart';

import '../finished_utterance.dart';
import '../live_transcription_event.dart';
import '../speech_decode_kind.dart';
import '../speech_decode_profile.dart';
import '../speech_decode_request.dart';
import '../speech_decode_result.dart';
import '../speech_engine_lease.dart';
import '../speech_failures.dart';
import '../speech_segment.dart';
import '../speech_text.dart';
import '../transcript_segment.dart';
import '../transcript_sink.dart';
import '../transcription_warning_kind.dart';
import 'backpressure_level.dart';
import 'decode_job.dart';
import 'decode_scheduler.dart';
import 'interim_stabiliser.dart';
import 'pcm_conversion.dart';
import 'prompt_carry.dart';
import 'segment_assembler.dart';
import 'segment_text.dart';
import 'segmenter_phase.dart';
import 'speech_pipeline_config.dart';
import 'utterance_boundary.dart';
import 'vad_driver.dart';
import 'word_sequence.dart';

/// Turns a take's audio, as it is captured, into transcript segments
/// (spec §30.4.7). Internal to `core/speech`; the live transcription
/// session owns one per take.
///
/// The [VadDriver] closes utterances; their finals are decoded in order,
/// one job at a time, from the [PcmStore] at dispatch, so a slow engine
/// lags and never loses audio, and a backlog left at stop is read from the
/// published take. The open utterance is drafted between finals and its
/// drafts are stabilised ([InterimStabiliser]). Each final is assembled
/// ([SegmentAssembler]) and written to the sink; only then are its
/// [SegmentFinalized] and [UtteranceFinalized] events emitted, durable
/// unless the sink failed. A sink failure keeps the utterance, and every
/// later one, queued in order and retried before the next.
///
/// A final that fails is retried once, then recorded as a gap (a skipped
/// utterance). After `maxConsecutiveDecodeFailures` failed decodes in a
/// row decoding stops, its finals kept, until a lease is attached again.
///
/// Finals are never dropped and finalized audio is never decoded again.
/// Draft text is never persisted and nothing here logs text.
final class SpeechPipeline {
  /// A pipeline over [store] with [config], writing to `sink` (none for
  /// memory-only dictation), numbering segments from [nextSegmentId] and
  /// reporting through `emit`.
  SpeechPipeline({
    required PcmStore store,
    required SpeechPipelineConfig config,
    this._sink,
    required int nextSegmentId,
    required this._emit,
    Logger? logger,
  }) : _store = store,
       _config = config,
       _logger = logger ?? Logger.current,
       _scheduler = DecodeScheduler(config: config),
       _assembler = SegmentAssembler(
         config: config,
         nextSegmentId: nextSegmentId,
       ),
       _prompt = PromptCarry(config: config),
       _noticeSamples = config.samplesOf(config.engineBehindNoticeInterval) {
    _vad = VadDriver(
      store: store,
      config: config,
      onClosed: _onClosed,
      onAdvanced: _onAdvanced,
      onFailure: _onDetectorFailure,
    );
  }

  final PcmStore _store;
  final SpeechPipelineConfig _config;
  final TranscriptSink? _sink;
  final void Function(LiveTranscriptionEvent event) _emit;
  final Logger _logger;
  final DecodeScheduler _scheduler;
  final SegmentAssembler _assembler;
  final PromptCarry _prompt;
  final InterimStabiliser _stabiliser = InterimStabiliser();
  final int _noticeSamples;
  final ListQueue<_Unsaved> _unsaved = ListQueue<_Unsaved>();
  final List<Completer<void>> _drainWaiters = <Completer<void>>[];
  late final VadDriver _vad;

  SpeechEngineLease? _lease;
  CancellationToken? _inFlightCancel;
  Completer<void>? _writing;
  Failure? _sinkFailure;
  int _available = 0;
  int _attempts = 0;
  int _consecutiveFailures = 0;
  int _retained = 0;
  int? _lastNoticeAt;
  bool _decodingStopped = false;
  bool _detectorDone = false;
  bool _skipping = false;
  bool _aborted = false;

  /// The sample up to which the take is accounted for: every utterance
  /// before it decoded or recorded as a gap and stored, and the rest
  /// silence. Never past audio a later decode may still cover.
  int get coveredToSample {
    int covered = _detectorDone
        ? math.max(_available, _vad.cursor)
        : _vad.settledTo;
    if (_scheduler.pendingFinals.isNotEmpty) {
      covered = math.min(covered, _scheduler.pendingFinals.first.startSample);
    }
    for (final UtteranceBoundary waiting in _assembler.waiting) {
      covered = math.min(covered, waiting.startSample);
    }
    if (_unsaved.isNotEmpty) {
      covered = math.min(covered, _unsaved.first.utterance.fromSample);
    }
    return math.max(0, covered);
  }

  /// Closed audio still waiting for its final.
  Duration get backlog => _durationOf(_scheduler.backlogSamples);

  /// Utterances not yet stored, oldest first.
  List<FinishedUtterance> get unsaved => List<FinishedUtterance>.unmodifiable(
    _unsaved.map((_Unsaved entry) => entry.utterance),
  );

  /// Completes once no sink write is in flight.
  Future<void> get sinkIdle => _writing?.future ?? Future<void>.value();

  /// Samples the pipeline holds right now for decoding; bounded by one
  /// utterance plus its seam whatever the backlog.
  @visibleForTesting
  int get debugPipelineRetainedSamples => _retained;

  /// Starts, or restarts after a failure, decoding and detection on
  /// [lease]. Decoding stopped by failures resumes with the queued finals.
  void attachLease(SpeechEngineLease lease) {
    if (_aborted) {
      return;
    }
    _lease = lease;
    _decodingStopped = false;
    _consecutiveFailures = 0;
    _attempts = 0;
    _vad.attachLease(lease);
    _pump();
  }

  /// The take now holds [totalSamples] samples.
  void audioAvailable(int totalSamples) {
    if (_aborted) {
      return;
    }
    _available = math.max(_available, totalSamples);
    _vad.audioAvailable(totalSamples);
  }

  /// Capture paused at [atSample] for [why]: the open utterance closes
  /// there.
  void markPause(int atSample, CapturePauseReason why) {
    if (_aborted) {
      return;
    }
    _logger.info(_tag, 'pipeline paused (${why.name})');
    _vad.markPause(atSample);
  }

  /// Capture resumed at [atSample]: no utterance spans the pause.
  void markResume(int atSample) {
    if (_aborted) {
      return;
    }
    _vad.markResume(atSample);
  }

  /// Ends the take. With [drain] the detector runs to the end of the
  /// store, the open utterance closes there, and every final is decoded
  /// and offered to the sink before this completes; without a lease it
  /// waits for one. Without [drain], or when called again without it
  /// while a drain runs, work stops at once: finals not yet decoded stay
  /// uncovered, past [coveredToSample].
  Future<void> finish({required bool drain}) async {
    if (_aborted) {
      return;
    }
    if (!drain) {
      _skipping = true;
      _vad.abort();
      _inFlightCancel?.cancel();
      _releaseDrainWaiters();
      await sinkIdle;
      return;
    }
    await _vad.finish(math.max(_available, _store.length));
    if (!_skipping && !_aborted) {
      _available = math.max(_available, _store.length);
      _detectorDone = true;
      _pump();
      await _drained();
    }
    await sinkIdle;
  }

  /// Stops everything: the decode in flight is cancelled, nothing more is
  /// decoded, written or reported. Completes once the sink write in flight,
  /// if any, has finished.
  Future<void> abort() async {
    if (_aborted) {
      return;
    }
    _aborted = true;
    _vad.abort();
    _inFlightCancel?.cancel();
    _releaseDrainWaiters();
    await sinkIdle;
  }

  /// Writes the queued utterances again, in order. Succeeds once every one
  /// is stored.
  Future<Result<void>> retryUnsaved() async {
    await sinkIdle;
    await _writeQueued();
    final Failure? failure = _sinkFailure;
    return _unsaved.isEmpty || failure == null
        ? const Success<void>(null)
        : FailureResult<void>(failure);
  }

  void _onClosed(UtteranceBoundary utterance) {
    _stabiliser.close(utterance.id);
    if (_scheduler.closeUtterance(utterance.id)) {
      _inFlightCancel?.cancel();
    }
    _scheduler.enqueueFinal(utterance);
    _noticeIfBehind();
    _pump();
  }

  void _onAdvanced() {
    final int? openStart = _vad.openStart;
    final SegmenterPhase phase = _vad.phase;
    if (openStart != null &&
        (phase == SegmenterPhase.speech || phase == SegmenterPhase.hangover)) {
      // A draft covers the whole open utterance: after a hard cut the
      // previous one's text stops short of the seam, which waits for this
      // utterance's final.
      if (_scheduler.offerInterim(
        utteranceId: _vad.nextUtteranceId,
        startSample: openStart,
        fromSample: openStart,
        toSample: _vad.cursor,
      )) {
        _pump();
      }
    }
    _noticeIfBehind();
  }

  void _onDetectorFailure(Failure failure) {
    _logger.warn(_tag, 'voice detection failed (${failure.runtimeType})');
    _emit(
      TranscriptionWarning(
        kind: TranscriptionWarningKind.transcriptionUnavailable,
        cause: failure,
      ),
    );
  }

  void _noticeIfBehind() {
    if (_scheduler.level == BackpressureLevel.normal) {
      return;
    }
    final int now = math.max(_available, _vad.cursor);
    final int? last = _lastNoticeAt;
    if (last != null && now - last < _noticeSamples) {
      return;
    }
    _lastNoticeAt = now;
    _logger.info(_tag, 'transcription behind (${_scheduler.level.name})');
    _emit(
      TranscriptionWarning(
        kind: TranscriptionWarningKind.engineBehind,
        lag: backlog,
      ),
    );
  }

  void _pump() {
    final SpeechEngineLease? lease = _lease;
    if (_aborted || _skipping || _decodingStopped || lease == null) {
      _checkDrained();
      return;
    }
    final DecodeJob? job = _scheduler.next();
    if (job == null) {
      _checkDrained();
      return;
    }
    unawaited(_run(lease, job));
  }

  Future<void> _run(SpeechEngineLease lease, DecodeJob job) async {
    final CancellationToken cancel = _inFlightCancel = CancellationToken();
    final bool committed = job.kind == SpeechDecodeKind.committed;
    final UtteranceBoundary? utterance = job.utterance;
    final String prompt = utterance != null
        ? _prompt.promptFor(utterance)
        : _prompt.promptAt(startSample: job.fromSample, length: job.length);
    _retained = job.length;
    final Result<Int16List> read = await _store.read(
      job.fromSample,
      job.toSample,
    );
    final Result<SpeechDecodeResult> outcome;
    switch (read) {
      case FailureResult<Int16List>(:final Failure failure):
        outcome = FailureResult<SpeechDecodeResult>(failure);
      case Success<Int16List>(:final Int16List value):
        final Float32List samples = Float32List(value.length);
        PcmConversion.toFloat32(value, samples);
        outcome = cancel.isCancelled
            ? FailureResult<SpeechDecodeResult>(speechCancelled())
            : await lease.decode(
                SpeechDecodeRequest(
                  samples: samples,
                  language: lease.selection.language,
                  kind: job.kind,
                  profile: committed
                      ? _finalProfile(lease, job.length)
                      : lease.selection.interim,
                  offsetSamples: job.fromSample,
                  prompt: prompt,
                  pieceTimings: committed,
                ),
                cancel: cancel,
              );
    }
    _retained = 0;
    if (identical(_inFlightCancel, cancel)) {
      _inFlightCancel = null;
    }
    if (_aborted) {
      return;
    }
    if (committed) {
      _onFinal(utterance!, job, outcome, lease: lease, prompt: prompt);
    } else {
      _onDraft(job, outcome);
    }
    _pump();
  }

  SpeechDecodeProfile _finalProfile(SpeechEngineLease lease, int samples) {
    final SpeechDecodeProfile profile = _config.dictation
        ? lease.selection.dictationCommittedFor(samples)
        : lease.selection.committed;
    return _scheduler.level == BackpressureLevel.reducedContext
        ? profile.copyWith(
            audioContextPad: AppConstants.speechEngine.reducedAudioContextPad,
          )
        : profile;
  }

  void _onDraft(DecodeJob job, Result<SpeechDecodeResult> outcome) {
    switch (outcome) {
      case Success<SpeechDecodeResult>(:final SpeechDecodeResult value):
        _scheduler.completed(job, compute: value.elapsed);
        if (_vad.openStart == null || _vad.nextUtteranceId != job.utteranceId) {
          return;
        }
        final String text = SegmentText.clean(
          SpeechText.join(
            value.segments.map((SpeechSegment segment) => segment.text),
          ),
        );
        final InterimTranscript? draft = _stabiliser.accept(
          job.utteranceId,
          job.fromSample,
          WordSequence.words(text),
        );
        if (draft != null) {
          _emit(draft);
        }
      case FailureResult<SpeechDecodeResult>():
        _scheduler.released(job);
    }
  }

  void _onFinal(
    UtteranceBoundary utterance,
    DecodeJob job,
    Result<SpeechDecodeResult> outcome, {
    required SpeechEngineLease lease,
    required String prompt,
  }) {
    switch (outcome) {
      case Success<SpeechDecodeResult>(:final SpeechDecodeResult value):
        _attempts = 0;
        _consecutiveFailures = 0;
        _scheduler.completed(job);
        _assemble(utterance, value, lease: lease, prompt: prompt);
      case FailureResult<SpeechDecodeResult>(:final Failure failure):
        _scheduler.released(job);
        if (_skipping) {
          return;
        }
        _attempts++;
        _consecutiveFailures++;
        _logger.warn(
          _tag,
          'final decode failed (${failure.runtimeType}), attempt $_attempts',
        );
        final bool stop =
            _consecutiveFailures >= _config.maxConsecutiveDecodeFailures;
        if (_attempts < _finalAttempts && !stop) {
          return;
        }
        _attempts = 0;
        _scheduler.completed(job);
        _emit(
          TranscriptionWarning(
            kind: TranscriptionWarningKind.utteranceSkipped,
            cause: failure,
          ),
        );
        _assemble(utterance, null, lease: lease, prompt: prompt);
        if (stop) {
          _decodingStopped = true;
          _logger.warn(_tag, 'decoding stopped after repeated failures');
          _emit(
            TranscriptionWarning(
              kind: TranscriptionWarningKind.transcriptionUnavailable,
              cause: failure,
            ),
          );
        }
    }
  }

  void _assemble(
    UtteranceBoundary utterance,
    SpeechDecodeResult? result, {
    required SpeechEngineLease lease,
    required String prompt,
  }) {
    final List<({FinishedUtterance utterance, bool resetPrompt})> ready =
        _assembler.add(
          utterance,
          result: result,
          language: lease.selection.language,
          modelId: lease.modelId,
          prompt: prompt,
        );
    for (final ({FinishedUtterance utterance, bool resetPrompt}) done
        in ready) {
      if (done.resetPrompt) {
        _prompt.reset();
      } else {
        _prompt.commit(done.utterance.segments);
      }
      _unsaved.addLast(_Unsaved(done.utterance));
    }
    if (ready.isNotEmpty) {
      unawaited(_writeQueued());
    }
  }

  /// Writes the queue in order. The first failure stops the run: the
  /// utterances still queued are reported, not durable, and wait for the
  /// next utterance or [retryUnsaved].
  Future<void> _writeQueued() async {
    if (_writing != null) {
      return;
    }
    final Completer<void> writing = _writing = Completer<void>();
    try {
      while (_unsaved.isNotEmpty && !_aborted) {
        final _Unsaved head = _unsaved.first;
        final TranscriptSink? sink = _sink;
        final Result<void> written = sink == null
            ? const Success<void>(null)
            : await sink.appendUtterance(head.utterance);
        if (_aborted) {
          return;
        }
        switch (written) {
          case Success<void>():
            _sinkFailure = null;
            _unsaved.removeFirst();
            if (!head.reported) {
              _report(head.utterance, durable: true);
            }
          case FailureResult<void>(:final Failure failure):
            _sinkFailure = failure;
            _logger.warn(
              _tag,
              'sink write failed (${failure.runtimeType}), '
              '${_unsaved.length} utterances queued',
            );
            for (final _Unsaved entry in _unsaved) {
              if (!entry.reported) {
                entry.reported = true;
                _report(entry.utterance, durable: false);
                _emit(
                  TranscriptionWarning(
                    kind: TranscriptionWarningKind.transcriptUnsaved,
                    cause: failure,
                  ),
                );
              }
            }
            return;
        }
      }
    } finally {
      _writing = null;
      writing.complete();
      _checkDrained();
    }
  }

  void _report(FinishedUtterance utterance, {required bool durable}) {
    for (final TranscriptSegment segment in utterance.segments) {
      _emit(SegmentFinalized(segment: segment, durable: durable));
    }
    _emit(
      UtteranceFinalized(
        utteranceId: utterance.utteranceId,
        fromSample: utterance.fromSample,
        toSample: utterance.toSample,
        segmentCount: utterance.segments.length,
        durable: durable,
        skipped: utterance.skipped,
      ),
    );
  }

  Future<void> _drained() {
    final Completer<void> waiter = Completer<void>();
    _drainWaiters.add(waiter);
    _checkDrained();
    return waiter.future;
  }

  void _checkDrained() {
    if (_drainWaiters.isEmpty || !_detectorDone) {
      return;
    }
    final bool settled =
        _aborted ||
        _skipping ||
        _decodingStopped ||
        (_scheduler.pendingFinals.isEmpty && _scheduler.inFlight == null);
    if (settled && _writing == null) {
      _releaseDrainWaiters();
    }
  }

  void _releaseDrainWaiters() {
    final List<Completer<void>> waiters = List<Completer<void>>.of(
      _drainWaiters,
    );
    _drainWaiters.clear();
    for (final Completer<void> waiter in waiters) {
      waiter.complete();
    }
  }

  static Duration _durationOf(int samples) => Duration(
    microseconds:
        samples *
        Duration.microsecondsPerSecond ~/
        AppConstants.audio.sampleRate,
  );
}

/// One finished utterance waiting for, or retrying, its sink write.
final class _Unsaved {
  _Unsaved(this.utterance);

  final FinishedUtterance utterance;

  /// Whether its events already went out, not durable.
  bool reported = false;
}

const String _tag = 'speech';

/// Decodes a final gets before it is recorded as a gap.
const int _finalAttempts = 2;
