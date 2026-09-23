// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:record/record.dart' as record;
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';

import 'audio_recorder_service.dart';

/// Native microphone adapter. Plugin types stop in this core platform file;
/// capture depends only on [AudioRecorderService].
final class AudioRecorderPlugin implements AudioRecorderService {
  /// Creates an adapter whose chunks land through [writer].
  AudioRecorderPlugin({required FileWriter writer}) : _writer = writer;

  final FileWriter _writer;
  final record.AudioRecorder _recorder = record.AudioRecorder();
  final StreamController<AudioRecorderState> _states =
      StreamController<AudioRecorderState>.broadcast();
  Future<Result<WrittenFile>>? _write;
  StreamSubscription<record.Amplitude>? _amplitude;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  AudioRecorderPhase _phase = AudioRecorderPhase.idle;
  AudioRecording? _completed;
  String? _path;

  @override
  Stream<AudioRecorderState> get state => _states.stream;

  @override
  AudioRecording? get completed => _completed;

  @override
  Future<Result<void>> start(String relativePath) async {
    try {
      _phase = AudioRecorderPhase.permission;
      _emit();
      if (!await _recorder.hasPermission()) {
        _phase = AudioRecorderPhase.failed;
        _emit();
        return const FailureResult<void>(
          PermissionFailure(
            message: Copy.audioPermissionDenied,
            recoveryAction: Copy.audioPermissionRecovery,
          ),
        );
      }
      _path = relativePath;
      _completed = null;
      _elapsed = Duration.zero;
      final Stream<List<int>> stream = await _recorder.startStream(
        const record.RecordConfig(encoder: record.AudioEncoder.wav),
      );
      _write = _writer.write(stream, relativePath);
      _phase = AudioRecorderPhase.recording;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (_phase == AudioRecorderPhase.recording) {
          _elapsed += const Duration(milliseconds: 100);
          _emit();
        }
      });
      _amplitude = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((record.Amplitude value) {
            _emit(level: ((value.current + 60) / 60).clamp(0, 1));
          });
      _emit();
      return const Success<void>(null);
    } on Object catch (error) {
      _phase = AudioRecorderPhase.failed;
      _emit();
      return FailureResult<void>(Failure.from(error));
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
      final Future<Result<WrittenFile>>? write = _write;
      if (write == null || _path == null) {
        throw StateError('No audio write is active.');
      }
      final Result<WrittenFile> result = await write;
      switch (result) {
        case FailureResult<WrittenFile>(:final Failure failure):
          _phase = AudioRecorderPhase.failed;
          _emit();
          return FailureResult<Duration>(failure);
        case Success<WrittenFile>(:final WrittenFile value):
          _completed = AudioRecording(
            relativePath: value.relativePath,
            sha256: value.sha256,
            byteLength: value.byteLength,
            duration: _elapsed,
            mimeType: 'audio/wav',
          );
          _phase = AudioRecorderPhase.completed;
          _emit();
          return Success<Duration>(_elapsed);
      }
    } on Object catch (error) {
      _phase = AudioRecorderPhase.failed;
      _emit();
      return FailureResult<Duration>(Failure.from(error));
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
