import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tapture/core/audio/audio_recorder_service.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

/// Walkthrough audio recorder with elapsed and level.
final class AudioRecorder extends StatefulWidget {
  /// Creates a recorder widget.
  const AudioRecorder({
    required this.recorder,
    required this.relativePath,
    this.onStopped,
    super.key,
  });

  /// Audio port.
  final AudioRecorderService recorder;

  /// Destination under the project folder.
  final String relativePath;

  /// Finished duration.
  final ValueChanged<Duration>? onStopped;

  @override
  State<AudioRecorder> createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  AudioRecorderState _state = const AudioRecorderState(
    phase: AudioRecorderPhase.idle,
  );
  StreamSubscription<AudioRecorderState>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.recorder.state.listen((AudioRecorderState next) {
      if (mounted) {
        setState(() => _state = next);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final Result<void> result = await widget.recorder.start(
      widget.relativePath,
    );
    result.fold((Failure failure) {
      showAppSnack(context, failure.message, tone: SnackTone.error);
    }, (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text('${_state.phase.name} ${_state.elapsed.inSeconds}s'),
        LinearProgressIndicator(value: _state.level.clamp(0.0, 1.0)),
        Row(
          children: <Widget>[
            if (_state.phase == AudioRecorderPhase.idle)
              AppButton(label: Copy.captureRecordAudio, onPressed: _start),
            if (_state.phase == AudioRecorderPhase.recording)
              AppButton(
                label: Copy.capturePauseAudio,
                onPressed: () => widget.recorder.pause(),
              ),
            if (_state.phase == AudioRecorderPhase.paused)
              AppButton(
                label: Copy.captureRecordAudio,
                onPressed: () => widget.recorder.resume(),
              ),
            if (_state.phase != AudioRecorderPhase.idle)
              AppButton(
                label: Copy.captureStopAudio,
                onPressed: () async {
                  final Result<Duration> stopped = await widget.recorder.stop();
                  stopped.fold((Failure failure) {
                    showAppSnack(
                      context,
                      failure.message,
                      tone: SnackTone.error,
                    );
                  }, (Duration elapsed) => widget.onStopped?.call(elapsed));
                },
              ),
          ],
        ),
      ],
    );
  }
}
