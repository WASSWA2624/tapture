part of 'audio_capture_event.dart';

/// The capture is taking audio again; the timeline continues at [atSample].
final class CaptureResumed extends AudioCaptureEvent {
  /// A resume at sample [atSample] of the take.
  const CaptureResumed({required this.atSample});

  /// Samples captured when it resumed.
  final int atSample;
}
