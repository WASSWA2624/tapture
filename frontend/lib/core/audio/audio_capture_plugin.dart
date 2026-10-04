import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart' as record;
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'audio_capture_event.dart';
import 'audio_capture_request.dart';
import 'audio_capture_service.dart';
import 'audio_capture_session.dart';
import 'audio_recording.dart';
import 'capture_format.dart';
import 'capture_pause_reason.dart';
import 'capture_staging.dart';
import 'microphone_access.dart';
import 'microphone_arbiter.dart';
import 'microphone_lease.dart';
import 'pcm_chunk.dart';
import 'pcm_level_meter.dart';
import 'pcm_resampler.dart';
import 'pcm_store.dart';

/// Captures that still hold a recorder or the microphone lease.
int _liveSessions = 0;

/// How many captures still hold a recorder or the microphone lease. Every
/// path out of a capture brings it back down.
@visibleForTesting
int get debugLiveCaptureSessions => _liveSessions;

/// The streaming adapter over the recorder plugin (FE-STR-11).
///
/// Each capture claims the microphone from [MicrophoneArbiter], checks
/// [MicrophoneAccess], opens [CaptureStaging] and starts a new recorder in
/// stream mode at 16 kHz mono, falling back to 48 and 44.1 kHz with
/// [PcmResampler] when the device refuses. Bytes are mixed down, resampled,
/// appended to staging, metered and only then emitted.
final class AudioCapturePlugin implements AudioCaptureService {
  /// An adapter staging takes under `storageRoot` and publishing them
  /// through `writer`. `recorderFactory` is the test seam.
  AudioCapturePlugin({
    required this._writer,
    required this._storageRoot,
    required this._access,
    required this._arbiter,
    @visibleForTesting record.AudioRecorder Function()? recorderFactory,
  }) : _recorderFactory = recorderFactory ?? record.AudioRecorder.new;

  final FileWriter _writer;
  final StorageRoot _storageRoot;
  final MicrophoneAccess _access;
  final MicrophoneArbiter _arbiter;
  final record.AudioRecorder Function() _recorderFactory;

  @override
  Future<Result<AudioCaptureSession>> start(AudioCaptureRequest request) async {
    _CaptureSession? session;
    final Result<MicrophoneLease> claimed = await _arbiter.claim(
      request.owner,
      onPreempted: () async {
        final VoidCallback? preempted = request.onPreempted;
        if (preempted != null) {
          preempted();
          return;
        }
        await session?.stop();
      },
    );
    final MicrophoneLease lease;
    switch (claimed) {
      case FailureResult<MicrophoneLease>(:final Failure failure):
        return FailureResult<AudioCaptureSession>(failure);
      case Success<MicrophoneLease>(:final MicrophoneLease value):
        lease = value;
    }
    final Result<void> allowed = await _access.ensure();
    if (allowed case FailureResult<void>(:final Failure failure)) {
      lease.release();
      return FailureResult<AudioCaptureSession>(failure);
    }
    final Result<CaptureStaging> staged = await CaptureStaging.open(
      root: _storageRoot,
      writer: _writer,
      relativePath: request.relativePath,
      maxDuration: request.maxDuration,
    );
    final CaptureStaging staging;
    switch (staged) {
      case FailureResult<CaptureStaging>(:final Failure failure):
        lease.release();
        return FailureResult<AudioCaptureSession>(failure);
      case Success<CaptureStaging>(:final CaptureStaging value):
        staging = value;
    }
    final record.AudioRecorder recorder;
    try {
      recorder = _recorderFactory();
    } on Object catch (error) {
      await staging.discardIfEmpty();
      await staging.release();
      lease.release();
      return FailureResult<AudioCaptureSession>(_captureFailure(error));
    }
    final _CaptureSession opened = _CaptureSession(
      recorder: recorder,
      staging: staging,
      lease: lease,
      access: _access,
    );
    session = opened;
    final Result<void> streaming = await opened._open();
    if (streaming case FailureResult<void>(:final Failure failure)) {
      await opened._failStart();
      return FailureResult<AudioCaptureSession>(failure);
    }
    return Success<AudioCaptureSession>(opened);
  }
}

