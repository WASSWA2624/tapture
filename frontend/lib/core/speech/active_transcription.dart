part of 'live_transcription_service.dart';

/// One running session: capture streams into the take, the pipeline
/// transcribes from the take's store, and the service owns the drain.
final class _ActiveTranscription implements LiveTranscriptionSession {
  _ActiveTranscription({
    required this._service,
    required this._request,
    required this._capture,
    required this._acquiring,
  }) : _dictation = _request.kind == TranscriptionKind.dictation {
    if (_acquiring != null) {
      _pipeline = _service._pipelineFor(
        _capture.store,
        languageTag: _request.languageTag,
        interims: _request.interims,
        dictation: _dictation,
        sink: _request.sink,
        nextSegmentId: _request.nextSegmentId,
        emit: _emit,
      );
    }
    final Duration? silence =
        _request.autoStopAfterSilence ??
        (_dictation ? AppConstants.dictation.pauseFor : null);
    final Duration? longest =
        _request.maxDuration ??
        (_dictation ? AppConstants.dictation.listenFor : null);
    _silenceSamples = silence == null
        ? null
        : _LiveTranscriptionService._samplesOf(silence);
    _maxSamples = longest == null
        ? null
        : _LiveTranscriptionService._samplesOf(longest);
    _limitSamples = _LiveTranscriptionService._samplesOf(
      _service._sessionLimit,
    );
    _storageEvery = _LiveTranscriptionService._samplesOf(
      AppConstants.speechSession.storageCheckInterval,
    );
    _nextStorageCheck = _storageEvery;
  }

  final _LiveTranscriptionService _service;
  final LiveTranscriptionRequest _request;
  final AudioCaptureSession _capture;
  final Future<Result<SpeechEngineLease>>? _acquiring;
  final bool _dictation;
  final StreamController<LiveTranscriptionEvent> _bus =
      StreamController<LiveTranscriptionEvent>.broadcast();
  final Completer<Result<LiveTranscriptionResult>> _done =
      Completer<Result<LiveTranscriptionResult>>();
  final Completer<void> _skipSignal = Completer<void>();
  final List<TranscriptSegment> _segments = <TranscriptSegment>[];

  SpeechPipeline? _pipeline;
  SpeechEngineLease? _lease;
  Future<void>? _acquired;
  StreamSubscription<PcmChunk>? _chunks;
  StreamSubscription<AudioCaptureEvent>? _captureEvents;
  Future<Result<StoppedCapture>>? _stopRun;
  Future<Result<CancelledTranscription>>? _cancelRun;
  Failure? _endFailure;
  CapturePauseReason? _requestedPause;
  LiveTranscriptionPhase _phase = LiveTranscriptionPhase.listening;
  CapturePauseReason? _pauseReason;
  StopReason _stopReason = StopReason.user;
  late final int? _silenceSamples;
  late final int? _maxSamples;
  late final int _limitSamples;
  late final int _storageEvery;
  int _nextStorageCheck = 0;
  bool _skipRequested = false;
  bool _exiting = false;
  bool _ended = false;

  Logger get _log => _service._logger;

  @override
  Stream<LiveTranscriptionEvent> get events {
    return Stream<LiveTranscriptionEvent>.multi((
      MultiStreamController<LiveTranscriptionEvent> out,
    ) {
      out.add(TranscriptionStateChanged(phase: _phase, reason: _pauseReason));
      if (_bus.isClosed) {
        unawaited(out.close());
        return;
      }
      final StreamSubscription<LiveTranscriptionEvent> forwarded = _bus.stream
          .listen(out.add, onError: out.addError, onDone: out.close);
      out.onCancel = forwarded.cancel;
    });
  }

  @override
  LiveTranscriptionPhase get phase => _phase;

  @override
  CapturePauseReason? get pauseReason => _pauseReason;

  @override
  Future<Result<LiveTranscriptionResult>> get done => _done.future;

  bool get _capturing =>
      _phase == LiveTranscriptionPhase.listening ||
      _phase == LiveTranscriptionPhase.paused;

  /// Starts following the capture and the engine.
  void _begin({required bool storageLow}) {
    _chunks = _capture.chunks.listen(_onChunk);
    _captureEvents = _capture.events.listen(_onCaptureEvent);
    _log.info(
      _tag,
      'session started (${_request.kind.name}, '
      '${_capture.format.inputSampleRate} Hz input, '
      '${_acquiring == null ? 'record only' : 'transcribing'})',
    );
    _emit(TranscriptionStateChanged(phase: _phase));
    if (storageLow) {
      _emit(
        const TranscriptionWarning(kind: TranscriptionWarningKind.storageLow),
      );
    }
    final Future<Result<SpeechEngineLease>>? acquiring = _acquiring;
    if (acquiring != null) {
      _acquired = acquiring.then(_onAcquired);
    }
  }

