import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/audio/audio_capture_event.dart';
import 'package:tapture/core/audio/audio_capture_request.dart';
import 'package:tapture/core/audio/audio_capture_service.dart';
import 'package:tapture/core/audio/audio_capture_session.dart';
import 'package:tapture/core/audio/audio_recording.dart';
import 'package:tapture/core/audio/audio_recovery_service.dart';
import 'package:tapture/core/audio/capture_format.dart';
import 'package:tapture/core/audio/capture_pause_reason.dart';
import 'package:tapture/core/audio/file_pcm_store.dart';
import 'package:tapture/core/audio/memory_pcm_store.dart';
import 'package:tapture/core/audio/microphone_owner.dart';
import 'package:tapture/core/audio/pcm_chunk.dart';
import 'package:tapture/core/audio/pcm_store.dart';
import 'package:tapture/core/audio/staged_take.dart';
import 'package:tapture/core/audio/wav_take.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/storage_guard.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/lifecycle/leave_guard.dart';
import 'package:tapture/core/lifecycle/lifecycle_observer.dart';
import 'package:tapture/core/logging/logger.dart';

import 'cancelled_transcription.dart';
import 'finished_utterance.dart';
import 'live_transcription_event.dart';
import 'live_transcription_phase.dart';
import 'live_transcription_request.dart';
import 'live_transcription_result.dart';
import 'live_transcription_session.dart';
import 'pipeline/backpressure_level.dart';
import 'pipeline/speech_pipeline.dart';
import 'pipeline/speech_pipeline_config.dart';
import 'speech_engine_host.dart';
import 'speech_engine_lease.dart';
import 'speech_failures.dart';
import 'stop_reason.dart';
import 'stopped_capture.dart';
import 'transcript_outcome.dart';
import 'transcript_segment.dart';
import 'transcript_sink.dart';
import 'transcription_kind.dart';
import 'transcription_warning_kind.dart';

part 'active_transcription.dart';
part 'remaining_transcription.dart';

/// Sessions started and not yet completed, cancelled or failed.
int _liveSessions = 0;

/// How many live transcription sessions are still running, draining
/// included. Every path out of a session brings it back down.
@visibleForTesting
int get debugLiveTranscriptionSessions => _liveSessions;

/// Records the microphone into a durable take and transcribes it on the
/// device as it is spoken (spec §30.4.5): the one entry point for
/// dictation and the long-form surfaces.
///
/// The service is kept alive for the process and owns its sessions'
/// drains, so leaving a page never loses a transcript. While a session
/// runs it holds one awaited pause flush on [LifecycleObserver], which
/// pauses long-form capture, patches and flushes the take and waits for
/// the transcript write in flight before the app is suspended (PO
/// decision 5); dictation stops instead. A window close checkpoints every
/// take and leaves it for recovery, never draining or publishing.
abstract interface class LiveTranscriptionService {
  /// The service over [capture] and the speech [host], following the app
  /// through [lifecycle], holding [leaveGuard] while a long-form session is
  /// unsaved and checking [storageGuard] at start and every
  /// `AppConstants.speechSession.storageCheckInterval` of audio.
  ///
  /// [recovery] adopts a take a killed process left (`recoverAudio`).
  /// [storageRoot] and, where files are not reachable (the browser),
  /// [reader] open a published take for `transcribeRemaining`.
  /// [sessionLimit] replaces the platform's session cap in tests.
  factory LiveTranscriptionService({
    required AudioCaptureService capture,
    required SpeechEngineHost host,
    required LifecycleObserver lifecycle,
    required LeaveGuard leaveGuard,
    required StorageGuard storageGuard,
    AudioRecoveryService? recovery,
    StorageRoot? storageRoot,
    FileReader? reader,
    @visibleForTesting Duration? sessionLimit,
    Logger? logger,
  }) = _LiveTranscriptionService;