final class _CaptureSession implements AudioCaptureSession {
  _CaptureSession({
    required this._recorder,
    required this._staging,
    required this._lease,
    required this._access,
  }) : _format = CaptureFormat(
         inputSampleRate: AppConstants.audio.sampleRate,
         inputChannels: AppConstants.audio.channels,
       ) {
    _liveSessions++;
  }

  final record.AudioRecorder _recorder;
  final CaptureStaging _staging;
  final MicrophoneLease _lease;
  final MicrophoneAccess _access;
  final StreamController<PcmChunk> _chunks = StreamController<PcmChunk>();
  final StreamController<AudioCaptureEvent> _events =
      StreamController<AudioCaptureEvent>.broadcast();
  final PcmLevelMeter _meter = PcmLevelMeter();

  StreamSubscription<Uint8List>? _frames;
  StreamSubscription<record.RecordState>? _states;
  Completer<void>? _framesDone;
  Future<void> _work = Future<void>.value();
  CaptureFormat _format;
  PcmResampler? _resampler;
  Uint8List _carry = Uint8List(0);
  int _captured = 0;
  bool _paused = false;
  bool _pauseRequested = false;
  bool _streamLost = false;
  bool _writeFailed = false;
  bool _stopping = false;
  bool _microphoneClosed = false;
  bool _published = false;
  bool _finished = false;
  bool _released = false;
  Future<Result<AudioRecording?>>? _stopRun;
  Future<Result<String?>>? _abandoned;

  @override
  Stream<PcmChunk> get chunks => _chunks.stream;

  @override
  Stream<AudioCaptureEvent> get events => _events.stream;

  @override
  int get capturedSamples => _captured;

  @override
  PcmStore get store => _staging.store;

  @override
  CaptureFormat get format => _format;

  /// Subscribes to the recorder's state and format before the stream
  /// starts, then opens the stream.
  Future<Result<void>> _open() async {
    try {
      _states = _recorder.onStateChanged().listen(
        _onState,
        onError: _onStreamError,
      );
      await _recorder.setOnConfigChanged(_onConfig);
    } on Object catch (error) {
      return FailureResult<void>(_captureFailure(error));
    }
    return _openStream();
  }

  /// Starts the stream at 16 kHz, or at the first fallback rate the device
  /// accepts, and listens in the same continuation: the recorder drops
  /// chunks that arrive while nothing listens.
  Future<Result<void>> _openStream() async {
    final List<int> rates = <int>[
      AppConstants.audio.sampleRate,
      ...AppConstants.speechSession.fallbackCaptureRates,
    ];
    for (final int rate in rates) {
      final CaptureFormat format = CaptureFormat(
        inputSampleRate: rate,
        inputChannels: AppConstants.audio.channels,
      );
      final PcmResampler? resampler;
      try {
        resampler = format.resampled ? PcmResampler(inputRate: rate) : null;
      } on ArgumentError {
        continue;
      }
      _format = format;
      _resampler = resampler;
      _carry = Uint8List(0);
      try {
        final Stream<Uint8List> stream = await _recorder.startStream(
          _config(rate),
        );
        final Completer<void> done = Completer<void>();
        _framesDone = done;
        _frames = stream.listen(
          _onBytes,
          onError: _onStreamError,
          onDone: () => _onStreamDone(done),
        );
        _streamLost = false;
        return const Success<void>(null);
      } on Object catch (error) {
        if (_rateRefused.hasMatch(error.toString())) {
          continue;
        }
        return FailureResult<void>(_captureFailure(error));
      }
    }
    return FailureResult<void>(_startFailed());
  }

  record.RecordConfig _config(int rate) {
    return record.RecordConfig(
      encoder: record.AudioEncoder.pcm16bits,
      sampleRate: rate,
      numChannels: AppConstants.audio.channels,
      audioInterruption: record.AudioInterruptionMode.pause,
      androidConfig: const record.AndroidRecordConfig(
        audioSource: record.AndroidAudioSource.voiceRecognition,
      ),
    );
  }