  void _onAcquired(Result<SpeechEngineLease> acquired) {
    switch (acquired) {
      case Success<SpeechEngineLease>(:final SpeechEngineLease value):
        if (_ended) {
          unawaited(value.release());
          return;
        }
        _lease = value;
        _pipeline?.attachLease(value);
        _log.info(_tag, 'transcribing with ${value.modelId}');
      case FailureResult<SpeechEngineLease>(:final Failure failure):
        if (_ended) {
          return;
        }
        _log.warn(_tag, 'engine unavailable (${failure.runtimeType})');
        if (_dictation) {
          unawaited(_fail(failure));
          return;
        }
        // Rule 3: the take keeps recording without a transcript.
        _emit(
          TranscriptionWarning(
            kind: TranscriptionWarningKind.transcriptionUnavailable,
            cause: failure,
          ),
        );
    }
  }

  void _emit(LiveTranscriptionEvent event) {
    if (event is SegmentFinalized) {
      _segments.add(event.segment);
    }
    if (!_bus.isClosed) {
      _bus.add(event);
    }
  }

  void _setPhase(LiveTranscriptionPhase phase, {CapturePauseReason? reason}) {
    _phase = phase;
    _pauseReason = phase == LiveTranscriptionPhase.paused ? reason : null;
    _emit(TranscriptionStateChanged(phase: phase, reason: _pauseReason));
  }

  void _onChunk(PcmChunk chunk) {
    final int total = chunk.startSample + chunk.samples.length;
    _pipeline?.audioAvailable(total);
    if (_phase != LiveTranscriptionPhase.listening) {
      return;
    }
    if (total >= _limitSamples) {
      _log.info(_tag, 'session limit reached');
      _emit(
        const TranscriptionWarning(kind: TranscriptionWarningKind.sessionLimit),
      );
      unawaited(_stopFor(StopReason.sessionLimit));
      return;
    }
    final int? longest = _maxSamples;
    if (longest != null && total >= longest) {
      unawaited(_stopFor(StopReason.maxDuration));
      return;
    }
    final int? silence = _silenceSamples;
    final SpeechPipeline? pipeline = _pipeline;
    if (silence != null &&
        pipeline != null &&
        _lease != null &&
        pipeline.detectedTo - pipeline.lastSpeechSample >= silence) {
      unawaited(_stopFor(StopReason.silence));
      return;
    }
    if (!_dictation && total >= _nextStorageCheck) {
      _nextStorageCheck = total + _storageEvery;
      unawaited(_checkStorage());
    }
  }

  Future<void> _checkStorage() async {
    final StorageGuard guard = _service._storageGuard;
    final Result<HeadroomState> checked = await guard.check();
    if (!_capturing || _ended) {
      return;
    }
    switch (checked) {
      case FailureResult<HeadroomState>(:final Failure failure):
        _log.warn(_tag, 'free space unknown (${failure.runtimeType})');
      case Success<HeadroomState>(value: HeadroomState.critical):
        _log.warn(_tag, 'storage ran out; stopping');
        _emit(
          const TranscriptionWarning(
            kind: TranscriptionWarningKind.storageStop,
          ),
        );
        unawaited(_stopFor(StopReason.storage));
      case Success<HeadroomState>(value: HeadroomState.low):
        if (guard.takeLowWarning()) {
          _log.info(_tag, 'storage is low');
          _emit(
            const TranscriptionWarning(
              kind: TranscriptionWarningKind.storageLow,
            ),
          );
        }
      case Success<HeadroomState>():
        break;
    }
  }

