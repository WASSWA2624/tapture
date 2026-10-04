import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;
import 'package:tapture/core/audio/audio_recording.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/lifecycle/leave_guard.dart';
import 'package:tapture/core/lifecycle/lifecycle_observer.dart';
import 'package:tapture/core/logging/logger.dart';
import 'package:tapture/core/speech/live_transcription_event.dart';
import 'package:tapture/core/speech/live_transcription_phase.dart';
import 'package:tapture/core/speech/live_transcription_request.dart';
import 'package:tapture/core/speech/live_transcription_result.dart';
import 'package:tapture/core/speech/live_transcription_service.dart';
import 'package:tapture/core/speech/live_transcription_session.dart';
import 'package:tapture/core/speech/speech_preferences.dart';
import 'package:tapture/core/speech/speech_readiness_notifier.dart';
import 'package:tapture/core/speech/speech_text.dart';
import 'package:tapture/core/speech/stopped_capture.dart';
import 'package:tapture/core/speech/transcript_segment.dart';
import 'package:tapture/core/speech/transcript_sink.dart';
import 'package:tapture/core/speech/transcription_kind.dart';
import 'package:tapture/core/speech/transcription_warning_kind.dart';

import '../domain/transcript_line.dart';
import '../domain/transcript_paragraphs.dart';
import '../domain/transcript_repository.dart';
import '../domain/transcript_summary.dart';
import '../transcripts.dart' show transcriptRepositoryProvider;
import 'live_transcript_frame.dart';
import 'live_transcript_status.dart';
import 'transcript_mode.dart';
import 'transcript_providers.dart';
import 'transcript_session_phase.dart';
import 'transcript_session_target.dart';

/// Runs one surface's live transcription session, held under its session
/// key (`LiveTranscriptKey`): the Transcribe screen, a meeting, or the
/// capture caption recorder (spec §30.4.5).
///
/// **Start** makes the transcript row durable before the microphone opens
/// (Rule 4): the target's audio path, its `beforeStart`, the `live` row,
/// then the session writing through the row's sink. **Stop** returns once
/// the take is published, filed through the target and linked to the row;
/// the transcript then finishes under the speech service, which owns the
/// drain, so leaving the page never loses it. A failed filing step is
/// retried from where it stopped (`retrySave`); until the take is filed the
/// controller holds the leave guard and an exit check, and a keep-alive
/// link when the target asks for one.
///
/// Capture pauses only when the app is paused or hidden, never when it is
/// merely inactive, and resumes only when the operator asks. The words
/// arrive many times a second, so they are published through [frames]
/// rather than as state.
final class LiveTranscriptController extends Notifier<LiveTranscriptStatus> {
  /// A controller for the session held under [sessionKey].
  LiveTranscriptController(this.sessionKey);

  /// The key this session is held under.
  final String sessionKey;

  ValueNotifier<LiveTranscriptFrame> _frames =
      ValueNotifier<LiveTranscriptFrame>(LiveTranscriptFrame.empty);
  bool _framesReleased = false;
  _LiveRun? _run;
  StreamSubscription<LiveTranscriptionEvent>? _events;
  KeepAliveLink? _keepAlive;
  TranscriptParagraphs _paragraphs = const TranscriptParagraphs.empty();
  int? _draftUtterance;
  bool _starting = false;

  /// What the transcript shows now: paragraphs, the words being recognised,
  /// the time recorded and the input level.
  ValueListenable<LiveTranscriptFrame> get frames => _frames;

  @override
  LiveTranscriptStatus build() {
    // Riverpod may rebuild this same notifier after an invalidate, so the
    // frames released by the last dispose are replaced here.
    if (_framesReleased) {
      _frames = ValueNotifier<LiveTranscriptFrame>(LiveTranscriptFrame.empty);
      _framesReleased = false;
    }
    ref.onDispose(_release);
    return LiveTranscriptStatus.idle;
  }