  /// The stand-in until `main` binds the service: every start fails.
  const factory LiveTranscriptionService.unavailable() =
      _UnavailableLiveTranscription;

  /// Claims the microphone, checks the permission and storage, opens the
  /// take and starts streaming; the engine is acquired in parallel. A
  /// long-form session whose engine cannot load keeps recording without a
  /// transcript (Rule 3); a dictation session fails.
  Future<Result<LiveTranscriptionSession>> start(
    LiveTranscriptionRequest request,
  );

  /// Publishes the take a killed process left staged for [audioPath]: as
  /// it stands when its header matches its size, else as a repaired copy
  /// beside the kept original.
  Future<Result<AudioRecording?>> recoverAudio(String audioPath);

  /// Transcribes what a stored take's transcript lacks, at the operator's
  /// request: first each of [gaps] (skipped sample ranges), then the tail
  /// from [fromSample], into [sink] with segment ids from
  /// [nextSegmentId]. The work starts when the stream is listened to and
  /// stops when the listener cancels; the sink is always finished.
  Stream<LiveTranscriptionEvent> transcribeRemaining(
    String audioPath, {
    required List<(int, int)> gaps,
    required int fromSample,
    required int nextSegmentId,
    required String languageTag,
    required TranscriptSink sink,
  });

  /// Aborts every drain, finishing its transcript as interrupted, and
  /// abandons every take still recording, kept for recovery.
  Future<void> dispose();
}

/// The process-wide live transcription service, kept alive deliberately:
/// it owns the drains of stopped sessions. Unavailable until `main`
/// overrides it.
final Provider<LiveTranscriptionService> liveTranscriptionServiceProvider =
    Provider<LiveTranscriptionService>((Ref _) {
      return const LiveTranscriptionService.unavailable();
    });

final class _UnavailableLiveTranscription implements LiveTranscriptionService {
  const _UnavailableLiveTranscription();

  @override
  Future<Result<LiveTranscriptionSession>> start(
    LiveTranscriptionRequest request,
  ) async {
    return FailureResult<LiveTranscriptionSession>(speechUnavailable());
  }

  @override
  Future<Result<AudioRecording?>> recoverAudio(String audioPath) async {
    return FailureResult<AudioRecording?>(speechUnavailable());
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
    return Stream<LiveTranscriptionEvent>.value(
      TranscriptionFailed(failure: speechUnavailable()),
    );
  }

  @override
  Future<void> dispose() async {}
}

final class _LiveTranscriptionService implements LiveTranscriptionService {
  _LiveTranscriptionService({
    required this._capture,
    required this._host,
    required this._lifecycle,
    required this._leaveGuard,
    required this._storageGuard,
    this._recovery,
    this._storageRoot,
    this._reader,
    Duration? sessionLimit,
    Logger? logger,
  }) : _sessionLimit =
           sessionLimit ??
           (kIsWeb
               ? AppConstants.speechSession.webMaxSessionDuration
               : AppConstants.speechSession.maxSessionDuration),
       _logger = logger ?? Logger.current {
    _states = _lifecycle.states.listen(_onLifecycle);
  }

  final AudioCaptureService _capture;
  final SpeechEngineHost _host;
  final LifecycleObserver _lifecycle;
  final LeaveGuard _leaveGuard;
  final StorageGuard _storageGuard;
  final AudioRecoveryService? _recovery;
  final StorageRoot? _storageRoot;
  final FileReader? _reader;
  final Duration _sessionLimit;
  final Logger _logger;
  final List<_ActiveTranscription> _sessions = <_ActiveTranscription>[];
  late final StreamSubscription<AppLifecycleState> _states;
  bool _disposed = false;