  void _onCaptureEvent(AudioCaptureEvent event) {
    switch (event) {
      case CaptureLevel(:final double level, :final double dbfs):
        _emit(InputLevelChanged(level: level, dbfs: dbfs));
      case CapturePaused(:final CapturePauseReason reason, :final int atSample):
        final CapturePauseReason why = reason == CapturePauseReason.user
            ? _requestedPause ?? reason
            : reason;
        _requestedPause = null;
        _pipeline?.markPause(atSample, why);
        if (_phase == LiveTranscriptionPhase.listening) {
          _log.info(_tag, 'paused (${why.name})');
          _setPhase(LiveTranscriptionPhase.paused, reason: why);
        }
      case CaptureResumed(:final int atSample):
        _pipeline?.markResume(atSample);
        if (_phase == LiveTranscriptionPhase.paused) {
          _setPhase(LiveTranscriptionPhase.listening);
        }
      case CaptureFailed(:final Failure failure):
        _log.warn(_tag, 'capture failed (${failure.runtimeType})');
        if (_capturing) {
          unawaited(_stopFor(StopReason.captureFailed));
        }
      case CaptureFormatChanged(:final CaptureFormat format):
        _log.info(_tag, 'input now ${format.inputSampleRate} Hz');
    }
  }

  @override
  Future<Result<void>> pause() => _pauseFor(CapturePauseReason.user);

  Future<Result<void>> _pauseFor(CapturePauseReason reason) async {
    if (_phase == LiveTranscriptionPhase.paused) {
      return const Success<void>(null);
    }
    if (_ended || _phase != LiveTranscriptionPhase.listening) {
      return const FailureResult<void>(ValidationFailure());
    }
    _requestedPause = reason;
    final Result<void> paused = await _capture.pause();
    if (paused case FailureResult<void>(:final Failure failure)) {
      _log.warn(_tag, 'pause failed (${failure.runtimeType})');
    }
    if (_phase == LiveTranscriptionPhase.listening && paused is Success<void>) {
      _log.info(_tag, 'paused (${reason.name})');
      _setPhase(LiveTranscriptionPhase.paused, reason: reason);
    }
    return paused;
  }

  @override
  Future<Result<void>> resume() async {
    if (_phase == LiveTranscriptionPhase.listening) {
      return const Success<void>(null);
    }
    if (_ended || _phase != LiveTranscriptionPhase.paused) {
      return const FailureResult<void>(ValidationFailure());
    }
    final Result<void> resumed = await _capture.resume();
    switch (resumed) {
      case Success<void>():
        if (_phase == LiveTranscriptionPhase.paused) {
          _log.info(_tag, 'resumed');
          _setPhase(LiveTranscriptionPhase.listening);
        }
      case FailureResult<void>(:final Failure failure):
        _log.warn(_tag, 'resume refused (${failure.runtimeType})');
        if (failure is PermissionFailure &&
            _phase == LiveTranscriptionPhase.paused) {
          _setPhase(
            LiveTranscriptionPhase.paused,
            reason: CapturePauseReason.permissionRevoked,
          );
        }
    }
    return resumed;
  }

  @override
  Future<Result<StoppedCapture>> stop() => _stopFor(StopReason.user);

  Future<Result<StoppedCapture>> _stopFor(StopReason reason) {
    final Future<Result<StoppedCapture>>? running = _stopRun;
    if (running != null) {
      return running;
    }
    if (_ended) {
      return Future<Result<StoppedCapture>>.value(
        FailureResult<StoppedCapture>(_endFailure ?? speechCancelled()),
      );
    }
    return _stopRun = _stop(reason);
  }

  Future<Result<StoppedCapture>> _stop(StopReason reason) async {
    _stopReason = reason;
    _log.info(_tag, 'stopping (${reason.name})');
    _setPhase(LiveTranscriptionPhase.stopping);
    final Result<AudioRecording?> published = await _capture.stop();
    final int captured = _capture.capturedSamples;
    if (_ended) {
      return FailureResult<StoppedCapture>(_endFailure ?? speechCancelled());
    }
    switch (published) {
      case FailureResult<AudioRecording?>(:final Failure failure):
        _log.warn(_tag, 'publish failed (${failure.runtimeType})');
        await _fail(failure);
        return FailureResult<StoppedCapture>(failure);
      case Success<AudioRecording?>(:final AudioRecording? value):
        _pipeline?.audioAvailable(captured);
        _setPhase(LiveTranscriptionPhase.draining);
        unawaited(_drain(captured));
        return Success<StoppedCapture>(
          StoppedCapture(
            audio: value,
            captured: _LiveTranscriptionService._durationOf(captured),
            reason: reason,
          ),
        );
    }
  }