  /// Starts recording for [target]: the audio path, `beforeStart`, the
  /// durable `live` row, then the microphone. Whatever fails before the
  /// microphone opens is undone, and nothing is recorded.
  Future<Result<void>> start(TranscriptSessionTarget target) async {
    final _LiveRun? previous = _run;
    if (target.sessionKey != sessionKey ||
        _starting ||
        (previous != null && previous.busy)) {
      return const FailureResult<void>(ValidationFailure());
    }
    _starting = true;
    try {
      return await _start(target);
    } finally {
      _starting = false;
    }
  }

  Future<Result<void>> _start(TranscriptSessionTarget target) async {
    _forgetRun();
    _resetFrames();
    state = LiveTranscriptStatus(
      phase: TranscriptSessionPhase.starting,
      mode: target.mode,
    );
    final TranscriptRepository repository = ref.read(
      transcriptRepositoryProvider,
    );
    final LiveTranscriptionService service = ref.read(
      liveTranscriptionServiceProvider,
    );
    final LeaveGuard leaveGuard = ref.read(leaveGuardProvider);
    final LifecycleObserver lifecycle = ref.read(lifecycleObserverProvider);
    final String languageTag = ref.read(speechLanguageProvider);
    final bool live = target.mode == TranscriptMode.live;
    final String modelId = live
        ? ref.read(speechReadinessProvider).selection?.model.id ?? ''
        : '';
    final DateTime startedAt = ref.read(transcriptClockProvider).nowUtc();
    final Logger logger = Logger.current;

    final Result<String> path = await target.audioPath();
    final String audioPath;
    switch (path) {
      case FailureResult<String>(:final Failure failure):
        return _startFailed(failure, logger);
      case Success<String>(:final String value):
        audioPath = value;
    }
    final Future<Result<void>> Function()? beforeStart = target.beforeStart;
    if (beforeStart != null) {
      final Result<void> prepared = await beforeStart();
      if (prepared case FailureResult<void>(:final Failure failure)) {
        return _startFailed(failure, logger);
      }
    }
    final Result<TranscriptSummary> begun = await repository.begin((
      projectId: target.projectId,
      ownerKind: target.ownerKind,
      ownerId: target.ownerId,
      attachmentId: null,
      audioPath: audioPath,
      title: '',
      languageTag: languageTag,
      modelId: modelId,
      startedAt: startedAt,
    ));
    final String transcriptId;
    switch (begun) {
      case FailureResult<TranscriptSummary>(:final Failure failure):
        await target.onDiscard?.call();
        return _startFailed(failure, logger);
      case Success<TranscriptSummary>(:final TranscriptSummary value):
        transcriptId = value.id;
    }
    final Result<TranscriptSink> sink = await repository.sinkFor(transcriptId);
    final Result<LiveTranscriptionSession> opened = switch (sink) {
      FailureResult<TranscriptSink>(:final Failure failure) =>
        FailureResult<LiveTranscriptionSession>(failure),
      Success<TranscriptSink>(:final TranscriptSink value) =>
        await service.start(
          LiveTranscriptionRequest(
            kind: TranscriptionKind.longForm,
            languageTag: languageTag,
            audioPath: audioPath,
            sink: value,
            transcribe: live,
          ),
        ),
    };
    switch (opened) {
      case FailureResult<LiveTranscriptionSession>(:final Failure failure):
        // Nothing was recorded: the row and the staged draft are undone.
        await repository.discard(transcriptId);
        await target.onDiscard?.call();
        return _startFailed(failure, logger);
      case Success<LiveTranscriptionSession>(
        :final LiveTranscriptionSession value,
      ):
        final _LiveRun run = _LiveRun(
          target: target,
          transcriptId: transcriptId,
          session: value,
          repository: repository,
          leaveGuard: leaveGuard,
          lifecycle: lifecycle,
          logger: logger,
        )..hold();
        logger.info(
          _tag,
          'live session started (${target.ownerKind.name}, '
          '${target.mode.name})',
        );
        if (!ref.mounted) {
          // The page went while the microphone opened: the take is kept.
          unawaited(run.finishDetached());
          return const Success<void>(null);
        }
        _run = run;
        if (target.keepAlive) {
          _keepAlive = ref.keepAlive();
        }
        _events = value.events.listen(
          (LiveTranscriptionEvent event) => _onEvent(run, event),
        );
        unawaited(
          value.done.then(
            (Result<LiveTranscriptionResult> result) => _onDone(run, result),
          ),
        );
        state = LiveTranscriptStatus(
          phase: TranscriptSessionPhase.recording,
          mode: target.mode,
          transcriptId: transcriptId,
        );
        return const Success<void>(null);
    }
  }

