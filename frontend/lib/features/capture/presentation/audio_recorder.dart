import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/audio/audio_recorder_service.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_recording_bar.dart';
import 'package:tapture/core/widgets/app_recording_phase.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/state_refresh.dart';

/// Walkthrough audio recorder with elapsed and level.
final class AudioRecorder extends StatefulWidget {
  /// Creates a recorder widget.
  const AudioRecorder({
    required this.recorder,
    required this.relativePath,
    this.onStopped,
    this.onCompleted,
    super.key,
  });

  /// Audio port.
  final AudioRecorderService recorder;

  /// Destination under the project folder.
  final String relativePath;

  /// Finished duration.
  final ValueChanged<Duration>? onStopped;

  /// Durable file metadata after stop.
  final ValueChanged<AudioRecording>? onCompleted;

  @override
  State<AudioRecorder> createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder>
    with WidgetsBindingObserver, StateRefresh {
  AudioRecorderState _state = const AudioRecorderState(
    phase: AudioRecorderPhase.idle,
  );
  StreamSubscription<AudioRecorderState>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = widget.recorder.state.listen((AudioRecorderState next) {
      if (mounted) {
        refresh(() => _state = next);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_state.phase != AudioRecorderPhase.recording) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(widget.recorder.pause());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nothing to show until a take starts, and nothing once it is saved: the
    // capture page lists saved clips itself.
    if (_state.phase == AudioRecorderPhase.idle ||
        _state.phase == AudioRecorderPhase.completed) {
      return const SizedBox.shrink();
    }
    final LocalizedCopy localCopy = Copy.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Space.x2),
      child: AppRecordingBar(
        phase: _barPhase(_state.phase),
        elapsed: _state.elapsed,
        level: _state.level,
        status: localCopy.audioRecorderStatus(_state.phase.name),
        onPause: () => widget.recorder.pause(),
        onResume: () => widget.recorder.resume(),
        onStop: _stop,
      ),
    );
  }

  /// A failed take has no controls of its own: the capture page starts the
  /// next one, so it shows as idle with its status.
  static AppRecordingPhase _barPhase(AudioRecorderPhase phase) {
    return switch (phase) {
      AudioRecorderPhase.permission => AppRecordingPhase.starting,
      AudioRecorderPhase.recording => AppRecordingPhase.recording,
      AudioRecorderPhase.paused => AppRecordingPhase.paused,
      AudioRecorderPhase.finalizing => AppRecordingPhase.finishing,
      AudioRecorderPhase.idle ||
      AudioRecorderPhase.failed ||
      AudioRecorderPhase.completed => AppRecordingPhase.idle,
    };
  }

  Future<void> _stop() async {
    final Result<Duration> stopped = await widget.recorder.stop();
    // The finished take is still handed on if the bar has left the screen;
    // only the error snack needs a mounted context.
    stopped.fold(
      (Failure failure) {
        if (!mounted) {
          return;
        }
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
      },
      (Duration elapsed) {
        widget.onStopped?.call(elapsed);
        final AudioRecording? completed = widget.recorder.completed;
        if (completed != null) {
          widget.onCompleted?.call(completed);
        }
      },
    );
  }
}