  /// Whether this device is a phone or tablet, which drafts less.
  bool get _mobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<Result<LiveTranscriptionSession>> start(
    LiveTranscriptionRequest request,
  ) async {
    if (_disposed) {
      return FailureResult<LiveTranscriptionSession>(speechUnavailable());
    }
    final bool dictation = request.kind == TranscriptionKind.dictation;
    final String? audioPath = request.audioPath;
    if (!dictation && audioPath == null) {
      return const FailureResult<LiveTranscriptionSession>(ValidationFailure());
    }
    bool storageLow = false;
    if (!dictation) {
      final Result<bool> admitted = await _admit();
      switch (admitted) {
        case FailureResult<bool>(:final Failure failure):
          _logger.warn(_tag, 'session refused (${failure.runtimeType})');
          return FailureResult<LiveTranscriptionSession>(failure);
        case Success<bool>(:final bool value):
          storageLow = value;
      }
    }
    final bool transcribe = dictation || request.transcribe;
    // The model loads while the microphone opens, so the first words are
    // captured even when the load is slow.
    final Future<Result<SpeechEngineLease>>? acquiring = transcribe
        ? _host.acquire(languageTag: request.languageTag)
        : null;
    _ActiveTranscription? session;
    final Result<AudioCaptureSession> started = await _capture.start(
      AudioCaptureRequest(
        owner: dictation
            ? MicrophoneOwner.dictation
            : MicrophoneOwner.liveTranscription,
        relativePath: dictation ? null : audioPath,
        maxDuration: dictation
            ? request.maxDuration ?? AppConstants.dictation.listenFor
            : null,
        onPreempted: () => session?._preempted(),
      ),
    );
    switch (started) {
      case FailureResult<AudioCaptureSession>(:final Failure failure):
        _logger.warn(_tag, 'capture did not start (${failure.runtimeType})');
        if (acquiring != null) {
          unawaited(_releaseWhenAcquired(acquiring));
        }
        return FailureResult<LiveTranscriptionSession>(failure);
      case Success<AudioCaptureSession>(:final AudioCaptureSession value):
        final _ActiveTranscription opened = _ActiveTranscription(
          service: this,
          request: request,
          capture: value,
          acquiring: acquiring,
        );
        session = opened;
        _track(opened);
        opened._begin(storageLow: storageLow);
        return Success<LiveTranscriptionSession>(opened);
    }
  }

  /// Whether a long-form take may start, and whether storage is low. Only
  /// a volume read as critical refuses: one that cannot be read never
  /// blocks capture (Rule 3).
  Future<Result<bool>> _admit() async {
    final Result<HeadroomState> checked = await _storageGuard.beginSession();
    switch (checked) {
      case FailureResult<HeadroomState>(:final Failure failure):
        _logger.warn(_tag, 'free space unknown (${failure.runtimeType})');
        return const Success<bool>(false);
      case Success<HeadroomState>(:final HeadroomState value):
        if (value == HeadroomState.critical) {
          final Result<HeadroomState> admitted = await _storageGuard
              .admitCapture();
          if (admitted case FailureResult<HeadroomState>(
            :final Failure failure,
          )) {
            return FailureResult<bool>(failure);
          }
        }
        return Success<bool>(_storageGuard.takeLowWarning());
    }
  }

  Future<void> _releaseWhenAcquired(
    Future<Result<SpeechEngineLease>> acquiring,
  ) async {
    final Result<SpeechEngineLease> acquired = await acquiring;
    if (acquired case Success<SpeechEngineLease>(
      :final SpeechEngineLease value,
    )) {
      await value.release();
    }
  }

