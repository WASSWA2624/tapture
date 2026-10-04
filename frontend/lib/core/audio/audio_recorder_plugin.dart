// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:io';

import 'package:record/record.dart' as record;
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'audio_recorder_service.dart';
import 'microphone_arbiter.dart';
import 'microphone_lease.dart';
import 'microphone_owner.dart';
import 'staged_take.dart';
import 'staged_take_recovery.dart';

/// Native microphone adapter. Plugin types stop in this core platform file;
/// capture depends only on [AudioRecorderService].
///
/// The recorder plugins cannot stream WAV, so a take is recorded in file mode
/// to a staging file beside the target and then published through
/// [publishStagedTake], which hashes it and renames it into place.
///
/// The microphone is claimed from [MicrophoneArbiter] as
/// [MicrophoneOwner.fileRecorder] for the length of a take.
final class AudioRecorderPlugin
    implements AudioRecorderService, AudioRecoveryService {
  /// Creates an adapter that stages takes under [storageRoot] and publishes
  /// them through [writer]. [arbiter] is the app's one microphone owner; a
  /// recorder of its own is used when it is omitted. [recorder] is the test
  /// seam.
  AudioRecorderPlugin({
    required FileWriter writer,
    required StorageRoot storageRoot,
    MicrophoneArbiter? arbiter,
    record.AudioRecorder? recorder,
  }) : _writer = writer,
       _storageRoot = storageRoot,
       _arbiter = arbiter ?? MicrophoneArbiter(),
       _recovery = StagedTakeRecovery(writer: writer, storageRoot: storageRoot),
       _recorder = recorder ?? record.AudioRecorder();

  final FileWriter _writer;
  final StorageRoot _storageRoot;
  final MicrophoneArbiter _arbiter;
  final StagedTakeRecovery _recovery;
  final record.AudioRecorder _recorder;
  MicrophoneLease? _lease;
  final StreamController<AudioRecorderState> _states =
      StreamController<AudioRecorderState>.broadcast();
  StreamSubscription<record.Amplitude>? _amplitude;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  AudioRecorderPhase _phase = AudioRecorderPhase.idle;
  AudioRecording? _completed;
  String? _path;
  File? _staging;

  @override
  Stream<AudioRecorderState> get state => _states.stream;

  @override
  AudioRecording? get completed => _completed;

  @override
  Future<Result<void>> start(String relativePath) async {
    if (_phase == AudioRecorderPhase.permission ||
        _phase == AudioRecorderPhase.recording ||
        _phase == AudioRecorderPhase.paused ||
        _phase == AudioRecorderPhase.finalizing) {
      return FailureResult<void>(
        ValidationFailure(localizedMessage: Copy.messages.audioStartFailed),
      );
    }
    final Result<MicrophoneLease> claimed = await _arbiter.claim(
      MicrophoneOwner.fileRecorder,
    );
    switch (claimed) {
      case FailureResult<MicrophoneLease>(:final Failure failure):
        return FailureResult<void>(failure);
      case Success<MicrophoneLease>(:final MicrophoneLease value):
        _lease = value;
    }
    try {
      _phase = AudioRecorderPhase.permission;
      _emit();
      if (!await _recorder.hasPermission()) {
        _phase = AudioRecorderPhase.failed;
        _releaseMicrophone();
        _emit();
        return FailureResult<void>(
          PermissionFailure(
            localizedMessage: Copy.messages.audioPermissionDenied,
            localizedRecovery: Copy.messages.audioPermissionRecovery,
          ),
        );
      }
      final Result<Directory> root = await _storageRoot.resolve();
      final Directory folder = switch (root) {
        Success<Directory>(:final Directory value) => value,
        FailureResult<Directory>(:final Failure failure) => throw failure,
      };
      final String relative = stagedTakePath(relativePath);
      final File staging = File('${folder.path}/$relative$stagedTakeSuffix');
      if (await staging.exists() ||
          await File('${folder.path}/$relative').exists()) {
        throw ValidationFailure(
          localizedMessage: Copy.messages.audioStartFailed,
        );
      }
      await staging.parent.create(recursive: true);
      _path = relativePath;
      _staging = staging;
      _completed = null;
      _elapsed = Duration.zero;
      await _recorder.start(
        record.RecordConfig(
          encoder: record.AudioEncoder.wav,
          sampleRate: AppConstants.audio.sampleRate,
          numChannels: AppConstants.audio.channels,
        ),
        path: staging.path,
      );
      _phase = AudioRecorderPhase.recording;
      _timer?.cancel();
      _timer = Timer.periodic(AppConstants.audio.meterTick, (_) {
        if (_phase == AudioRecorderPhase.recording) {
          _elapsed += AppConstants.audio.meterTick;
          _emit();
        }
      });
      _amplitude = _recorder
          .onAmplitudeChanged(AppConstants.audio.meterTick)
          .listen((record.Amplitude value) {
            _emit(level: ((value.current + 60) / 60).clamp(0, 1));
          });
      _emit();
      return const Success<void>(null);
    } on Failure catch (failure) {
      _phase = AudioRecorderPhase.failed;
      _releaseMicrophone();
      _emit();
      return FailureResult<void>(failure);
    } on Object {
      _phase = AudioRecorderPhase.failed;
      _releaseMicrophone();
      _emit();
      return FailureResult<void>(
        ProviderFailure(
          localizedMessage: Copy.messages.audioStartFailed,
          localizedRecovery: Copy.messages.audioStartFailedRecovery,
        ),
      );
    }
  }

  @override
  Future<Result<void>> pause() async {
    try {
      await _recorder.pause();
      _phase = AudioRecorderPhase.paused;
      _emit();
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(Failure.from(error));
    }
  }

  @override
  Future<Result<void>> resume() async {
    try {
      await _recorder.resume();
      _phase = AudioRecorderPhase.recording;
      _emit();
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(Failure.from(error));
    }
  }

  @override
  Future<Result<Duration>> stop() async {
    _timer?.cancel();
    _timer = null;
    await _amplitude?.cancel();
    _amplitude = null;
    try {
      _phase = AudioRecorderPhase.finalizing;
      _emit();
      await _recorder.stop();
      _releaseMicrophone();
      final File? staging = _staging;
      final String? path = _path;
      if (staging == null || path == null) {
        throw StateError('No audio take is active.');
      }
      final Result<AudioRecording> result = await publishStagedTake(
        writer: _writer,
        staging: staging,
        relativePath: path,
        fallback: _elapsed,
      );
      switch (result) {
        case FailureResult<AudioRecording>(:final Failure failure):
          // The staging file is the only copy; it stays for the next attempt
          // and the orphan report (FE-SIMP-09).
          _phase = AudioRecorderPhase.failed;
          _emit();
          return FailureResult<Duration>(failure);
        case Success<AudioRecording>(:final AudioRecording value):
          _completed = value;
          _staging = null;
          _phase = AudioRecorderPhase.completed;
          _emit();
          return Success<Duration>(value.duration);
      }
    } on Object catch (error) {
      _phase = AudioRecorderPhase.failed;
      _releaseMicrophone();
      _emit();
      return FailureResult<Duration>(Failure.from(error));
    }
  }

  @override
  Future<Result<AudioRecording?>> recover(String relativePath) async {
    try {
      final String path = stagedTakePath(relativePath);
      if (_path == path &&
          (_phase == AudioRecorderPhase.recording ||
              _phase == AudioRecorderPhase.paused)) {
        final Result<Duration> stopped = await stop();
        return stopped.map((_) => _completed);
      }
      if (_path == path &&
          (_phase == AudioRecorderPhase.permission ||
              _phase == AudioRecorderPhase.finalizing)) {
        return FailureResult<AudioRecording?>(
          StorageFailure(localizedMessage: Copy.messages.audioStartFailed),
        );
      }
      return _recovery.recover(path);
    } on Object catch (error) {
      return FailureResult<AudioRecording?>(Failure.from(error));
    }
  }

  void _releaseMicrophone() {
    _lease?.release();
    _lease = null;
  }

  void _emit({double level = 0}) {
    if (!_states.isClosed) {
      _states.add(
        AudioRecorderState(phase: _phase, elapsed: _elapsed, level: level),
      );
    }
  }
}
