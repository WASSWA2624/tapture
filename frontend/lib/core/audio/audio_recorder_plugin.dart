// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'package:record/record.dart' as record;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'audio_recorder_service.dart';

part 'wav_take.dart';

/// Suffix of a take the plugin is still writing. It sits beside the target,
/// never under `.cache`, because it is the only copy until it is published.
const String _stagingSuffix = '.recording';

/// Native microphone adapter. Plugin types stop in this core platform file;
/// capture depends only on [AudioRecorderService].
///
/// The recorder plugins cannot stream WAV, so a take is recorded in file mode
/// to a staging file beside the target and then published through
/// [FileWriter.copyIn], which hashes it and renames it into place.
final class AudioRecorderPlugin
    implements AudioRecorderService, AudioRecoveryService {
  /// Creates an adapter that stages takes under [storageRoot] and publishes
  /// them through [writer]. [recorder] is the test seam.
  AudioRecorderPlugin({
    required FileWriter writer,
    required StorageRoot storageRoot,
    record.AudioRecorder? recorder,
  }) : _writer = writer,
       _storageRoot = storageRoot,
       _recorder = recorder ?? record.AudioRecorder();

  final FileWriter _writer;
  final StorageRoot _storageRoot;
  final record.AudioRecorder _recorder;
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
    try {
      _phase = AudioRecorderPhase.permission;
      _emit();
      if (!await _recorder.hasPermission()) {
        _phase = AudioRecorderPhase.failed;
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
      final File staging = File(
        '${folder.path}/${_relative(relativePath)}$_stagingSuffix',
      );
      if (await staging.exists() ||
          await File('${folder.path}/${_relative(relativePath)}').exists()) {
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
      _emit();
      return FailureResult<void>(failure);
    } on Object {
      _phase = AudioRecorderPhase.failed;
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
      final File? staging = _staging;
      final String? path = _path;
      if (staging == null || path == null) {
        throw StateError('No audio take is active.');
      }
      final Result<WrittenFile> result = await _writer.copyIn(staging, path);
      switch (result) {
        case FailureResult<WrittenFile>(:final Failure failure):
          // The staging file is the only copy; it stays for the next attempt
          // and the orphan report (FE-SIMP-09).
          _phase = AudioRecorderPhase.failed;
          _emit();
          return FailureResult<Duration>(failure);
        case Success<WrittenFile>(:final WrittenFile value):
          final Duration duration =
              (await _WavTake.read(staging))?.duration ?? _elapsed;
          _completed = AudioRecording(
            relativePath: value.relativePath,
            sha256: value.sha256,
            byteLength: value.byteLength,
            duration: duration,
            mimeType: 'audio/wav',
          );
          _staging = null;
          await discardUnpublishedFile(staging);
          _phase = AudioRecorderPhase.completed;
          _emit();
          return Success<Duration>(duration);
      }
    } on Object catch (error) {
      _phase = AudioRecorderPhase.failed;
      _emit();
      return FailureResult<Duration>(Failure.from(error));
    }
  }

  @override
  Future<Result<AudioRecording?>> recover(String relativePath) async {
    try {
      final String path = _relative(relativePath);
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
      final Result<Directory> root = await _storageRoot.resolve();
      if (root case FailureResult<Directory>(:final Failure failure)) {
        return FailureResult<AudioRecording?>(failure);
      }
      final Directory folder = (root as Success<Directory>).value;
      final File published = File('${folder.path}/$path');
      if (await published.exists()) {
        // A kill may occur between publication and saving the session. Do
        // not overwrite that file; stream its hash and recover its metadata.
        return runIsolate<(String, String), AudioRecording?>(
          _readPublishedTake,
          (published.path, path),
        );
      }
      final File staging = File('${published.path}$_stagingSuffix');
      if (!await staging.exists()) {
        return const Success<AudioRecording?>(null);
      }
      final _WavTake? take = await _WavTake.read(staging, interrupted: true);
      if (take == null) throw const FormatException('Invalid staged WAV take.');
      final Result<WrittenFile> written = await _writer.write(
        take.repairedBytes(staging),
        path,
      );
      return written.map((WrittenFile file) {
        // Header repair produces a playable derivative. The raw .recording
        // file remains beside it, byte-for-byte, for recovery and inspection.
        return AudioRecording(
          relativePath: file.relativePath,
          sha256: file.sha256,
          byteLength: file.byteLength,
          duration: take.duration,
          mimeType: 'audio/wav',
        );
      });
    } on Object catch (error) {
      return FailureResult<AudioRecording?>(Failure.from(error));
    }
  }

  void _emit({double level = 0}) {
    if (!_states.isClosed) {
      _states.add(
        AudioRecorderState(phase: _phase, elapsed: _elapsed, level: level),
      );
    }
  }
}

/// [relativePath] with forward slashes, refused when it could leave the
/// storage folder. [FileWriter.copyIn] applies the same rule to the target.
String _relative(String relativePath) {
  final String relative = relativePath.replaceAll(r'\', '/').trim();
  final List<String> parts = relative.split('/');
  if (relative.isEmpty ||
      relative.startsWith('/') ||
      relative.contains(':') ||
      parts.any((String part) => part.isEmpty || part == '.' || part == '..')) {
    throw ValidationFailure(
      localizedMessage: Copy.messages.audioPathOutsideStorage,
      localizedRecovery: Copy.messages.audioStartFailedRecovery,
    );
  }
  return relative;
}