  @override
  Future<Result<AudioRecording?>> recoverAudio(String audioPath) async {
    final AudioRecoveryService? recovery = _recovery;
    if (recovery == null) {
      return FailureResult<AudioRecording?>(speechUnavailable());
    }
    final Result<AudioRecording?> recovered = await recovery.recover(audioPath);
    if (recovered case FailureResult<AudioRecording?>(:final Failure failure)) {
      _logger.warn(_tag, 'take recovery failed (${failure.runtimeType})');
    }
    return recovered;
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
    _RemainingTranscription? job;
    late final StreamController<LiveTranscriptionEvent> out;
    out = StreamController<LiveTranscriptionEvent>(
      onListen: () {
        final _RemainingTranscription started = job = _RemainingTranscription(
          service: this,
          audioPath: audioPath,
          gaps: gaps,
          fromSample: fromSample,
          nextSegmentId: nextSegmentId,
          languageTag: languageTag,
          sink: sink,
          emit: (LiveTranscriptionEvent event) {
            if (!out.isClosed) {
              out.add(event);
            }
          },
        );
        unawaited(started.run().whenComplete(out.close));
      },
      onCancel: () => job?.cancel(),
    );
    return out.stream;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _states.cancel();
    await Future.wait(<Future<void>>[
      for (final _ActiveTranscription session in List<_ActiveTranscription>.of(
        _sessions,
      ))
        session._shutDown(),
    ]);
  }

  /// A pipeline over [store] in [languageTag] from [startSample].
  SpeechPipeline _pipelineFor(
    PcmStore store, {
    required String languageTag,
    required bool interims,
    required bool dictation,
    required TranscriptSink? sink,
    required int nextSegmentId,
    required void Function(LiveTranscriptionEvent event) emit,
    int startSample = 0,
  }) {
    return SpeechPipeline(
      store: store,
      config: SpeechPipelineConfig(
        languageTag: languageTag,
        interims: interims,
        mobile: _mobile,
        dictation: dictation,
      ),
      sink: sink,
      nextSegmentId: nextSegmentId,
      emit: emit,
      logger: _logger,
      startSample: startSample,
    );
  }

  /// Starts holding the pause flush and the exit check with the first
  /// session, and the leave guard for each long-form one.
  void _track(_ActiveTranscription session) {
    if (_sessions.isEmpty) {
      _lifecycle
        ..addPauseFlush(_checkpointAll)
        ..addExitCheck(_exitCheck);
    }
    _sessions.add(session);
    if (!session._dictation) {
      _leaveGuard.hold(session);
    }
    _liveSessions++;
  }

  /// Lets go of what [_track] held once [session] has ended.
  void _untrack(_ActiveTranscription session) {
    if (!_sessions.remove(session)) {
      return;
    }
    _leaveGuard.release(session);
    if (_sessions.isEmpty) {
      _lifecycle
        ..removePauseFlush(_checkpointAll)
        ..removeExitCheck(_exitCheck);
    }
    _liveSessions--;
  }

  /// The awaited pause flush: every long-form take is paused, patched and
  /// flushed and its last transcript write has landed; dictation stops.
  Future<void> _checkpointAll() async {
    await Future.wait(<Future<void>>[
      for (final _ActiveTranscription session in List<_ActiveTranscription>.of(
        _sessions,
      ))
        session._toBackground(),
    ]);
  }

  /// The window is closing: every take is checkpointed and left for
  /// recovery to adopt. Nothing drains and nothing is published.
  Future<bool> _exitCheck() async {
    await Future.wait(<Future<void>>[
      for (final _ActiveTranscription session in List<_ActiveTranscription>.of(
        _sessions,
      ))
        session._leaveForRecovery(),
    ]);
    return true;
  }

  void _onLifecycle(AppLifecycleState state) {
    if (state != AppLifecycleState.detached) {
      return;
    }
    // The engine is going away: capture stops and publishes, and the drain
    // runs on without being awaited.
    for (final _ActiveTranscription session in List<_ActiveTranscription>.of(
      _sessions,
    )) {
      unawaited(session._detach());
    }
  }

  /// [samples] of the 16 kHz timeline as a duration.
  static Duration _durationOf(int samples) => stagedTakeDuration(samples);

  /// [duration] in samples of the 16 kHz timeline.
  static int _samplesOf(Duration duration) =>
      duration.inMicroseconds *
      AppConstants.audio.sampleRate ~/
      Duration.microsecondsPerSecond;
}

const String _tag = 'speech';