  Result<void> _startFailed(Failure failure, Logger logger) {
    logger.warn(_tag, 'live session did not start (${failure.runtimeType})');
    if (ref.mounted) {
      state = state.copyWith(
        phase: TranscriptSessionPhase.failed,
        failure: failure,
        retryable: false,
      );
    }
    return FailureResult<void>(failure);
  }

  /// Pauses the recording; the take so far is made durable.
  Future<Result<void>> pause() async {
    final _LiveRun? run = _run;
    if (run == null || state.phase != TranscriptSessionPhase.recording) {
      return const FailureResult<void>(ValidationFailure());
    }
    final Result<void> paused = await run.session.pause();
    _noteRefusal(run, paused);
    return paused;
  }

  /// Resumes a paused recording, after any pause. A withdrawn microphone
  /// permission keeps it paused, with everything recorded kept.
  Future<Result<void>> resume() async {
    final _LiveRun? run = _run;
    if (run == null || state.phase != TranscriptSessionPhase.paused) {
      return const FailureResult<void>(ValidationFailure());
    }
    final Result<void> resumed = await run.session.resume();
    _noteRefusal(run, resumed);
    if (resumed is Success<void> && ref.mounted && identical(_run, run)) {
      state = state.copyWith(clearFailure: true);
    }
    return resumed;
  }

  void _noteRefusal(_LiveRun run, Result<void> result) {
    if (result case FailureResult<void>(:final Failure failure)
        when ref.mounted && identical(_run, run)) {
      state = state.copyWith(failure: failure);
    }
  }

  /// Stops the recording and returns once its audio is published, filed
  /// and linked: the attachment id, or null when the target files none.
  /// The transcript keeps finishing under the speech service.
  Future<Result<String?>> stop() async {
    final _LiveRun? run = _run;
    if (run == null || _starting) {
      return const FailureResult<String?>(ValidationFailure());
    }
    if (run.filed) {
      return Success<String?>(run.attachmentId);
    }
    state = state.copyWith(
      phase: TranscriptSessionPhase.finishing,
      retryable: false,
      clearFailure: true,
      clearPauseReason: true,
    );
    final Result<String?> filed = await run.file();
    if (ref.mounted && identical(_run, run)) {
      _afterFiling(run, filed);
    }
    return filed;
  }

  /// Tries the failed filing step again, then the steps after it.
  Future<Result<String?>> retrySave() async {
    final _LiveRun? run = _run;
    if (run == null || state.phase != TranscriptSessionPhase.failed) {
      return const FailureResult<String?>(ValidationFailure());
    }
    return stop();
  }