  void _onBytes(Uint8List bytes) => _enqueue(() => _process(bytes));

  void _onConfig(record.RecordConfig config) {
    _enqueue(() async {
      final CaptureFormat format = CaptureFormat(
        inputSampleRate: config.sampleRate,
        inputChannels: config.numChannels,
      );
      if (format.inputSampleRate == _format.inputSampleRate &&
          format.inputChannels == _format.inputChannels) {
        return;
      }
      await _flushResampler();
      final PcmResampler? resampler;
      try {
        resampler = format.resampled
            ? PcmResampler(inputRate: format.inputSampleRate)
            : null;
      } on ArgumentError {
        await _failWrite(_startFailed());
        return;
      }
      _format = format;
      _resampler = resampler;
      _carry = Uint8List(0);
      _emit(CaptureFormatChanged(format));
    });
  }

  void _onState(record.RecordState state) {
    if (_stopping || _streamLost) {
      return;
    }
    switch (state) {
      case record.RecordState.pause:
        if (!_pauseRequested && !_paused) {
          unawaited(_interrupted());
        }
      case record.RecordState.stop:
        unawaited(_lose(CapturePauseReason.microphoneLost));
      case record.RecordState.record:
        break;
    }
  }

  void _onStreamError(Object error) {
    if (_stopping || _streamLost) {
      return;
    }
    final Failure failure = _captureFailure(error);
    unawaited(
      _lose(
        failure is PermissionFailure
            ? CapturePauseReason.permissionRevoked
            : CapturePauseReason.microphoneLost,
      ),
    );
  }

  void _onStreamDone(Completer<void> done) {
    if (!done.isCompleted) {
      done.complete();
    }
    if (!_stopping && !_streamLost) {
      unawaited(_lose(CapturePauseReason.microphoneLost));
    }
  }

  /// Turns raw bytes into 16 kHz mono samples and keeps them. A partial
  /// frame waits for the next chunk.
  Future<void> _process(Uint8List bytes) async {
    if (_writeFailed) {
      return;
    }
    final int channels = _format.inputChannels;
    final int frameBytes = 2 * channels;
    final Uint8List joined;
    if (_carry.isEmpty) {
      joined = bytes;
    } else {
      joined = Uint8List(_carry.length + bytes.length)
        ..setRange(0, _carry.length, _carry)
        ..setRange(_carry.length, _carry.length + bytes.length, bytes);
    }
    final int frames = joined.length ~/ frameBytes;
    _carry = joined.sublist(frames * frameBytes);
    if (frames == 0) {
      return;
    }
    // Read through ByteData: a chunk need not start on a 2-byte boundary.
    final ByteData data = ByteData.sublistView(joined, 0, frames * frameBytes);
    final Int16List mono = Int16List(frames);
    for (int frame = 0; frame < frames; frame++) {
      var sum = 0;
      for (int channel = 0; channel < channels; channel++) {
        sum += data.getInt16((frame * channels + channel) * 2, Endian.little);
      }
      mono[frame] = channels == 1 ? sum : (sum / channels).floor();
    }
    final Int16List samples = _resampler?.process(mono) ?? mono;
    if (samples.isNotEmpty) {
      await _keep(samples);
    }
  }

  /// Appends [samples] to staging, meters them and emits them, in that
  /// order.
  Future<void> _keep(Int16List samples) async {
    final Result<void> kept = await _staging.append(samples);
    if (kept case FailureResult<void>(:final Failure failure)) {
      await _failWrite(failure);
      return;
    }
    final int start = _captured;
    _captured += samples.length;
    for (final CaptureLevel level in _meter.add(samples)) {
      _emit(level);
    }
    if (!_chunks.isClosed) {
      _chunks.add(PcmChunk(start, samples));
    }
  }

  Future<void> _flushResampler() async {
    final PcmResampler? resampler = _resampler;
    _resampler = null;
    final Int16List tail = resampler?.flush() ?? Int16List(0);
    if (tail.isNotEmpty && !_writeFailed) {
      await _keep(tail);
    }
  }