  /// Finishes the transcript after the audio is published: every final
  /// is decoded and stored, unless the operator skips the rest, then the
  /// sink records how it ended.
  Future<void> _drain(int captured) async {
    final SpeechPipeline? pipeline = _pipeline;
    _emit(
      TranscriptionDraining(
        pending: _LiveTranscriptionService._durationOf(
          pipeline == null
              ? 0
              : math.max(0, captured - pipeline.coveredToSample),
        ),
      ),
    );
    if (pipeline != null) {
      final Future<void>? acquired = _acquired;
      if (_lease == null && acquired != null && !_skipRequested) {
        await Future.any(<Future<void>>[acquired, _skipSignal.future]);
      }
      await pipeline.finish(drain: _lease != null && !_skipRequested);
    }
    if (_ended) {
      return;
    }
    final int covered = pipeline?.coveredToSample ?? 0;
    final bool complete = covered >= captured;
    await _finishSink(captured: captured, covered: covered, complete: complete);
    if (_ended) {
      return;
    }
    _logSummary(captured: captured, covered: covered);
    final LiveTranscriptionResult result = LiveTranscriptionResult(
      segments: List<TranscriptSegment>.unmodifiable(_segments),
      languageTag: _request.languageTag,
      modelId: _lease?.modelId,
      captured: _LiveTranscriptionService._durationOf(captured),
      transcriptComplete: complete,
      coveredToSample: covered,
      unsaved: pipeline?.unsaved ?? const <FinishedUtterance>[],
      stopReason: _stopReason,
    );
    await _end(
      LiveTranscriptionPhase.completed,
      Success<LiveTranscriptionResult>(result),
    );
  }

  Future<void> _finishSink({
    required int captured,
    required int covered,
    required bool complete,
  }) async {
    final TranscriptSink? sink = _request.sink;
    if (sink == null) {
      return;
    }
    final Result<void> finished = await sink.finish(
      TranscriptOutcome(
        complete: complete,
        captured: _LiveTranscriptionService._durationOf(captured),
        coveredToSample: covered,
        languageTag: _request.languageTag,
        modelId: _lease?.modelId,
      ),
    );
    if (finished case FailureResult<void>(:final Failure failure)) {
      _log.warn(_tag, 'sink finish failed (${failure.runtimeType})');
    }
  }

  void _logSummary({required int captured, required int covered}) {
    final SpeechPipeline? pipeline = _pipeline;
    final int seconds = captured ~/ AppConstants.audio.sampleRate;
    if (pipeline == null || _lease == null) {
      _log.info(_tag, 'session ended without transcription, ${seconds}s');
      return;
    }
    final ({
      int utterances,
      int segments,
      int dropped,
      int collapsed,
      double gatedRatio,
      Duration meanCompute,
      Duration p90Compute,
      double realTimeFactor,
      BackpressureLevel ladder,
    })
    stats = pipeline.stats;
    _log.info(
      _tag,
      'session ended (${_stopReason.name}): ${seconds}s, '
      '${stats.utterances} utterances, ${stats.segments} segments, '
      '${stats.dropped} dropped, ${stats.collapsed} collapsed, '
      'gated ${(stats.gatedRatio * 100).round()}%, '
      'final compute mean ${stats.meanCompute.inMilliseconds} ms '
      'p90 ${stats.p90Compute.inMilliseconds} ms, '
      'rtf ${stats.realTimeFactor.toStringAsFixed(2)}, '
      'ladder ${stats.ladder.name}, '
      'covered ${covered * 100 ~/ math.max(1, captured)}%',
    );
  }

  @override
  void skipRemaining() {
    if (_ended || _skipRequested) {
      return;
    }
    _skipRequested = true;
    _skipSignal.complete();
    _log.info(_tag, 'remaining transcription skipped');
    if (_phase == LiveTranscriptionPhase.draining) {
      unawaited(_pipeline?.finish(drain: false));
    }
  }

  @override
  Future<Result<CancelledTranscription>> cancel() => _cancelRun ??= _cancel();

  Future<Result<CancelledTranscription>> _cancel() async {
    if (_ended) {
      return FailureResult<CancelledTranscription>(
        _endFailure ?? const ValidationFailure(),
      );
    }
    _ended = true;
    _endFailure = speechCancelled();
    _log.info(_tag, 'session cancelled');
    _setPhase(LiveTranscriptionPhase.cancelled);
    await _pipeline?.abort();
    // Rule 1: the staged take is kept byte-for-byte, unpublished.
    final Result<String?> kept = await _capture.abandon();
    final int captured = _capture.capturedSamples;
    await _teardown();
    _done.complete(FailureResult<LiveTranscriptionResult>(speechCancelled()));
    await _close();
    return kept.map(
      (String? path) => CancelledTranscription(
        keptStagingPath: path,
        captured: _LiveTranscriptionService._durationOf(captured),
      ),
    );
  }