  /// Discards the recording: the transcript row is tombstoned and the
  /// target undoes its draft. Audio is never deleted (Rule 1): a take still
  /// recording stays staged, and one already published stays on disk. The
  /// panel asks the operator first.
  Future<Result<void>> discard() async {
    final _LiveRun? run = _run;
    if (run == null || _starting) {
      return const FailureResult<void>(ValidationFailure());
    }
    state = state.copyWith(phase: TranscriptSessionPhase.finishing);
    final LiveTranscriptionPhase phase = run.session.phase;
    if (phase == LiveTranscriptionPhase.preparing ||
        phase == LiveTranscriptionPhase.listening ||
        phase == LiveTranscriptionPhase.paused) {
      await run.session.cancel();
    } else {
      run.session.skipRemaining();
    }
    final Result<void> discarded = await run.repository.discard(
      run.transcriptId,
    );
    if (discarded case FailureResult<void>(:final Failure failure)) {
      run.logger.warn(_tag, 'discard failed (${failure.runtimeType})');
      if (ref.mounted && identical(_run, run)) {
        state = state.copyWith(
          phase: TranscriptSessionPhase.failed,
          failure: failure,
          retryable: false,
        );
      }
      return discarded;
    }
    await run.target.onDiscard?.call();
    run.release();
    run.logger.info(_tag, 'live session discarded');
    if (ref.mounted && identical(_run, run)) {
      _forgetRun();
      _resetFrames();
      state = LiveTranscriptStatus(mode: run.target.mode);
    }
    return const Success<void>(null);
  }

  void _afterFiling(_LiveRun run, Result<String?> filed) {
    switch (filed) {
      case FailureResult<String?>(:final Failure failure):
        final bool retryable = run.retryable;
        if (!retryable) {
          // The session ended without publishing: its take stays staged and
          // boot recovery files it. Nothing is left to hold here.
          run.release();
          _closeKeepAlive();
        }
        state = state.copyWith(
          phase: TranscriptSessionPhase.failed,
          failure: failure,
          retryable: retryable,
        );
      case Success<String?>(:final String? value):
        run.release();
        _closeKeepAlive();
        final StoppedCapture? stopped = run.stopped;
        if (stopped != null) {
          _frames.value = _frames.value.copyWith(
            elapsed: stopped.captured,
            tentative: '',
            level: 0,
          );
        }
        final LiveTranscriptionPhase phase = run.session.phase;
        state = state.copyWith(
          phase: TranscriptSessionPhase.saved,
          attachmentId: value,
          retryable: false,
          draining:
              phase == LiveTranscriptionPhase.stopping ||
              phase == LiveTranscriptionPhase.draining,
          clearFailure: true,
          clearPauseReason: true,
        );
    }
  }

  void _onEvent(_LiveRun run, LiveTranscriptionEvent event) {
    if (!ref.mounted || !identical(_run, run)) {
      return;
    }
    switch (event) {
      case TranscriptionStateChanged(:final LiveTranscriptionPhase phase):
        _onPhase(run, phase, event);
      case InputLevelChanged(:final double level):
        if (state.phase == TranscriptSessionPhase.recording) {
          final LiveTranscriptFrame frame = _frames.value;
          _frames.value = frame.copyWith(
            level: level,
            elapsed: frame.elapsed + AppConstants.audio.meterTick,
          );
        }
      case InterimTranscript(
        :final int utteranceId,
        :final String stable,
        :final String tentative,
      ):
        _draftUtterance = utteranceId;
        _frames.value = _frames.value.copyWith(
          tentative: SpeechText.join(<String>[stable, tentative]),
        );
      case SegmentFinalized(
        :final TranscriptSegment segment,
        :final bool durable,
      ):
        _paragraphs = _paragraphs.append(TranscriptLine.fromSegment(segment));
        _frames.value = _frames.value.copyWith(
          paragraphs: _paragraphs.paragraphs,
        );
        if (durable && state.unsaved) {
          state = state.copyWith(unsaved: false);
        }
      case UtteranceFinalized(:final int utteranceId, :final bool durable):
        if (utteranceId == _draftUtterance) {
          _draftUtterance = null;
          _frames.value = _frames.value.copyWith(tentative: '');
        }
        // Writes land in order, so a stored utterance means every earlier
        // one is stored too.
        if (durable && state.unsaved) {
          state = state.copyWith(unsaved: false);
        }
      case TranscriptionDraining():
        state = state.copyWith(draining: true);
      case TranscriptionWarning(
        :final TranscriptionWarningKind kind,
        :final Duration? lag,
      ):
        state = kind == TranscriptionWarningKind.transcriptUnsaved
            ? state.copyWith(unsaved: true)
            : state.copyWith(warning: kind, lag: lag);
      case TranscriptionFailed(:final Failure failure):
        state = state.copyWith(failure: failure);
    }
  }

