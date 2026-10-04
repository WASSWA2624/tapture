part of 'audio_capture_event.dart';

/// The capture stopped taking audio. Everything before [atSample] is on
/// disk, with the take's header patched.
final class CapturePaused extends AudioCaptureEvent {
  /// A pause for [reason] at sample [atSample] of the take.
  const CapturePaused({required this.reason, required this.atSample});

  /// Why the capture paused.
  final CapturePauseReason reason;

  /// Samples captured when it paused.
  final int atSample;
}