  /// Ends the session as failed with [failure]: the take, unpublished, is
  /// kept for recovery.
  Future<void> _fail(Failure failure) async {
    if (_ended) {
      return;
    }
    _ended = true;
    _endFailure = failure;
    _log.warn(_tag, 'session failed (${failure.runtimeType})');
    await _pipeline?.abort();
    _emit(TranscriptionFailed(failure: failure));
    await _end(
      LiveTranscriptionPhase.failed,
      FailureResult<LiveTranscriptionResult>(failure),
    );
  }

  /// Background: a long-form take is paused, patched and flushed and its
  /// last transcript write lands before this completes; dictation stops.
  Future<void> _toBackground() async {
    if (_ended || _exiting) {
      return;
    }
    if (_dictation) {
      if (_capturing) {
        await _stopFor(StopReason.exit);
      }
      return;
    }
    if (_phase == LiveTranscriptionPhase.listening) {
      await _pauseFor(CapturePauseReason.background);
    }
    final Future<Result<StoppedCapture>>? stopping = _stopRun;
    if (_capturing) {
      await _capture.checkpoint();
    } else if (stopping != null) {
      await stopping;
    }
    await _pipeline?.sinkIdle;
  }

  /// The window is closing: the take is checkpointed for recovery to
  /// adopt, and nothing more is published or drained.
  Future<void> _leaveForRecovery() async {
    if (_ended) {
      return;
    }
    _exiting = true;
    if (_capturing) {
      await _capture.checkpoint();
    }
    await _pipeline?.sinkIdle;
    _log.info(_tag, 'take left for recovery');
  }

  /// The app is detached: capture stops and publishes, and the drain runs
  /// on unawaited.
  Future<void> _detach() async {
    if (_ended || _exiting || !_capturing) {
      return;
    }
    await _stopFor(StopReason.exit);
  }

  void _preempted() {
    if (_ended) {
      return;
    }
    _log.info(_tag, 'microphone taken by evidence capture');
    unawaited(_stopFor(StopReason.preempted));
    _request.onPreempted?.call();
  }

  /// The service is going away: a drain is aborted and its transcript
  /// finished as interrupted; a take still recording is abandoned, kept
  /// for recovery.
  Future<void> _shutDown() async {
    final Future<Result<StoppedCapture>>? stopping = _stopRun;
    if (stopping != null) {
      await stopping;
    }
    if (_ended) {
      return;
    }
    if (_phase == LiveTranscriptionPhase.draining) {
      _ended = true;
      final SpeechPipeline? pipeline = _pipeline;
      await pipeline?.abort();
      final int captured = _capture.capturedSamples;
      final int covered = pipeline?.coveredToSample ?? 0;
      await _finishSink(captured: captured, covered: covered, complete: false);
      await _end(
        LiveTranscriptionPhase.completed,
        Success<LiveTranscriptionResult>(
          LiveTranscriptionResult(
            segments: List<TranscriptSegment>.unmodifiable(_segments),
            languageTag: _request.languageTag,
            modelId: _lease?.modelId,
            captured: _LiveTranscriptionService._durationOf(captured),
            transcriptComplete: false,
            coveredToSample: covered,
            unsaved: pipeline?.unsaved ?? const <FinishedUtterance>[],
            stopReason: _stopReason,
          ),
        ),
      );
      return;
    }
    _ended = true;
    _endFailure = speechUnavailable();
    await _pipeline?.abort();
    await _capture.abandon();
    await _end(
      LiveTranscriptionPhase.failed,
      FailureResult<LiveTranscriptionResult>(speechUnavailable()),
    );
  }

  /// Releases everything and reports [result] as the session's end in
  /// [phase].
  Future<void> _end(
    LiveTranscriptionPhase phase,
    Result<LiveTranscriptionResult> result,
  ) async {
    _ended = true;
    await _teardown();
    _setPhase(phase);
    if (!_done.isCompleted) {
      _done.complete(result);
    }
    await _close();
  }

  /// Stops following the capture, releases it (an unpublished take stays
  /// staged) and gives the engine lease back.
  Future<void> _teardown() async {
    await _chunks?.cancel();
    _chunks = null;
    await _captureEvents?.cancel();
    _captureEvents = null;
    await _capture.release();
    final SpeechEngineLease? lease = _lease;
    _lease = null;
    await lease?.release();
  }

  Future<void> _close() async {
    _service._untrack(this);
    await _bus.close();
  }
}
