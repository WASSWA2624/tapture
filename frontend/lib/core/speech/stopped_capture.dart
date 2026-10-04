import 'package:tapture/core/audio/audio_recording.dart';

import 'stop_reason.dart';

/// What a live transcription session's stop hands back as soon as its
/// audio is published, while its transcript may still be finishing
/// (spec §30.4.5).
final class StoppedCapture {
  /// [audio] published after [captured] of audio, stopped for [reason].
  const StoppedCapture({
    required this.audio,
    required this.captured,
    required this.reason,
  });

  /// The published take, or null for memory-only dictation.
  final AudioRecording? audio;

  /// How much audio was captured, paused time excluded.
  final Duration captured;

  /// Why capture stopped.
  final StopReason reason;
}