  void _onPhase(
    _LiveRun run,
    LiveTranscriptionPhase phase,
    TranscriptionStateChanged event,
  ) {
    final TranscriptSessionPhase current = state.phase;
    final bool capturing =
        current == TranscriptSessionPhase.recording ||
        current == TranscriptSessionPhase.paused;
    switch (phase) {
      case LiveTranscriptionPhase.listening:
        if (capturing) {
          state = state.copyWith(
            phase: TranscriptSessionPhase.recording,
            clearPauseReason: true,
          );
        }
      case LiveTranscriptionPhase.paused:
        if (capturing) {
          state = state.copyWith(
            phase: TranscriptSessionPhase.paused,
            pauseReason: event.reason,
          );
        }
      case LiveTranscriptionPhase.stopping:
        // The session stopped by itself (silence, a limit, storage, a lost
        // capture): its take is filed as if the operator had stopped it.
        if (capturing) {
          unawaited(stop());
        }
      case LiveTranscriptionPhase.failed:
        if (capturing) {
          run.release();
          _closeKeepAlive();
          state = state.copyWith(
            phase: TranscriptSessionPhase.failed,
            retryable: false,
          );
        }
      case LiveTranscriptionPhase.completed:
        state = state.copyWith(draining: false);
      case LiveTranscriptionPhase.preparing:
      case LiveTranscriptionPhase.draining:
      case LiveTranscriptionPhase.cancelled:
        break;
    }
  }

  void _onDone(_LiveRun run, Result<LiveTranscriptionResult> result) {
    if (!ref.mounted || !identical(_run, run)) {
      return;
    }
    final bool saved = switch (result) {
      Success<LiveTranscriptionResult>(:final LiveTranscriptionResult value) =>
        value.unsaved.isEmpty,
      FailureResult<LiveTranscriptionResult>() => false,
    };
    state = state.copyWith(
      draining: false,
      unsaved: saved ? false : state.unsaved,
    );
  }

  void _resetFrames() {
    _paragraphs = const TranscriptParagraphs.empty();
    _draftUtterance = null;
    _frames.value = LiveTranscriptFrame.empty;
  }

  void _closeKeepAlive() {
    _keepAlive?.close();
    _keepAlive = null;
  }

  /// Stops following a run that is filed or gone.
  void _forgetRun() {
    final StreamSubscription<LiveTranscriptionEvent>? events = _events;
    _events = null;
    _run = null;
    _closeKeepAlive();
    unawaited(events?.cancel());
  }

  /// The provider is going: a take not yet filed is stopped, filed and
  /// linked through the references the run captured, never through `ref`.
  void _release() {
    final StreamSubscription<LiveTranscriptionEvent>? events = _events;
    _events = null;
    unawaited(events?.cancel());
    _keepAlive = null;
    final _LiveRun? run = _run;
    _run = null;
    if (run != null) {
      unawaited(run.finishDetached());
    }
    _frames.dispose();
    _framesReleased = true;
  }
}

/// The filing step a run reached: publish the take, file it, link it.
enum _FilingStep { stop, file, link, done }

/// One started session and everything its filing needs, captured at start
/// so filing finishes after the controller is gone.
final class _LiveRun {
  _LiveRun({
    required this.target,
    required this.transcriptId,
    required this.session,
    required this.repository,
    required this.leaveGuard,
    required this.lifecycle,
    required this.logger,
  });

  final TranscriptSessionTarget target;
  final String transcriptId;
  final LiveTranscriptionSession session;
  final TranscriptRepository repository;
  final LeaveGuard leaveGuard;
  final LifecycleObserver lifecycle;
  final Logger logger;

  _FilingStep _step = _FilingStep.stop;
  Future<Result<String?>>? _filing;
  bool _held = false;

