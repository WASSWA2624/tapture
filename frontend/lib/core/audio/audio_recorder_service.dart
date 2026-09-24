import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';

import 'audio_recording.dart';

export 'audio_recording.dart';

part 'audio_recorder_state.dart';

/// Records walkthrough audio to a file via [FileWriter] chunks. Never
/// transcribed here (FE-SEC-04). Features never call a recorder plugin
/// (FE-STR-11).
abstract interface class AudioRecorderService {
  /// Unavailable stand-in until [main] overrides.
  const factory AudioRecorderService.unavailable() = _UnavailableAudioRecorder;

  /// Scripted stand-in writing silence chunks through [writer].
  factory AudioRecorderService.fake({
    FileWriter? writer,
    Failure? startFailure,
    Duration tick = AppConstants.audioMeterTick,
  }) {
    return _FakeAudioRecorder(
      writer: writer,
      startFailure: startFailure,
      tick: tick,
    );
  }

  /// Live recorder status.
  Stream<AudioRecorderState> get state;

  /// Metadata from the last fully flushed recording.
  AudioRecording? get completed;

  /// Starts writing to [relativePath] under the storage root.
  Future<Result<void>> start(String relativePath);

  /// Pauses chunk writes; elapsed freezes.
  Future<Result<void>> pause();

  /// Resumes after [pause].
  Future<Result<void>> resume();

  /// Finalises the file and returns elapsed duration.
  Future<Result<Duration>> stop();
}

/// Process-wide recorder. Default is unavailable.
final Provider<AudioRecorderService> audioRecorderServiceProvider =
    Provider<AudioRecorderService>((Ref _) {
      return const AudioRecorderService.unavailable();
    });

final class _UnavailableAudioRecorder implements AudioRecorderService {
  const _UnavailableAudioRecorder();

  static const ProviderFailure _fail = ProviderFailure(
    message: Copy.audioRecorderUnavailable,
  );

  @override
  Stream<AudioRecorderState> get state => Stream<AudioRecorderState>.value(
    const AudioRecorderState(phase: AudioRecorderPhase.idle),
  );

  @override
  AudioRecording? get completed => null;

  @override
  Future<Result<void>> start(String relativePath) async {
    return const FailureResult<void>(_fail);
  }

  @override
  Future<Result<void>> pause() async => const Success<void>(null);

  @override
  Future<Result<void>> resume() async => const Success<void>(null);

  @override
  Future<Result<Duration>> stop() async {
    return const FailureResult<Duration>(_fail);
  }
}

final class _FakeAudioRecorder implements AudioRecorderService {
  _FakeAudioRecorder({
    required this.writer,
    required this.startFailure,
    required this.tick,
  });

  final FileWriter? writer;
  final Failure? startFailure;
  final Duration tick;

  final StreamController<AudioRecorderState> _controller =
      StreamController<AudioRecorderState>.broadcast();
  AudioRecorderPhase _phase = AudioRecorderPhase.idle;
  Duration _elapsed = Duration.zero;
  double _level = 0;
  Timer? _timer;
  final List<List<int>> _chunks = <List<int>>[];
  String? _path;
  AudioRecording? _completed;

  @override
  AudioRecording? get completed => _completed;

  @override
  Stream<AudioRecorderState> get state => _controller.stream;

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(
        AudioRecorderState(phase: _phase, elapsed: _elapsed, level: _level),
      );
    }
  }

  @override
  Future<Result<void>> start(String relativePath) async {
    final Failure? failure = startFailure;
    if (failure != null) {
      return FailureResult<void>(failure);
    }
    _path = relativePath;
    _completed = null;
    _chunks.clear();
    _elapsed = Duration.zero;
    _phase = AudioRecorderPhase.recording;
    _level = 0.4;
    _timer?.cancel();
    _timer = Timer.periodic(tick, (_) {
      if (_phase == AudioRecorderPhase.recording) {
        _elapsed += tick;
        _chunks.add(Uint8List(64));
        _level = (_level + 0.1) % 1.0;
        _emit();
      }
    });
    _emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> pause() async {
    if (_phase == AudioRecorderPhase.recording) {
      _phase = AudioRecorderPhase.paused;
      _emit();
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> resume() async {
    if (_phase == AudioRecorderPhase.paused) {
      _phase = AudioRecorderPhase.recording;
      _emit();
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<Duration>> stop() async {
    _timer?.cancel();
    _timer = null;
    final Duration elapsed = _elapsed;
    final String? path = _path;
    final FileWriter? fileWriter = writer;
    if (path != null && fileWriter != null && _chunks.isNotEmpty) {
      final Result<WrittenFile> written = await fileWriter.write(
        Stream<List<int>>.fromIterable(_chunks),
        path,
      );
      final Failure? fail = written.fold((Failure f) => f, (_) => null);
      if (fail != null) {
        _phase = AudioRecorderPhase.idle;
        _emit();
        return FailureResult<Duration>(fail);
      }
      final WrittenFile file = (written as Success<WrittenFile>).value;
      _completed = AudioRecording(
        relativePath: file.relativePath,
        sha256: file.sha256,
        byteLength: file.byteLength,
        duration: elapsed,
        mimeType: 'audio/wav',
      );
    } else if (path != null) {
      _completed = AudioRecording(
        relativePath: path,
        sha256: '',
        byteLength: _chunks.fold<int>(0, (int n, List<int> c) => n + c.length),
        duration: elapsed,
        mimeType: 'audio/wav',
      );
    }
    _phase = AudioRecorderPhase.idle;
    _level = 0;
    _emit();
    return Success<Duration>(elapsed);
  }
}