  /// Audio could not be kept: say so and stop the microphone at once, so
  /// nothing more is silently lost.
  Future<void> _failWrite(Failure failure) async {
    if (_writeFailed) {
      return;
    }
    _writeFailed = true;
    _emit(CaptureFailed(failure));
    await _silenceMicrophone();
  }

  /// The platform paused the microphone (audio focus, a call). It stays
  /// paused until the operator resumes.
  Future<void> _interrupted() async {
    _paused = true;
    await _drain();
    await _staging.checkpoint();
    _emit(
      CapturePaused(
        reason: CapturePauseReason.interruption,
        atSample: _captured,
      ),
    );
  }

  /// The stream ended or failed while recording: keep what arrived, patch
  /// the take and pause for [reason].
  Future<void> _lose(CapturePauseReason reason) async {
    if (_streamLost || _stopping) {
      return;
    }
    _paused = true;
    await _silenceMicrophone();
    await _drain();
    await _flushResampler();
    await _staging.checkpoint();
    _emit(CapturePaused(reason: reason, atSample: _captured));
  }

  Future<void> _silenceMicrophone() async {
    _streamLost = true;
    final StreamSubscription<Uint8List>? frames = _frames;
    _frames = null;
    await frames?.cancel();
    final Completer<void>? done = _framesDone;
    if (done != null && !done.isCompleted) {
      done.complete();
    }
    try {
      await _recorder.stop();
    } on Object {
      // The stream is already gone; stopping is best effort.
    }
  }

  void _enqueue(Future<void> Function() job) {
    _work = _work.then((_) => job()).then<void>((_) {}, onError: (Object _) {});
  }

  /// Waits until every chunk received so far has been kept.
  Future<void> _drain() async {
    Future<void> current;
    do {
      current = _work;
      await current;
    } while (!identical(current, _work));
  }

  void _emit(AudioCaptureEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }

  @override
  Future<Result<void>> pause() async {
    if (_writeFailed) {
      return const FailureResult<void>(StorageFailure());
    }
    if (_paused || _microphoneClosed) {
      return const Success<void>(null);
    }
    _pauseRequested = true;
    _paused = true;
    try {
      await _recorder.pause();
    } on Object catch (error) {
      _pauseRequested = false;
      _paused = false;
      return FailureResult<void>(_captureFailure(error));
    }
    await _drain();
    final Result<void> checkpointed = await _staging.checkpoint();
    _emit(CapturePaused(reason: CapturePauseReason.user, atSample: _captured));
    return checkpointed;
  }