  /// What the stop published, once it has.
  StoppedCapture? stopped;

  /// The attachment the take was filed as, once filed.
  String? attachmentId;

  /// Whether the take is published, filed and linked.
  bool get filed => _step == _FilingStep.done;

  /// Whether the run still owns the microphone or a take to file, so no
  /// other session may start under the same key.
  bool get busy => !filed && retryable;

  /// Whether the step that failed can be tried again: filing and linking
  /// always can; the stop only while the session is still open.
  bool get retryable {
    if (_step != _FilingStep.stop) {
      return true;
    }
    final LiveTranscriptionPhase phase = session.phase;
    return phase == LiveTranscriptionPhase.listening ||
        phase == LiveTranscriptionPhase.paused ||
        phase == LiveTranscriptionPhase.stopping;
  }

  /// Holds the leave guard and the exit check until the take is filed.
  void hold() {
    if (_held) {
      return;
    }
    _held = true;
    leaveGuard.hold(this);
    lifecycle.addExitCheck(_exitCheck);
  }

  /// Lets go of what [hold] took.
  void release() {
    if (!_held) {
      return;
    }
    _held = false;
    leaveGuard.release(this);
    lifecycle.removeExitCheck(_exitCheck);
  }

  /// A window close never waits on recording: the speech service leaves a
  /// take still recording for recovery. A take already published is filed
  /// first, so it is not left unlinked.
  Future<bool> _exitCheck() async {
    final Future<Result<String?>>? filing = _filing;
    if (filing != null) {
      await filing;
    } else if (stopped != null && !filed) {
      await file();
    }
    return true;
  }

  /// Publishes, files and links the take from the first step not yet done.
  /// Concurrent calls share one run.
  Future<Result<String?>> file() {
    final Future<Result<String?>>? running = _filing;
    if (running != null) {
      return running;
    }
    final Future<Result<String?>> started = _file();
    _filing = started;
    unawaited(
      started.whenComplete(() {
        if (identical(_filing, started)) {
          _filing = null;
        }
      }),
    );
    return started;
  }

  Future<Result<String?>> _file() async {
    if (_step == _FilingStep.stop) {
      final Result<StoppedCapture> result = await session.stop();
      switch (result) {
        case FailureResult<StoppedCapture>(:final Failure failure):
          logger.warn(_tag, 'take not published (${failure.runtimeType})');
          return FailureResult<String?>(failure);
        case Success<StoppedCapture>(:final StoppedCapture value):
          stopped = value;
          _step = _FilingStep.file;
      }
    }
    if (_step == _FilingStep.file) {
      final AudioRecording? audio = stopped?.audio;
      if (audio != null) {
        final Result<String?> filedAs = await target.fileAudio(audio);
        switch (filedAs) {
          case FailureResult<String?>(:final Failure failure):
            logger.warn(_tag, 'take not filed (${failure.runtimeType})');
            return FailureResult<String?>(failure);
          case Success<String?>(:final String? value):
            attachmentId = value;
        }
      }
      _step = _FilingStep.link;
    }
    if (_step == _FilingStep.link) {
      final String? attachment = attachmentId;
      if (attachment != null) {
        final Result<void> linked = await repository.linkAttachment(
          transcriptId,
          attachment,
        );
        if (linked case FailureResult<void>(:final Failure failure)) {
          logger.warn(_tag, 'take not linked (${failure.runtimeType})');
          return FailureResult<String?>(failure);
        }
      }
      _step = _FilingStep.done;
      final StoppedCapture? published = stopped;
      logger.info(
        _tag,
        'live session filed (${published?.reason.name}, '
        '${published?.captured.inSeconds}s)',
      );
    }
    return Success<String?>(attachmentId);
  }

  /// Files the take with no controller left to report to, then lets go.
  Future<void> finishDetached() async {
    if (!filed && retryable) {
      await file();
    }
    release();
  }
}

const String _tag = 'speech';
