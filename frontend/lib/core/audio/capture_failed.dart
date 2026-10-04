part of 'audio_capture_event.dart';

/// Audio could not be kept, for example because the disk is full. The
/// microphone has stopped; what was already kept can still be published.
final class CaptureFailed extends AudioCaptureEvent {
  /// A capture that stopped keeping audio because of [failure].
  const CaptureFailed(this.failure);

  /// Why the audio could not be kept.
  final Failure failure;
}