  @override
  Future<Result<void>> resume() async {
    if (_writeFailed) {
      return const FailureResult<void>(StorageFailure());
    }
    if (_microphoneClosed) {
      return FailureResult<void>(_startFailed());
    }
    if (!_paused) {
      return const Success<void>(null);
    }
    if (!await _access.isGranted()) {
      return FailureResult<void>(_permissionDenied());
    }
    if (_streamLost) {
      final Result<void> reopened = await _openStream();
      if (reopened is FailureResult<void>) {
        return reopened;
      }
    } else {
      try {
        await _recorder.resume();
      } on Object catch (error) {
        return FailureResult<void>(_captureFailure(error));
      }
    }
    _paused = false;
    _pauseRequested = false;
    _emit(CaptureResumed(atSample: _captured));
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> checkpoint() async {
    await _drain();
    return _staging.checkpoint();
  }

  @override
  Future<Result<AudioRecording?>> stop() {
    final Future<Result<AudioRecording?>>? running = _stopRun;
    if (running != null) {
      return running;
    }
    final Future<Result<AudioRecording?>> next = _stop();
    _stopRun = next;
    unawaited(
      next.then<void>((Result<AudioRecording?> result) {
        // A failed publish keeps the staged take; calling again retries.
        if (result is FailureResult<AudioRecording?>) {
          _stopRun = null;
        }
      }),
    );
    return next;
  }

  Future<Result<AudioRecording?>> _stop() async {
    if (_abandoned != null) {
      return FailureResult<AudioRecording?>(_startFailed());
    }
    await _closeMicrophone();
    final Result<AudioRecording?> published = await _staging.publish();
    _published = published is Success<AudioRecording?>;
    await _finish();
    return published;
  }

  @override
  Future<Result<String?>> abandon() {
    return _abandoned ??= () async {
      await _closeMicrophone();
      await _drainStop();
      if (_published) {
        await _finish();
        return const Success<String?>(null);
      }
      final Result<String?> kept = await _staging.abandon();
      await _finish();
      return kept;
    }();
  }

  /// Lets a stop already under way settle before an abandon reads its
  /// outcome.
  Future<void> _drainStop() async {
    final Future<Result<AudioRecording?>>? running = _stopRun;
    if (running != null) {
      await running;
    }
  }

  @override
  Future<void> release() async {
    if (_released) {
      return;
    }
    if (!_finished) {
      await abandon();
    }
    _released = true;
    await _staging.release();
  }

  /// Stops the recorder, waits for the chunks it was still delivering and
  /// keeps the resampler's tail.
  Future<void> _closeMicrophone() async {
    if (_microphoneClosed) {
      return;
    }
    _microphoneClosed = true;
    _stopping = true;
    final Completer<void>? done = _framesDone;
    if (!_streamLost) {
      try {
        await _recorder.stop();
      } on Object {
        // The stream is cancelled below whether or not stop succeeded.
      }
      if (done != null) {
        await done.future.timeout(
          AppConstants.dictation.settle,
          onTimeout: () {},
        );
      }
    }
    await _frames?.cancel();
    _frames = null;
    await _states?.cancel();
    _states = null;
    await _drain();
    await _flushResampler();
  }

  /// Disposes the recorder and gives the microphone back. Idempotent.
  Future<void> _finish() async {
    if (_finished) {
      return;
    }
    _finished = true;
    try {
      await _recorder.dispose();
    } on Object {
      // Disposal is best effort; the lease is released regardless.
    }
    _lease.release();
    unawaited(_chunks.close());
    unawaited(_events.close());
    _liveSessions--;
  }

  /// Cleans up after a start that never streamed. A staging file that
  /// never received audio is removed; it holds nothing.
  Future<void> _failStart() async {
    _microphoneClosed = true;
    _stopping = true;
    await _frames?.cancel();
    _frames = null;
    await _states?.cancel();
    _states = null;
    await _staging.discardIfEmpty();
    await _staging.release();
    _released = true;
    await _finish();
  }
}

/// Platform messages that mean the device refused the requested rate:
/// Android `AudioRecord`, and Media Foundation on Windows.
final RegExp _rateRefused = RegExp(
  'not supported by the hardware|failed to initialize|Unable to instantiate|'
  'MF_E_INVALIDMEDIATYPE|0xC00D36B4',
  caseSensitive: false,
);

/// Messages that mean the microphone is blocked by a permission or a
/// privacy setting.
final RegExp _permissionRefused = RegExp(
  'NotAllowedError|permission|denied|0x80070005|E_ACCESSDENIED',
  caseSensitive: false,
);

/// Messages that mean there is no microphone to open.
final RegExp _noDevice = RegExp(
  'NotFoundError|no input device',
  caseSensitive: false,
);

/// Maps a start or stream error onto the failure the operator sees.
Failure _captureFailure(Object error) {
  final String text = error.toString();
  if (error is PermissionFailure || _permissionRefused.hasMatch(text)) {
    return _permissionDenied();
  }
  if (error is ProcessException || _noDevice.hasMatch(text)) {
    return ProviderFailure(
      kind: ProviderFailureKind.unavailable,
      localizedMessage: Copy.messages.audioRecorderUnavailable,
    );
  }
  if (error is Failure) {
    return error;
  }
  return _startFailed();
}

PermissionFailure _permissionDenied() {
  return PermissionFailure(
    localizedMessage: Copy.messages.audioPermissionDenied,
    localizedRecovery: Copy.messages.audioPermissionRecovery,
  );
}

ProviderFailure _startFailed() {
  return ProviderFailure(
    localizedMessage: Copy.messages.audioStartFailed,
    localizedRecovery: Copy.messages.audioStartFailedRecovery,
  );
}
